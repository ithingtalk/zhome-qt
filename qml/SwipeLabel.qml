import QtQuick
import QtQuick.Controls

Label {
    id: idRoot
    property color bcolor: "white"
    property string actionStr: ""
    text: "default"
    color: "white"
    verticalAlignment: Label.AlignVCenter
    horizontalAlignment: Label.AlignHCenter
    height: parent.height
    width: Math.max(implicitWidth + 8, height + 8)
    background: Rectangle {
        color: idRoot.SwipeDelegate.pressed ? Qt.darker(idRoot.bcolor, 1.2) : idRoot.bcolor
    }
    SwipeDelegate.onClicked: {
        try {
            clicked(actionStr)
        } catch (e) {
            console.error("Error in clicked: ", e)
        }
    }
    signal clicked(var actionStr)
}
