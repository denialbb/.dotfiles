#!/usr/bin/env python3
"""Lid-gate fingerprint polling in omarchy lock Service.qml. Idempotent."""
import sys

P = "/usr/share/omarchy/shell/plugins/lock/Service.qml"
src = open(P).read()
orig = src

def sub(old, new, count=1):
    global src
    found = src.count(old)
    assert found == count, f"expected {count}x, found {found}x: {old[:70]!r}"
    src = src.replace(old, new)

if "property bool lidOpen" not in src:
    sub("""  property bool usbKeyPresent: false
  property bool usbAuthenticating: false
""", """  property bool usbKeyPresent: false
  property bool usbAuthenticating: false
  // Lid gate: polling the swipe sensor while the lid is shut only cooks it
  // (fprintd disables the device to prevent overheating). Default open so a
  // missing /proc path fails safe to working fingerprint.
  property bool lidOpen: true
""")

if "function refreshLidStatus" not in src:
    sub("""  function refreshUsbKeyStatus() {
    if (!usbCheckProc.running) usbCheckProc.running = true
  }
""", """  function refreshUsbKeyStatus() {
    if (!usbCheckProc.running) usbCheckProc.running = true
  }

  function refreshLidStatus() {
    if (!lidCheckProc.running) lidCheckProc.running = true
  }
""")

if "root.refreshLidStatus()" not in src:
    sub("""    Qt.callLater(function() {
      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.refreshUsbKeyStatus()
    })""", """    Qt.callLater(function() {
      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.refreshUsbKeyStatus()
      root.refreshLidStatus()
    })""")
    sub("""      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.refreshUsbKeyStatus()
      root.previewVisible = true""", """      root.refreshBackground()
      root.refreshFingerprintStatus()
      root.refreshUsbKeyStatus()
      root.refreshLidStatus()
      root.previewVisible = true""")
    sub("""    refreshBackground()
    refreshFingerprintStatus()
    refreshUsbKeyStatus()
    checkStrandedLock()""", """    refreshBackground()
    refreshFingerprintStatus()
    refreshUsbKeyStatus()
    refreshLidStatus()
    checkStrandedLock()""")

if "root.lidOpen" not in src.replace("property bool lidOpen", ""):
    sub("""    if (!lockRequested || !sessionLock.secure || !fingerprintConfigured) return
    if (root.usbKeyPresent) return // USB key takes over: no swipe, no sensor heat""",
"""    if (!lockRequested || !sessionLock.secure || !fingerprintConfigured) return
    if (root.usbKeyPresent) return // USB key takes over: no swipe, no sensor heat
    if (!root.lidOpen) return // lid shut: sensor off""")
    sub("""    } else if (fingerprintConfigured) {
      fingerprintRetryTimer.restart()""", """    } else if (fingerprintConfigured && root.lidOpen) {
      fingerprintRetryTimer.restart()""")
    sub("""      if (root.lockRequested && root.fingerprintConfigured) fingerprintRetryTimer.restart()""",
"""      if (root.lockRequested && root.fingerprintConfigured && root.lidOpen) fingerprintRetryTimer.restart()""")

if "onLidOpenChanged" not in src:
    sub("""  onUsbKeyPresentChanged: {
    if (root.usbKeyPresent) {
      if (fingerprintPam.active) fingerprintPam.abort()
      fingerprintAuthenticating = false
      fingerprintRetryTimer.stop()
    } else {
      if (usbPam.active) usbPam.abort()
      usbAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured) root.startFingerprint()
    }
  }
""", """  onUsbKeyPresentChanged: {
    if (root.usbKeyPresent) {
      if (fingerprintPam.active) fingerprintPam.abort()
      fingerprintAuthenticating = false
      fingerprintRetryTimer.stop()
    } else {
      if (usbPam.active) usbPam.abort()
      usbAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured) root.startFingerprint()
    }
  }

  onLidOpenChanged: {
    if (!root.lidOpen) {
      if (fingerprintPam.active) fingerprintPam.abort()
      fingerprintAuthenticating = false
      fingerprintRetryTimer.stop()
    } else {
      if (root.lockRequested && root.fingerprintConfigured) root.startFingerprint()
    }
  }
""")

if "id: lidCheckProc" not in src:
    sub("""  // Presence probe only: mounted pam_usb volume, no pad use (no pad burn).
  Process {
    id: usbCheckProc""", """  // Lid probe: /proc/acpi has no inotify, so poll while locked (see usbPollTimer).
  // Any lid reporting closed means shut; unknown/missing reads as open.
  Process {
    id: lidCheckProc
    command: ["bash", "-c", "grep -qis closed /proc/acpi/button/lid/*/state 2>/dev/null && echo no || echo yes"]
    stdout: StdioCollector { id: lidCheckStdout; waitForEnd: true }
    onExited: {
      root.lidOpen = String(lidCheckStdout.text || "").trim() === "yes"
    }
  }

  // Presence probe only: mounted pam_usb volume, no pad use (no pad burn).
  Process {
    id: usbCheckProc""")

if "refreshLidStatus()" not in src.split("id: usbPollTimer")[1].split("}")[0]:
    sub("""  // Re-checks the USB key while locked so inserting/removing the key
  // mid-lock updates the icon and (dis)arms passwordless unlock.
  Timer {
    id: usbPollTimer
    interval: 5000
    repeat: true
    running: root.lockRequested
    onTriggered: root.refreshUsbKeyStatus()
  }""", """  // Re-checks the USB key and lid state while locked so inserting/removing
  // the key mid-lock updates the icon and (dis)arms passwordless unlock, and
  // shutting the lid stops sensor polling (sensor heat) until it reopens.
  Timer {
    id: usbPollTimer
    interval: 5000
    repeat: true
    running: root.lockRequested
    onTriggered: { root.refreshUsbKeyStatus(); root.refreshLidStatus() }
  }""")

if "lidOpen: root.lidOpen" not in src:
    sub("""        fingerprint: root.fingerprintConfigured,""",
"""        fingerprint: root.fingerprintConfigured,
        lidOpen: root.lidOpen,""")

if src == orig:
    print("already-applied")
else:
    open(P, "w").write(src)
    print("patched-ok")
