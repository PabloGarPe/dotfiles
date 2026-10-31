// Quickshell: centro de control (reloj de waybar), selector de fondos (con fundido) y esquinas redondeadas.
//   qs ipc call controlcenter toggle · qs ipc call wallpapers toggle
// Colores: Theme.qml (mismo cristal que waybar) + Matugen.qml (acento del wallpaper)
import Quickshell

ShellRoot {
    ControlCenter {}
    WallpaperFade { id: wallFade }
    WallpaperPicker { fade: wallFade }
    ScreenCorners {}
}
