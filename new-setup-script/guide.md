Excellent question. I designed the script with a straightforward debugging system. Here is a comprehensive guide on how to use it effectively.

---

### How to Debug the Bash Script

The script includes a built-in debug mode that you can activate with a simple command-line flag: `--debug`.

Using this flag enables two powerful types of diagnostic output, giving you a complete picture of what the script is doing.

#### The Basic Command

To run the entire script in debug mode, simply add the `--debug` flag to your command:

```bash
./setup.sh --debug
```

#### What to Expect: The Two Types of Debug Output

When you run with `--debug`, your terminal will become much more verbose. You will see two kinds of special output mixed in with the script's normal messages:

**1. Command Tracing (Lines starting with `+`)**

This is Bash's built-in `xtrace` feature. It prints the **exact command** that is about to be executed, after all variables have been expanded.

- **What it looks like:**
  ```
  + print_info 'Installing 1 DNF groups...'
  + sudo dnf install -y @development-tools
  ```
- **Why it's useful:**
  This shows you precisely what is being run. It's perfect for diagnosing:
  - Typos in commands.
  - Variables that are empty or have the wrong value.
  - Problems with file paths.
  - Permission errors (you see exactly which command needed `sudo`).

**2. Custom Debug Messages (Lines starting with `🐞 [DEBUG]`)**

These are user-friendly messages that I added to the script to explain its **internal logic and state**. They tell you _why_ a command is being run or what data the script is working with.

- **What it looks like:**
  ```
  🐞 [DEBUG] Debug mode enabled. Activating verbose command tracing (set -x).
  🐞 [DEBUG] Final list of groups to install: @development-tools
  🐞 [DEBUG] Content for '/etc/dnf/dnf.conf':
  ---
  [main]
  gpgcheck=1
  installonly_limit=3
  ...
  ---
  ```
- **Why it's useful:**
  This shows you what the script is "thinking." It's perfect for diagnosing:
  - Why a certain `if` condition was met (or not met).
  - The contents of an array before it's used in a command.
  - Which files are being read or written to.

---

### Practical Examples

Here are a few common scenarios where debugging is incredibly helpful.

#### Scenario 1: Debugging a Specific Task

Imagine the package installation is failing, but you don't want to run the entire script just to see the error. You can combine a task flag with the debug flag to isolate the problem.

```bash
# This will ONLY run the package installation step, but with full debug output.
./setup.sh --install-packages --debug
```

This is the most efficient way to troubleshoot a specific part of the script.

#### Scenario 2: Checking the Logic of User Configuration

If you want to see exactly what commands are being run to set up your user (e.g., to verify the `git config` commands), you can do this:

```bash
./setup.sh --configure-user --debug
```

You will see the `+ run_as_user git config --global user.name aahsnr` lines, confirming the exact commands being executed on your behalf.

#### Scenario 3: Saving a Full Debug Log to a File

The debug output can be very long. To analyze it carefully, it's best to save it to a log file. The script is designed to send all debug output (`xtrace` and custom messages) to **Standard Error (stderr)**.

You can redirect this output to a file like so:

```bash
# Runs the full script in debug mode.
# - Normal output goes to 'setup.log'.
# - All debug traces and errors go to 'debug_trace.log'.
./setup.sh --debug > setup.log 2> debug_trace.log
```

After the script finishes (or fails), you can open `debug_trace.log` in a text editor and search for errors or review the exact sequence of commands that led to a problem.

### Summary

| To achieve this...                                  | Use this command...                      |
| --------------------------------------------------- | ---------------------------------------- |
| Run the entire setup with verbose debugging         | `./setup.sh --debug`                     |
| Isolate and debug only one specific step            | `./setup.sh --harden-system --debug`     |
| Save all the debug information to a file for review | `./setup.sh --debug 2> debug_output.txt` |
