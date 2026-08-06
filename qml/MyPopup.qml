pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Popup {
    id: idRoot
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 4 // show radius background connor
    parent: Overlay.overlay

    signal clickFunc(var actionStr)
    property var gModel: []

    background: Rectangle {
        color: Global.popupBackgroud
        radius: 5
    }
    
    contentItem: ColumnLayout {
        id: contentColumnLayout
        anchors.centerIn: parent
        spacing: 0
        
        Repeater {
            model: idRoot.gModel
            
            ItemDelegate {
                id: idItem
                Layout.fillWidth: true
                padding: bItem ? 10 : 2
                
                required property string itemText
                required property string iconSrc
                required property string actionStr

                property bool bItem: idItem.itemText != ""
                
                background: Rectangle {
                    id: idBg
                    color: Global.popupBackgroud
                }
                
                contentItem: RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Button {
                        visible: idItem.bItem
                        icon.source: idItem.iconSrc
                        icon.color: "white" // palette.text // Global.popupIconColor
                        icon.height: Global.popupIconSize
                        icon.width: Global.popupIconSize
                        display: AbstractButton.IconOnly
                        background: null
                        padding: 0 // remove default padding of google style
                    }
                    
                    Text {
                        text: idItem.itemText
                        visible: idItem.bItem
                        color: "white" // palette.text
                        font.pixelSize: Global.fontSize
                        padding: 0
                    }

                    Rectangle { // seperate line
                        Layout.fillWidth: true
                        implicitHeight: idItem.bItem ? 0 : 1
                        color: Qt.lighter(Global.popupBackgroud, 1.2) // Global.isDarkTheme ? Qt.lighter(Global.popupBackgroud, 1.2) : Qt.darker(Global.popupBackgroud, 1.2)
                    }
                }
                
                MouseArea {
                    id: idMouseer
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onClicked: {
                        if (idItem.bItem) {
                            idRoot.close()
                            idRoot.clickFunc(idItem.actionStr)
                        }
                    }
                }

                states: [
                    State {
                        when: idMouseer.containsMouse && idItem.bItem
                        PropertyChanges {
                            idBg.color: Qt.lighter(Global.popupBackgroud, 1.2)
                        }
                    }
                ]
            }
        }
    }
}
