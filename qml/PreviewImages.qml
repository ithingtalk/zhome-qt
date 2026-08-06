import QtQuick
import QtQuick.Controls
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property string title: ""

    ZhomeToolbar {
        id: idToolbar
        visible: Global.isMobile
        winTitle: idRoot.title
        z: 2
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    BusyIndicator {
        id: idBusy
        anchors.centerIn: parent
        width: 80
        height: 80
        running: false
        visible: false
        states: [
            State {
                when: (idImageView.status === Image.Loading) && (!idRoot.fileExists())
                PropertyChanges {
                    idBusy.running: true
                    idBusy.visible: true
                }
            }
        ]
    }

    Image {
        id: idImageView
        width: parent.width
        height: parent.height
        fillMode: Image.PreserveAspectFit
        autoTransform: true
        // Small Image look more clear
        mipmap: true
        // Image show more smooth
        asynchronous: true
        layer.enabled: true
        layer.smooth: true

        onStatusChanged: {
            if (status === Image.Ready) { console.log("Image load Ready") }
            else if (status === Image.Error) { console.error("Image load Error") }
        }

        PinchHandler {
            id: pinchHandler

            target: idImageView
            scaleAxis.enabled : true
            scaleAxis.maximum : 5.0
            scaleAxis.minimum : 0.5
            onActiveScaleChanged: idImageView.scale = Logic.clamp(activeScale, minimumScale, maximumScale)

            rotationAxis.enabled: false
            xAxis.enabled: false
            yAxis.enabled: false
        }

        MouseArea {
            anchors.fill: parent

            drag.target: idImageView.scale > 1.0 ? idImageView : null
            drag.axis: Drag.XAndYAxis
            drag.filterChildren: true
            drag.maximumX: ( idImageView.width * idImageView.scale - idRoot.width ) / 2
            drag.minimumX: drag.maximumX * -1
            drag.maximumY: ( idImageView.height * idImageView.scale - idRoot.height ) / 2
            drag.minimumY: drag.maximumY * -1

            onWheel: (wheel)=> idImageView.scale = Logic.clamp(idImageView.scale * (1.0 + (wheel.angleDelta.y / 120) * 0.1), 0.5, 5.0)

            onDoubleClicked: { idRoot.restoreAll() }
        }
    }

    ToolBar {
        id: idBottomToolBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Global.bottomPad
        height: 50
        z: 2

        background: Rectangle {
            color: "transparent"
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            MyToolButton {
                visible: Zpath.fileListPreview.length > 1
                gIcon: "../icons/ionicons/arrow-back.svg"
                gSize: 48
                iconH: 36
                iconW: 36
                gTipText: qsTr("Previous")
                onToolButtonClicked: {
                    Zpath.fileSelectedIndex = (Zpath.fileSelectedIndex - 1 + Zpath.fileListPreview.length) % Zpath.fileListPreview.length
                    idRoot.loadImage()
                }
            }

            /*MyToolButton {
                gIcon: "../icons/fontawesome/svgs/solid/arrow-rotate-left.svg"
                gSize: 48
                iconH: 36
                iconW: 36
                gTipText: qsTr("Rotate left")
                onToolButtonClicked: {
                    idImageView.rotation = (idImageView.rotation + 360 - 90) % 360
                }
            }*/

            MyToolButton {
                gText: Math.round(idImageView.scale * 100) + " %"
                gDisplay: AbstractButton.IconOnly
                gIcon: "../icons/fontawesome/svgs/solid/expand.svg"
                gSize: 48
                iconH: 36
                iconW: 36
                gTipText: qsTr("Restore")
                onToolButtonClicked: {
                    idRoot.restoreAll()
                }
            }

            /*MyToolButton {
                gIcon: "../icons/fontawesome/svgs/solid/arrow-rotate-right.svg"
                gSize: 48
                iconH: 36
                iconW: 36
                gTipText: qsTr("Rotate right")
                onToolButtonClicked: {
                    idImageView.rotation = (idImageView.rotation + 360 + 90) % 360
                }
            }*/

            MyToolButton {
                visible: Zpath.fileListPreview.length > 1
                gIcon: "../icons/ionicons/arrow-forward.svg"
                gSize: 48
                iconH: 36
                iconW: 36
                gTipText: qsTr("Next")
                onToolButtonClicked: {
                    Zpath.fileSelectedIndex = (Zpath.fileSelectedIndex + 1) % Zpath.fileListPreview.length
                    idRoot.loadImage()
                }
            }
        }
    }

    Connections {
        target: Zpath.previewImageCpp
        function onDownloadFinish(filePath) {
            // console.log("=============> PreviewImage.qml, filePath: " + filePath)
            idImageView.source = Global.utilsCpp.addLocalFilePrefix(filePath)
        }
    }

    function loadImage() {
        restoreAll()
        if (fileExists()) {
            idImageView.source = getLocalFilePath()
        }
        else {
            idImageView.source = ""
            // delay run, waiting for empty source
            Qt.callLater( function() {
                // console.log("=============> PreviewImage.qml, localPath: " + getLocalFilePath())
                Zpath.previewImageCpp.download(getRemoteUrl(), getLocalFilePath())
                idRoot.title = Logic.getFileName(Zpath.fileListPreview[Zpath.fileSelectedIndex].filepath)
            } )
        }
    }

    function restoreAll() {
        idImageView.scale = 1
        idImageView.rotation = 0
        idImageView.x = 0
        idImageView.y = 0
    }

    function fileExists() {
        return Number(Zpath.fileListPreview[Zpath.fileSelectedIndex].filesize) === Global.utilsCpp.fileSize(idRoot.getLocalFilePath())
    }

    function getLocalFilePath() {
        return Global.utilsCpp.addLocalFilePrefix(Zpath.previewImageCpp.cacheDir() + "/" + Logic.getFileName(Zpath.fileListPreview[Zpath.fileSelectedIndex].filepath))
    }

    function getRemoteUrl() {
        return Global.nasApiCpp.getRemoteFilePath(Zpath.fileListPreview[Zpath.fileSelectedIndex].filepath)
    }

    Component.onCompleted: {
        console.log("fileList count: " + Zpath.fileListPreview.length + ", index: " + Zpath.fileSelectedIndex)
        if (Global.isDesktop) {
            Global.idWindow.title = Qt.binding(() => idRoot.title)
            // Global.idWindow.showMaximized()
        }
        loadImage()
    }

    Component.onDestruction: {
        if (Global.isDesktop) {
            Global.idWindow.title = Qt.binding(() => Global.currDevice.name)
            // Global.idWindow.showNormal()
        }
    }
}
