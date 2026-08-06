import QtQuick
import QtQuick.Controls
import "Global"

ApplicationWindow {
    id: idRoot
    minimumWidth: Global.minWindowWidth
    minimumHeight: Global.minWindowHeight
    font.pixelSize: Global.fontSize
    title: Global.currDevice?.name ?? ""
    visibility: Global.isDesktop ? Window.Windowed : Window.Maximized
    flags: Qt.Window | Qt.WindowCloseButtonHint | Qt.WindowMinMaxButtonsHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | (Global.isMobile ? Qt.MaximizeUsingFullscreenGeometryHint : 0)
    topPadding: visibility === Window.FullScreen ? 0 : SafeArea.margins.top
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    background: Rectangle { color: Global.toolbarBgColor }

    // ios: top: 50, bottom: 34, other: 0
    // android: top: 41, other: 0

    Connections {
        target: Global.themeCpp
        function onDataChanged() {
            timerUpdateBgColor.start()
        }
    }

    Timer {
        id: timerUpdateBgColor
        repeat: false
        interval: 50
        onTriggered: {
            Global.updateWindowBgColor()
        }
    }

    signal setTheme()

    StackView {
        id: idStack
        anchors.fill: parent
        anchors.margins: idRoot.visibility === Window.FullScreen ? 0 : 5
        padding: 0
    }

    onClosing: function(event) {
        if (idStack.depth > 1) {
            Global.popStackviewPage()
            event.accepted = false
        } else {
            event.accepted = true
        }
    }

    Connections {
        target: Screen
        function onOrientationChanged() {
            console.log("screen orientation changed to: " + Screen.orientation)
            if (Screen.orientation === Qt.PortraitOrientation) {
                Global.normalWindowStage2();
            }
        }
    }

    Component.onCompleted: {
        console.log(Qt.platform.os)
        console.log("fontSize: " + idRoot.font.pixelSize + ", " + idRoot.font.pointSize)

        Global.idWindow = idRoot
        Global.idStack = idStack

        idRoot.setTheme()
        Global.updateWindowBgColor()

        // ==================================================
        Global.localAccountCpp.getPass() !== "" ? idStack.push("DevicesPage.qml") : idStack.push("WelcomePage.qml")
        // ==================================================

        Global.normalWindowStage2()
    }

    Loader {
        width: 10
        height: parent.height
        anchors.left: parent.left
        sourceComponent: Global.isIos && (Global.iosUtilsCpp?.leftGestureEnabled ?? false) ? idSwipeLeft : null
    }

    Loader {
        width: 10
        height: parent.height
        anchors.right: parent.right
        sourceComponent: Global.isIos && (Global.iosUtilsCpp?.rightGestureEnabled ?? false) ? idSwipeRight : null
    }

    Component {
        id: idSwipeLeft
        MyIosGesture {
            bLeft: true
        }
    }

    Component {
        id: idSwipeRight
        MyIosGesture {
            bLeft: false
        }
    }

    // property color frColor: Global.isDarkTheme ? palette.window : palette.base
    // property color bgColor: Global.isDarkTheme ? palette.base : palette.window
}
