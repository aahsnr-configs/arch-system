## Mastering SELinux: A Guide to Crafting Custom Policies for Your Fedora Applications

Taming SELinux to create custom security policies for your applications on Fedora may seem daunting, but with a systematic approach and the right tools, you can effectively confine your applications and enhance your system's security. This guide will walk you through the entire process, from initial analysis in permissive mode to deploying a robust, enforcing policy.

### Understanding the Ground Rules: SELinux Fundamentals

Before diving into policy creation, it's crucial to grasp a few core SELinux concepts:

  * **SELinux Modes:**

      * **Enforcing:** The default and most secure mode. SELinux actively blocks any action that violates the policy and logs the denial.
      * **Permissive:** SELinux does not block any actions but logs what it *would have* denied. This mode is essential for developing and debugging policies without breaking functionality.
      * **Disabled:** SELinux is completely turned off. This is not recommended as it leaves your system vulnerable and makes re-enabling SELinux more challenging due to incorrect file labeling.

  * **Security Contexts:** Every process and file on an SELinux-enabled system has a security context, which is a label that defines its security attributes. A context consists of four parts: `user:role:type:level`. For most policy development, the **type** is the most critical component. It's the primary mechanism for defining what a process (a "domain") can do and what files (an "object") it can access.

You can check the current SELinux mode with the `getenforce` command and view the security context of files and processes using the `-Z` option with `ls` and `ps` respectively (e.g., `ls -Z /path/to/file`, `ps auxZ | grep my_app`).

-----

### The Policy Creation Workflow: From Permissive to Enforcing

Creating a custom SELinux policy is an iterative process. Here's a proven workflow to follow:

#### Step 1: Laying the Groundwork in Permissive Mode

For a new application that doesn't have an existing SELinux policy, it will likely run in the `unconfined_service_t` domain, which, as the name suggests, is not heavily restricted. To begin creating a custom policy, your first step is to put SELinux into permissive mode. This allows your application to run without being blocked, while still logging all potential denials.

```bash
sudo setenforce 0
```

Now, run your application and exercise all of its functionalities. This will generate the necessary audit logs that you'll use to build your policy.

-----

#### Step 2: Generating the Initial Policy Structure

Fedora provides a convenient tool called `sepolicy` to generate a basic set of policy files for your new application. This saves you from writing a significant amount of boilerplate code.

First, you need to identify the executable for your application. For this example, let's assume your application's executable is located at `/usr/local/bin/my_app`.

Install the necessary tools:

```bash
sudo dnf install setools-console selinux-policy-devel
```

Now, generate the initial policy files:

```bash
sepolicy generate --name my_app_policy --path /usr/local/bin/my_app
```

This command will create a new directory named `my_app_policy` containing three key files:

  * `my_app_policy.te` (Type Enforcement): This is the main policy file where you'll define the rules that govern your application's behavior.
  * `my_app_policy.if` (Interface): This file defines how other SELinux-aware applications can interact with your application.
  * `my_app_policy.fc` (File Context): This file specifies the default security contexts for your application's files and directories.

-----

#### Step 3: Analyzing Audit Logs and Generating Rules

With your application running in permissive mode and the initial policy structure in place, it's time to analyze the audit logs for SELinux denials. The `audit2allow` tool is your primary ally in this step. It reads the audit logs and translates the denial messages into human-readable SELinux policy rules.

To see the denials and the corresponding `allow` rules, run:

```bash
ausearch -m avc -ts recent | audit2allow -a
```

The output will show the actions that were denied and the `allow` rules that would permit those actions. For example, you might see something like this:

```
allow my_app_t var_log_t:file { open read };
```

This rule would allow the `my_app_t` domain (your application's process type) to open and read files with the `var_log_t` type (typically log files in `/var/log`).

**A Word of Caution:** It's tempting to pipe the output of `audit2allow -a` directly into your `.te` file. **Avoid this.** Blindly allowing every denied action can create an overly permissive policy, defeating the purpose of SELinux. Carefully review each suggested rule to ensure it makes sense for your application's intended behavior.

-----

#### Step 4: Building and Installing Your Custom Policy Module

Once you've reviewed and added the necessary `allow` rules to your `my_app_policy.te` file, you need to compile and install your policy module.

Navigate to the directory containing your policy files (`my_app_policy`) and run the following commands:

```bash
make -f /usr/share/selinux/devel/Makefile
sudo semodule -i my_app_policy.pp
```

The `make` command will compile your `.te` file into a policy package (`.pp`). The `semodule -i` command then installs this package into the kernel.

-----

#### Step 5: Labeling Your Application's Files

After installing the policy module, you need to apply the correct security contexts to your application's files as defined in your `.fc` file. The `restorecon` command does this for you.

For your application's executable:

```bash
sudo restorecon -v /usr/local/bin/my_app
```

If your application uses other files (e.g., configuration files in `/etc`, data files in `/var/lib`), you'll need to add entries for them in your `my_app_policy.fc` file and then run `restorecon` on those paths as well.

-----

#### Step 6: Iterating and Refining Your Policy

At this point, you have a basic custom policy in place. The next steps involve a cycle of testing, analyzing, and refining:

1.  **Restart your application.**
2.  **Continue to exercise its functionality.**
3.  **Check for new SELinux denials:** `ausearch -m avc -ts recent | audit2allow -a`
4.  **Add new, well-vetted rules to your `my_app_policy.te` file.**
5.  **Rebuild and reinstall your policy module:**
    ```bash
    make -f /usr/share/selinux/devel/Makefile clean
    make -f /usr/share/selinux/devel/Makefile
    sudo semodule -u my_app_policy.pp
    ```
    (Note the use of `semodule -u` to update the existing module).
6.  **Repeat this process** until your application runs without generating any new SELinux denials.

-----

### Going Live: Switching to Enforcing Mode

Once you are confident that your SELinux policy is complete and your application runs smoothly in permissive mode without generating any denials, it's time to switch to enforcing mode and reap the full security benefits of SELinux.

```bash
sudo setenforce 1
```

After switching to enforcing mode, it's a good practice to thoroughly test your application one more time to ensure everything is working as expected. Keep an eye on the audit logs for any unexpected denials that might have been missed in permissive mode.

By following this structured approach, you can systematically create effective SELinux policies for your applications in Fedora, significantly strengthening your system's security posture. Remember that policy creation is an iterative process that requires careful analysis and a clear understanding of your application's behavior.
