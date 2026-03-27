import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root


    // A subtle gradient background for the welcome screen
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#f0f0f5" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        // App Title
        Label {
            text: "Omen Notes"
            font.pixelSize: 42
            font.bold: true
            color: "#222222"
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 30 // Add some space below the title
        }

        // --- CUSTOM ANIMATED BUTTON COMPONENT ---
        // We define a reusable component here so we don't write the animation code 3 times
        component MenuButton : Button {
            Layout.preferredWidth: 250
            Layout.preferredHeight: 50

            // The text styling
            contentItem: Text {
                text: parent.text
                font.pixelSize: 16
                font.bold: true
                color: parent.down ? "#ffffff" : "#333333" // White when clicked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // The animated background
            background: Rectangle {
                radius: 10
                // Logic: If clicked -> Purple. If hovered -> Light Gray. Else -> White.
                color: parent.down ? "#9e1fff" : (parent.hovered ? "#e8e8e8" : "#ffffff")
                border.color: "#dddddd"
                border.width: 1

                // This is the magic that makes the color change fluid instead of instant!
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // --- ACTUAL BUTTONS ---

        MenuButton {
            text: "New Note"
            onClicked: {
                // We will tell the StackView to load the Workspace here!
                root.StackView.view.push("workspace.qml")
            }
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