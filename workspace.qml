import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import OmenNotes.Canvas
import QtQuick.Effects

Item {
    id: root
    // Notice: NO 'anchors.fill: parent' here to keep the StackView happy!

    // --- 1. THE SMART LIST ---
    // This tracks our pages and safely lives at the very top of the app
    ListModel {
        id: pageModel

        ListElement {
            pageIndex: 1
        } // Start with exactly 1 empty page
    }
    // --- KEYBOARD SHORTCUTS ---
    Shortcut {
        sequence: StandardKey.Undo
        onActivated: {
            if (canvasArea.currentCanvas !== null) {
                canvasArea.currentCanvas.undo()
            }
        }
    }

    Shortcut {
        sequence: StandardKey.Redo
        onActivated: {
            if (canvasArea.currentCanvas !== null) {
                canvasArea.currentCanvas.redo()
            }
        }
    }
    // --- 2. THE MAIN LAYOUT ---
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        background: null
        handle: Rectangle {
            id: splitHandle

            // 1. Make it wide enough to see the box and grab it easily
            implicitWidth: 6

            // 2. Make the inside completely transparent
            color: "#13ff69b4"

            // 3. Put the border around the OUTSIDE of the handle
            border.color: "#dddddd" // Use "#e6ffffff" if you went back to the glass look!
            border.width: 0.6

            // 4. (Optional) Give it rounded corners so it looks like a modern track
            radius: 4

            // 5. (Optional) Squeeze the top and bottom so it floats slightly inside the window
            // height: parent.height - 20
            // anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SplitHCursor
                acceptedButtons: Qt.NoButton
            }
        }
        // --- LEFT SIDEBAR ---
        Rectangle {
            id: sidebar
            SplitView.preferredWidth: 200
            SplitView.minimumWidth: 180
            SplitView.maximumWidth: 400
            color: "transparent"

            Label {
                anchors.centerIn: parent
                text: "Notes List"
                color: "#888888"
            }

            // --- PREMIUM GLASS BACK BUTTON ---
            Rectangle {
                id: backBtn
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 30

                width: 180
                height: 46
                radius: 23

                // 1. BASE COLORS: Translucent hot pink base (25% opacity)
                color: "#33ffffff"

                // 2. BORDER ANIMATION: Shifts to Solid White on hover
                border.color: backMouse.containsMouse ? "#ffffff" : "#ffb8ed"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutQuad } }

                // 3. SQUISH PHYSICS (Kept from your original design!)
                scale: backMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                // --- THE CENTER GLOW ENGINE ---
                Rectangle {
                    id: backMask
                    anchors.fill: parent
                    radius: backBtn.radius
                    layer.enabled: true
                    visible: false
                }

                Rectangle {
                    id: backGlow
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.7
                    radius: height / 2
                    color: "#ffffff"
                    layer.enabled: true
                    visible: false
                }
                // 3. The Compositor (Combines the Core and the Mask safely!)
                MultiEffect {
                    anchors.fill: parent
                    source: backGlow

                    // THE FIX: Move the hover fade to the MultiEffect itself!
                    opacity: backMouse.containsMouse ? 0.4 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                    blurEnabled: true
                    blurMax: 20
                    blur: 1.0

                    maskEnabled: true
                    maskSource: backMask // This reference will NEVER break now!
                }

                // --- BUTTON CONTENT ---
                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "⟵"
                        font.pixelSize: 18
                        font.bold: true

                        // Changed to pure white so it pops against the pink glass
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Back to Menu"
                        font.pixelSize: 15
                        font.bold: true

                        // Changed to pure white so it pops against the pink glass
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // --- THE MOUSE SENSOR ---
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true // Required for the glow and border to track the mouse!
                    cursorShape: Qt.PointingHandCursor
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
            color: "transparent"
            clip: true
            property real zoomLevel: 1.0
            property string activeTool: "pen"      // Can be "pen", "eraser", or "stroke_eraser"
            property color activeColor: "#000000"
            property var currentCanvas: null
            property real activeBrushSize: 15.0
            property real activeBrushOpacity: 1.0
            property bool isSettingsOpen: false
            // --- THE SCROLLABLE AREA (Optimized for Trackpad & Mouse) ---
            Flickable {
                id: scroller
                anchors.fill: parent
                clip: true

                contentWidth: pageColumn.width
                contentHeight: pageColumn.height

                ScrollBar.vertical: ScrollBar {
                }
                ScrollBar.horizontal: ScrollBar {
                }

                // --- SMART SCROLLING ENGINE ---
                WheelHandler {
                    onWheel: function (event) {
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
                            transform: Translate {
                                id: slideTransform; y: 150
                            }

                            Component.onCompleted: entryAnim.start()

                            // 3. Explicitly tell the animation to target 'pageRect'
                            ParallelAnimation {
                                id: entryAnim
                                NumberAnimation {
                                    target: pageRect; // <-- THE MISSING LINK!
                                    property: "opacity";
                                    to: 1.0;
                                    duration: 400; easing.type: Easing.OutQuart
                                }
                                NumberAnimation {
                                    target: slideTransform; property: "y";
                                    to: 0;
                                    duration: 400; easing.type: Easing.OutQuart
                                }
                            }

                            DrawingCanvas {
                                id: myPageCanvas
                                anchors.fill: parent
                                // THE MAGIC BINDING:
                                // Every single page now instantly watches the toolbar!
                                penColor: canvasArea.activeColor

                                // THE NEW BINDING: Tells C++ what tool you clicked!
                                activeTool: canvasArea.activeTool
                                brushSize: canvasArea.activeBrushSize
                                brushOpacity: canvasArea.activeBrushOpacity
                                HoverHandler {
                                    onHoveredChanged: {
                                        if (hovered) {
                                            canvasArea.currentCanvas = myPageCanvas
                                        }
                                    }

                                }
                            }
                        }
                    }
                    // --- PREMIUM GLASS ADD PAGE BUTTON ---
                    Button {
                        id: addPageBtn
                        text: "+ Add New Page"

                        // Kept your dynamic sizing and positioning!
                        width: (scroller.width - 60) * canvasArea.zoomLevel
                        height: 60
                        anchors.horizontalCenter: parent.horizontalCenter

                        // CRITICAL: Turn on the hover sensor for the standard Qt Button!
                        hoverEnabled: true

                        onClicked: pageModel.append({pageIndex: pageModel.count + 1})

                        // --- BUTTON TEXT ---
                        contentItem: Text {
                            text: addPageBtn.text
                            font.pixelSize: 18
                            font.bold: true

                            // Changed to pure white so it pops against the pink glass
                            color: "#ffffff"

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            // Added a tiny opacity drop when pressed for extra tactile feedback!
                            opacity: addPageBtn.down ? 0.7 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // --- THE GLASS BACKGROUND & GLOW ---
                        background: Rectangle {
                            id: bgBase
                            radius: 25

                            // 1. Capture the Button's hover state safely
                            readonly property bool isHovered: parent.hovered

                            // 2. Base Color: Translucent hot pink base (25% opacity)
                            color: "#33ffffff"

                            // 3. Border Animation: Shifts to Solid White on hover
                            border.color: bgBase.isHovered ? "#ffffff" : "#ffb8ed"
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutQuad } }

                            // --- THE CENTER GLOW ENGINE ---
                            Rectangle {
                                id: addMask
                                anchors.fill: parent
                                radius: parent.radius // Dynamically matches the 15px radius above
                                layer.enabled: true
                                visible: false
                            }

                            Rectangle {
                                id: addGlow
                                anchors.centerIn: parent
                                width: parent.width * 0.9
                                height: parent.height * 0.6
                                radius: height / 2
                                color: "#ffffff"
                                layer.enabled: true
                                visible: false
                            }
                            MultiEffect {
                                anchors.fill: parent
                                source: addGlow

                                // THE FIX: Move the hover fade to the MultiEffect itself!
                                opacity: bgBase.isHovered ? 0.4 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                                blurEnabled: true
                                blurMax: 64
                                blur: 1.0

                                maskEnabled: true
                                maskSource: addMask // This reference will NEVER break now!
                            }
                        }

                        // --- SQUISH PHYSICS ---
                        // (Kept from your original design)
                        scale: addPageBtn.down ? 0.98 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100; easing.type: Easing.OutQuad
                            }
                        }
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
                    color: zoomMouse.pressed ? "#33000000" : (zoomMouse.containsMouse ? "#1a000000" : "transparent")
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.text
                        font.pixelSize: 16
                        font.bold: true
                        color: zoomMouse.pressed ? "#222222" : "#666666"
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
                    border.color: "#dddddd"
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

                        ZoomButton {
                            text: "+"; onClicked: zoomSlider.value = Math.min(3.0, zoomSlider.value + 0.1)
                        }

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

                        ZoomButton {
                            text: "−"; onClicked: zoomSlider.value = Math.max(0.2, zoomSlider.value - 0.1)
                        }
                    }
                }

                // --- CUSTOM ACTION BUTTON (Undo/Redo) ---
                component ActionButton : Rectangle {
                    property string text: ""

                    signal clicked()

                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 20 // Always perfectly round

                    color: actionMouse.pressed ? "#33000000" : (actionMouse.containsMouse ? "#1a000000" : "transparent")
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.text
                        font.pixelSize: 22
                        font.bold: true
                        color: actionMouse.pressed ? "#222222" : "#555555"
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

                    color: isSelected ? "#26000000" : (toolMouse.containsMouse ? "#1a000000" : "transparent")
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        property int b_margin: parent.isSelected ? 14 : 8

                        anchors.bottomMargin: b_margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom

                        // 2. The separate 'b_margin: ...' line is now deleted

                        text: parent.icon
                        font.pixelSize: 26

                        Behavior on b_margin {
                            NumberAnimation {
                                duration: 150; easing.type: Easing.OutBack
                            }
                        }

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
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150; easing.type: Easing.OutBack
                        }
                    }

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
                    id: mainToolbar
                    z: 10
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 15

                    width: toolRow.width + 30
                    height: toolRow.height + 20
                    radius: height / 2

                    // THE ILLUSION OF GLASS
                    // 85% Solid White. It acts like a diffuser for anything underneath it!
                    color: "#ffffff"

                    // A crisp, 95% white border to catch the light and separate it from the canvas
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
                            ActionButton {
                                text: "↶";
                                onClicked: {
                                    if (canvasArea.currentCanvas !== null) {
                                        canvasArea.currentCanvas.undo()
                                    }
                                }
                            }
                            ActionButton {
                                text: "↷";
                                onClicked: {
                                    if (canvasArea.currentCanvas !== null) {
                                        canvasArea.currentCanvas.redo()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 1; height: 35; color: "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter
                        }

                        // 2. The Tools
                        Row {
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter
                            ToolButton {
                                icon: "🖊️"; toolId: "pen"
                            }
                            ToolButton {
                                icon: "🖍️"; toolId: "highlighter"
                            }
                            ToolButton {
                                icon: "▱"; toolId: "eraser"
                            }
                            ToolButton {
                                icon: "✖"; toolId: "stroke_eraser"
                            }
                        }

                        Rectangle {
                            width: 1; height: 35; color: "#e0e0e0"; anchors.verticalCenter: parent.verticalCenter
                        }

                        // 3. The Color Grid
                        // Swapped GridLayout for standard Grid!
                        Grid {
                            columns: 3
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            ColorSwatch {
                                swatchColor: "#1c1c1e"
                            }
                            ColorSwatch {
                                swatchColor: "#007aff"
                            }
                            ColorSwatch {
                                swatchColor: "#34c759"
                            }
                            ColorSwatch {
                                swatchColor: "#ffcc00"
                            }
                            ColorSwatch {
                                swatchColor: "#ff3b30"
                            }
                            ColorSwatch {
                                swatchColor: "#af52de"
                            }
                        }
                    }
                }

            // --- COMPACT BRUSH SETTINGS PILL ---
            Rectangle {
                id: settingsBar
                z: 9
                width: 290 // Bumped slightly to fit the numbers perfectly
                height: 38
                radius: 19
                color: "#ffffff"
                border.color: "#dddddd"
                border.width: 1

                anchors.top: mainToolbar.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                // 1. Create a custom variable (no dots!) to handle the open/close math
                property real dynamicTopMargin: canvasArea.isSettingsOpen ? 12 : -38

                // 2. Apply that variable to the actual anchor
                anchors.topMargin: dynamicTopMargin

                // 3. Animate the custom variable instead!
                Behavior on dynamicTopMargin {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                }
                // If it is open, make it 100% solid. If closed, make it completely invisible!
                opacity: canvasArea.isSettingsOpen ? 1.0 : 0.0

                // --- 2. ADD THIS OPACITY BEHAVIOR ---
                // Makes it fade beautifully alongside the sliding animation
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 8 // Tightly spaces the input and its slider

                    // --- 1. FLUID SIZE INPUT ---
                    TextField {
                        id: sizeInput
                        width: 46
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        hoverEnabled: true

                        // Two-way binding: Automatically displays the slider's value!
                        text: canvasArea.activeBrushSize.toFixed(1)
                        font.pixelSize: 13
                        color: "#444444"
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter

                        // FLUID DESIGN: Invisible until you hover or click!
                        background: Rectangle {
                            radius: 6
                            color: sizeInput.activeFocus ? "#eeeeee" : (sizeInput.hovered ? "#f8f8f8" : "transparent")
                            border.color: sizeInput.activeFocus ? "#d1d1d6" : "transparent"
                            border.width: 1
                        }

                        // Forces the user to only type numbers between 1 and 50
                        validator: DoubleValidator { bottom: 1.0; top: 50.0 }

                        // When you hit Enter or click away, it snaps the slider to your typed value!
                        onEditingFinished: {
                            let val = parseFloat(text)
                            if (!isNaN(val)) {
                                canvasArea.activeBrushSize = Math.max(1.0, Math.min(50.0, val))
                            }
                            focus = false // Drop the keyboard focus
                        }
                    }

                    // --- SIZE SLIDER ---
                    Slider {
                        id: sizeSlider
                        width: 80
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        from: 1.0
                        to: 50.0
                        value: canvasArea.activeBrushSize
                        onValueChanged: canvasArea.activeBrushSize = value
                        // --- 1. THE NEW SLIDER STICK (TRACK) ---
                        background: Rectangle {
                            x: sizeSlider.leftPadding
                            y: sizeSlider.topPadding + sizeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4 // Thickness of the stick
                            width: sizeSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#e5e5ea" // 1. The EMPTY track color (Light Gray)

                            Rectangle {
                                width: sizeSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#888888" // 2. The FILLED track color (Dark Gray)
                                radius: 2
                            }
                        }
                        handle: Rectangle {
                            x: sizeSlider.leftPadding + sizeSlider.visualPosition * (sizeSlider.availableWidth - width)
                            y: sizeSlider.topPadding + sizeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: sizeSlider.pressed ? "#e5e5ea" : "#ffffff"
                            border.color: "#c7c7cc"
                            border.width: 1
                        }
                    }

                    // --- 2. FLUID OPACITY INPUT ---
                    TextField {
                        id: opacityInput
                        width: 46
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        hoverEnabled: true

                        text: canvasArea.activeBrushOpacity.toFixed(2)
                        font.pixelSize: 13
                        color: "#444444"
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter

                        background: Rectangle {
                            radius: 6
                            color: opacityInput.activeFocus ? "#eeeeee" : (opacityInput.hovered ? "#f8f8f8" : "transparent")
                            border.color: opacityInput.activeFocus ? "#d1d1d6" : "transparent"
                            border.width: 1
                        }

                        validator: DoubleValidator { bottom: 0.05; top: 1.0 }

                        onEditingFinished: {
                            let val = parseFloat(text)
                            if (!isNaN(val)) {
                                canvasArea.activeBrushOpacity = Math.max(0.05, Math.min(1.0, val))
                            }
                            focus = false
                        }
                    }

                    // --- OPACITY SLIDER ---
                    Slider {
                        id: opacitySlider
                        width: 80
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        from: 0.05
                        to: 1.0
                        value: canvasArea.activeBrushOpacity
                        onValueChanged: canvasArea.activeBrushOpacity = value
                        // --- THE OPACITY STICK ---
                        background: Rectangle {
                            x: opacitySlider.leftPadding
                            y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: opacitySlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#e5e5ea" // Empty track

                            Rectangle {
                                width: opacitySlider.visualPosition * parent.width
                                height: parent.height
                                color: "#888888" // Filled track
                                radius: 2
                            }
                        }
                        handle: Rectangle {
                            x: opacitySlider.leftPadding + opacitySlider.visualPosition * (opacitySlider.availableWidth - width)
                            y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: opacitySlider.pressed ? "#e5e5ea" : "#ffffff"
                            border.color: "#c7c7cc"
                            border.width: 1
                        }
                    }
                }
            }

            // --- THE PULL TAB BUTTON ---
            Rectangle {
                id: pullTab
                z: 8 // Bottom Layer: Behind the settings pill
                width: 48
                height: 20
                radius: 10 // Perfectly round edges

                color: pullTabMouse.pressed ? "#e5e5ea" : (pullTabMouse.containsMouse ? "#f4f4f4" : "#ffffff")
                border.color: "#dddddd"
                border.width: 1

                // Attach it to the bottom of the settings pill!
                anchors.top: settingsBar.bottom
                anchors.topMargin: -10 // Tucks the top half behind the pill, leaving 10px sticking out
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: canvasArea.isSettingsOpen ? "▲" : "▼"
                    font.pixelSize: 10
                    color: "#8e8e93"
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 3 // Pushes the arrow down into the visible space
                }

                MouseArea {
                    id: pullTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: canvasArea.isSettingsOpen = !canvasArea.isSettingsOpen
                }
            }
        } // End of canvasArea Rectangle
    } // End of SplitView
} // End of Root Item



