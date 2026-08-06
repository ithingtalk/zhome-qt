pragma Singleton
import QtQuick
import "../global.js" as Logic
import Zhome

QtObject {
    property var dbFilesPrivateCpp: dbFilesFromCpp
    property var dbFilesSharedCpp: dbFilesSharedFromCpp
    property var previewDocCpp: previewDocFromCpp
    property var previewImageCpp: previewImageFromCpp
    property var btFileServiceCpp: btFileServiceFromCpp
    property var idStack: Global.idStack
    property var nasApiCpp: Global.nasApiCpp
    property var localAccountCpp: Global.localAccountCpp
    readonly property bool isMobile: Global.isMobile
    property var utilsCpp: Global.utilsCpp
    // tree items array ========================================
    readonly property string cdt_MYDOCUMENTS: "cdtMyDocuments"
    readonly property string cdt_SHARE: "cdtShare"
    readonly property string cdt_TRASH: "cdtTrash"
    readonly property string cdt_DOWNLOAD_TASK: "cdtDownloadTask"
    readonly property string cdt_DOWNLOAD_CONTENT: "cdtDownloadContent"
    readonly property string cdt_PC_BACKUP: "cdtPcBackup"
    readonly property string cdt_UTILS: "cdtUtils"
    readonly property string cdt_EXTERNAL_STORAGE: "cdtExternalStorage"
    readonly property string cdt_SMALL_GAME: "cdtSmallGame"
    readonly property var items: [
        { name: cdt_MYDOCUMENTS,        display: qsTr("My Documents"),          path: "/MyFiles",           icon: "../icons/ionicons/folder.svg",                          comp: "FileContent.qml" },
        { name: cdt_SHARE,              display: qsTr("Share Documents"),       path: "/MyFiles",           icon: "../icons/fontawesome/svgs/solid/share-nodes.svg",       comp: "FileContent.qml" },
        { name: cdt_DOWNLOAD_TASK,      display: qsTr("Download Task"),         path: "/DownloadTask",      icon: "../icons/fontawesome/svgs/solid/file-arrow-down.svg",   comp: "DownloadTask.qml" },
        { name: cdt_DOWNLOAD_CONTENT,   display: qsTr("Download Content"),      path: "/DownloadContent",   icon: "../icons/ionicons/archive.svg",                         comp: "DownloadContent.qml" },
        // { name: cdt_PC_BACKUP,        display: qsTr("PC Backup"),             path: "/PcBackup",          icon: "../icons/fontawesome/svgs/solid/window-restore.svg",    comp: "OtherPage.qml" },
        // { name: cdt_UTILS,            display: qsTr("Utils"),                 path: "/Utils",             icon: "../icons/fontawesome/svgs/solid/toolbox.svg",           comp: "OtherPage.qml" },
        // { name: cdt_EXTERNAL_STORAGE, display: qsTr("External Storage"),      path: "/ExternalStorage",   icon: "../icons/fontawesome/svgs/solid/floppy-disk.svg",       comp: "OtherPage.qml" },
        // { name: cdt_SMALL_GAME,       display: qsTr("Small Game"),            path: "/SmallGame",         icon: "../icons/ionicons/game-controller-outline.svg",         comp: "../SameGameModule/Main.qml" },
        { name: cdt_TRASH,              display: qsTr("Trash"),                 path: "/MyFiles",           icon: "../icons/fontawesome/svgs/solid/recycle.svg",           comp: "FileContent.qml" }
    ]
    // file type array ==========================================
    readonly property string type_PICTURE: "typePicture"
    readonly property string type_VIDEO: "typeVideo"
    readonly property string type_AUDIO: "typeAudio"
    readonly property string type_DOCUMENT: "typeDocument"
    readonly property var documents_subdir: [
        { name: type_PICTURE,            display: qsTr("Picture"),              path: "Image",             icon: "../icons/ionicons/folder.svg", fileicon: "../icons/fontawesome/svgs/solid/image.svg" },
        { name: type_VIDEO,              display: qsTr("Video"),                path: "Video",             icon: "../icons/ionicons/folder.svg", fileicon: "../icons/ionicons/film.svg" },
        { name: type_AUDIO,              display: qsTr("Audio"),                path: "Audio",             icon: "../icons/ionicons/folder.svg", fileicon: "../icons/fontawesome/svgs/solid/music.svg" },
        { name: type_DOCUMENT,           display: qsTr("Other Documents"),      path: "Doc",               icon: "../icons/ionicons/folder.svg", fileicon: "../icons/fontawesome/svgs/solid/note-sticky.svg" }
    ]
    readonly property string imagePath: "/MyFiles/Image"
    readonly property string videoPath: "/MyFiles/Video"
    readonly property string audioPath: "/MyFiles/Audio"
    readonly property string otherPath: "/MyFiles/Doc"
    // ===========================================================
    property var pp_recyclebin_display: items[2].display
    // for pathview
    property int pp_selectedIndex: 0
    property string pp_subdirString: ""
    property string pathSeparator: "/"
    property string displaySeparator: " > "
    property var pp_subdirItems: pp_subdirString.split(pathSeparator).filter(function(item) { return item !== "" })
    property string transferPath: pp_subdirItems.join(pathSeparator)
    property bool selectedMyFiles: pp_selectedIndex === idxMyFiles()
    property bool selectedTrash: pp_selectedIndex === idxTrash()
    property bool selectedShared: pp_selectedIndex === idxShared()
    property bool selectedOfflineDownload: pp_selectedIndex === idxDownloadTask()
    property bool selectedOfflineDownloaded: pp_selectedIndex === idxDownloadContent()
    property bool selectedPcBackup: pp_selectedIndex === idxPcBackup()
    property bool selectedUtils: pp_selectedIndex === idxUtils()
    property bool selectedExternalStorage: pp_selectedIndex === idxExternalStorage()
    property bool selectedSmallGame: pp_selectedIndex === idxSmallGame()
    // file type
    property bool selectedDocImage: (selectedMyFiles || selectedShared) && (pp_subdirItems[0] === documents_subdir[idxTypePicture()].path)
    property bool selectedDocVideo: (selectedMyFiles || selectedShared) && (pp_subdirItems[0] === documents_subdir[idxTypeVideo()].path)
    property bool selectedDocAudio: (selectedMyFiles || selectedShared) && (pp_subdirItems[0] === documents_subdir[idxTypeAudio()].path)
    property bool selectedDocDoc: (selectedMyFiles || selectedShared) && (pp_subdirItems[0] === documents_subdir[idxTypeDocument()].path)
    // other property
    property bool isUserDirOrFile: (selectedMyFiles || selectedShared) && (pp_subdirItems.length > 0)
    property bool pp_hasFileList: fileList.length > 0
    property var fileList: []
    property int fileSelectedIndex: 0
    property var fileListPreview: []
    readonly property string cdtUpload: "cdtUpload"
    readonly property string cdtUploadDir: "cdtUploadDir"
    readonly property string cdtOpen: "cdtOpen"
    readonly property string cdtRename: "cdtRename"
    readonly property string cdtDelete: "cdtDelete"
    readonly property string cdtMove: "cdtMove"
    readonly property string cdtDownload: "cdtDowload"
    readonly property string cdtShare: "cdtShare"
    property var allFilesCount: undefined
    property var allFilesNormalCount: undefined
    property var allFilesInTrashCount: undefined
    property bool movingMode: selectedMyFiles && (moveFilePathFrom !== "")
    property string moveFilePathFrom: ""
    property var movingFiles: []
    property bool editMode: false
    /** Bumped on selection changes so recycled ListView/GridView delegates re-read checked state. */
    property int selectionRevision: 0
    property bool selectedFilesHasDir: false
    property bool normalMode: !movingMode && !editMode
    property bool shareTypeOthers: true
    property int selectedFileCount: 0
    property string getFilesFilter: ""
    property bool searchMode: getFilesFilter != ""
    // ===========================================================
    property string fileTitle: ""

    // tree type index
    function idxMyFiles() { return items.findIndex(item => item.name === cdt_MYDOCUMENTS) }
    function idxShared() { return items.findIndex(item => item.name === cdt_SHARE) }
    function idxTrash() { return items.findIndex(item => item.name === cdt_TRASH) }
    function idxDownloadTask() { return items.findIndex(item => item.name === cdt_DOWNLOAD_TASK) }
    function idxDownloadContent() { return items.findIndex(item => item.name === cdt_DOWNLOAD_CONTENT) }
    function idxPcBackup() { return items.findIndex(item => item.name === cdt_PC_BACKUP) }
    function idxUtils() { return items.findIndex(item => item.name === cdt_UTILS) }
    function idxExternalStorage() { return items.findIndex(item => item.name === cdt_EXTERNAL_STORAGE) }
    function idxSmallGame() { return items.findIndex(item => item.name === cdt_SMALL_GAME) }

    // file type index
    function idxTypePicture() { return documents_subdir.findIndex(item => item.name === type_PICTURE) }
    function idxTypeVideo() { return documents_subdir.findIndex(item => item.name === type_VIDEO) }
    function idxTypeAudio() { return documents_subdir.findIndex(item => item.name === type_AUDIO) }
    function idxTypeDocument() { return documents_subdir.findIndex(item => item.name === type_DOCUMENT) }

    function topTreeModel() {
        var modelItems = []
        for (var i = 0; i < items.length; i++) {
            modelItems.push( {iconSrc: items[i].icon, itemText: Logic.getFileName(items[i].display), actionStr: i} )
        }
        return modelItems
    }

    /** 主页横向功能入口：不含「我的文档」（下方单独列表），其余项按显示名排序。 */
    function mainPageToolsModel() {
        var modelItems = []
        var skip = idxMyFiles()
        for (var i = 0; i < items.length; i++) {
            if (i === skip)
                continue
            modelItems.push( {iconSrc: items[i].icon, itemText: Logic.getFileName(items[i].display), actionStr: i} )
        }
        modelItems.sort(function (a, b) {
            return a.itemText.localeCompare(b.itemText, undefined, { sensitivity: "base" })
        })
        return modelItems
    }

    function documentsSubdirModel()
    {
        var subDirs = []
        for (var idx = 0; idx < 4; idx++) {
            var item = {}
            item["filepath"] = items[pp_selectedIndex].path + "/" + documents_subdir[idx].path
            item["filesize"] = allFilesCount[idx + 1]
            item["filedate"] = 0
            item["isdir"] = true
            item["filedisplay"] = documents_subdir[idx].display
            item["selected"] = false
            subDirs.push(item)
        }
        subDirs.sort(function (a, b) {
            return a.filedisplay.localeCompare(b.filedisplay, undefined, { sensitivity: "base" })
        })
        return subDirs
    }

    // convert second field of path to display name
    function getDisplayName(pathVal) {
        for (var idx = 0; idx < documents_subdir.length; idx++) {
            if (documents_subdir[idx].path === pathVal) {
                return documents_subdir[idx].display
            }
        }
        return pathVal // should not arrived here
    }

    function getDefaultFileIcon(pathStr) {
        if (fileIsImage(pathStr)) {
            return documents_subdir[idxTypePicture()].fileicon
        }
        else if (fileIsVideo(pathStr)) {
            return documents_subdir[idxTypeVideo()].fileicon
        }
        else if (fileIsAudio(pathStr)) {
            return documents_subdir[idxTypeAudio()].fileicon
        }
        else { // if (fileIsDoc(pathStr)) {
            return documents_subdir[idxTypeDocument()].fileicon
        }
    }

    function fileIsImage(pathStr) {
        return pathStr.includes(imagePath);
    }

    function fileIsVideo(pathStr) {
        return pathStr.includes(videoPath);
    }

    function fileIsAudio(pathStr) {
        return pathStr.includes(audioPath);
    }

    function fileIsDoc(pathStr) {
        return pathStr.includes(otherPath);
    }

    function audioFiles() {
        var files = []
        if (selectedDocAudio && !selectedTrash) {
            for (var idx = 0; idx < fileList.length; idx++) {
                if (!fileList[idx].isdir && (editMode ? fileList[idx].selected : true)) {
                    files.push(fileList[idx])
                }
            }
        }
        return files
    }

    function getSelectedFileType() {
        if (selectedDocImage) { return idxTypePicture() }
        else if (selectedDocVideo) { return idxTypeVideo() }
        else if (selectedDocAudio) { return idxTypeAudio() }
        else { return 99 }
    }

    function popSubdir() {
        if (pp_subdirItems.length > 0) {
            pp_subdirItems.pop()
            pp_subdirString = pp_subdirItems.join(pathSeparator)
            if (!pp_subdirString.startsWith("/") && pp_subdirString != "") {
                var tmp = pp_subdirString
                pp_subdirString = "/" + tmp
            }
            sendChangeSignal()
        }
        exitEditMode()
    }

    function pushSubdir(dir) {
        var subdirString = pp_subdirString + "/" + dir
        treeItemChanged(pp_selectedIndex, subdirString)
    }

    function goToSubDirectory(index) {
        if (index >= 0 && index < pp_subdirItems.length) {
            var subdirString = "/" + pp_subdirItems.slice(0, index + 1).join(pathSeparator)
            treeItemChanged(pp_selectedIndex, subdirString)
        }
        else {
            exitEditMode()
        }
    }

    /** 从「我的文档 / 共享文档」文件列表进入回收站根目录 */
    function openRecycleBin() {
        treeItemChanged(idxTrash(), "")
    }

    function treeItemChanged(idx, subDir = "") {
        const wasShared = selectedShared
        pp_subdirString = subDir
        if ((idx >= 0) && (idx < items.length)) {
            pp_selectedIndex = idx
        }
        nasApiCpp.setIsShared(selectedShared)
        // Auto refresh shared db once when entering shared page.
        if (!wasShared && selectedShared) {
            dbFilesSharedCpp.updateDbFile(true)
        }
        sendChangeSignal()
        exitEditMode()
        updateFileTitle()
    }

    function updateFileTitle() {
        if (selectedMyFiles && selectedDocImage) {
            fileTitle = qsTr("My Image")
        }
        else if (selectedMyFiles && selectedDocVideo) {
            fileTitle = qsTr("My Video")
        }
        else if (selectedMyFiles && selectedDocAudio) {
            fileTitle = qsTr("My Audio")
        }
        else if (selectedMyFiles && selectedDocDoc) {
            fileTitle = qsTr("My Other Doc")
        }
        else if (selectedShared && selectedDocImage) {
            fileTitle = qsTr("Share Image")
        }
        else if (selectedShared && selectedDocVideo) {
            fileTitle = qsTr("Share Video")
        }
        else if (selectedShared && selectedDocAudio) {
            fileTitle = qsTr("Share Audio")
        }
        else if (selectedShared && selectedDocDoc) {
            fileTitle = qsTr("Share Other Doc")
        }
        else if (selectedMyFiles) {
            fileTitle = qsTr("My Documents")
        }
        else if (selectedShared) {
            fileTitle = qsTr("Share Documents")
        }
        else if (selectedOfflineDownload) {
            fileTitle = qsTr("Download Task")
        }
        else if (selectedOfflineDownloaded) {
            fileTitle = qsTr("Download Content")
        }
        else if (selectedTrash) {
            fileTitle = qsTr("Trash")
        }
    }

    function gotoFileType(subPath) {
        var subdirString = "/" + subPath
        treeItemChanged(pp_selectedIndex, subdirString)
    }

    function gotoImage() { gotoFileType(documents_subdir[0].path) }
    function gotoVideo() { gotoFileType(documents_subdir[1].path) }
    function gotoAudio() { gotoFileType(documents_subdir[2].path) }
    function gotoOther() { gotoFileType(documents_subdir[3].path) }
    function gotoInitPage() {
        if (!isUserDirOrFile) {
            // gotoOther()
        }
    }

    function currentFileDir() {
        return items[pp_selectedIndex].path + pp_subdirString;
    }

    function currentFileDirWithoutFirstChar() {
        var strPath = currentFileDir()
        const myFilesIndex = strPath.indexOf('MyFiles')
        return strPath.substring(myFilesIndex)
    }

    function getFiles() {
        var dbFilesCpp = selectedShared ? dbFilesSharedCpp : dbFilesPrivateCpp
        var fileList222 = dbFilesCpp.getFiles(currentFileDir(), getFilesFilter, selectedTrash, shareTypeOthers)
        if (fileList.length > 0 && fileList222.length > 0) {
            for (var idx = 0; idx < fileList.length; idx++) {
                if (fileList[idx].selected) {
                    var filePath = fileList[idx].filepath
                    for (var j = 0; j < fileList222.length; j++) {
                        if (fileList222[j].filepath === filePath) {
                            fileList222[j].selected = true
                            break
                        }
                    }
                }
            }
        }
        fileList = fileList222
        selectionRevision++
        return fileList;
    }

    function sendChangeSignal() {
        var dbFilesCpp = selectedShared ? dbFilesSharedCpp : dbFilesPrivateCpp
        dbFilesCpp.sendChangeSignal()
    }

    function getPlayPage(isAudioFile = true) {
        if (isMobile && isAudioFile) {
            return "../PlayAudioPage.qml";
        }
        return "../PlayPage.qml";
    }

    function playOneFile(fileName) {
        var urls = []
        urls.push(fileName)
        idStack.push(getPlayPage( isSelectedAudio(fileName) ), { gVideoUrls: urls } )
    }

    /*function playAudioFiles(files) {
        var urls = []
        for (var i = 0; i < files.length; i++) {
            if (!files[i].isdir) {
                urls.push(files[i].filepath)
            }
        }
        idStack.push(getPlayPage(), { gVideoUrls: urls } )
    }*/

    function isSelectedVideo(filename = "") {
        if (searchMode) {
            return fileIsVideo(filename)
        }
        else {
            return selectedDocVideo
        }
    }

    function isSelectedAudio(filename = "") {
        if (searchMode) {
            return fileIsAudio(filename)
        }
        else {
            return selectedDocAudio
        }
    }

    function isSelectedImageFile(filename = "") {
        if (searchMode) {
            return fileIsImage(filename)
        }
        else {
            return selectedDocImage
        }
    }

    function openFile(fileName) {
    	console.log("open file: " + fileName)
        if (isSelectedVideo(fileName) || isSelectedAudio(fileName)) {
            playOneFile(fileName)
        }
        else if (isSelectedImageFile(fileName)) {
            if (searchMode) {
                fileListPreview = []
                var idx = fileList.findIndex(item => item.filepath === fileName)
                fileListPreview.push(fileList[idx])
                fileSelectedIndex = 0
            }
            else {
                fileListPreview = fileList
            }
            idStack.push("../PreviewImages.qml")
        }
        else {
            console.log("open other type file: " + fileName)
            var fileUrl = nasApiCpp.getRemoteFilePath(fileList[fileSelectedIndex].filepath)
            var localPath = utilsCpp.addLocalFilePrefix(previewDocCpp.cacheDir() + "/" + Logic.getFileName(fileList[fileSelectedIndex].filepath))
            previewDocCpp.download(fileUrl, localPath)
        }
    }

    function saveMovingFiles() {
        movingFiles = getSelectedFilesPath()
    }

    function exitMovingMode() {
        moveFilePathFrom = ""
    }

    function enableEditMode(enabled) {
        editMode = enabled
        if (!enabled) {
            selectAll(false)
        } else {
            selectionRevision++
        }
    }

    function selectAll(selected) {
        for (var idx = 0; idx < fileList.length; idx++) {
            fileList[idx].selected = selected
        }
        updateSelectedFilesHasDir()
        selectionRevision++
        printSelectedFiles()
    }

    function isFileSelected(filepath) {
        // Depend on selectionRevision so bindings refresh after recycle/scroll.
        var _rev = selectionRevision
        for (var idx = 0; idx < fileList.length; idx++) {
            if (fileList[idx].filepath === filepath)
                return !!fileList[idx].selected
        }
        return false
    }

    function selectFile(filepath) {
        const file = fileList.find(file => file.filepath === filepath);
        if (file) {
            file.selected = !file.selected;
            updateSelectedFilesHasDir()
            selectionRevision++
            printSelectedFiles()
            return file.selected
        }
        else {
            console.log("error: should not arrived here !!!")
            return false
        }
    }

    function updateSelectedFilesHasDir() {
        for (var idx = 0; idx < fileList.length; idx++) {
            if (fileList[idx].isdir && fileList[idx].selected) {
                selectedFilesHasDir = true
                return
            }
        }
        selectedFilesHasDir = false
    }

    function getSelectedFilesPath() {
        var strFiles = []
        for (var idx = 0; idx < fileList.length; idx++) {
            if (fileList[idx].selected) {
                strFiles.push(fileList[idx].filepath)
            }
        }
        selectedFileCount = strFiles.length
        return strFiles
    }

    function getSharedSelectedFilesPath() {
        var strFiles = []
        for (var idx = 0; idx < fileList.length; idx++) {
            if (fileList[idx].selected) {
                var pathNow = Logic.normalizeUserMyFilesPath(fileList[idx].filepath)
                strFiles.push(pathNow)
            }
        }
        return strFiles
    }

    function printSelectedFiles() {
        var strFileList = ""
        var fileList = getSelectedFilesPath()
        for (var idx = 0; idx < fileList.length; idx++) {
            strFileList += "\n" + fileList[idx]
        }
        strFileList += "\n" + "count: " + fileList.length
        console.log(strFileList)
        return strFileList
    }

    function selectedRemotePath() {
        var fileList = getSelectedFilesPath()
        if (fileList.length === 1) {
            return fileList[0]
        }
        return ""
    }

    function printRecycleBinFiles() {
        var strFileList = ""
        var fileList = getFiles()
        for (var idx = 0; idx < fileList.length; idx++) {
            strFileList += "\n" + fileList[idx].filepath
        }
        strFileList += "\n" + "count: " + fileList.length
        console.log(strFileList)
        return strFileList
    }

    function exitEditMode() {
        if (editMode) {
            var dbFilesCpp = selectedShared ? dbFilesSharedCpp : dbFilesPrivateCpp
            dbFilesCpp.setSelectAll(true)
            dbFilesCpp.setSelectAll(false)
            enableEditMode(false)
        }
    }

    function getAllFilesPath() {
        var filesPath = []
        var files = getFiles()
        for (var idx=0; idx<files.length; idx++) {
            filesPath.push(files[idx].filepath)
        }
        return filesPath;
    }

    function dbFilescppSendCmd(strCmd) {
        var dbFilesCpp = selectedShared ? dbFilesSharedCpp : dbFilesPrivateCpp
        dbFilesCpp.sendCmd(strCmd)
    }

    function fileExists(filePath, fileSize) {
        return Number(fileSize) === utilsCpp.fileSize(getLocalFilePath(filePath))
    }

    function getLocalFilePath(filePath) {
        return utilsCpp.addLocalFilePrefix(Zpath.previewImageCpp.cacheDir() + "/" + Logic.getFileName(filePath))
    }

    function hasImageCache(filePath, fileSize) {
        return fileIsImage(filePath) && fileExists(filePath, fileSize)
    }

    function getThumbnail(filePath, fileSize) {
        console.log("getThumbnail: " + filePath)
        if (hasImageCache(filePath, fileSize)) {
            return getLocalFilePath(filePath);
        }
        else {
            return getDefaultFileIcon(filePath)
        }
    }

    function hasAudioFile() {
        return Zpath.audioFiles().length > 0
    }

    function playAudioFiles() {
        var files = Zpath.audioFiles()
        Zpath.exitEditMode()
        if (files.length > 0) {
            var urls = []
            for (var i = 0; i < files.length; i++) {
                if (!files[i].isdir) {
                    urls.push(files[i].filepath)
                }
            }
            idStack.push(getPlayPage(), { gVideoUrls: urls } )
        }
    }
}
