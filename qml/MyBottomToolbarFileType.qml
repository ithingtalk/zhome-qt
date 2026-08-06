import QtQuick
import QtQuick.Layouts
import "Global"

Rectangle {
    id: idRoot
    color: Global.toolbarBgColor
    visible: (Zpath.normalMode || Zpath.movingMode) && (Zpath.selectedShared || Zpath.selectedMyFiles)

    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: Global.bottomPad
        spacing: 0

        MyBottomRadioButton {
            Layout.fillHeight: true
            Layout.fillWidth: true
            gChecked: Zpath.selectedDocImage
            btnText: qsTr("Picture")
            gIconSrc: "../icons/fontawesome/svgs/solid/image.svg"
            onAcceptClicked: {
                Zpath.gotoImage()
            }
        }

        MyBottomRadioButton {
            Layout.fillHeight: true
            Layout.fillWidth: true
            gChecked: Zpath.selectedDocVideo
            btnText: qsTr("Video")
            gIconSrc: "../icons/ionicons/film.svg"
            onAcceptClicked: {
                Zpath.gotoVideo()
            }
        }

        MyBottomRadioButton {
            Layout.fillHeight: true
            Layout.fillWidth: true
            gChecked: Zpath.selectedDocAudio
            btnText: qsTr("Music")
            gIconSrc: "../icons/ionicons/musical-note.svg"
            onAcceptClicked: {
                Zpath.gotoAudio()
            }
        }

        MyBottomRadioButton {
            Layout.fillHeight: true
            Layout.fillWidth: true
            gChecked: Zpath.selectedDocDoc
            btnText: qsTr("Other")
            gIconSrc: "../icons/ionicons/document-text.svg"
            onAcceptClicked: {
                Zpath.gotoOther()
            }
        }
    }
}
