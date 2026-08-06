import QtQuick
import QtQuick.Layouts
import "Global"

Item {
    id: idRoot

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        FilePathview {
            Layout.fillWidth: true
            Layout.minimumHeight: Global.toolbarHeight
            Layout.maximumHeight: Global.toolbarHeight
            visible: !Zpath.selectedSmallGame
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: Zpath.items[Zpath.pp_selectedIndex].comp
        }

        MyBottomToolbarTrash {
            Layout.fillWidth: true
            implicitHeight: visible ? (Global.bottomButtonHeight + 16 + Global.bottomPad) : 0
        }

        MyBottomToobarOperates {
            Layout.fillWidth: true
            implicitHeight: visible ? (Global.bottomButtonHeight + 16 + Global.bottomPad) : 0
        }

        MyBottomToolbarFileType {
            Layout.fillWidth: true
            implicitHeight: visible ? (Global.bottomButtonHeight + 16 + Global.bottomPad) : 0
        }
    }

    Component.onCompleted: {}

    Component.onDestruction: {
        Zpath.exitEditMode()
    }

    Connections {
        target: Zpath.previewDocCpp
        function onDownloadFinish(filePath) {
            if (Global.utilsCpp.isReadableDocument(filePath)) {
                var fileUrl = Global.utilsCpp.addLocalFilePrefix(filePath)
                fileUrl = fileUrl.replace("////", "///")
                Qt.openUrlExternally(fileUrl)
            }
            else {
                Global.utilsCpp.openFileDirectory(filePath)
            }
        }
    }
}
