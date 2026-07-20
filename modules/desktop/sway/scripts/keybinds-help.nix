{ pkgs }:
pkgs.writeShellScriptBin "keybinds-help" ''
  nav()    { printf "󰩈  Navigation\n";    printf "  Mod4+1-9            Workspace 1-9\n  Mod4+0              Workspace 10\n  Ctrl+Left           Workspace önceki\n  Ctrl+Right          Workspace sonraki\n  Ctrl+Tab            Workspace sonraki\n  Ctrl+Shift+Tab      Workspace önceki\n  Mod4+Tab            Workspace sonraki\n  Mod4+Shift+Tab      Workspace önceki\n  Mod4+Shift+1-9      Pencereyi workspace'e taşı\n  Mod4+a              Parent container\n  Mod4+grave          Scratchpad toggle\n"; }
  launch() { printf "󰐌  Launch\n";         printf "  Mod4+Return         Alacritty (terminal)\n  Alt+Space           Fuzzel (launcher)\n  Mod4+d              Fuzzel (launcher)\n  Mod4+e              PCManFM (dosya yöneticisi)\n"; }
  win()    { printf "  Windows\n";        printf "  Mod4+q              Kapat\n  Mod4+f              Tam ekran\n  Mod4+r              Resize modu\n  Mod4+Shift+space    Floating toggle\n  Mod4+space          Focus mode_toggle\n  Mod4+Shift+minus    Scratchpad'a gönder\n  Mod4+minus          Scratchpad göster\n  Mod4+arrows/hjkl    Odaklan\n  Mod4+Shift+arrows   Taşı\n"; }
  layout() { printf "  Layout\n";         printf "  Mod4+s              Stacking (üst üste)\n  Mod4+w              Tabbed (sekme)\n  Mod4+b              Splith (yan yana)\n  Mod4+v              Splitv (alt alta)\n"; }
  ss()     { printf "󰧚  Screenshot\n";    printf "  Print               Bölge seç → Swappy\n  Mod4+Print          Tam ekran → Swappy\n  Mod4+Shift+s        Bölge seç → clipboard\n  Mod4+Shift+a        Bölge → OCR (tesseract)\n  Mod4+c              Cliphist (pano geçmişi)\n"; }
  media()  { printf "  Media / System\n"; printf "  XF86AudioRaise      Ses +\n  XF86AudioLower      Ses -\n  XF86AudioMute       Sessiz\n  XF86AudioNext/Prev  Sonraki/Önceki şarkı\n  XF86AudioPlay       Oynat/Duraklat\n  XF86MonBrightness+  Parlaklık +\n  XF86MonBrightness-  Parlaklık -\n  Caps_Lock           Caps OSD\n  Mod4+l              Kilit ekranı\n  Mod4+m              AGS Quick Settings\n  Mod4+Escape         Power menu\n  Mod4+p              Power menu\n  Mod4+k              Bu yardım\n  Mod4+Shift+c        Config reload\n  Mod4+Shift+e        Sway'den çıkış\n  Mod4+Shift+i        Sistem bilgisi\n  Mod4+Shift+r        Kayıt başlat/durdur\n  Notification tıkla  Notification Center\n  Notification sağ tık Bildirimleri temizle\n"; }

  categories="󰩈  Navigation
󰐌  Launch
  Windows
  Layout
󰧚  Screenshot
  Media / System"
  all_bindings() { nav; launch; win; layout; ss; media; }

  pick=$(printf "%s\n" "$categories" | fuzzel --dmenu --prompt="Kategori > " --width=35 --lines=8)
  [ -z "$pick" ] && exit
  case "$pick" in
    "󰩈"*) echo "$(nav)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    "󰐌"*) echo "$(launch)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    ""*) echo "$(win)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    ""*) echo "$(layout)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    "󰧚"*) echo "$(ss)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    ""*) echo "$(media)" | fuzzel --dmenu --prompt="Keybinds > " --width=65 --lines=20 ;;
    *) echo "$(all_bindings)" | grep -i "$pick" | fuzzel --dmenu --prompt="Sonuç: $pick" --width=65 --lines=20 ;;
  esac
''
