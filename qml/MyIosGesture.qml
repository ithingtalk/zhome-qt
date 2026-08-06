import QtQuick
import "Global"

Item {
    id: idRoot

    property bool bLeft: true

    property int gStartX: bLeft ? 0 : Global.idWindow.width
    property int _startX: gStartX
    property int _startY: 0

    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) {
            idRoot._startX = mouse.x
            idRoot._startY = mouse.y
            //console.log("press:（" + mouse.x + "," + mouse.y + "）")
        }
        onReleased: function(mouse) {
            console.log("release:（"+ mouse.x + "," + mouse.y + "）")
            if (Math.abs(mouse.x - idRoot._startX) > 50) {
                //console.log("-------> right")
                if (Math.abs(mouse.y - idRoot._startY) < 50) {
                    //if ( ( idRoot.bLeft && iosUtilsFromCpp.gestureLeftEnabled() ) || ( !idRoot.bLeft && iosUtilsFromCpp.gestureRightEnabled() ) ) {
                        Global.idWindow.close()
                    //}
                }
            }
            idRoot._startX = idRoot.gStartX
        }
    }
}
