import QtQuick
import QtQuick.Controls

Window {
    width: 1000
    height: 600
    visible: true
    title: qsTr("Omen")

    color: "#80ff0000"
    StackView {
        id: stackView
        anchors.fill: parent
        background: null
        // This is the very first screen the app shows when it launches
        initialItem: "WelcomeScreen.qml"

        // Optional: Add a smooth fade/slide transition when switching screens
        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        pushExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
        }
        popEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
        }
    }
}
