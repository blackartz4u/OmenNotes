import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import OmenNotes.Canvas
Item {
    id: root
    anchors.fill: parent
    // SplitView allows the user to drag the divider to resize the sidebar
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // 1. The Sidebar (Left pane)
        Rectangle {
            id: sidebar
            SplitView.preferredWidth: 250 // Starting width
            SplitView.minimumWidth: 150   // Prevent making it too small
            SplitView.maximumWidth: 400   // Prevent making it too large
            color: "#ffe6cc"              // Standard sidebar color

            // A placeholder text for now
            Label {
                anchors.centerIn: parent
                text: "Notes List"
                color: "#888888"
            }
            Button {
                contentItem: Text {
                    text: "Back"
                    font.pixelSize: 16
                    font.bold: true
                    color: parent.down ? "#ffffff" : "#333333" // White when clicked
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 20
                onClicked: {
                    // This tells the StackView to throw away the current card and go back one step
                    root.StackView.view.pop()
                }
                background: Rectangle {
                    radius: 10

                    // Logic: If clicked -> Purple. If hovered -> Light Gray. Else -> White.
                    color: parent.down ? "#9e1fff" : (parent.hovered ? "#c99f75" : "#ffdfbf")
                    border.color: "#dddddd"
                    border.width: 1

                    // This is the magic that makes the color change fluid instead of instant!
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // 2. The Canvas Area (Right pane)
        Rectangle {
            id: canvasArea
            SplitView.fillWidth: true    // Tells it to take up the rest of the space
            color: "#ffffff"             // Pure white for the drawing area
            DrawingCanvas {
                            id: myCanvas
                            anchors.fill: parent // <-- THIS IS CRITICAL. It forces the canvas to be full size.
                        }
        }
    }
}