import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import OmenNotes.Canvas
Item {
    id: root
    anchors.fill: parent
    ListModel {
        id: pageModel
        ListElement {} // We start the app with exactly 1 empty item (Page 1)
    }
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
            SplitView.fillWidth: true
            color: "#e0e0e0"

            property real zoomLevel: 1.0

            // --- THE SCROLLABLE AREA (Now fills the whole screen) ---
            ScrollView {
                id: scroller
                anchors.fill: parent
                clip: true

                Column {
                    id: pageColumn
                    width: Math.max(scroller.width, ((scroller.width - 60) * canvasArea.zoomLevel) + 60)
                    spacing: 30
                    padding: 30

                    Repeater {
                        model: pageModel

                        delegate: Rectangle {
                            width: (scroller.width - 60) * canvasArea.zoomLevel
                            height: width * 1.3333
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 10
                            clip: true
                            DrawingCanvas {
                                anchors.fill: parent
                            }
                        }
                    }

                    // --- CUSTOM ANIMATED ADD PAGE BUTTON ---
                    Button {
                        id: addPageBtn // Give it an ID so we can easily check its states
                        text: "+ Add New Page"

                        // It still scales perfectly with the zoom!
                        width: (scroller.width - 60) * canvasArea.zoomLevel
                        height: 60
                        anchors.horizontalCenter: parent.horizontalCenter

                        onClicked: {
                            pageModel.append({})
                        }

                        // 1. Custom Text Animation
                        contentItem: Text {
                            text: addPageBtn.text
                            font.pixelSize: 18
                            font.bold: true
                            // Turns white when pressed, gray otherwise
                            color: addPageBtn.down ? "#ffffff" : "#666666"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // 2. Custom Background Animation
                        background: Rectangle {
                            radius: 15 // Nice, soft rounded corners

                            // Dark gray when clicked, light gray when hovered, faint gray when resting
                            color: addPageBtn.down ? "#555555" : (addPageBtn.hovered ? "#e8e8e8" : "#fdfdfd")
                            border.color: addPageBtn.down ? "#555555" : "#cccccc"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        // 3. The "Squish" Animation!
                        // When pressed, it shrinks to 98% of its size. When released, it bounces back.
                        scale: addPageBtn.down ? 0.98 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            // --- CUSTOM ANIMATED ZOOM BUTTON ---
            // --- CUSTOM ANIMATED ZOOM BUTTON ---
            component ZoomButton : Button {
                Layout.preferredWidth: 26  // Shrunk from 32 to 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignHCenter

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 16     // Smaller text
                    font.bold: true
                    color: parent.down ? "#ffffff" : "#666666"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 13 // Perfectly circular (Half of 26)
                    color: parent.down ? "#555555" : (parent.hovered ? "#e0e0e0" : "transparent")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // --- THE FLOATING VERTICAL TOOLBAR ---
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 15 // Tucked slightly closer to the wall

                width: 36   // Ultra-thin! (Was 50)
                height: 180 // Shorter! (Was 250)
                radius: 18  // Half of width for the perfect pill shape
                color: "#ffffff"
                border.color: "#dcdcdc"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 2

                    Label {
                        // Removed the "%" symbol to keep the UI perfectly narrow
                        text: Math.round(canvasArea.zoomLevel * 100)
                        font.pixelSize: 10
                        font.bold: true
                        color: "#888888"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 4
                    }

                    ZoomButton {
                        text: "+"
                        onClicked: zoomSlider.value = Math.min(3.0, zoomSlider.value + 0.1)
                    }

                    // --- CUSTOM ULTRA-THIN SLIDER ---
                    Slider {
                        id: zoomSlider
                        orientation: Qt.Vertical
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                        from: 0.2
                        to: 3.0
                        value: canvasArea.zoomLevel
                        onValueChanged: canvasArea.zoomLevel = value

                        // 1. The Thin Track
                        background: Rectangle {
                            x: zoomSlider.leftPadding + (zoomSlider.availableWidth - width) / 2
                            y: zoomSlider.topPadding
                            implicitWidth: 4 // A 4-pixel thin line!
                            implicitHeight: 100
                            width: implicitWidth
                            height: zoomSlider.availableHeight
                            radius: 2
                            color: "#eeeeee"

                            // The filled portion of the track
                            Rectangle {
                                width: parent.width
                                height: zoomSlider.position * parent.height
                                anchors.bottom: parent.bottom
                                color: "#bbbbbb"
                                radius: 2
                            }
                        }

                        // 2. The Tiny Handle
                        handle: Rectangle {
                            x: zoomSlider.leftPadding + (zoomSlider.availableWidth - width) / 2
                            y: zoomSlider.topPadding + zoomSlider.visualPosition * (zoomSlider.availableHeight - height)
                            implicitWidth: 12
                            implicitHeight: 12
                            radius: 6
                            color: zoomSlider.pressed ? "#666666" : "#ffffff"
                            border.color: zoomSlider.pressed ? "#666666" : "#cccccc"
                            border.width: 1
                        }
                    }

                    ZoomButton {
                        text: "−"
                        onClicked: zoomSlider.value = Math.max(0.2, zoomSlider.value - 0.1)
                    }
                }
            }
        }
    }
}