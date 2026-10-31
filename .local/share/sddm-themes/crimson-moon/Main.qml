import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#000000"

    // ---------- config ----------
    readonly property color accent: config.Accent || "#ff2a3d"
    readonly property color accentSoft: config.AccentSoft || "#ff6b78"
    readonly property color tint: config.Tint || "#140709"
    function tinted(a) { return Qt.rgba(tint.r, tint.g, tint.b, a) }
    readonly property string fontName: config.Font || "Inter"
    readonly property real dim: config.Dim !== undefined && config.Dim !== "" ? Number(config.Dim) : 0.25
    readonly property real s: Math.min(width / 1920, height / 1080)   // escala

    function resolve(p) {
        if (!p) return ""
        return p.startsWith("/") ? "file://" + p : Qt.resolvedUrl(p)
    }

    // ---------- estado ----------
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool busy: false
    property string errorText: ""

    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
            readonly property string userName: name
            readonly property string displayName: realName !== "" ? realName : name
            readonly property string userIcon: icon
        }
    }
    readonly property var currentUser: users.count > 0 ? users.itemAt(Math.min(userIndex, users.count - 1)) : null
    readonly property string userName: currentUser ? currentUser.userName : userModel.lastUser
    readonly property string displayName: currentUser ? currentUser.displayName : userModel.lastUser

    function doLogin() {
        if (busy) return
        busy = true
        errorText = ""
        sddm.login(userName, password.text, sessionIndex)
        busyGuard.restart()
    }
    Timer { id: busyGuard; interval: 15000; onTriggered: root.busy = false }

    Connections {
        target: sddm
        function onLoginFailed() {
            busyGuard.stop()
            root.busy = false
            root.errorText = "Contraseña incorrecta"
            password.text = ""
            password.forceActiveFocus()
            shake.restart()
        }
        function onLoginSucceeded() {
            outro.start()
        }
    }

    // ---------- fondo ----------
    Item {
        id: background
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: root.resolve(config.Background)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }

        MediaPlayer {
            id: player
            source: root.resolve(config.Video)
            loops: MediaPlayer.Infinite
            videoOutput: video
            Component.onCompleted: if (source != "") play()
        }
        VideoOutput {
            id: video
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            opacity: player.playbackState === MediaPlayer.PlayingState ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 800 } }
        }

        Rectangle { anchors.fill: parent; color: "black"; opacity: root.dim }

        // viñeta lateral: oscurece izquierda (reloj) y derecha (tarjeta)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "#cc000000" }
                GradientStop { position: 0.35; color: "#00000000" }
                GradientStop { position: 0.65; color: "#00000000" }
                GradientStop { position: 1.0;  color: "#b3000000" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "#66000000" }
                GradientStop { position: 0.25; color: "#00000000" }
                GradientStop { position: 0.8;  color: "#00000000" }
                GradientStop { position: 1.0;  color: "#99000000" }
            }
        }
    }

    // ---------- contenido ----------
    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        // ===== reloj =====
        Column {
            id: clock
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 110 * root.s
            anchors.bottomMargin: 120 * root.s
            spacing: 4 * root.s

            property date now: new Date()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

            Text {
                text: {
                    const h = clock.now.getHours()
                    return h < 6 ? "Buenas noches" : h < 13 ? "Buenos días" : h < 21 ? "Buenas tardes" : "Buenas noches"
                }
                color: root.accentSoft
                font.family: root.fontName
                font.pixelSize: 22 * root.s
                font.weight: Font.Medium
                font.letterSpacing: 6 * root.s
                font.capitalization: Font.AllUppercase
            }
            Text {
                id: timeText
                text: Qt.formatTime(clock.now, config.ClockFormat || "HH:mm")
                color: "white"
                font.family: root.fontName
                font.pixelSize: 168 * root.s
                font.weight: Font.Thin
                font.letterSpacing: -4 * root.s
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accent
                    shadowBlur: 1.0
                    shadowOpacity: 0.55
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }
            Row {
                spacing: 14 * root.s
                Rectangle {
                    width: 40 * root.s; height: 2 * root.s
                    color: root.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: {
                        const t = Qt.locale().toString(clock.now, config.DateFormat || "dddd, d MMMM")
                        return t.charAt(0).toUpperCase() + t.slice(1)
                    }
                    color: "#e6ffffff"
                    font.family: root.fontName
                    font.pixelSize: 28 * root.s
                    font.weight: Font.Light
                }
            }
        }

        // ===== tarjeta de login =====
        Item {
            id: cardWrap
            width: 400 * root.s
            height: card.implicitHeight
            anchors.right: parent.right
            anchors.rightMargin: 150 * root.s
            anchors.verticalCenter: parent.verticalCenter

            // cristal: fondo desenfocado recortado a la tarjeta
            ShaderEffectSource {
                id: glassSrc
                anchors.fill: parent
                sourceItem: background
                sourceRect: Qt.rect(cardWrap.x + shakeOffset.x, cardWrap.y, cardWrap.width, cardWrap.height)
                visible: false
                live: true
            }
            Rectangle {
                id: glassMask
                anchors.fill: parent
                radius: 30 * root.s
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: glassSrc
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                autoPaddingEnabled: false
                saturation: 0.2
                maskEnabled: true
                maskSource: glassMask
            }
            Rectangle {
                anchors.fill: parent
                radius: 30 * root.s
                color: root.tinted(0.35)
                border.width: 1
                border.color: "#26ffffff"
            }
            // brillo superior
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.6
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.accentSoft }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            transform: Translate { id: shakeOffset; x: 0 }
            SequentialAnimation {
                id: shake
                loops: 1
                NumberAnimation { target: shakeOffset; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 70 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 5; duration: 70 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 60 }
            }

            Column {
                id: card
                width: parent.width
                topPadding: 44 * root.s
                bottomPadding: 30 * root.s
                spacing: 0

                // avatar con anillo
                Item {
                    width: 132 * root.s; height: width
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        id: ring
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 2 * root.s
                        border.color: root.accent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true; shadowColor: root.accent
                            shadowBlur: 1.0; shadowOpacity: 0.9
                            shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.45; duration: 1800; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 1800; easing.type: Easing.InOutSine }
                        }
                    }

                    Item {
                        id: avatar
                        anchors.centerIn: parent
                        width: parent.width - 16 * root.s; height: width
                        readonly property string iconPath: config.Avatar ? config.Avatar : root.currentUser ? root.currentUser.userIcon : ""
                        readonly property bool useImage: faceImg.status === Image.Ready && iconPath.indexOf("/sddm/faces/.face.icon") < 0

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.darker(root.accent, 3.2) }
                                GradientStop { position: 1; color: root.tint }
                            }
                            visible: !avatar.useImage
                            Text {
                                anchors.centerIn: parent
                                text: root.displayName.charAt(0).toUpperCase()
                                color: "white"
                                font.family: root.fontName
                                font.pixelSize: parent.height * 0.42
                                font.weight: Font.Light
                            }
                        }
                        Image {
                            id: faceImg
                            anchors.fill: parent
                            source: root.resolve(avatar.iconPath)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            sourceSize: Qt.size(256, 256)
                        }
                        Rectangle { id: faceMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                        MultiEffect {
                            anchors.fill: parent
                            source: faceImg
                            maskEnabled: true
                            maskSource: faceMask
                            visible: avatar.useImage
                        }
                    }
                }

                Item { width: 1; height: 22 * root.s }

                // nombre (clic para cambiar de usuario)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.displayName
                    color: "white"
                    font.family: root.fontName
                    font.pixelSize: 30 * root.s
                    font.weight: Font.DemiBold
                    MouseArea {
                        anchors.fill: parent
                        enabled: users.count > 1
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { root.userIndex = (root.userIndex + 1) % users.count; password.text = ""; password.forceActiveFocus() }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    text: users.count > 1 ? "@" + root.userName + "  ·  cambiar"
                        : root.displayName !== root.userName ? "@" + root.userName : ""
                    color: "#80ffffff"
                    font.family: root.fontName
                    font.pixelSize: 15 * root.s
                    topPadding: 4 * root.s
                }

                Item { width: 1; height: 34 * root.s }

                // campo de contraseña + botón
                Item {
                    width: parent.width - 64 * root.s
                    height: 56 * root.s
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        id: field
                        anchors.fill: parent
                        radius: height / 2
                        color: password.activeFocus ? "#33000000" : "#26000000"
                        border.width: 1.5
                        border.color: root.errorText !== "" ? root.accent
                                    : password.activeFocus ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.8)
                                    : "#33ffffff"
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    TextField {
                        id: password
                        anchors.left: parent.left
                        anchors.right: loginBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 22 * root.s
                        anchors.rightMargin: 6 * root.s
                        echoMode: reveal.pressed ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        placeholderText: "Contraseña"
                        placeholderTextColor: "#73ffffff"
                        color: "white"
                        selectionColor: root.accent
                        font.family: root.fontName
                        font.pixelSize: 18 * root.s
                        font.letterSpacing: echoMode === TextInput.Password && text.length ? 3 * root.s : 0
                        background: null
                        enabled: !root.busy
                        focus: true
                        onTextChanged: if (text.length) root.errorText = ""
                        onAccepted: root.doLogin()
                        Keys.onEscapePressed: text = ""
                        Component.onCompleted: forceActiveFocus()
                    }

                    // botón circular
                    Rectangle {
                        id: loginBtn
                        width: 44 * root.s; height: width
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.rightMargin: 6 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        color: btnArea.pressed ? Qt.darker(root.accent, 1.3) : root.accent
                        scale: btnArea.containsMouse ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true; shadowColor: root.accent
                            shadowBlur: 0.8; shadowOpacity: btnArea.containsMouse ? 0.9 : 0.5
                            shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                        }
                        Image {
                            anchors.centerIn: parent
                            width: 20 * root.s; height: width
                            source: "assets/arrow.svg"
                            sourceSize: Qt.size(64, 64)
                            visible: !root.busy
                        }
                        // spinner
                        Rectangle {
                            anchors.centerIn: parent
                            width: 20 * root.s; height: width; radius: width / 2
                            color: "transparent"
                            border.width: 2 * root.s
                            border.color: "white"
                            visible: root.busy
                            Rectangle { width: 6 * root.s; height: width; radius: width/2; color: root.accent; anchors.horizontalCenter: parent.horizontalCenter; y: -2 * root.s }
                            RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                        }
                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.doLogin()
                        }
                    }
                }

                // mensajes
                Item {
                    width: parent.width
                    height: 40 * root.s
                    Row {
                        anchors.centerIn: parent
                        spacing: 16 * root.s
                        Text {
                            visible: root.errorText !== ""
                            text: root.errorText
                            color: root.accentSoft
                            font.family: root.fontName
                            font.pixelSize: 14 * root.s
                            font.weight: Font.Medium
                        }
                        Text {
                            visible: keyboard.capsLock
                            text: "⇪ Bloq Mayús activado"
                            color: "#ffd27a"
                            font.family: root.fontName
                            font.pixelSize: 14 * root.s
                        }
                        Image {
                            id: revealIcon
                            visible: password.text.length > 0 && root.errorText === "" && !keyboard.capsLock
                            width: 18 * root.s; height: width
                            source: "assets/eye.svg"; sourceSize: Qt.size(48, 48)
                            opacity: reveal.pressed ? 1 : 0.5
                            MouseArea { id: reveal; anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                // separador
                Rectangle {
                    width: parent.width - 64 * root.s; height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#1affffff"
                }
                Item { width: 1; height: 16 * root.s }

                // selector de sesión
                Rectangle {
                    id: sessionPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 38 * root.s
                    width: sessRow.implicitWidth + 32 * root.s
                    radius: height / 2
                    color: sessArea.containsMouse || sessionMenu.visible ? "#1fffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Repeater {
                        id: sessions
                        model: sessionModel
                        delegate: Item { required property string name; readonly property string sessionName: name }
                    }

                    Row {
                        id: sessRow
                        anchors.centerIn: parent
                        spacing: 10 * root.s
                        Image { width: 16 * root.s; height: width; source: "assets/session.svg"; sourceSize: Qt.size(48,48); opacity: 0.7; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: sessions.count > 0 && sessions.itemAt(root.sessionIndex) ? sessions.itemAt(root.sessionIndex).sessionName : "Sesión"
                            color: "#ccffffff"
                            font.family: root.fontName
                            font.pixelSize: 15 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Image { width: 14 * root.s; height: width; source: "assets/chevron.svg"; sourceSize: Qt.size(48,48); opacity: 0.6; anchors.verticalCenter: parent.verticalCenter
                                rotation: sessionMenu.visible ? 180 : 0; Behavior on rotation { NumberAnimation { duration: 150 } } }
                    }
                    MouseArea {
                        id: sessArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionMenu.visible ? sessionMenu.close() : sessionMenu.open()
                    }

                    Popup {
                        id: sessionMenu
                        y: parent.height + 8 * root.s
                        x: (parent.width - width) / 2
                        width: 260 * root.s
                        padding: 6 * root.s
                        onClosed: password.forceActiveFocus()
                        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
                        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 } }
                        background: Rectangle { radius: 16 * root.s; color: root.tinted(0.95); border.width: 1; border.color: "#26ffffff" }
                        contentItem: Column {
                            Repeater {
                                model: sessionModel
                                delegate: Rectangle {
                                    required property string name
                                    required property int index
                                    width: 248 * root.s; height: 38 * root.s
                                    radius: 10 * root.s
                                    color: index === root.sessionIndex ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
                                         : itemArea.containsMouse ? "#14ffffff" : "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: 14 * root.s
                                        text: name
                                        color: "white"
                                        font.family: root.fontName
                                        font.pixelSize: 15 * root.s
                                    }
                                    MouseArea {
                                        id: itemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.sessionIndex = index; sessionMenu.close() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ===== botones de energía =====
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 40 * root.s
            spacing: 14 * root.s

            component PowerButton: Rectangle {
                id: pb
                property string icon
                property string label
                signal activated()
                width: 50 * root.s; height: width; radius: width / 2
                color: pbArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35) : "#26000000"
                border.width: 1
                border.color: pbArea.containsMouse ? root.accent : "#26ffffff"
                Behavior on color { ColorAnimation { duration: 150 } }
                Image { anchors.centerIn: parent; width: 20 * root.s; height: width; source: pb.icon; sourceSize: Qt.size(48,48); opacity: 0.9 }
                MouseArea { id: pbArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.activated() }
                ToolTip {
                    visible: pbArea.containsMouse
                    delay: 400
                    text: pb.label
                    contentItem: Text { text: pb.label; color: "white"; font.family: root.fontName; font.pixelSize: 13 * root.s }
                    background: Rectangle { color: root.tinted(0.9); radius: 8; border.color: "#26ffffff" }
                }
            }

            PowerButton { icon: "assets/suspend.svg"; label: "Suspender"; visible: sddm.canSuspend; onActivated: sddm.suspend() }
            PowerButton { icon: "assets/reboot.svg";  label: "Reiniciar";  visible: sddm.canReboot;  onActivated: sddm.reboot() }
            PowerButton { icon: "assets/power.svg";   label: "Apagar";     visible: sddm.canPowerOff; onActivated: sddm.powerOff() }
        }

        // hostname arriba a la derecha
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 40 * root.s
            text: sddm.hostName
            color: "#80ffffff"
            font.family: root.fontName
            font.pixelSize: 14 * root.s
            font.letterSpacing: 4 * root.s
            font.capitalization: Font.AllUppercase
        }
    }

    // ---------- animaciones de entrada/salida ----------
    ParallelAnimation {
        id: intro
        running: true
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: cardWrap; property: "anchors.rightMargin"; from: 90 * root.s; to: 150 * root.s; duration: 1000; easing.type: Easing.OutCubic }
        NumberAnimation { target: clock; property: "anchors.leftMargin"; from: 150 * root.s; to: 110 * root.s; duration: 1000; easing.type: Easing.OutCubic }
    }
    NumberAnimation { id: outro; target: content; property: "opacity"; to: 0; duration: 400 }
}
