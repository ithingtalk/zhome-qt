pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot
    property string title: qsTr("Settings")

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: idToolbar.height
        color: palette.base

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            ComboBox {
                id: themeStyleComboBox
                model: [qsTr("Default style"), qsTr("Universal style"), qsTr("Material style"), qsTr("Fusion style")]
                currentIndex: idRoot.getStyle()
                onCurrentIndexChanged: idRoot.setStyle(currentIndex)
                Layout.fillWidth: true
                Layout.topMargin: 40
                background: Rectangle {
                    color: Global.bgColor
                    radius: 0
                }
                contentItem: Text {
                    leftPadding: 8
                    rightPadding: themeStyleComboBox.indicator.width + themeStyleComboBox.spacing
                    topPadding: 8
                    bottomPadding: 8
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    text: themeStyleComboBox.displayText
                    font.pixelSize: Global.fontSize
                    color: palette.text
                    // color: themeStyleComboBox.pressed ? "#17a81a" : "#21be2b"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                Layout.topMargin: 40
                color: Global.bgColor
                radius: 0

                Text {
                    id: idTextFontSize
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 20
                    anchors.bottomMargin: 10
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    text: (idFontSizeSlider.value === 0 ? qsTr("System default") : qsTr("Font size")) + ": " + Global.fontSize
                    color: palette.text
                    font.pixelSize: Global.fontSize
                }

                Slider {
                    id: idFontSizeSlider
                    anchors.top: idTextFontSize.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    snapMode: Slider.SnapOnRelease
                    from: 0
                    to: Global.fontValues.length - 1
                    stepSize: 1
                    value: Global.themeCpp?.getFontSize() ?? 0 // Global.fontIdx
                    onValueChanged: {
                        console.log("Selected Language:", idFontSizeSlider.value)
                        Global.setFontSize(idFontSizeSlider.value)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.topMargin: 40
                color: Global.bgColor
                radius: 0

                Text {
                    id: idTextUseP2p
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: idUseP2p.left
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("Force P2P")
                    color: palette.text
                    font.pixelSize: Global.fontSize
                }

                Switch {
                    id: idUseP2p
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    checked: Global.localAccountCpp.getForceP2p()
                    onClicked: Global.localAccountCpp.setForceP2p(checked)
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: Global.isIos ? 50 : 0
                Layout.topMargin: Global.isIos ? 40 : 0
                sourceComponent: Global.isIos ? idGestureLeft : null
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: Global.isIos ? 50 : 0
                Layout.topMargin: Global.isIos ? 1 : 0
                sourceComponent: Global.isIos ? idGestureRight : null
            }

            Component {
                id: idGestureLeft
                Rectangle {
                    color: Global.bgColor
                    radius: 0

                    Text {
                        text: qsTr("Left hand gesture")
                        font.pixelSize: Global.fontSize
                        color: palette.text
                        topPadding: 10
                        bottomPadding: 10
                        leftPadding: 20
                    }

                    Switch {
                        text: ""
                        checked: Global.iosUtilsCpp?.isGestureLeftEnabled() ?? false
                        // onClicked: iosUtilsFromCpp.enableGestureLeft(checked)
                        display: AbstractButton.IconOnly
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        onCheckedChanged: {
                            Global.iosUtilsCpp?.enableGestureLeft(checked)
                        }
                    }
                }
            }

            Component {
                id: idGestureRight
                Rectangle {
                    color: Global.bgColor
                    radius: 0
                    Text {
                        text: qsTr("Right hand gesture")
                        font.pixelSize: Global.fontSize
                        color: palette.text
                        topPadding: 10
                        bottomPadding: 10
                        leftPadding: 20
                    }
                    Switch {
                        text: ""
                        checked: Global.iosUtilsCpp?.isGestureRightEnabled() ?? false
                        // onClicked: iosUtilsFromCpp.enableGestureRight(checked)
                        display: AbstractButton.IconOnly
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        onCheckedChanged: {
                            Global.iosUtilsCpp?.enableGestureRight(checked)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.topMargin: 40
                color: Global.bgColor
                radius: 0
                Text {
                    text: qsTr("APP Version") + ": " + Global.utilsCpp.appVer()
                    color: palette.text
                    // anchors.centerIn: parent
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    font.pixelSize: Global.fontSize
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Text {
                text: Global.localAccountCpp.getUser()
                color: palette.text
                font.pixelSize: Global.fontSize
                Layout.margins: 8
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                // Layout.fillWidth: true
                // horizontalAlignment: Text.AlignHCenter
            }

            RoundButton {
                id: idLogoutButton
                visible: Global.localAccountCpp.getPass() !== ""
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 40
                contentItem: Text {
                    text: qsTr("Logout")
                    font.pixelSize: Global.fontSize
                    color: "tomato"
                    horizontalAlignment: Text.AlignHCenter
                }
                background: Rectangle {
                    id: idBg
                    color: Global.bgColor
                    radius: 0
                }
                MouseArea {
                    id: idMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        Global.localAccountCpp.setPass("");
                        // Global.idStack.clear()
                        // Global.idStack.push("LoginPage.qml")
                        Global.idStack.pop()
                    }
                }
                states: [
                    State {
                        when: idMouseArea.pressed
                        PropertyChanges {
                            idBg.color: Global.bgColor2
                        }
                    }
                ]
            }
        }
    }

    function getStyle()
    {
        var iIndex = 0 // default
        if (Global.themeCpp.isStyleU()) {
            iIndex = 1
        }
        else if (Global.themeCpp.isStyleM()) {
            iIndex = 2
        }
        else if (Global.themeCpp.isStyleF()) {
            iIndex = 3
        }
        return iIndex
    }

    function setStyle(idx)
    {
        if (idx === 0) {
            Global.themeCpp.setStyleDefault()
        }
        else if (idx === 1) {
            Global.themeCpp.setStyleU()
        }
        else if (idx === 2) {
            Global.themeCpp.setStyleM()
        }
        else if (idx === 3) {
            Global.themeCpp.setStyleF()
        }
        else {
            console.log("error style idx: " + idx)
        }
    }
}
