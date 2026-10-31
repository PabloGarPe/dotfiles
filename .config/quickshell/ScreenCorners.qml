// Esquinas de pantalla redondeadas, como en los monitores de macOS.
// Cuatro ventanitas por monitor en la capa Overlay (quedan por encima de todo, también
// de las apps a pantalla completa) que pintan de negro el hueco fuera del arco.
// No reciben clics: la máscara de entrada está vacía.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    property int radius: 12

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            Variants {   // Repeater solo instancia Items; las ventanas van con Variants
                // [arriba, izquierda]
                model: [[true, true], [true, false], [false, true], [false, false]]

                PanelWindow {
                    required property var modelData
                    readonly property bool isTop: modelData[0]
                    readonly property bool isLeft: modelData[1]

                    screen: perScreen.modelData
                    anchors { top: isTop; bottom: !isTop; left: isLeft; right: !isLeft }
                    implicitWidth: root.radius
                    implicitHeight: root.radius
                    exclusionMode: ExclusionMode.Ignore
                    color: "transparent"
                    mask: Region {}

                    WlrLayershell.namespace: "screen-corners"   // sin blur ni animación: hypr/conf/rules.lua
                    WlrLayershell.layer: WlrLayer.Overlay

                    // Cuadrado negro menos un cuarto de círculo con centro en la esquina interior
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        // Dibuja la esquina de arriba a la izquierda y la refleja para las demás
                        transform: Scale {
                            origin.x: root.radius / 2
                            origin.y: root.radius / 2
                            xScale: isLeft ? 1 : -1
                            yScale: isTop ? 1 : -1
                        }

                        ShapePath {
                            fillColor: "black"
                            strokeWidth: -1
                            startX: 0; startY: 0
                            PathLine { x: root.radius; y: 0 }
                            PathArc {
                                x: 0; y: root.radius
                                radiusX: root.radius; radiusY: root.radius
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }
        }
    }
}
