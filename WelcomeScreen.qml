import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        // App Title
        Label {
            text: "Omen Notes"
            font.pixelSize: 48
            font.bold: true
            color: "#ffffff"
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter // Already centered
            Layout.bottomMargin: 40
        }

        // --- CUSTOM ANIMATED BUTTON COMPONENT ---
        component MenuButton : Button {
            id: control
            Layout.preferredWidth: 250
            Layout.preferredHeight: 50

            // THE FIX: This force-centers the button within the ColumnLayout
            Layout.alignment: Qt.AlignHCenter

            hoverEnabled: true

            contentItem: Text {
                text: control.text
                font.pixelSize: 16
                font.bold: true
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                id: bgBase
                radius: 10
                color: "#33ffffff"
                readonly property bool isHovered: control.hovered

                border.color: bgBase.isHovered ? "#ffffff" : "#ffb8ed"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutQuad }}

                // --- THE UPDATED GLOW ENGINE (Sibling Method) ---

                Rectangle {
                    id: buttonMask
                    anchors.fill: parent
                    radius: parent.radius
                    layer.enabled: true
                    visible: false
                }

                Rectangle {
                    id: glowCore
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.7
                    radius: width / 2
                    color: "#ffffff"
                    layer.enabled: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: glowCore
                    opacity: bgBase.isHovered ? 0.3 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                    maskEnabled: true
                    maskSource: buttonMask
                }
            }
        }

        // --- ACTUAL BUTTONS (Now perfectly centered) ---

        MenuButton {
            text: "New Note"
            onClicked: root.StackView.view.push("workspace.qml")
        }

        MenuButton {
            text: "Open Note"
            onClicked: console.log("Open Note clicked!")
        }

        MenuButton {
            text: "Settings"
            onClicked: console.log("Settings clicked!")
        }
    }
}