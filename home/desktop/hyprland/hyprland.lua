local mod = "SUPER"
local terminal = "ghostty"
local files = "thunar"
local browser = "firefox"
local hypr = os.getenv("HOME") .. "/.config/hypr"
local ok, palette = pcall(dofile, os.getenv("HOME") .. "/.config/ecu-theme/palette.lua")
if not ok or type(palette) ~= "table" then palette = { ground = "#0a0a0c" } end

local focus = "rgba(ffffff80)"
local line = "rgba(ffffff14)"
local ring = "rgba(0000004d)"

---------------------------------------------------------------- environment
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

------------------------------------------------------------------- monitors
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-3", mode = "1920x1080@75", position = "1920x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

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
  cursor = {
    no_hardware_cursors = 1,
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = tonumber("ff" .. palette.ground:sub(2), 16),
    vrr = 2,
  },
})

hl.curve("ease", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "ease" })

---------------------------------------------------------------------- rules
hl.window_rule({
  name = "tools-float",
  match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager|xdg-desktop-portal-gtk)$" },
  float = true,
  center = true,
})

hl.layer_rule({
  name = "shell-overlay-blur",
  match = { namespace = "^(ecu-drawer|ecu-power|ecu-overview|ecu-walls|ecu-keys)$" },
  blur = true,
  ignore_alpha = 0.3,
})

hl.layer_rule({
  name = "quickshell-shot-noanim",
  match = { namespace = "quickshell-shot" },
  no_anim = true,
})

------------------------------------------------------------------- keybinds
local qs = "qs ipc call "

local function key(keys, action, description, opts)
  opts = opts or {}
  opts.description = description
  hl.bind(keys, action, opts)
end

key(mod .. " + K", hl.dsp.exec_cmd(qs .. "keys toggle"), "Masaüstü: Kısayollar (bu ekran)")
local overview = hl.dsp.exec_cmd(qs .. "overview toggle")
key(mod .. " + TAB", overview, "Masaüstü: Pencere görünümü")
key("mouse:277", overview, "Masaüstü: Pencere görünümü")
key("mouse:276", overview, "Masaüstü: Pencere görünümü")
key(mod .. " + SPACE", hl.dsp.exec_cmd("vicinae toggle"), "Masaüstü: Arama (Vicinae)")
local clipboard = hl.dsp.exec_cmd(qs .. "clipboard toggle")
key(mod .. " + V", clipboard, "Masaüstü: Pano geçmişi")
key("CTRL + ALT + V", clipboard, "Masaüstü: Pano geçmişi")
key(mod .. " + SHIFT + V", clipboard, "Masaüstü: Pano geçmişi")
key(mod .. " + SHIFT + W", hl.dsp.exec_cmd(qs .. "walls toggle"), "Masaüstü: Duvar kağıdı seç")

key(mod .. " + RETURN", hl.dsp.exec_cmd(terminal), "Uygulamalar: Terminal")
key(mod .. " + E", hl.dsp.exec_cmd(files), "Uygulamalar: Dosyalar")
key(mod .. " + B", hl.dsp.exec_cmd(browser), "Uygulamalar: Firefox")

key(mod .. " + Q", hl.dsp.window.close(), "Pencereler: Kapat")
key("ALT + F4", hl.dsp.window.close(), "Pencereler: Kapat")
key(mod .. " + F", hl.dsp.window.fullscreen(), "Pencereler: Tam ekran")
key(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), "Pencereler: Yüzen pencere")
key(mod .. " + J", hl.dsp.layout("togglesplit"), "Pencereler: Bölmeyi çevir")
for _, d in ipairs({ { "LEFT", "l" }, { "RIGHT", "r" }, { "UP", "u" }, { "DOWN", "d" } }) do
  key(mod .. " + " .. d[1], hl.dsp.focus({ direction = d[2] }), "Pencereler: Pencereler arasında geç")
  key(mod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[2] }), "Pencereler: Pencereyi taşı")
end
key(mod .. " + mouse:272", hl.dsp.window.drag(), "Pencereler: Sürükleyerek taşı", { mouse = true })
key(mod .. " + mouse:273", hl.dsp.window.resize(), "Pencereler: Sürükleyerek boyutlandır", { mouse = true })

for i = 1, 10 do
  local n = i % 10
  key(mod .. " + " .. n, hl.dsp.focus({ workspace = i }), "Çalışma alanları: Çalışma alanına geç")
  key(mod .. " + SHIFT + " .. n, hl.dsp.window.move({ workspace = i }), "Çalışma alanları: Pencereyi çalışma alanına taşı")
end
key(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Çalışma alanları: Sonraki")
key(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Çalışma alanları: Önceki")

key("Print", hl.dsp.exec_cmd(qs .. "shot open"), "Ekran görüntüsü: Alan, pencere ya da ekran seç")
key("F8", hl.dsp.exec_cmd(qs .. "shot open"), "Ekran görüntüsü: Alan, pencere ya da ekran seç")
key(mod .. " + SHIFT + S", hl.dsp.exec_cmd(qs .. "shot open"), "Ekran görüntüsü: Alan, pencere ya da ekran seç")
key("SHIFT + Print", hl.dsp.exec_cmd(qs .. "shot screen"), "Ekran görüntüsü: Tüm ekran")
key("CTRL + Print", hl.dsp.exec_cmd(qs .. "shot record"), "Ekran görüntüsü: Video kaydı başlat / durdur")
key("CTRL + F8", hl.dsp.exec_cmd(qs .. "shot record"), "Ekran görüntüsü: Video kaydı başlat / durdur")
key("CTRL + SHIFT + Print", hl.dsp.exec_cmd(qs .. "shot gif"), "Ekran görüntüsü: GIF kaydı başlat / durdur")
key("CTRL + SHIFT + F8", hl.dsp.exec_cmd(qs .. "shot gif"), "Ekran görüntüsü: GIF kaydı başlat / durdur")
key(mod .. " + SHIFT + T", hl.dsp.exec_cmd(qs .. "shot text"), "Ekran görüntüsü: Ekrandaki yazıyı kopyala (OCR)")
key(mod .. " + SHIFT + Q", hl.dsp.exec_cmd(qs .. "shot qr"), "Ekran görüntüsü: Ekrandaki QR kodu oku")

key(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), "Oturum: Kilitle")
key(mod .. " + ESCAPE", hl.dsp.exec_cmd(qs .. "power toggle"), "Oturum: Güç menüsü (barda)")
key(mod .. " + P", hl.dsp.exec_cmd(qs .. "session toggle"), "Oturum: Tam ekran güç menüsü")
key(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), "Oturum: Hyprland ayarlarını yeniden yükle")

local vol = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "
key("XF86AudioRaiseVolume", hl.dsp.exec_cmd(vol .. "5%+"), "Ses ve medya: Sesi aç", { locked = true, repeating = true })
key("XF86AudioLowerVolume", hl.dsp.exec_cmd(vol .. "5%-"), "Ses ve medya: Sesi kıs", { locked = true, repeating = true })
key("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Ses ve medya: Sesi kapat / aç", { locked = true })
key("F9", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Ses ve medya: Mikrofonu kapat / aç", { locked = true })
key("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Ses ve medya: Mikrofonu kapat / aç", { locked = true })
key("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Ses ve medya: Oynat / duraklat", { locked = true })
key("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Ses ve medya: Oynat / duraklat", { locked = true })
key("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Ses ve medya: Sonraki parça", { locked = true })
key("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Ses ve medya: Önceki parça", { locked = true })

-------------------------------------------------------------------- startup
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORM NIXOS_OZONE_WL; systemctl --user start vicinae.service app-com.mitchellh.ghostty.service")
  hl.exec_cmd("qs")
  hl.exec_cmd("hypridle")
  hl.exec_cmd(hypr .. "/bin/sunset")
  hl.exec_cmd("hyprpolkitagent")
  hl.exec_cmd("blueman-applet")
end)

pcall(dofile, hypr .. "/local.lua")
