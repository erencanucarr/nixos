-- Hyprland, linked from ~/nixos/home/desktop/hyprland/hyprland.lua.
-- Düzenle: hyprconf    Uygula: hyprreload    Kısayollar: zhelp hypr
--
-- Based on xeome/dots (MIT): graphite edges, its animation curve and its
-- habits, made thinner and with GNOME's keys where GNOME had one.

local mod = "SUPER"
local terminal = "ghostty"
local files = "nautilus"
local browser = "firefox"
local hypr = os.getenv("HOME") .. "/.config/hypr"

-- Graphite (the same palette as the prompt, Vicinae and Ghostty).
local focus = "rgba(ffffff80)" -- the focused window's border
local line = "rgba(ffffff14)" -- every other edge
local ring = "rgba(0000004d)" -- the 1px dark shadow outside an edge

---------------------------------------------------------------- environment

hl.env("XCURSOR_THEME", "WhiteSur-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Electron apps (Obsidian, Discord) as native Wayland windows.
hl.env("NIXOS_OZONE_WL", "1")
-- NVIDIA: the GLX vendor library (LIBVA_DRIVER_NAME is set system-wide).
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

------------------------------------------------------------------- monitors

-- Left: the Samsung at 144 Hz. Right: the 75 Hz panel (GNOME ran it at 60).
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-3", mode = "1920x1080@75", position = "1920x0", scale = 1 })
-- Anything else plugged in.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspaces 1-5 on the left screen, 6-10 on the right.
for i = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(i),
    monitor = i <= 5 and "HDMI-A-2" or "HDMI-A-3",
    default = (i == 1 or i == 6),
  })
end

--------------------------------------------------------------------- looks

hl.config({
  input = {
    kb_layout = "tr",
    numlock_by_default = true,
    follow_mouse = 1,
  },
  general = {
    border_size = 1,
    gaps_in = 4,
    gaps_out = 8,
    col = {
      active_border = focus,
      inactive_border = line,
    },
    layout = "dwindle",
    resize_on_border = true,
  },
  decoration = {
    rounding = 8,
    rounding_power = 2.0,
    -- Focus reads from lightness alone: the border, and others dimmed.
    dim_inactive = true,
    dim_strength = 0.1,
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
      noise = 0.02,
      contrast = 1.1,
      vibrancy = 0.1696,
    },
    shadow = {
      enabled = true,
      sharp = true,
      range = 1,
      render_power = 1,
      color = ring,
      color_inactive = ring,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  -- Software cursors, so hyprsunset's warm tint covers the cursor too: a
  -- hardware cursor is its own plane, which the colour transform skips. One
  -- frozen copy of the cursor was seen right after login once; moving it
  -- across both screens afterwards left nothing behind.
  cursor = {
    no_hardware_cursors = 1,
  },
  misc = {
    -- A plain graphite ground instead of the mascot wallpapers.
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = 0xff0a0a0c,
    -- Variable refresh rate in fullscreen only (games, video).
    vrr = 2,
  },
})

-- xeome's curve: OutCubic over 200 ms.
hl.curve("ease", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "ease" })

---------------------------------------------------------------------- rules

-- Small tool windows float instead of taking half the screen.
hl.window_rule({
  name = "tools-float",
  match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager|xdg-desktop-portal-gtk|org.gnome.Calculator)$" },
  float = true,
  center = true,
})

-- The app drawer, power menu and window overview blur what is behind them.
hl.layer_rule({
  name = "shell-overlay-blur",
  match = { namespace = "^(can-drawer|can-power|can-overview|can-walls)$" },
  blur = true,
  ignore_alpha = 0.3,
})

-- Shot shows a frozen frame of the screen; fading that in reads as a flicker.
hl.layer_rule({
  name = "quickshell-shot-noanim",
  match = { namespace = "quickshell-shot" },
  no_anim = true,
})

------------------------------------------------------------------- keybinds

local qs = "qs ipc call "

-- Super alone opens the app drawer.
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd(qs .. "drawer toggle"), { release = true })

-- The window overview: the MX Master 3S's thumb button (BTN_FORWARD, 277;
-- 276 too, in case another mouse calls it BTN_EXTRA) and Super+Tab.
local overview = hl.dsp.exec_cmd(qs .. "overview toggle")
hl.bind("mouse:276", overview)
hl.bind("mouse:277", overview)
hl.bind(mod .. " + TAB", overview)

hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("vicinae toggle"))
-- Clipboard history (Vicinae keeps it; passwords from password managers are
-- skipped). Super+V as on Windows, Ctrl+Alt+V and Super+Shift+V as well.
local clipboard = hl.dsp.exec_cmd("vicinae cmd launch clipboard:history")
hl.bind(mod .. " + V", clipboard)
hl.bind("CTRL + ALT + V", clipboard)
hl.bind(mod .. " + SHIFT + V", clipboard)

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(files))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd(qs .. "power toggle"))
-- The wallpaper picker (quickshell/wallpaper/Picker.qml).
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(qs .. "walls toggle"))
-- The full-screen power menu, in the lock screen's look.
hl.bind(mod .. " + P", hl.dsp.exec_cmd(qs .. "session toggle"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Screenshots (Shot.qml) go to the clipboard and ~/Resimler/Ekran Görüntüleri.
-- The MX Keys Mini's screenshot key: with Fn Lock on it sends plain F8
-- (as F9 does, seen with libinput), without it presumably Super+Shift+S,
-- Windows' snipping shortcut. bin/screenshot is the fallback without qs.
hl.bind("Print", hl.dsp.exec_cmd(qs .. "shot open"))
hl.bind("F8", hl.dsp.exec_cmd(qs .. "shot open"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(qs .. "shot open"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(qs .. "shot screen"))

for _, d in ipairs({ { "LEFT", "l" }, { "RIGHT", "r" }, { "UP", "u" }, { "DOWN", "d" } }) do
  hl.bind(mod .. " + " .. d[1], hl.dsp.focus({ direction = d[2] }))
  hl.bind(mod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }))
end

for i = 1, 10 do
  local key = i % 10 -- workspace 10 is on key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Super + left drag moves a window, Super + right drag resizes it.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys work on the lock screen too.
local vol = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(vol .. "5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(vol .. "5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
-- The MX Keys Mini's mic key sends plain F9 with Fn Lock on.
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("F9", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-------------------------------------------------------------------- startup

hl.on("hyprland.start", function()
  -- Hand the session to user services and portals (screen sharing, file
  -- pickers), then start what GNOME used to provide.
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORM NIXOS_OZONE_WL")
  hl.exec_cmd("qs") -- the bar, app drawer and power menu (~/.config/quickshell)
  hl.exec_cmd("mako") -- notifications
  hl.exec_cmd("hypridle") -- lock after 15 minutes, screens off after 20
  hl.exec_cmd(hypr .. "/bin/sunset") -- warm screen at the last `hyprsunset` value
  hl.exec_cmd("hyprpolkitagent") -- password prompts for admin actions
  hl.exec_cmd("nm-applet") -- network, in the tray
  hl.exec_cmd("blueman-applet") -- bluetooth, in the tray
  hl.exec_cmd("systemctl --user start vicinae.service app-com.mitchellh.ghostty.service")
end)

-- Machine-only experiments that should not go into the repo.
pcall(dofile, hypr .. "/local.lua")
