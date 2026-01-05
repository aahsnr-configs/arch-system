Based on your request for an **up-to-date** guide that specifically implements the **openSUSE Btrfs layout** (nested subvolumes) to enable the native `snapper rollback` command on Arch Linux, here is the best resource available as of 2025.

### **Recommended Guide**

**Title:** Installing Arch Linux on a Btrfs Filesystem with Snapper for System Snapshots and Rollbacks
**Source:** Ordinatechnic
**Updated:** April 2025 (Verified via associated [YouTube Walkthrough](https://www.youtube.com/watch?v=AXdPNrRtqUA))

**Link:** **[Click here for the Ordinatechnic Guide](https://www.ordinatechnic.com/distribution-specific-guides/Arch/an-arch-linux-installation-on-a-btrfs-filesystem-with-snapper-for-system-snapshots-and-rollbacks)**

### **Why this guide fits your requirements:**

- **True openSUSE Layout:** Unlike most Arch guides that use a "flat" layout (where `@snapshots` is a sibling of `@`), this guide uses the nested layout (e.g., creating `@` and then creating `@/.snapshots` inside it). This specific hierarchy is required for the `snapper rollback` command to function correctly without manual intervention.
- **Full `snapper rollback` Support:** It explicitly sets up the system so you can use the native `snapper rollback` command to revert your system state, rather than relying on manual `mv` commands or third-party tools like `btrfs-assistant`.
- **Up-to-Date (2025):** The content was refreshed in April 2025 to reflect current Arch install ISO changes and package versions.
- **Manual Installation:** It follows the manual "Arch way" of installation (command line) but creates the specific subvolume structure you need.

### **Alternative Resource (Video)**

If you prefer following a visual guide along with the text, the **SysGuides** channel released a three-part series in **March 2025** covering this exact topic:

- **Video:** [Arch Linux with Snapshots: Setup Snapper (2025)](https://www.youtube.com/watch?v=rl-VasRoUe4)
- **Key Note:** This also covers the `snapper rollback` functionality but double-check the subvolume creation step to ensure they nest `.snapshots` if you strictly want the SUSE layout, though modern Snapper is more flexible. The Ordinatechnic guide above is the strictest implementation of the SUSE layout.
