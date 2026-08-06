import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property string title: qsTr("Replace Disk")
    property string adminPasswd: ""
    property int step: 1
    property bool busy: false
    property string errorText: ""
    property string errorCode: ""
    property string progressStatus: ""
    property string progressRaw: ""
    property string pendingStep: ""

    readonly property bool step3FatalError: step === 3 && errorText !== ""
        && (isFormatError(errorCode) || isCopyError(errorCode))

    ZhomeToolbar {
        id: idToolbar
        winTitle: idRoot.title
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: idToolbar.height
        anchors.margins: 12
        contentHeight: idCol.implicitHeight
        clip: true

        ColumnLayout {
            id: idCol
            width: parent.width
            spacing: 12

            Text {
                text: qsTr("Replace Disk")
                font.pixelSize: Global.fontSize + 4
                font.bold: true
                color: palette.text
            }
            Text {
                text: qsTr("Step %1 of %2").arg(idRoot.step).arg(8)
                font.pixelSize: Global.fontSize - 2
                color: palette.placeholderText
            }
            Image {
                Layout.fillWidth: true
                Layout.maximumHeight: 220
                fillMode: Image.PreserveAspectFit
                source: "images/disk_replace/step_" + idRoot.step + ".png"
            }
            Text {
                text: stepTitle()
                font.pixelSize: Global.fontSize + 2
                font.bold: true
                color: palette.text
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Text {
                text: stepBody()
                font.pixelSize: Global.fontSize
                color: palette.text
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                visible: idRoot.step === 1
                spacing: 8
                BusyIndicator { running: true; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                Text { text: qsTr("Preparing the device..."); color: palette.text }
            }

            ColumnLayout {
                visible: idRoot.step === 3 && !idRoot.step3FatalError
                spacing: 6
                Text {
                    text: phaseLabel()
                    color: palette.highlight
                }
                Text {
                    visible: idRoot.progressRaw !== ""
                    text: idRoot.progressRaw
                    font.pixelSize: Global.fontSize + 4
                    color: palette.text
                }
                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    indeterminate: progressFraction() < 0
                    value: Math.max(0, progressFraction())
                }
            }

            Text {
                visible: idRoot.errorText !== ""
                text: idRoot.errorText
                color: "red"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }

                // Fatal format: Back only
                Button {
                    visible: idRoot.step3FatalError && isFormatError(idRoot.errorCode)
                    text: qsTr("Back")
                    onClicked: {
                        idRoot.step = 2
                        clearError()
                    }
                }
                // Fatal copy: Stop only
                Button {
                    visible: idRoot.step3FatalError && isCopyError(idRoot.errorCode)
                    text: qsTr("Stop")
                    onClicked: Global.popStackviewPage()
                }

                // Normal footer
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step !== 8
                    text: qsTr("Cancel")
                    enabled: idRoot.step !== 3 || idRoot.errorText !== ""
                    onClicked: Global.popStackviewPage()
                }
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step === 2
                    text: qsTr("Next")
                    enabled: !idRoot.busy
                    onClicked: runStart()
                }
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step === 3 && idRoot.errorText !== ""
                    text: qsTr("Back")
                    onClicked: {
                        idRoot.step = 2
                        clearError()
                    }
                }
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step >= 4 && idRoot.step <= 8
                    text: qsTr("Previous")
                    onClicked: {
                        idRoot.step -= 1
                        idRoot.errorText = ""
                    }
                }
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step >= 4 && idRoot.step <= 7
                    text: qsTr("Next")
                    onClicked: {
                        idRoot.step += 1
                        idRoot.errorText = ""
                    }
                }
                Button {
                    visible: !idRoot.step3FatalError && idRoot.step === 8
                    text: qsTr("Done")
                    onClicked: Global.idStack.replace("DevicesPage.qml")
                }
            }
        }
    }

    Timer {
        id: idStatusTimer
        interval: 3000
        repeat: true
        running: idRoot.step === 3 && !idRoot.step3FatalError
        onTriggered: {
            idRoot.pendingStep = "status"
            Logic.sendCmdReplaceHardDisk(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd, "status")
        }
    }

    Connections {
        target: Global.cmdServiceDeviceManagmentCpp
        function onDataReceived(strCmd, strResult) {
            if (strResult.indexOf("replace_hard_disk") < 0 && idRoot.pendingStep === "")
                return
            handleReplaceResult(strResult)
        }
        function onErrorOccurred(errString, errCode) {
            if (idRoot.pendingStep === "")
                return
            idRoot.busy = false
            idRoot.errorText = errString
            idRoot.pendingStep = ""
        }
    }

    Component.onCompleted: {
        idRoot.pendingStep = "prepare"
        idRoot.busy = true
        Logic.sendCmdReplaceHardDisk(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd, "prepare")
    }

    function clearError() {
        idRoot.errorText = ""
        idRoot.errorCode = ""
        idRoot.progressStatus = ""
        idRoot.progressRaw = ""
    }

    function isFormatError(code) { return code === "format_failed" }
    function isCopyError(code) { return code === "copy_failed" || code === "rsync_failed" }

    function formatBytes(raw) {
        var n = parseInt(raw, 10)
        if (isNaN(n) || n <= 0)
            return raw
        var gb = n / (1024.0 * 1024.0 * 1024.0)
        if (gb >= 1.0)
            return gb.toFixed(1) + " GB"
        return Math.round(n / (1024.0 * 1024.0)) + " MB"
    }

    function errorUiText(code, message, usbSize, hddUsed) {
        var base = ""
        if (code === "no_usb")
            base = qsTr("No USB disk detected. Install the new disk in a USB enclosure, plug it into the NAS, then retry.")
        else if (code === "disk_too_small")
            base = qsTr("The new disk is too small. Its capacity must be greater than the used space on the current NAS disk.")
        else if (code === "format_failed")
            base = message !== "" ? message : qsTr("Failed to format the USB disk.")
        else if (code === "copy_failed" || code === "rsync_failed")
            base = message !== "" ? message : qsTr("Failed to copy data to the USB disk.")
        else
            base = message !== "" ? message : qsTr("Disk replacement failed")
        if (code === "disk_too_small" && usbSize !== "" && hddUsed !== "")
            base += "\n" + qsTr("New disk: %1 · Used on NAS: %2").arg(formatBytes(usbSize)).arg(formatBytes(hddUsed))
        return base
    }

    function progressFraction() {
        var m = idRoot.progressRaw.trim().match(/^(\d{1,3})\s*%$/)
        if (!m)
            return -1
        var p = parseInt(m[1], 10)
        if (isNaN(p))
            return -1
        return Math.max(0, Math.min(100, p))
    }

    function phaseLabel() {
        var s = idRoot.progressStatus.toLowerCase()
        if (s === "init")
            return qsTr("Initializing new disk...")
        if (s === "copy")
            return qsTr("Copying data...")
        return idRoot.progressStatus !== "" ? idRoot.progressStatus : qsTr("Starting...")
    }

    function stepTitle() {
        switch (idRoot.step) {
        case 1: return qsTr("Preparing")
        case 2: return qsTr("Connect the new disk")
        case 3: return qsTr("Copying data")
        case 4: return qsTr("Unplug the USB cable")
        case 5: return qsTr("Power off the NAS")
        case 6: return qsTr("Remove the old disk")
        case 7: return qsTr("Install the new disk")
        default: return qsTr("Power on")
        }
    }

    function stepBody() {
        switch (idRoot.step) {
        case 1: return qsTr("Please wait while the NAS stops disk monitoring and clears previous replace state.")
        case 2: return qsTr("Install the new disk into a USB enclosure and plug the USB cable into the NAS. Then tap Next to start copying.")
        case 3: return qsTr("The NAS is initializing the new disk and copying data. Keep the USB cable connected.")
        case 4: return qsTr("Please unplug the USB cable from the NAS first.")
        case 5: return qsTr("Press the NAS power button to shut down the device normally.")
        case 6: return qsTr("Open the NAS enclosure and remove the old disk.")
        case 7: return qsTr("Take the new disk out of the USB enclosure and install it into the NAS enclosure.")
        default: return qsTr("Press the NAS power button to start the device. Disk replacement is complete.")
        }
    }

    function runStart() {
        idRoot.busy = true
        clearError()
        idRoot.pendingStep = "start"
        Logic.sendCmdReplaceHardDisk(Global.cmdServiceDeviceManagmentCpp, idRoot.adminPasswd, "start")
    }

    function handleReplaceResult(strResult) {
        var pending = idRoot.pendingStep
        idRoot.pendingStep = ""
        idRoot.busy = false

        var ok = Global.nasApiCpp.parseReplaceHardDiskOk(strResult)
        var status = Global.nasApiCpp.parseReplaceHardDiskStatus(strResult)
        var progress = Global.nasApiCpp.parseReplaceHardDiskProgress(strResult)
        var errCode = Global.nasApiCpp.parseReplaceHardDiskErrorCode(strResult)
        var errMsg = Global.nasApiCpp.parseReplaceHardDiskErrorMessage(strResult)
        var usbSize = Global.nasApiCpp.parseReplaceHardDiskUsbSize(strResult)
        var hddUsed = Global.nasApiCpp.parseReplaceHardDiskHddUsedSize(strResult)

        if (pending === "prepare") {
            if (ok)
                idRoot.step = 2
            else
                idRoot.errorText = errMsg !== "" ? errMsg : qsTr("Failed to prepare disk replacement")
            return
        }

        if (pending === "start") {
            if (status.toLowerCase() === "error" || errCode !== "") {
                idRoot.errorCode = errCode
                idRoot.errorText = errorUiText(errCode, errMsg, usbSize, hddUsed)
            } else {
                idRoot.progressStatus = status
                idRoot.progressRaw = progress
                idRoot.step = 3
            }
            return
        }

        // status poll (or unsolicited)
        idRoot.progressStatus = status
        idRoot.progressRaw = progress
        if (status.toLowerCase() === "finish") {
            clearError()
            idRoot.step = 4
        } else if (status.toLowerCase() === "error") {
            idRoot.errorCode = errCode
            idRoot.errorText = errorUiText(errCode, errMsg, usbSize, hddUsed)
        }
    }
}
