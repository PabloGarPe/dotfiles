// Quickshell: centro de control (reloj de waybar) y selector de fondos.
//   qs ipc call controlcenter toggle · qs ipc call wallpapers toggle
// Colores: Theme.qml (mismo cristal que waybar) + Matugen.qml (acento del wallpaper)
import Quickshell

ShellRoot {
    ControlCenter {}
    WallpaperPicker {}
}
