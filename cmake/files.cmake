# set app version
#######################################################################################
set(HEADER_OUTPUT_DIR ${CMAKE_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${HEADER_OUTPUT_DIR})
configure_file(
    ${CMAKE_SOURCE_DIR}/cfg/VER.h.in
    ${HEADER_OUTPUT_DIR}/VER.h
    @ONLY
)
include_directories(${HEADER_OUTPUT_DIR})

set(MY_QML_FILES
    qml/global.js
    qml/WelcomePage.qml
    qml/LoginPage.qml
    qml/DevicesPage.qml
    qml/FilePage.qml
    qml/PlayPage.qml
    qml/Material.qml
    qml/Universal.qml
    qml/SettingPage.qml
    qml/ZhomeToolbar.qml
    qml/ZhomeMain.qml
    qml/Global/Global.qml
    qml/Global/Zpath.qml
    qml/DeviceConfigureNewPage.qml
    qml/DeviceManagmentPage.qml
    qml/DiskReplaceWizardPage.qml
    qml/ConfirmDialog.qml
    qml/DeviceUserPage.qml
    qml/ConnectDevicePage.qml
    qml/UserServicePage.qml
    qml/FilePathview.qml
    qml/FileList.qml
    qml/FileIcon.qml
    qml/FileContent.qml
    qml/FileTransfer.qml
    qml/SwipeLabel.qml
    qml/MainDefault.qml
    qml/MyBottomButton.qml
    qml/MyToolButton.qml
    qml/PreviewImages.qml
    qml/TracksOptions.qml
    qml/DownloadTask.qml
    qml/DownloadContent.qml
    qml/MyRadioButton.qml
    qml/MyBottomRadioButton.qml
    qml/MyBottomToolbarFileType.qml
    qml/MyBottomToobarOperates.qml
    qml/MyBottomToolbarTrash.qml
    qml/MyPopup.qml
    qml/MyIosGesture.qml
    qml/FileDropArea.qml
    qml/AddBtDialog.qml
    qml/ContentMainPage.qml
    qml/MySearch.qml
    qml/Qrcode.qml
    qml/AwsLoginPage.qml
    qml/DevicesSearchPage.qml
)

if(IOS OR ANDROID)
    list(APPEND MY_QML_FILES qml/PlayAudioPage.qml qml/QrScanner.qml)
endif()

set(MY_SOURCES
    cpp/localSettings.h cpp/himsgcenter.h
    cpp/dbDevices.h cpp/dbDevices.cpp
    cpp/themeManager.h cpp/themeManager.cpp
    cpp/localAccount.h cpp/localAccount.cpp
    cpp/singleInstance.h cpp/singleInstance.cpp
    cpp/dbFiles.h cpp/dbFiles.cpp
    cpp/searchLocalIdevice.h cpp/searchLocalIdevice.cpp
    cpp/nasApi.h cpp/nasApi.cpp
    cpp/cmdService.h cpp/cmdService.cpp
    cpp/localFileService.h cpp/localFileService.cpp
    cpp/screenKeepAwake.h cpp/screenKeepAwake.cpp
    cpp/dbFileTransfer.cpp cpp/dbFileTransfer.h
    cpp/utils.h cpp/utils.cpp
    cpp/globalCpp.h cpp/globalCpp.cpp
    cpp/awsAccount.h cpp/awsAccount.cpp
    cpp/awsDbService.h cpp/awsDbService.cpp
    cpp/awsIot.h cpp/awsIot.cpp
)

if(IOS)
    list(APPEND MY_SOURCES cpp/audioPlayerManager.mm cpp/audioService.cpp cpp/audioService.h
        cpp/mobileOrientationController.mm cpp/mobileOrientationController.h
        cpp/iosUtils.mm cpp/iosUtils.cpp cpp/iosUtils.h
        cpp/iosUploadPhotoAndVideo.mm
        cpp/iosDocumentPickerHandler.mm
    )
endif()

if(ANDROID)
    list(APPEND MY_SOURCES cpp/androidAudioPlayer.h cpp/androidAudioPlayer.cpp cpp/audioService.cpp cpp/audioService.h
        cpp/mobileOrientationController.cpp cpp/mobileOrientationController.h cpp/androidUtils.cpp cpp/androidUtils.h
    )
endif()

set(MY_ICONS
    icons/ionicons/construct.svg
    icons/ionicons/reader.svg
    icons/ionicons/cut.svg
    icons/ionicons/copy.svg
    icons/ionicons/lock-closed.svg
    icons/ionicons/lock-open.svg
    icons/ionicons/trash-bin.svg
    icons/ionicons/archive.svg
    icons/ionicons/pause.svg
    icons/ionicons/play.svg
    icons/ionicons/search.svg
    icons/ionicons/options.svg
    icons/ionicons/pulse-sharp.svg
    icons/ionicons/settings-sharp.svg
    icons/ionicons/arrow-back.svg
    icons/ionicons/arrow-forward.svg
    icons/ionicons/exit-outline.svg
    icons/fontawesome/svgs/solid/trash-can.svg
    icons/fontawesome/svgs/solid/circle-arrow-right.svg
    icons/fontawesome/svgs/solid/plus.svg
    icons/fontawesome/svgs/solid/minus.svg
    icons/fontawesome/svgs/solid/ellipsis.svg
    icons/fontawesome/svgs/solid/ellipsis-vertical.svg
    icons/fontawesome/svgs/solid/chevron-left.svg
    icons/fontawesome/svgs/solid/circle-user.svg
    icons/fontawesome/svgs/solid/down-long.svg
    icons/fontawesome/svgs/solid/up-long.svg
    icons/fontawesome/svgs/solid/share.svg
    icons/fontawesome/svgs/solid/share-nodes.svg
    icons/fontawesome/svgs/solid/circle-down.svg
    icons/fontawesome/svgs/solid/circle-up.svg
    icons/fontawesome/svgs/solid/file-image.svg
    icons/fontawesome/svgs/solid/file-video.svg
    icons/fontawesome/svgs/solid/file-audio.svg
    icons/fontawesome/svgs/solid/file-word.svg
    icons/fontawesome/svgs/solid/file.svg
    icons/fontawesome/svgs/solid/file-zipper.svg
    icons/fontawesome/svgs/solid/file-arrow-down.svg
    icons/fontawesome/svgs/solid/cart-arrow-down.svg
    icons/fontawesome/svgs/solid/image.svg
    icons/fontawesome/svgs/solid/video.svg
    icons/fontawesome/svgs/solid/music.svg
    icons/fontawesome/svgs/solid/window-restore.svg
    icons/fontawesome/svgs/solid/toolbox.svg
    icons/fontawesome/svgs/solid/floppy-disk.svg
    icons/fontawesome/svgs/solid/recycle.svg
    icons/fontawesome/svgs/solid/list.svg
    icons/fontawesome/svgs/solid/icons.svg
    icons/fontawesome/svgs/solid/folder.svg
    icons/fontawesome/svgs/solid/expand.svg
    icons/fontawesome/svgs/solid/down-left-and-up-right-to-center.svg
    icons/fontawesome/svgs/solid/up-right-and-down-left-from-center.svg
    icons/fontawesome/svgs/solid/audio-description.svg
    icons/fontawesome/svgs/regular/user.svg
    icons/fontawesome/svgs/solid/arrows-left-right.svg
    icons/ionicons/repeat.svg
    icons/repeatOne.svg
    icons/ionicons/play-skip-back.svg icons/ionicons/play-skip-forward.svg
    icons/changpian.png
    icons/repeatAll.svg
    icons/ionicons/document-text.svg
    icons/device.png
    icons/logo.png
    qml/images/disk_replace/step_1.png
    qml/images/disk_replace/step_2.png
    qml/images/disk_replace/step_3.png
    qml/images/disk_replace/step_4.png
    qml/images/disk_replace/step_5.png
    qml/images/disk_replace/step_6.png
    qml/images/disk_replace/step_7.png
    qml/images/disk_replace/step_8.png
    icons/ionicons/film.svg
    icons/ionicons/swap-vertical.svg
    icons/ionicons/folder.svg
    icons/ionicons/musical-note.svg
    icons/ionicons/add.svg
    icons/ionicons/refresh.svg
    icons/fontawesome/svgs/solid/angle-left.svg
    icons/fontawesome/svgs/solid/angle-right.svg
    icons/fontawesome/svgs/solid/arrow-rotate-left.svg
    icons/fontawesome/svgs/solid/arrow-rotate-right.svg
    icons/ionicons/arrow-redo-circle-outline.svg
    icons/ionicons/move.svg
    icons/ionicons/arrow-up.svg
    icons/ionicons/pulse.svg
    icons/fontawesome/svgs/solid/file-arrow-up.svg
    icons/fontawesome/svgs/solid/folder-plus.svg
    icons/ionicons/bag-add-outline.svg
    icons/ionicons/information-circle-outline.svg
    icons/fontawesome/svgs/solid/pencil.svg
    icons/ionicons/close.svg
    icons/ionicons/close-circle.svg
    icons/ionicons/game-controller-outline.svg
    icons/ionicons/menu.svg
    icons/ionicons/ellipsis-vertical.svg
    icons/fontawesome/svgs/solid/folder-open.svg
    icons/fontawesome/svgs/solid/paste.svg
    icons/ionicons/checkmark-circle-outline.svg
    icons/ionicons/download-outline.svg
    icons/ionicons/share-social-outline.svg
    icons/ionicons/share-social.svg
    icons/ionicons/desktop-outline.svg
    icons/ionicons/logo-microsoft.svg
    icons/ionicons/lock-closed-outline.svg
    icons/fontawesome/svgs/solid/tablet-button.svg
    icons/ionicons/chevron-forward.svg
    icons/ionicons/person-circle.svg
    icons/ionicons/musical-notes.svg
    icons/fontawesome/svgs/solid/display.svg
    icons/fontawesome/svgs/solid/note-sticky.svg
    icons/fontawesome/svgs/solid/film.svg
    icons/fontawesome/svgs/solid/key.svg
    icons/fontawesome/svgs/solid/lock.svg
    icons/ionicons/scan.svg
)

# target_link_options(appZhome PRIVATE
#    "-Wl,--exclude-libs,libssl.so"
#    "-Wl,--exclude-libs,libcrypto.so"
# )

# Configure qtquickcontrols2.conf
# qt_add_resources(appZhome "configuration"
#     PREFIX "/"
#     FILES
#         qtquickcontrols2.conf
# )
