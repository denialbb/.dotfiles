import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

# Add scripts directory to path for direct imports
PLUGIN_DIR = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = PLUGIN_DIR / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

try:
    import steer_hook
except ImportError:
    steer_hook = None


class TestSteerHookUnits(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.state_dir = Path(self.tmp_dir.name)

    def tearDown(self):
        self.tmp_dir.cleanup()

    def test_module_exists(self):
        self.assertIsNotNone(steer_hook, "steer_hook module should exist")

    def test_clean_message_text(self):
        self.assertEqual(steer_hook.clean_message_text("/steer do this now"), "do this now")
        self.assertEqual(steer_hook.clean_message_text("/steer   focus on auth  "), "focus on auth")
        self.assertEqual(steer_hook.clean_message_text("normal steering message"), "normal steering message")
        self.assertEqual(steer_hook.clean_message_text("  trimmed message  "), "trimmed message")
        self.assertEqual(steer_hook.clean_message_text("/steer\twith tab"), "with tab")

    def test_is_steering_message(self):
        self.assertTrue(steer_hook.is_steering_message({"display": "please stop"}))
        self.assertTrue(steer_hook.is_steering_message({"display": "/steer do something"}))
        self.assertFalse(steer_hook.is_steering_message({"display": ""}))
        self.assertFalse(steer_hook.is_steering_message({"display": "   "}))
        # CLI slash commands that are not /steer should be skipped
        self.assertFalse(steer_hook.is_steering_message({"display": "/artifact", "type": "slash_command"}))
        self.assertFalse(steer_hook.is_steering_message({"display": "/usage", "type": "slash_command"}))
        # Explicit /steer slash command should be accepted
        self.assertTrue(steer_hook.is_steering_message({"display": "/steer run tests", "type": "slash_command"}))

    def test_read_and_save_state(self):
        state_file = self.state_dir / "test-state.json"
        self.assertEqual(steer_hook.read_state(state_file), {})

        sample_state = {"last_seen_timestamp": 123456789}
        steer_hook.save_state(state_file, sample_state)
        self.assertTrue(state_file.exists())
        self.assertEqual(steer_hook.read_state(state_file), sample_state)

    def test_format_inject_steps(self):
        self.assertEqual(steer_hook.format_inject_steps([]), [])
        steps = steer_hook.format_inject_steps(["make tests pass", "don't use mock"])
        expected = [
            {"userMessage": "make tests pass"},
            {"userMessage": "don't use mock"},
        ]
        self.assertEqual(steps, expected)

    def test_find_unseen_inputs(self):
        entries = [
            {"display": "old msg", "timestamp": 100, "conversationId": "c1"},
            {"display": "new msg 1", "timestamp": 200, "conversationId": "c1"},
            {"display": "new msg 2", "timestamp": 300, "conversationId": "c1"},
        ]
        unseen, max_ts = steer_hook.find_unseen_inputs(entries, last_seen_ts=150)
        self.assertEqual(len(unseen), 2)
        self.assertEqual(max_ts, 300)
        self.assertEqual(unseen[0]["display"], "new msg 1")
        self.assertEqual(unseen[1]["display"], "new msg 2")

    def test_read_history_entries(self):
        hist_file = self.state_dir / "history.jsonl"
        lines = [
            json.dumps({"display": "msg 1", "timestamp": 100, "conversationId": "c1"}),
            "invalid json line",
            json.dumps({"display": "msg 2", "timestamp": 200, "conversationId": "c2"}),
            json.dumps({"display": "msg 3", "timestamp": 300, "conversationId": "c1"}),
        ]
        hist_file.write_text("\n".join(lines), encoding="utf-8")

        entries = steer_hook.read_history_entries(hist_file, conv_id="c1")
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["timestamp"], 100)
        self.assertEqual(entries[1]["timestamp"], 300)

    def test_purge_history_entries(self):
        hist_file = self.state_dir / "history.jsonl"
        lines = [
            json.dumps({"display": "msg 1", "timestamp": 100, "conversationId": "c1"}),
            json.dumps({"display": "msg 2", "timestamp": 200, "conversationId": "c1"}),
            json.dumps({"display": "msg 3", "timestamp": 300, "conversationId": "c2"}),
        ]
        hist_file.write_text("\n".join(lines), encoding="utf-8")

        steer_hook.purge_history_entries(hist_file, "c1", {100})
        remaining = steer_hook.read_history_entries(hist_file, conv_id="c1")
        self.assertEqual(len(remaining), 1)
        self.assertEqual(remaining[0]["timestamp"], 200)

    def test_check_turn_duplicate(self):
        transcript_msgs = {"fix tests in auth"}
        injected = ["fix tests in auth", "other prompt"]
        dup, remaining = steer_hook.check_turn_duplicate(transcript_msgs, injected)
        self.assertEqual(dup, "fix tests in auth")
        self.assertEqual(remaining, ["other prompt"])

        dup2, remaining2 = steer_hook.check_turn_duplicate(transcript_msgs, ["unrelated"])
        self.assertIsNone(dup2)
        self.assertEqual(remaining2, ["unrelated"])


class TestSteerHookIntegration(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.base_dir = Path(self.tmp_dir.name)
        self.history_file = self.base_dir / "history.jsonl"
        self.state_file = self.base_dir / "agy-steer-state-test-conv.json"

    def tearDown(self):
        self.tmp_dir.cleanup()

    def test_process_steering_with_new_messages(self):
        entries = [
            {"display": "/steer cancel that and write docs", "timestamp": 2000, "conversationId": "test-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )
        self.state_file.write_text(
            json.dumps({"last_seen_timestamp": 1000}), encoding="utf-8"
        )

        hook_input = {"conversationId": "test-conv", "invocationNum": 2}
        result = steer_hook.process_steering(
            hook_input, history_path=self.history_file, state_path=self.state_file
        )

        expected = {
            "injectSteps": [
                {"userMessage": "cancel that and write docs"}
            ]
        }
        self.assertEqual(result, expected)

        updated_state = steer_hook.read_state(self.state_file)
        self.assertEqual(updated_state.get("last_seen_timestamp"), 2000)

    def test_process_steering_no_new_input(self):
        entries = [
            {"display": "already seen msg", "timestamp": 1000, "conversationId": "test-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )
        self.state_file.write_text(
            json.dumps({"last_seen_timestamp": 1000}), encoding="utf-8"
        )

        hook_input = {"conversationId": "test-conv", "invocationNum": 3}
        result = steer_hook.process_steering(
            hook_input, history_path=self.history_file, state_path=self.state_file
        )
        self.assertEqual(result, {"injectSteps": []})

    def test_process_steering_ignores_other_conversations(self):
        entries = [
            {"display": "msg for another conv", "timestamp": 2000, "conversationId": "other-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )
        self.state_file.write_text(
            json.dumps({"last_seen_timestamp": 1000}), encoding="utf-8"
        )

        hook_input = {"conversationId": "test-conv", "invocationNum": 2}
        result = steer_hook.process_steering(
            hook_input, history_path=self.history_file, state_path=self.state_file
        )
        self.assertEqual(result, {"injectSteps": []})

    def test_transcript_initial_prompt_not_duplicated(self):
        transcript_file = self.base_dir / "transcript.jsonl"
        transcript_entries = [
            {"step_index": 0, "type": "USER_INPUT", "content": "Initial prompt from user"}
        ]
        transcript_file.write_text(
            "\n".join(json.dumps(e) for e in transcript_entries), encoding="utf-8"
        )

        entries = [
            {"display": "Initial prompt from user", "timestamp": 1000, "conversationId": "test-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )

        hook_input = {
            "conversationId": "test-conv",
            "invocationNum": 1,
            "transcriptPath": str(transcript_file),
        }
        result = steer_hook.process_steering(
            hook_input, history_path=self.history_file, state_path=self.state_file
        )
        self.assertEqual(result, {"injectSteps": []})
        self.assertEqual(
            steer_hook.read_state(self.state_file).get("last_seen_timestamp"), 1000
        )

    def test_process_steering_missing_conv_id(self):
        result = steer_hook.process_steering({})
        self.assertEqual(result, {"injectSteps": []})

    def test_process_steering_corrupted_state(self):
        self.state_file.write_text("{not json", encoding="utf-8")
        entries = [
            {"display": "recovering from bad state", "timestamp": 100, "conversationId": "test-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )
        hook_input = {"conversationId": "test-conv", "invocationNum": 2}
        result = steer_hook.process_steering(
            hook_input, history_path=self.history_file, state_path=self.state_file
        )
        self.assertEqual(
            result,
            {"injectSteps": [{"userMessage": "recovering from bad state"}]},
        )
        self.assertEqual(
            steer_hook.read_state(self.state_file).get("last_seen_timestamp"), 100
        )

    def test_cli_execution_via_subprocess(self):
        script_path = SCRIPTS_DIR / "steer_hook.py"
        if not script_path.exists():
            self.skipTest("steer_hook.py does not exist yet")

        entries = [
            {"display": "/steer abort mission", "timestamp": 5000, "conversationId": "subproc-conv"},
        ]
        self.history_file.write_text(
            "\n".join(json.dumps(e) for e in entries), encoding="utf-8"
        )
        subproc_state = self.base_dir / "agy-steer-state-subproc-conv.json"
        subproc_state.write_text(
            json.dumps({"last_seen_timestamp": 4000}), encoding="utf-8"
        )

        hook_input = json.dumps({"conversationId": "subproc-conv", "invocationNum": 2})
        env = {
            **os.environ,
            "AGY_HISTORY_PATH": str(self.history_file),
            "AGY_STEER_STATE_DIR": str(self.base_dir),
        }
        res = subprocess.run(
            [sys.executable, str(script_path)],
            input=hook_input,
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )
        self.assertEqual(res.returncode, 0, f"Error: {res.stderr}")
        data = json.loads(res.stdout)
        self.assertEqual(
            data,
            {"injectSteps": [{"userMessage": "abort mission"}]},
        )


if __name__ == "__main__":
    unittest.main()
