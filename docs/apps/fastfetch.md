# Fastfetch Configuration

Fastfetch is a lightweight, ultra-fast system information tool configured to display system hardware, environment telemetry, and desktop branding in terminal sessions.

---

## File Structure & Paths

* **Repository configuration:** `~/dotfiles/fastfetch/config.jsonc`
* **Custom logo art:** `~/dotfiles/fastfetch/logo.txt`
* **Target symlink:** `~/.config/fastfetch` -> `~/dotfiles/fastfetch`

---

## Layout & Visual Architecture

The configuration leverages custom braille ASCII art alongside structured telemetry modules styled with the system's red primary accent:

### 1. Logo Section
* **Type:** File-based logo sourced from `~/.config/fastfetch/logo.txt`.
* **Art style:** High-density Unicode/Braille graphic emblem.
* **Color:** Pure red (`"1": "red"`).
* **Spacing:** 4 characters of right-side padding to separate art from text keys.

### 2. Display and Bar Formatting
* **Separator:** Custom arrow delimiter colored red.
* **Progress Bars:** Dual-line glyph bars (`━` elapsed, `─` remaining) enclosed in bracket borders `[ ]` for graphical representation of:
  * System Memory (RAM) utilization.
  * Root disk partition capacity (`used / total (percentage)`).
  * Battery charge level and AC power status.

### 3. Displayed Modules
* **User & Host:** `user@host` with custom color formatting.
* **Operating System:** Debian GNU/Linux 13 (Trixie) x86_64.
* **Kernel:** Active Linux kernel build and architecture.
* **Uptime:** Session elapsed time.
* **Packages:** Total dpkg package count.
* **Shell:** Current interactive shell binary.
* **Window Manager:** Hyprland compositor version and protocol.
* **Hardware:** CPU model and maximum frequency, integrated GPU chipset.
* **Memory & Storage:** Real-time RAM and storage consumption.
* **Battery:** Charge percentage and charging status.
* **Terminal Palette:** 8 circular color swatches positioned at the base.

---

## Execution & Usage

To invoke fastfetch using this configuration:

```bash
fastfetch
```
