pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtMultimedia
import "Global"

ComboBox {
    id: idRoot
    textRole: "key"
    valueRole: "value"
    model: elements

    required property int selectedTrack
    required property list<mediaMetaData> metaData
    required property string trackName

    onActivated: idRoot.selectedTrack = currentValue
    Component.onCompleted: currentIndex = idRoot.selectedTrack

    contentItem: Text {
        text: idRoot.displayText
        font.bold: true
        font.pixelSize: Global.fontSizeSmall3
        color: Global.iconColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
    }

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
        // border.color: "#444"
        radius: 4
    }

    popup.font.pixelSize: Global.fontSizeSmall3

    function readTracks(metadataList : list<mediaMetaData>) {
        elements.clear()
        if (metadataList && metadataList.length > 0) {
            metadataList.forEach(function (metadata, index) {
                var strLang = ""
                console.log("============================================")
                console.log("Track", index, ":")
                if (metadata) {
                    for (var key of metadata.keys()) {
                        if (metadata.stringValue(key)) {
                            console.log("name: " + metadata.metaDataKeyToString(key))
                            console.log("value: " + metadata.stringValue(key))
                        }
                        if (metadata.metaDataKeyToString(key) === "Language") {
                            strLang = ": " + metadata.stringValue(key)
                            // break
                        }
                    }
                }
                console.log("============================================")

                elements.append({
                    key: trackName + strLang,
                    value: index
                })
            })
        }
    }

    onMetaDataChanged: readTracks(idRoot.metaData)

    ListModel { id: elements }
}
