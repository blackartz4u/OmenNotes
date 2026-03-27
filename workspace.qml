import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import OmenNotes.Canvas

Item {
    id: root
    // Notice: NO 'anchors.fill: parent' here to keep the StackView happy!

    // --- 1. THE SMART LIST ---
    // This tracks our pages and safely lives at the very top of the app
    ListModel {
        id: pageModel

        ListElement {pageIndex: 1} // Start with exactly 1 empty page
    }

    // --- 2. THE MAIN LAYOUT ---
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // --- LEFT SIDEBAR ---
        Rectangle {
            id: sidebar
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 150
            SplitView.maximumWidth: 400
            color: "#f3f3f3"

            Label {
                anchors.centerIn: parent
                text: "Notes List"
                color: "#888888"
            }

            // --- CUSTOM ANIMATED BACK BUTTON ---
            Rectangle {
                id: backBtn
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 30 // Lifted it up slightly so it breathes

                width: 180
                height: 46
                radius: 23 // Perfect pill shape (Half of 46)

                // Solid white resting state so it pops off the gray sidebar
                color: backMouse.pressed ? "#555555" : (backMouse.containsMouse ? "#e8e8e8" : "#ffffff")
                border.color: backMouse.pressed ? "#555555" : "#cccccc"
                border.width: 1

                // The tactile "Squish" physics
                scale: backMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Using a Row to perfectly align the arrow and text
                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "⟵" // Elegant long arrow
                        font.pixelSize: 18
                        font.bold: true
                        color: backMouse.pressed ? "#ffffff" : "#666666"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Back to Menu"
                        font.pixelSize: 15
                        font.bold: true
                        color: backMouse.pressed ? "#ffffff" : "#666666"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor // Gives you the hand pointer!
                    onClicked: {
                        root.StackView.view.pop()
                    }
                }
            }
        }

        // --- RIGHT CANVAS AREA ---
        Rectangle {
            id: canvasArea
            SplitView.fillWidth: true
            color: "#e0e0e0"
            clip: true
            property real zoomLevel: 1.0
            property string activeTool: "pen"      // Can be "pen", "eraser", or "stroke_eraser"
            property color activeColor: "#000000"
            // --- THE SCROLLABLE AREA (Optimized for Trackpad & Mouse) ---
            Flickable {
                id: scroller
                anchors.fill: parent
                clip: true

                contentWidth: pageColumn.width
                contentHeight: pageColumn.height

                ScrollBar.vertical: ScrollBar {}
                ScrollBar.horizontal: ScrollBar {}

                // --- SMART SCROLLING ENGINE ---
                WheelHandler {
                    onWheel: function(event) {
                        // 1. Is this a Trackpad? (Trackpads output pixelDelta)
                        if (event.pixelDelta.y !== 0 || event.pixelDelta.x !== 0) {
                            // Tell the handler to ignore it and let Flickable's native,
                            // highly-optimized C++ physics engine take over completely!
                            event.accepted = false
                            return
                        }

                        // 2. It's a standard "clicky" Mouse Wheel!
                        // We do a crisp, instant jump of 150 pixels per click. Zero lag.
                        let jump = (event.angleDelta.y / 120) * 150

                        let maxY = Math.max(0, scroller.contentHeight - scroller.height)
                        scroller.contentY = Math.max(0, Math.min(maxY, scroller.contentY - jump))
                    }
                }
                Column {
                    id: pageColumn
                    width: Math.max(scroller.width, ((scroller.width - 60) * canvasArea.zoomLevel) + 60)
                    spacing: 30
                    padding: 30

                    // --- THE PAGES ---
                    Repeater {
                        model: pageModel

                        delegate: Rectangle {
                            id: pageRect // 1. Put the ID back!

                            width: (scroller.width - 60) * canvasArea.zoomLevel
                            height: width * 1.3333
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 10
                            clip: true

                            // 2. Start completely invisible and pushed down
                            opacity: 0
                            transform: Translate { id: slideTransform; y: 150 }

                            Component.onCompleted: entryAnim.start()

                            // 3. Explicitly tell the animation to target 'pageRect'
                            ParallelAnimation {
                                id: entryAnim
                                NumberAnimation {
                                    target: pageRect; // <-- THE MISSING LINK!
                                    property: "opacity"; to: 1.0;
                                    duration: 400; easing.type: Easing.OutQuart
                                }
                                NumberAnimation {
                                    target: slideTransform; property: "y"; to: 0;
                                    duration: 400; easing.type: Easing.OutQuart
                                }
                            }

                            DrawingCanvas {
                                anchors.fill: parent
                            }
                        }
                    }

                    // --- ADD PAGE BUTTON ---
                    Button {
                        id: addPageBtn
                        text: "+ Add New Page"
                        width: (scroller.width - 60) * canvasArea.zoomLevel
                        height: 60
                        anchors.horizontalCenter: parent.horizontalCenter

                        onClicked: pageModel.append({pageIndex: pageModel.count + 1})

                        contentItem: Text {
                            text: addPageBtn.text
                            font.pixelSize: 18
                            font.bold: true
                            color: addPageBtn.down ? "#ffffff" : "#666666"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        background: Rectangle {
                            radius: 15
                            color: addPageBtn.down ? "#555555" : (addPageBtn.hovered ? "#e8e8e8" : "#fdfdfd")
                            border.color: addPageBtn.down ? "#555555" : "#cccccc"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        scale: addPageBtn.down ? 0.98 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    }
                }
            }
            // --- CUSTOM ANIMATED ZOOM BUTTON ---
            component ZoomButton : Rectangle {
                property string text: ""
                signal clicked()

                // implicitWidth guarantees the layout will NEVER stretch it
                implicitWidth: 26
                implicitHeight: 26
                Layout.alignment: Qt.AlignHCenter

                radius: 13
                color: zoomMouse.pressed ? "#555555" : (zoomMouse.containsMouse ? "#e0e0e0" : "#00ffffff")
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: parent.text
                    font.pixelSize: 16
                    font.bold: true
                    color: zoomMouse.pressed ? "#ffffff" : "#666666"
                }

                MouseArea {
                    id: zoomMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.clicked()
                }
            }

            // --- THE FLOATING VERTICAL TOOLBAR ---
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 15

                width: 36
                height: 180
                radius: 18
                color: "#ffffff"
                border.color: "#dcdcdc"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 2

                    Label {
                        text: Math.round(canvasArea.zoomLevel * 100)
                        font.pixelSize: 10
                        font.bold: true
                        color: "#888888"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 4
                    }

                    ZoomButton { text: "+"; onClicked: zoomSlider.value = Math.min(3.0, zoomSlider.value + 0.1) }

                    Slider {
                        id: zoomSlider
                        orientation: Qt.Vertical
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                        from: 0.2
                        to: 3.0
                        value: canvasArea.zoomLevel
                        onValueChanged: canvasArea.zoomLevel = value

                        background: Rectangle {
                            x: zoomSlider.leftPadding + (zoomSlider.availableWidth - width) / 2
                            y: zoomSlider.topPadding
                            implicitWidth: 4
                            height: zoomSlider.availableHeight
                            radius: 2
                            color: "#eeeeee"

                            Rectangle {
                                width: parent.width
                                height: zoomSlider.position * parent.height
                                anchors.bottom: parent.bottom
                                color: "#bbbbbb"
                                radius: 2
                            }
                        }

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

                    ZoomButton { text: "−"; onClicked: zoomSlider.value = Math.max(0.2, zoomSlider.value - 0.1) }
                }
            }

            // --- CUSTOM ACTION BUTTON (Undo/Redo) ---
            component ActionButton : Rectangle {
                property string text: ""
                signal clicked()

                implicitWidth: 40
                implicitHeight: 40
                radius: 20 // Always perfectly round

                color: actionMouse.pressed ? "#dddddd" : (actionMouse.containsMouse ? "#e0e0e0" : "#00ffffff")
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: parent.text
                    font.pixelSize: 22
                    font.bold: true
                    color: "#555555"
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.clicked()
                }
            }

            // --- CUSTOM TOOL BUTTON (Pens/Erasers) ---
            component ToolButton : Rectangle {
                property string icon: ""
                property string toolId: "pen"
                property bool isSelected: canvasArea.activeTool === toolId

                implicitWidth: 44
                implicitHeight: 54
                radius: 8

                color: isSelected ? "#e5e5e5" : (toolMouse.containsMouse ? "#e0e0e0" : "#00ffffff")
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.isSelected ? 14 : 8
                    text: parent.icon
                    font.pixelSize: 26
                    Behavior on anchors.bottomMargin { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: toolMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: canvasArea.activeTool = parent.toolId
                }
            }

            // --- CUSTOM COLOR SWATCH (The Grid Dots) ---
            component ColorSwatch : Rectangle {
                property color swatchColor: "#000000"
                property bool isSelected: canvasArea.activeColor === swatchColor && canvasArea.activeTool === "pen"

                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: swatchColor

                border.color: isSelected ? "#aaaaaa" : "transparent"
                border.width: isSelected ? 3 : 0

                scale: isSelected ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                MouseArea {
                    id: swatchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        canvasArea.activeTool = "pen"
                        canvasArea.activeColor = parent.swatchColor
                    }
                }
            }

            // --- THE TOP FLOATING TOOLBAR (Apple Notes Style) ---
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 15

                // Dynamically wrap tightly around the inner Row!
                width: toolRow.width + 30
                height: toolRow.height + 20
                radius: height / 2 // Dynamic pill shape
                color: "#fefefe"
                border.color: "#dddddd"
                border.width: 1

                // Changed from RowLayout to a standard Row to completely prevent stretching
                Row {
                    id: toolRow
                    anchors.centerIn: parent
                    spacing: 12

                    // 1. Undo / Redo
                    Row {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        ActionButton { text: "↶"; onClicked: console.log("Undo!") }
                        ActionButton { text: "↷"; onClicked: console.log("Redo!") }
                    }

                    Rectangle { width: 1; height: 35; color: "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter }

                    // 2. The Tools
                    Row {
                        spacing: 5
                        anchors.verticalCenter: parent.verticalCenter
                        ToolButton { icon: "🖊️"; toolId: "pen" }
                        ToolButton { icon: "🖍️"; toolId: "highlighter" }
                        ToolButton { icon: "▱"; toolId: "eraser" }
                        ToolButton { icon: "✖"; toolId: "stroke_eraser" }
                    }

                    Rectangle { width: 1; height: 35; color: "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter }

                    // 3. The Color Grid
                    // Swapped GridLayout for standard Grid!
                    Grid {
                        columns: 3
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        ColorSwatch { swatchColor: "#1c1c1e" }
                        ColorSwatch { swatchColor: "#007aff" }
                        ColorSwatch { swatchColor: "#34c759" }
                        ColorSwatch { swatchColor: "#ffcc00" }
                        ColorSwatch { swatchColor: "#ff3b30" }
                        ColorSwatch { swatchColor: "#af52de" }
                    }
                }
            }
        } // End of canvasArea Rectangle
    } // End of SplitView
} // End of Root Item


