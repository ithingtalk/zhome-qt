import QtQuick
import QtMultimedia
import "Global"
import QZXing

Item {
    id: idRoot
    property bool bDone: false

    function foundTag(tag) {
        console.log("found tag: " + tag)
        if (!idRoot.bDone) {
            idRoot.bDone = true
            Global.qrcode = tag
            idCamera.active = false
            idDialogSuccess.gStrMsg = tag
            idDialogSuccess.open()
        }
    }

    ConfirmDialog {
        id: idDialogSuccess
        gTitle: qsTr("Success")
        gStrMsg: ""
        hasCancelButton: false
        onAcceptClicked: {
            Global.idStack.pop()
        }
    }

    ZhomeToolbar {
        id: idToolbar
        winTitle: qsTr("PC Login")
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    Text {
        text: qsTr("Scan the QR Code to Login from PC")
        anchors.top: idToolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        font.pixelSize: Global.fontSize
        color: palette.text
        wrapMode: Text.WordWrap
    }

    Text {
        text: Global.currDevice.ip
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Global.bottomPad + 10
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Global.fontSize
        color: palette.text
        wrapMode: Text.WordWrap
    }

    VideoOutput {
        id: idVideoOutput
        anchors.fill: parent
        anchors.margins: 10
        Component.onCompleted: {
            idCamera.active = false
            idCamera.active = true
        }
    }

    Camera {
        id: idCamera
        active: true
        focusMode: Camera.FocusModeAutoNear
    }

    CaptureSession {
        camera: idCamera
        videoOutput: idVideoOutput
    }

    QZXingFilter {
        videoSink: idVideoOutput.videoSink
        decoder {
            enabledDecoders: QZXing.DecoderFormat_QR_CODE
            onTagFound: function(tag) { idRoot.foundTag(tag) }
        }
    }
}
