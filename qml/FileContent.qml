import QtQuick

Item {
    anchors.fill: parent
    Loader {
        anchors.fill: parent
        sourceComponent: Zpath.selectedShared ?
                             ( Zpath.dbFilesPrivateCpp.displayType === 0 ? idListShared : idIconShared) :
                             ( Zpath.dbFilesPrivateCpp.displayType === 0 ? idList : idIcon)
    }

    Component {
        id: idList
        FileList {
            dbFilesCpp: Zpath.dbFilesPrivateCpp
        }
    }

    Component {
        id: idListShared
        FileList {
            dbFilesCpp: Zpath.dbFilesSharedCpp
        }
    }

    Component {
        id: idIcon
        FileIcon {
            dbFilesCpp: Zpath.dbFilesPrivateCpp
        }
    }

    Component {
        id: idIconShared
        FileIcon {
            dbFilesCpp: Zpath.dbFilesSharedCpp
        }
    }
}
