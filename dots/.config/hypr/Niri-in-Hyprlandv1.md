Yes, there are multiple ways to replicate the functionality of the **niri overview feature** in the **Hyprland Wayland compositor** through its **plugin ecosystem** and features.

The core concept of Niri's overview feature (invoked with Super+O) is to provide a zoomed-out view of all open windows and workspaces, allowing for visual navigation and interaction.1

---

## **💻 Hyprland Plugins for Overview/Expo**

Hyprland's community has developed several plugins to add overview-like functionality, similar to what you might find in GNOME's overview, macOS's Mission Control, or the "expo" mode in other window managers:2

* **hyprview**: This is a dedicated overview/Mission Control plugin for Hyprland. It offers features like:  
  * Live, scaled window previews.  
  * Ability to **interact** with the window tiles (typing, scrolling) while in overview mode.  
  * Multi-monitor support.  
  * Configurable window labels.  
* **hyprexpo**: This is an official plugin that adds an "expo-like workspace overview." Unlike hyprview, the search results indicate you generally **can't interact** with the windows while in this mode.  
* **hyprspace**: This plugin adds a "workspace overview similar to KDE Plasma and macOS."3

These plugins provide the window visualization and navigation aspects of the Niri overview, although they operate within Hyprland's tiling model rather than Niri's scrolling-tiling model.

---

## **🌀 Replicating Niri's Scrolling Layout**

Another key feature related to Niri's workflow is its **scrollable-tiling layout**, where new windows are placed to the side and the desktop horizontally scrolls.4 If you are looking to replicate this specific *workflow* (of which the overview is a component), you can use:

* **hyprscroller**: This is a Hyprland plugin that implements a **scrolling layout** similar to Niri or PaperWM.5

By using hyprscroller to change your tiling model and one of the overview plugins (hyprview or hyprexpo) for visualization, you can combine features to create a highly similar overall experience to Niri within the Hyprland environment.

---

You can see a demonstration of setting up a scrolling layout in Hyprland by watching this video: Turn Hyprland into Niri with Hyprscrolling.  
