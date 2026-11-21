import QtQuick
import Quickshell

// The window overview, on every screen at once: a blurred backdrop, that
// screen's five workspaces along the top and the shown workspace's windows
// spread out below, all live. The mouse's thumb button and Super+Tab open
// it (qs ipc call overview toggle).
//
//   click a window     go to it          middle click   close it
//   drag a window      onto a workspace to move it there
//   click a workspace  show and switch to it
//   arrows / Enter     pick a window / go to it
//   1-5                show that workspace      Esc or a click on the backdrop: close
Scope {
    Variants {
        model: Quickshell.screens

        delegate: OverviewScreen {}
    }
}
