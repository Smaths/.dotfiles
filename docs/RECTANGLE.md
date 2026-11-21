# Rectangle

Homebrew installs Rectangle through the macOS `desktop` package group
(`install/platforms/macos/packages/desktop.Brewfile`), included in the `full`
profile. Its preferences are imported manually, like Alfred's assets; bootstrap
does not overwrite the live preferences or symlink files into
`~/Library/Preferences`.

## Restore on a new Mac

1. Run bootstrap with the `full` profile (the default), add `--with desktop`
   when using `--profile slim`, or install only Rectangle with
   `brew install --cask rectangle`.
2. Open Rectangle and grant **Accessibility** access in System Settings when
   prompted.
3. Open Rectangle's settings and use **Import** in the settings menu to select
   `~/.dotfiles/config/rectangle/RectangleConfig.json`. Use **Export** first if
   this Mac already has settings you want to preserve.
4. Quit and reopen Rectangle so the shortcut preset is reloaded. Since the
   menu-bar icon is hidden by this config, run `open -a Rectangle` again to
   reach its settings.
5. Verify **Launch on login** in Rectangle. Toggle it off/on if necessary to
   register the app with this Mac's login items; a saved preference alone does
   not migrate macOS service registration or Accessibility permission.

This is a curated file in Rectangle's native JSON import format, based on this
workstation's Rectangle 0.94 (build 100) preferences. It keeps:

- The alternate (Magnet-style) default shortcut preset: **Control + Option**
  with arrow keys for halves, Return for maximize, and U/I/J/K for corners.
- **Allow any shortcut** enabled.
- A hidden menu-bar icon and the launch-on-login preference.
- Repeat execution mode **across monitor** (`subsequentExecutionMode = 1`).
- The stored Todo shortcuts: **Control + Option + B** to toggle and
  **Control + Option + N** to reflow. This does not enable Todo mode.

Unspecified settings retain Rectangle's defaults on a fresh installation.
Import overlays these keys; it does not clear pre-existing custom shortcuts on
an already-configured Mac. The main window shortcuts come from the preset,
not an explicit binding for every action. Check them after importing if the
new Mac has a different Rectangle version.

Update history, update-check preferences, app version history, onboarding flags,
and window positions are deliberately excluded. The JSON `version` field is
required import-format metadata, not an app-version pin.

## Avoid competing window tiling

On this workstation, native macOS window tiling is disabled. On macOS versions
that offer these controls, open **System Settings → Desktop & Dock → Windows**
and turn off:

- Drag windows to screen edges to tile.
- Drag windows to the menu bar to fill the screen.
- Hold the Option key while dragging windows to tile.

These are separate macOS settings, not part of Rectangle's import. Labels vary
by macOS version. Leave Rectangle's own drag-to-snap feature enabled.

## Voyager modifiers

The Voyager's macOS-specific **Command ↔ Control** swap is also separate from
Rectangle. Configure it under **Keyboard → Keyboard Shortcuts → Modifier Keys**,
selecting the Voyager. With that swap, a Voyager key assigned **GUI/Command** in
Oryx supplies the **Control** modifier used by Rectangle; **Alt** supplies Option.
The keyboard's firmware layout stays on the Voyager and needs no reflash.

## Keep the copy current

Export from Rectangle's settings to a temporary file, compare it with
`config/rectangle/RectangleConfig.json`, and copy only intentional changes into
the tracked file. Keep machine-specific paths, app history, and unrelated
settings out of it. To undo an import, import your earlier export and restart
Rectangle; review login items separately.
