pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"

/**
 * 出示设备二维码：与 Android 一致，载荷为 zh2: + JSON（设备库 mac/sn/name/ip/online/pending + 当前 cfg）。
 */
Item {
    id: idRoot
    anchors.fill: parent

    // 不透明背景，避免 StackView 过渡时下层「功能列表」里的「下载内容」等字样透出闪烁
    Rectangle {
        anchors.fill: parent
        z: -1
        color: (Global.isWindows && Global.isDarkTheme) ? palette.window : palette.base
    }

    function buildPayload() {
        if (typeof Global.dbDevicesCpp.buildQrSharePayload !== "function")
            return ""
        return Global.dbDevicesCpp.buildQrSharePayload()
    }

    function refreshQr() {
        idErrorText.visible = false
        idImage.source = ""
        if (typeof Global.utilsCpp.qrEncode !== "function") {
            idErrorText.text = qsTr("当前版本未包含二维码生成（缺少 QZXING）")
            idErrorText.visible = true
            return
        }
        var payload = buildPayload()
        if (!payload || payload.length < 8) {
            idErrorText.text = qsTr("无法生成二维码：当前无有效设备记录或数据库中缺少该设备")
            idErrorText.visible = true
            return
        }
        var base64Image = Global.utilsCpp.qrEncode(payload)
        if (base64Image && base64Image.length > 0) {
            idImage.source = base64Image
        } else {
            idErrorText.text = qsTr("二维码生成失败，请稍后重试")
            idErrorText.visible = true
        }
    }

    ZhomeToolbar {
        id: idToolbar
        winTitle: qsTr("设备二维码")
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    Item {
        id: contentArea
        anchors.top: idToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 420)
            spacing: 20

            Item {
                Layout.preferredWidth: 260
                Layout.preferredHeight: 260
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: false

                Image {
                    id: idImage
                    anchors.centerIn: parent
                    width: 240
                    height: 240
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: false
                    smooth: true
                }
            }

            Text {
                id: idHintBelow
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("使用其它手机扫码，即可将本设备加入对方应用中的设备列表并开始使用")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Global.fontSize + 1
                color: palette.text
            }

            Text {
                id: idErrorText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: false
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Global.fontSize
                color: "#E65100"
            }
        }
    }

    Timer {
        id: deferQr
        interval: 1
        running: false
        repeat: false
        onTriggered: idRoot.refreshQr()
    }

    Connections {
        target: Global
        function onCurrDeviceChanged() {
            deferQr.restart()
        }
    }

    Component.onCompleted: deferQr.restart()

    onVisibleChanged: {
        if (visible)
            deferQr.restart()
    }
}
