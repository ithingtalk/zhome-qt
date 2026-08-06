pragma Singleton
import QtQuick
import QtQuick.Controls

QtObject {
    // cpp class
    property var cmdServiceBtCpp: cmdServiceBtFromCpp
    property var cmdServiceDbFilesCpp: cmdServiceDbFilesFromCpp
    property var cmdServiceConnectDeviceCpp: cmdServiceConnectDeviceFromCpp
    property var cmdServiceDeviceManagmentCpp: cmdServiceDeviceManagmentFromCpp
    property var cmdServiceDeviceUserCpp: cmdServiceDeviceUserFromCpp
    property var cmdServiceLoginCpp: cmdServiceLoginFromCpp
    property var cmdServiceUserServiceCpp: cmdServiceUserServiceFromCpp
    property var themeCpp: themeManagerFromCpp
    property var localAccountCpp: localAccountFromCpp
    property var dbDevicesCpp: dbDevicesFromCpp
    property var searchLocalIdeviceCpp: searchLocalIdeviceFromCpp
    property var nasApiCpp: nasApiFromCpp
    property var dbFileTransferCpp: dbFileTransferFromCpp
    property var uploadingListCpp: uploadingListFromCpp
    property var downloadingListCpp: downloadingListFromCpp
    property var utilsCpp: utilsFromCpp
    property var mobileOrientationControllerCpp: isMobile ? mobileOrientationControllerFromCpp : undefined
    property var iosUtilsCpp: isIos ? iosUtilsFromCpp : undefined
    property var androidUtilsCpp: isAndroid ? androidUtilsFromCpp : undefined
    property var awsAccountCpp: awsAccountFromCpp
    property var awsDbServiceCpp : awsDbServiceFromCpp
    // qml property
    property ApplicationWindow idWindow
    property StackView idStack
    readonly property color iconColor: Qt.rgba(45/255, 165/255, 203/255, 1)
    readonly property color differIconColor: isDarkTheme ? Qt.lighter(iconColor, 1.5) :  Qt.darker(iconColor, 1.5)
    readonly property color popupIconColor: iconColor
    property var fontValues: [0, 11, 13, 15, 17, 19, 21, 23, 25, 27]
    property var fontIdx: themeCpp?.getFontSize() ?? 0
    property int fontSize: fontValues[fontIdx] === 0 ? (idWindow?.font.pixelSize ?? 14) : fontValues[fontIdx]
    property int fontSizeSmall3: Math.max(11, fontSize - 3)
    property int fontSizeTitle: fontSize // Math.max(11, fontSize + 2)
    property int fontSizeFooter: Math.max(11, fontSize - 5)
    readonly property int minWindowWidth: 480
    readonly property int minWindowHeight: 620 // 620 // 720
    readonly property int popupIconSize: 16
    readonly property int popupItemHeight: 40
    readonly property var popupBackgroud: Qt.rgba(80/255, 85/255, 90/255, 1)
    // readonly property var popupBackgroud: isDarkTheme ? Qt.rgba(60/255, 60/255, 60/255, 1) : Qt.rgba(220/255, 220/255, 220/255, 1)
    // mobile safearea
    property real bottomPad: idWindow?.SafeArea.margins.bottom ?? 0
    property real bottomButtonHeight: 50
    // comtum bgcolor
    property bool isDarkTheme: false
    property color bgColor: "grey"
    property color bgColor2: isDarkTheme ? Qt.lighter(bgColor, 1.2) : Qt.darker(bgColor, 1.2)
    property color bgColor3: isDarkTheme ? Qt.lighter(bgColor, 1.5) : Qt.darker(bgColor, 1.5)
    readonly property color toolbarBgColor: isMobile ? "transparent" : bgColor
    readonly property color toolbarBgColor2: isMobile ? "transparent" : bgColor2
    // system type
    readonly property bool isApple: Qt.platform.os === "ios" || Qt.platform.os === "macos"
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"
    readonly property bool isDesktop: !isMobile //windows, osx, linux
    readonly property bool isIos: Qt.platform.os === "ios"
    readonly property bool isAndroid: Qt.platform.os === "android"
    readonly property bool isWindows: Qt.platform.os === "windows"
    property bool isFullscreen:  idWindow?.visibility === Window.FullScreen ?? false
    property bool gbDevicePageEdit: false
    property var currDevice: { mac: ""; sn: ""; name: ""; cfg: ""; ip: ""; login: "" }
    property var currUser: undefined
    property var currDeviceInfo: undefined
    property int gConfigureNewDeviceRetryTimes: 0
    property int filelistPadding: 8
    property real cellSize: 144
    property real toolbarIconSize: 32
    property real toolbarHeight: 60
    property string qrcode: ""

    function setFontSize(idx) {
        themeCpp.setFontSize(idx)
        fontIdx = idx
    }

    function normalWindow() {
        if (isMobile) {
            mobileOrientationControllerCpp.request(false)
        }
        else {
            normalWindowStage2()
        }
    }

    function normalWindowStage2() {
        if (isDesktop) {
            idWindow.showNormal()
        }
        else {
            idWindow.showMaximized()
            androidSetStatusBarStyle()
        }
    }

    function androidSetStatusBarStyle() {
        if (isAndroid) {
            androidUtilsCpp.setStatusBarStyle(themeCpp.windowBgColor(), !themeCpp.isDarkTheme());
        }
    }

    function fullScreen() {
        idWindow.showFullScreen()
        if (isMobile) {
            mobileOrientationControllerCpp.request(true)
        }
    }

    function popStackviewPage()
    {
        if (isFullscreen) {
            normalWindow()
        }
        idStack.pop()
    }

    function closeWindow() {
        idWindow.close()
    }

    function updateWindowBgColor() {
        isDarkTheme = themeCpp.isDarkTheme()
        bgColor = themeCpp.windowBgColor()
        androidSetStatusBarStyle()
    }
}
