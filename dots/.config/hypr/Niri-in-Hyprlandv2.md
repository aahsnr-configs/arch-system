Yes, you can replicate the niri overview feature in Hyprland, but it's best achieved by combining two different types of plugins to fully emulate the niri "experience": one for the **scrolling layout** and one for the **overview display**.

Niri's workflow is defined by its scrolling tile layout (like an infinite horizontal desktop) and its "overview" mode, which is a zoomed-out view of all your windows and workspaces to manage them.1

Here’s how to get similar functionality in Hyprland.

### **1\. Replicating the Scrolling Layout**

The core of the niri feel is its "scrollable" window management.2 The best way to achieve this in Hyprland is with the **hyprscroller** plugin.

* **What it is:** hyprscroller is a layout plugin for Hyprland that arranges your windows in a horizontal, scrollable strip, just like niri or PaperWM.3

* **Built-in Overview:** This plugin also includes its own simple overview function. You can use the scroller:toggleoverview dispatcher to "toggle an overview of the workspace where all the windows are temporarily scaled to fit the monitor."4

### **2\. Replicating the Full Overview Feature**

For a more advanced, dedicated overview feature that mimics GNOME, macOS, or niri's workspace management, you have several excellent plugin options.5 These can be used with hyprscroller or even with Hyprland's default layouts.

* **Hyprspace:** This plugin is specifically designed to be a "workspace overview feature similar to that of KDE Plasma, GNOME and macOS."6 It provides a full-screen minimap of all your workspaces, allowing you to see all open windows at a glance and drag-and-drop them between workspaces.

* **hyprview:** This is another popular overview plugin that shows your open windows as live, scaled-down tiles. You can interact with them and, with recent updates, it can display windows from all workspaces, not just the current one.  
* **Pyprland (expose plugin):** If you use the Pyprland plugin manager, it comes with a built-in plugin called expose. 7This function "exposes all the windows for a quick 'jump to' feature," which is a simpler but very fast way to get a window overview.8

### **Summary**

To get the most niri-like setup, your best bet is to:

1. **Install hyprscroller** to get the scrolling window layout.9

2. **Install Hyprspace or hyprview** to get a powerful, full-featured workspace and window overview.10

This combination will give you both the scrolling workflow and the "zoomed-out" management feature you're looking for.

---

This video provides a comparison that may be helpful in seeing how Niri and Hyprland differ.  
