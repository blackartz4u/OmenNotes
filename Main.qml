import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 2.15

Window {
    id: window
    width: 640
    height: 480
    visible: true
    title: qsTr("OmenNotes")

    GridLayout {
        id: gridLayout
        x: 0
        y: 0
        width: 640
        height: 480
        flow: GridLayout.LeftToRight
        layoutDirection: Qt.LeftToRight
        rowSpacing: 1
        columnSpacing: 1
        rows: 3
        columns: 3

        Button {
            id: button
            text: qsTr("Yo")
            icon.cache: true
            checked: false
            highlighted: true
            flat: false
            display: AbstractButton.TextBesideIcon
            hoverEnabled: true
            icon.height: 41
            icon.width: 43
            icon.color: "#ff0000"
        }

        CheckBox {
            id: checkBox
            text: qsTr("Check Box")
        }
    }
}
