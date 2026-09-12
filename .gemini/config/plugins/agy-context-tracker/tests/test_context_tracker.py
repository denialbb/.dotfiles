"""Unit tests for agy-context-tracker plugin."""

import importlib.util
import io
import json
import os
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch

# Scripts directory (for subprocess tests)
SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts"))


def _load_module(name: str):
    """Load a plugin script by path (no sys.path mutation needed)."""
    spec = importlib.util.spec_from_file_location(
        name, os.path.join(SCRIPTS_DIR, f"{name}.py")
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


context_guard = _load_module("context_guard")
statusline = _load_module("statusline")


class TestStatusline(unittest.TestCase):
    """Test suite for statusline calculations and formatting."""

    def test_get_model_context_window_defaults(self):
        self.assertEqual(
            statusline.get_model_context_window("Gemini 3.8 Flash (Medium)"),
            1_048_576,
        )
        self.assertEqual(
            statusline.get_model_context_window("gemini-1.5-flash"),
            1_048_576,
        )
        self.assertEqual(
            statusline.get_model_context_window("unknown-model"),
            1_048_576,
        )

    def test_get_model_context_window_pro(self):
        self.assertEqual(
            statusline.get_model_context_window("gemini-3.8-pro"),
            2_097_152,
        )
        self.assertEqual(
            statusline.get_model_context_window("Gemini 1.5 Pro"),
            2_097_152,
        )

    def test_get_model_context_window_third_party(self):
        self.assertEqual(
            statusline.get_model_context_window("claude-3-5-sonnet"),
            200_000,
        )
        self.assertEqual(
            statusline.get_model_context_window("gpt-4o"),
            128_000,
        )

    def test_format_token_count(self):
        self.assertEqual(statusline.format_token_count(450), "450")
        self.assertEqual(statusline.format_token_count(24_500), "24.5k")
        self.assertEqual(statusline.format_token_count(1_048_576), "1.0M")
        self.assertEqual(statusline.format_token_count(2_097_152), "2.1M")

    def test_format_status_badge(self):
        badge = statusline.format_status_badge("Gemini 3.8 Flash", 24_500, 1_048_576)
        self.assertIn("[Gemini 3.8 Flash]", badge)
        self.assertIn("24.5k/1.0M", badge)
        self.assertIn("2.3%", badge)

    def test_clean_model_display_name(self):
        self.assertEqual(
            statusline.clean_model_display_name("Gemini 3.8 Flash (Medium)"),
            "Gemini 3.8 Flash",
        )
        self.assertEqual(
            statusline.clean_model_display_name("gemini-1.5-pro"),
            "Gemini 1.5 Pro",
        )

    def test_parse_transcript_tokens_explicit(self):
        with tempfile.NamedTemporaryFile(mode="w+", delete=False) as f:
            f.write(json.dumps({"step_index": 0, "total_tokens": 1200}) + "\n")
            f.write(json.dumps({"step_index": 1, "total_tokens": 3400}) + "\n")
            f_path = f.name
        try:
            tokens = statusline.parse_transcript_tokens(f_path)
            self.assertEqual(tokens, 3400)
        finally:
            os.remove(f_path)

    def test_parse_transcript_tokens_character_estimate(self):
        content_text = "A" * 400
        with tempfile.NamedTemporaryFile(mode="w+", delete=False) as f:
            f.write(json.dumps({"step_index": 0, "content": content_text}) + "\n")
            f_path = f.name
        try:
            tokens = statusline.parse_transcript_tokens(f_path)
            self.assertGreaterEqual(tokens, 100)
        finally:
            os.remove(f_path)

    def test_estimate_sqlite_tokens(self):
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db_path = f.name
        try:
            conn = sqlite3.connect(db_path)
            cur = conn.cursor()
            cur.execute("CREATE TABLE steps (idx INT PRIMARY KEY, step_payload BLOB)")
            cur.execute("INSERT INTO steps VALUES (1, ?)", (b"X" * 800,))
            conn.commit()
            conn.close()

            tokens = statusline.estimate_sqlite_tokens(db_path)
            self.assertEqual(tokens, 200)
        finally:
            os.remove(db_path)

    def test_statusline_main_cli_output(self):
        with (
            patch("sys.stdin", io.StringIO('{"modelName": "Gemini 3.8 Flash"}')),
            patch("sys.stdout", new_callable=io.StringIO) as out,
            patch(
                "statusline.resolve_active_context",
                return_value=("Gemini 3.8 Flash", 24_500, 1_048_576),
            ),
        ):
            statusline.main()
            output = out.getvalue().strip()
            self.assertIn("Gemini 3.8 Flash", output)
            self.assertIn("24.5k/1.0M", output)
            self.assertIn("2.3%", output)


class TestContextGuard(unittest.TestCase):
    """Test suite for context guard hook."""

    def test_calculate_usage_percentage(self):
        pct = context_guard.calculate_usage_percentage(840_000, 1_000_000)
        self.assertAlmostEqual(pct, 84.0, places=1)

    def test_generate_guard_response_under_threshold(self):
        res = context_guard.generate_guard_response(
            tokens=50_000, window=1_048_576, threshold=0.80
        )
        self.assertEqual(res, {"injectSteps": []})

    def test_generate_guard_response_exceeds_threshold(self):
        res = context_guard.generate_guard_response(
            tokens=850_000, window=1_000_000, threshold=0.80
        )
        self.assertEqual(len(res["injectSteps"]), 1)
        msg = res["injectSteps"][0]["ephemeralMessage"]
        self.assertIn("WARNING: Context window usage is at 85%", msg)
        self.assertIn("850,000 / 1,000,000 tokens", msg)
        self.assertIn("/handoff", msg)

    def test_context_guard_main_hook_safe(self):
        payload = {
            "conversationId": "test-conv",
            "modelName": "gemini-3.8-flash",
            "transcriptPath": "/nonexistent/path/transcript.jsonl",
        }
        with (
            patch("sys.stdin", io.StringIO(json.dumps(payload))),
            patch("sys.stdout", new_callable=io.StringIO) as out,
        ):
            context_guard.main()
            res = json.loads(out.getvalue())
            self.assertEqual(res, {"injectSteps": []})

    def test_context_guard_main_hook_triggered(self):
        huge_content = "a" * 3_500_000
        with tempfile.NamedTemporaryFile(mode="w+", delete=False) as temp_transcript:
            temp_transcript.write(json.dumps({"content": huge_content}) + "\n")
            temp_path = temp_transcript.name
        payload = {
            "modelName": "Gemini 3.8 Flash",
            "transcriptPath": temp_path,
        }
        try:
            with (
                patch("sys.stdin", io.StringIO(json.dumps(payload))),
                patch("sys.stdout", new_callable=io.StringIO) as out,
            ):
                context_guard.main()
                res = json.loads(out.getvalue())
                self.assertEqual(len(res.get("injectSteps", [])), 1)
                self.assertIn("WARNING", res["injectSteps"][0]["ephemeralMessage"])
        finally:
            os.remove(temp_transcript.name)


if __name__ == "__main__":
    unittest.main()


class TestEdgeCasesAndSubprocess(unittest.TestCase):
    """Test boundary conditions, errors, and subprocess execution."""

    def test_threshold_boundary_conditions(self):
        res_80 = context_guard.generate_guard_response(800_000, 1_000_000)
        self.assertEqual(res_80, {"injectSteps": []})

        res_80_1 = context_guard.generate_guard_response(801_000, 1_000_000)
        self.assertEqual(len(res_80_1["injectSteps"]), 1)

    def test_sqlite_invalid_schema(self):
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db_path = f.name
        try:
            conn = sqlite3.connect(db_path)
            conn.execute("CREATE TABLE foo (bar TEXT)")
            conn.commit()
            conn.close()
            tokens = statusline.estimate_sqlite_tokens(db_path)
            self.assertEqual(tokens, 0)
        finally:
            os.remove(db_path)

    def test_subprocess_context_guard(self):
        import subprocess

        script = os.path.join(SCRIPTS_DIR, "context_guard.py")
        payload = json.dumps({"modelName": "gemini-3.8-flash"})
        proc = subprocess.run(
            [sys.executable, script],
            input=payload,
            text=True,
            capture_output=True,
            check=True,
        )
        data = json.loads(proc.stdout)
        self.assertEqual(data, {"injectSteps": []})

    def test_subprocess_statusline(self):
        import subprocess

        script = os.path.join(SCRIPTS_DIR, "statusline.py")
        proc = subprocess.run(
            [sys.executable, script],
            input="",
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(proc.returncode, 0)
        self.assertIn("Gemini", proc.stdout)
        self.assertIn("%", proc.stdout)
