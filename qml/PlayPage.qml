import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "Global"
import "global.js" as Logic

Item {
    id: idRoot
    property var gVideoUrls
    property int gUrlsIdx: 0
    /** 0=原画 1=高清(.hd.mp4) 2=标清(.sd.mp4)，默认高清 */
    property int gVideoQuality: 1
    property int gRepeatMode: 2
    property bool currentFileIsVideo: Zpath.isSelectedVideo(gVideoUrls[gUrlsIdx])
    property bool currentFileIsAudio: Zpath.isSelectedAudio(gVideoUrls[gUrlsIdx])

    ZhomeToolbar {
        id: idToolbar
        visible: Global.isMobile && !Global.isFullscreen
        winTitle: Logic.getFileName(idRoot.gVideoUrls[idRoot.gUrlsIdx])
        z: 2
        onBackFunc: function () {
            Global.popStackviewPage()
        }
    }

    Button {
        anchors.centerIn: parent
        visible: (idPlayer.playbackState != MediaPlayer.PlayingState) && idPlayer.hasVideo
        icon.source: "../icons/ionicons/play.svg"
        icon.color: "darkblue"
        icon.width: 150
        icon.height: 150
        background: null
        width: 200
        height: 200
        display: AbstractButton.IconOnly
        z: 3
        onClicked: {
            idRoot.playPause()
            idRoot.toolbarVisible(true)
        }
    }

    Rectangle {
        id: idPlayVideoWindow
        anchors.fill: parent
        color: Global.isFullscreen ? "black" : palette.window
        visible: true
        z: 1

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
            z: 1
        }

        MouseArea {
            id: idVideoMouseArea
            anchors.fill: videoOutput
            anchors.bottomMargin: idToolbarPlayer.implicitHeight
            propagateComposedEvents: true
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            onDoubleClicked: function(event) {
                idRoot.normalFullscreen()
            }

            onPositionChanged: {
                idRoot.toolbarVisible(true)
            }

            onClicked: {
                var bShow = true
                if (!idToolbarMouseArea.containsMouse && idToolbarPlayer.visible) {
                    bShow = false
                }
                idRoot.toolbarVisible(bShow)
            }
        }
    }

    states: [
        State {
            when: !idToolbarPlayer.visible
            PropertyChanges {
                idVideoMouseArea.cursorShape: Qt.BlankCursor
            }
        },
        State {
            when: idRoot.currentFileIsAudio
            PropertyChanges {
                idPlayVideoWindow.visible: false
                idPlayMusicWindow.visible: true
            }
        }
    ]

    ColumnLayout { // play music
        id: idPlayMusicWindow
        visible: false
        anchors.centerIn: parent
        width: parent.width
        spacing: 16
        Image {
            id: record
            source: "../icons/changpian.png"
            Layout.preferredHeight: 360
            Layout.preferredWidth: 360
            Layout.alignment: Qt.AlignHCenter

            RotationAnimation on rotation {
                id: rotateAnimation
                from: 0
                to: 360
                duration: 36000 // one circle
                loops: Animation.Infinite // endless loop
                running: idPlayer.playbackState === MediaPlayer.PlayingState
            }
        }
    }

    function forceHFullscreen() {
        setForceFullscreen(videoOutput.fillMode !== VideoOutput.PreserveAspectCrop)
    }

    function setForceFullscreen(bForce) {
        videoOutput.fillMode = bForce ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
    }

    MediaPlayer {
        id: idPlayer
        videoOutput: videoOutput
        audioOutput: AudioOutput {}
        onPlaybackStateChanged: function(newState) {
            if (idRoot.currentFileIsVideo) {
                if (newState === MediaPlayer.PlayingState) {
                    console.log("change to playing")
                    idScreenKeeper.start()
                } else {
                    console.log("change to none playing")
                    idScreenKeeper.stop()
                }
            }
        }
        onMediaStatusChanged: {
            switch (mediaStatus) {
                case MediaPlayer.NoMedia:
                    console.log("No media")
                    break
                case MediaPlayer.LoadingMedia:
                    console.log("Media loading")
                    break
                case MediaPlayer.LoadedMedia:
                    //Qt.callLater(function() {
                        console.log("Media loaded")
                        /*var i
                        var idx
                        for (i=0; i < audioTracks.length; i++) {
                            var sMetadata = audioTracks[i]
                            for (const key of sMetadata.keys())
                                if (sMetadata.stringValue(key))
                                    console.log(sMetadata.metaDataKeyToString(key) + "==> " + sMetadata.stringValue(key))
                        }*/
                    //})
                    break
                case MediaPlayer.StalledMedia:
                    console.log("Media stalled")
                    break
                case MediaPlayer.BufferingMedia:
                    console.log("Media buffering")
                    break
                case MediaPlayer.BufferedMedia:
                    console.log("Media buffered")
                    break
                case MediaPlayer.EndOfMedia:
                    console.log("Media ended")
                    // 视频：播完即停，不循环、不自动下一首；音频仍按循环模式处理
                    if (idRoot.currentFileIsVideo)
                        break
                    if (idRoot.gRepeatMode === 1) {
                        idRoot.playCurrUrl()
                    }
                    else if (idRoot.gRepeatMode === 2) {
                        idRoot.playNextUrl()
                    }
                    break
                case MediaPlayer.InvalidMedia:
                    console.log("Media invalid")
                    break
            }
        }
    }

    ToolBar {
        id: idToolbarPlayer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Global.idWindow.SafeArea.margins.bottom
        height: toolbarPlayerId.implicitHeight
        z: 2

        background: Rectangle {
            color: "transparent"
        }

        ColumnLayout {
            id: toolbarPlayerId
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                spacing: 4

                Text {
                    Layout.minimumWidth: idEndTime.implicitWidth + 2
                    Layout.maximumWidth: idEndTime.implicitWidth + 2
                    color: Global.iconColor
                    font.bold: true
                    font.pixelSize: Global.fontSizeSmall3
                    text: Logic.getHumanTime(Math.round(idPlayer.position / 1000))
                }

                Item { Layout.fillWidth: true }

                TracksOptions {
                    id: idSubtitleTracks
                    visible: idPlayer.subtitleTracks.length > 1
                    Layout.preferredWidth: visible ? implicitWidth + (Global.isIos ? 16 : 0) : 20
                    trackName: qsTr("Subtitle")
                    selectedTrack: 0
                    metaData: idPlayer.subtitleTracks
                    onSelectedTrackChanged: idPlayer.activeSubtitleTrack = idSubtitleTracks.selectedTrack
                }

                TracksOptions {
                    id: idVideoTracks
                    visible: idPlayer.videoTracks.length > 1
                    Layout.preferredWidth: visible ? implicitWidth + (Global.isIos ? 16 : 0) : 0
                    trackName: qsTr("Video")
                    selectedTrack: 0
                    metaData: idPlayer.videoTracks
                    onSelectedTrackChanged: idPlayer.activeVideoTrack = idVideoTracks.selectedTrack
                }

                TracksOptions {
                    id: idAudioTrack
                    visible: idPlayer.audioTracks.length > 1
                    Layout.preferredWidth: visible ? implicitWidth + (Global.isIos ? 16 : 0) : 0
                    trackName: qsTr("Audio")
                    selectedTrack: 0
                    metaData: idPlayer.audioTracks
                    onSelectedTrackChanged: idPlayer.activeAudioTrack = idAudioTrack.selectedTrack
                }

                ToolButton {
                    visible: Global.isFullscreen
                    icon.height: 24
                    icon.width: 24
                    implicitWidth: visible ? 40 : 0
                    implicitHeight: 40
                    icon.source: "../icons/fontawesome/svgs/solid/arrows-left-right.svg"
                    icon.color:  Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idRoot.forceHFullscreen() }
                    }
                }

                ComboBox {
                    id: idSpeedControl
                    textRole: "key"
                    valueRole: "value"
                    onActivated: idPlayer.playbackRate = currentValue
                    Component.onCompleted: currentIndex = 2
                    Layout.preferredWidth: implicitWidth + (Global.isIos ? 16 : 4)

                    model: [
                        { value: 0.5, key: "0.5X" },
                        { value: 0.75, key: "0.75X" },
                        { value: 1.0, key: "1.0X" },
                        { value: 1.25, key: "1.25X" },
                        { value: 1.5, key: "1.5X" },
                        { value: 1.75, key: "1.75X" },
                        { value: 2.0, key: "2.0X" },
                        { value: 3.0, key: "3.0X" },
                        { value: 5.0, key: "5.0X" },
                        { value: 9.0, key: "9.0X" }
                    ]

                    contentItem: Text {
                        text: idSpeedControl.displayText
                        font.bold: true
                        font.pixelSize: Global.fontSizeSmall3
                        color: Global.iconColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        //border.color: "#444"
                        radius: 4
                    }

                    popup.font.pixelSize: Global.fontSizeSmall3
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: idEndTime
                    color: Global.iconColor
                    font.bold: true
                    font.pixelSize: Global.fontSizeSmall3
                    text: Logic.getHumanTime(Math.round(idPlayer.duration.valueOf() / 1000))
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 0
                Slider {
                    id: idSeekSlider
                    Layout.fillWidth: true
                    padding: 0
                    from: 0
                    to: idPlayer.duration / 1000
                    stepSize: 1

                    ToolTip {
                        parent: idSeekSlider.handle
                        visible: idSeekSlider.pressed
                        text: Logic.getHumanTime(idSeekSlider.value.toFixed(1))
                    }

                    Binding {
                        id: positionBinding
                        target: idSeekSlider
                        property: "value"
                        value: idPlayer.position / 1000
                        when: !idSeekSlider.pressed
                    }

                    onPressedChanged: {
                        if (!pressed) {
                            idPlayer.setPosition(position * idPlayer.duration)
                        }
                    }

                    background: Rectangle {
                        x: idSeekSlider.leftPadding
                        y: idSeekSlider.topPadding + idSeekSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: idSeekSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#bdbebf"

                        Rectangle {
                            width: idSeekSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#21be2b"
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: idSeekSlider.leftPadding + idSeekSlider.visualPosition * (idSeekSlider.availableWidth - width)
                        y: idSeekSlider.topPadding + idSeekSlider.availableHeight / 2 - height / 2
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: idSeekSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: "#bdbebf"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                spacing: 4

                Item { Layout.fillWidth: true }

                ToolButton { // 0:no, 1:repeat one, 2: repeat all（仅音频；视频不循环、无此控件）
                    id: idRepeat
                    visible: !idRoot.currentFileIsVideo
                    icon.height: 40
                    icon.width: 40
                    implicitWidth: 40
                    implicitHeight: 40
                    padding: 0
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            idRoot.gRepeatMode++
                            if (idRoot.gRepeatMode > 2) {
                                idRoot.gRepeatMode = 0
                            }
                        }
                    }

                    states: [
                        State {
                            when: idRoot.gRepeatMode === 0
                            PropertyChanges {
                                idRepeat.icon.source: "../icons/ionicons/repeat.svg"
                                idRepeat.icon.color: "grey"
                            }
                        },
                        State {
                            when: idRoot.gRepeatMode === 1
                            PropertyChanges {
                                idRepeat.icon.source: "../icons/repeatOne.svg"
                                idRepeat.icon.color: Global.iconColor
                            }
                        },
                        State {
                            when: idRoot.gRepeatMode === 2
                            PropertyChanges {
                                idRepeat.icon.source: "../icons/repeatAll.svg"
                                idRepeat.icon.color: Global.iconColor
                            }
                        }
                    ]
                }

                Item { Layout.fillWidth: true }

                ToolButton {
                    icon.height: 40
                    icon.width: 40
                    implicitWidth: 40
                    implicitHeight: 40
                    padding: 0
                    icon.source: "../icons/ionicons/play-skip-back.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idRoot.playPrevUrl() }
                    }
                }

                ToolButton {
                    icon.height: 44
                    icon.width: 44
                    implicitWidth: 44
                    implicitHeight: 44
                    padding: 0
                    icon.source: (idPlayer.playbackState === MediaPlayer.PlayingState) ? "../icons/ionicons/pause.svg" : "../icons/ionicons/play.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idRoot.playPause() }
                    }
                }

                ToolButton {
                    icon.height: 40
                    icon.width: 40
                    implicitWidth: 40
                    implicitHeight: 40
                    padding: 0
                    icon.source: "../icons/ionicons/play-skip-forward.svg"
                    icon.color: Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idRoot.playNextUrl() }
                    }
                }

                Item { Layout.fillWidth: true }

                ComboBox {
                    id: idVideoQuality
                    visible: idRoot.currentFileIsVideo
                    textRole: "key"
                    valueRole: "value"
                    currentIndex: 1
                    Layout.preferredWidth: implicitWidth + (Global.isIos ? 12 : 4)
                    model: [
                        { value: 0, key: qsTr("原画") },
                        { value: 1, key: qsTr("高清") },
                        { value: 2, key: qsTr("标清") },
                    ]
                    onActivated: {
                        idRoot.gVideoQuality = currentValue
                        idRoot.playCurrUrl()
                    }
                    contentItem: Text {
                        text: idVideoQuality.displayText
                        font.bold: true
                        font.pixelSize: Global.fontSizeSmall3
                        color: Global.iconColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 4
                    }
                    popup.font.pixelSize: Global.fontSizeSmall3
                }

                ToolButton {
                    icon.height: 24
                    icon.width: 24
                    implicitWidth: 40
                    implicitHeight: 40
                    padding: 0
                    icon.source: (Global.idWindow.visibility != Window.FullScreen) ? "../icons/fontawesome/svgs/solid/up-right-and-down-left-from-center.svg" : "../icons/fontawesome/svgs/solid/down-left-and-up-right-to-center.svg"
                    icon.color:  Global.iconColor
                    display: AbstractButton.IconOnly
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: { idRoot.normalFullscreen() }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        MouseArea {
            id: idToolbarMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton

            onEntered: {
                console.log("======> mouse enter toolbar")
                idRoot.toolbarVisible(true)
            }

            onExited: {
                console.log("------> mouse exit toolbar")
                idRoot.toolbarVisible(true)
            }

            onClicked: {
                console.log("toolbar clicked, set mouse into toolbar")
                idRoot.toolbarVisible(true)
            }
        }
    }

    Keys.onReturnPressed: { normalFullscreen() }

    Keys.onEscapePressed: { idRoot.normalWindow() }

    Keys.onSpacePressed: { playPause() }

    Keys.onLeftPressed: {
        var setTo = Math.max(idPlayer.position - 5000, 0)
        idPlayer.setPosition(setTo)
    }

    Keys.onRightPressed: {
        var setTo = Math.min(idPlayer.position + 5000, idPlayer.duration)
        idPlayer.setPosition(setTo)
    }

    Timer {
        id: hideTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if ( (!idToolbarMouseArea.containsMouse)
                        && (idPlayer.playbackState === MediaPlayer.PlayingState)
                        && ((Global.idWindow.visibility === Window.FullScreen)
                            || (Global.idWindow.visibility === Window.Maximized)) )
            {
                idRoot.toolbarVisible(false)
            }
        }
    }

    function toolbarVisible(bShow) {
        if (bShow) hideTimer.restart()
        else hideTimer.stop()
        idToolbarPlayer.visible = bShow
    }

    function playPause() {
        if (idPlayer.playbackState === MediaPlayer.PlayingState) {
            idPlayer.pause()
        } else {
            // 视频已到片尾时再播需从头开始（部分平台片尾后 mediaStatus 可能变化，故同时看进度）
            if (idRoot.currentFileIsVideo) {
                var atEnd = (idPlayer.mediaStatus === MediaPlayer.EndOfMedia)
                    || (idPlayer.duration > 0 && idPlayer.position >= idPlayer.duration - 80)
                if (atEnd)
                    idPlayer.setPosition(0)
            }
            idPlayer.play()
        }
        idRoot.toolbarVisible(true)
    }

    function normalFullscreen() {
        if (Global.idWindow.visibility === Window.FullScreen) {
            idRoot.normalWindow()
        }
        else {
            Global.fullScreen()
            toolbarVisible(true)
        }
        idRoot.toolbarVisible(true)
    }

    function normalWindow() {
        setForceFullscreen(false)
        Global.normalWindow()
    }

    function playUrl(strUrl) {
        // Probe HD/SD via check_file_exists; fall back to original if missing (osx/Android parity).
        var pathForPlay = Global.nasApiCpp.resolvePlayableVideoPath(strUrl, idRoot.gVideoQuality)
        idPlayer.source = new URL(Global.nasApiCpp.getPlayerUrl(pathForPlay))
        idPlayer.play()
        forceActiveFocus() // KeyEvent support
    }

    function playCurrUrl() { playUrl(gVideoUrls[gUrlsIdx]) }

    function playNextUrl() {
        gUrlsIdx = (gUrlsIdx + 1) % gVideoUrls.length
        playUrl(gVideoUrls[gUrlsIdx])
    }

    function playPrevUrl() {
        gUrlsIdx = (gUrlsIdx - 1 + gVideoUrls.length) % gVideoUrls.length
        playUrl(gVideoUrls[gUrlsIdx])
    }

    Component.onCompleted: {
        console.log("PlayPage.qml ===> tracks: " + gVideoUrls.length + " " + Qt.platform.os)
        // Defer probe+play so StackView can paint PlayPage first. Otherwise sync
        // resolvePlayableVideoPath blocks while the file list still shows the
        // pressed/highlighted item (looks like select-then-play).
        Qt.callLater(function () {
            playCurrUrl()
        })
        if (Global.isDesktop) {
            Global.idWindow.title = Qt.binding(() => idToolbar.winTitle)
            // Global.idWindow.showMaximized()
        }
    }

    Component.onDestruction: {
        if (Global.isDesktop) {
            Global.idWindow.title = Qt.binding(() => Global.currDevice.name)
            // Global.idWindow.showNormal()
        }
    }

    ScreenKeepAwake {
        id: idScreenKeeper
    }
}
