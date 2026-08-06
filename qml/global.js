// admin cmd
function sendCmdGetUserList(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.getUserList(adminPass), "admin", adminPass)
}

var USER_ADMIN_MUTATION_TRANSFER_TIMEOUT_MS = 5000

function sendCmdDeleteUser(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.deleteUser(adminPass, Global.currUser.name), "admin", adminPass, USER_ADMIN_MUTATION_TRANSFER_TIMEOUT_MS)
}

function sendCmdAllowUser(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.allowUser(adminPass, Global.currUser.name), "admin", adminPass, USER_ADMIN_MUTATION_TRANSFER_TIMEOUT_MS)
}

function sendCmdRejectUser(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.rejectUser(adminPass, Global.currUser.name), "admin", adminPass, USER_ADMIN_MUTATION_TRANSFER_TIMEOUT_MS)
}

function sendCmdChangeDeviceName(httpsConn, adminPass, newName) {
    httpsConn.send(Global.nasApiCpp.changeDeviceName(adminPass, newName), "admin", adminPass)
}

function sendCmdChangeAdminPass(httpsConn, adminPass, newPass) {
    httpsConn.send(Global.nasApiCpp.changeAdminPass(adminPass, newPass), "admin", adminPass)
}

function sendCmdLogin(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.adminLogin(adminPass), "admin", adminPass)
}

function sendCmdGetAdminDeviceStatus(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.getAdminDeviceStatus(adminPass), "admin", adminPass)
}

function sendCmdInitHdd(httpsConn, adminPass) {
    httpsConn.send(Global.nasApiCpp.initHdd(adminPass), "admin", adminPass)
}

function sendCmdReplaceHardDisk(httpsConn, adminPass, step) {
    httpsConn.send(Global.nasApiCpp.replaceHardDisk(adminPass, step), "admin", adminPass)
}

function getDeviceUsersListModel(strJson)
{
    var model = []
    try {
        var jsonObject = JSON.parse(strJson)
        var userList = jsonObject.user_list
        for (var i = 0; i < userList.length; i++) {
            var userObject = userList[i]
            var email = Object.keys(userObject)[0]
            var status = userObject[email]
            var user_storage = userObject.user_storage
            var user_nickname = userObject.user_nickname
            model.push({
                username: email,
                userstatus: status,
                filesize: user_storage,
                nickname: user_nickname
            })
            //console.log("new user: " + email + ", " + status + ", " + user_storage + ", " + user_nickname)
        }
    } catch (e) {
        console.error("JSON parse error: ", e)
    }
    model.sort(function (a, b) {
        var na = (a.nickname || a.username || "").toString()
        var nb = (b.nickname || b.username || "").toString()
        return na.localeCompare(nb, undefined, { sensitivity: "base" })
    })
    return model
}
// admin cmd end

// user cmd
function sendCmdUserLogin(httpsConn) {
    httpsConn.send(Global.nasApiCpp.userLogin())
}

function sendCmdGetUserStatus(httpsConn) {
    httpsConn.send(Global.nasApiCpp.userGetStatus())
}

function sendCmdGetDbFileDir(httpsConn) {
    httpsConn.send(Global.nasApiCpp.userGetDbFileDir())
}

function sendCmdSetFtp(httpsConn, strFtpEnabled, strFtpPass) {
    httpsConn.send(Global.nasApiCpp.setFtp(strFtpEnabled, strFtpPass))
}

function sendCmdSetSmb(httpsConn, strSmbEnabled, strSmbPass) {
    httpsConn.send(Global.nasApiCpp.setSmb(strSmbEnabled, strSmbPass))
}

function sendCmdAddBt(strBtUrl) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.addBt(strBtUrl))
}

function sendCmdGetBtStatus() {
    Global.cmdServiceCpp.send(Global.nasApiCpp.getBtStatus())
}

function sendCmdDelBt(btId) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.delBt(btId))
}

function sendCmdStartBt(btId) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.startBt(btId))
}

function sendCmdStopBt(btId) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.stopBt(btId))
}

function sendCmdUploadBtFile(btFile) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.uploadBtFile(btFile))
}

function sendCmdGetBtFiles() {
    Global.cmdServiceCpp.send(Global.nasApiCpp.getBtFiles())
}

function sendCmdBtMoveToMyFiles(old_name, new_name) {
    Global.cmdServiceCpp.send(Global.nasApiCpp.fileRename(old_name, new_name))
}

function sendCmdBtDeleteFile(astrFiles) {
    if (astrFiles.length > 0) {
        Global.cmdServiceCpp.send(Global.nasApiCpp.deleteFiles(astrFiles))
    }
}

// file operations
function renameFile(strFileName, strNewFile) {
    console.log("rename file to " + strNewFile + " from " + strFileName)
}

function removeFiles(astrFiles) { // move file to recycle-bin
    if (astrFiles.length > 0) {
        Zpath.dbFilescppSendCmd(Global.nasApiCpp.removeFiles(astrFiles.map(path => normalizeMyFilesPath(path))))
    }
}

function shareFiles(astrFiles) {
    if (astrFiles.length > 0) {
        Zpath.dbFilescppSendCmd(Global.nasApiCpp.shareFiles(astrFiles.map(path => normalizeUserMyFilesPath(path))))
    }
}

function deleteShared(astrFiles) {
    if (astrFiles.length > 0) {
        Zpath.dbFilescppSendCmd(Global.nasApiCpp.deleteShared(astrFiles.map(path => normalizeUserMyFilesPath(path))))
    }
}

function deleteFiles(astrFiles) { // delete file directly or from recycle-bin
    if (astrFiles.length > 0) {
        Zpath.dbFilescppSendCmd(Global.nasApiCpp.deleteFiles(astrFiles.map(path => normalizeMyFilesPath(path))))
    }
}

function recoverFiles(astrFiles) {
    if (astrFiles.length > 0) {
        Zpath.dbFilescppSendCmd(Global.nasApiCpp.recoverFiles(astrFiles.map(path => normalizeMyFilesPath(path))))
    }
}

function openFile(strFileName, bIsDir) {
    if (bIsDir) {
        if (!Zpath.selectedTrash || !Zpath.isUserDirOrFile) {
            Zpath.pushSubdir(getFileName(strFileName))
        }
    }
    else {
        if (Zpath.normalMode && (Zpath.selectedMyFiles || Zpath.selectedShared)) {
            Zpath.openFile(strFileName)
        }
    }
}

function moveFile(strFileName, strNewFile) {
    console.log("move file to " + strNewFile + " from " + strFileName)
}

function shareFile(strFileName) {
    console.log("share file ... " + strFileName)
}

function downloadFile(strRemoteFile) {
    Global.dbFileTransferCpp.add(1, Global.nasApiCpp.getRemoteFilePath(strRemoteFile))
}

function downloadFiles(files) {
    if (files.length > 0) {
        for (var idx = 0; idx < files.length; idx++) {
            downloadFile(files[idx])
        }
    }
}

function uploadFile(strRemoteFile, strLocalFile) {
    Global.dbFileTransferCpp.add(0, strRemoteFile, strLocalFile)
}

function uploadFiles(selectedFiles) {
    if (selectedFiles.length > 0) {
        for (var idx = 0; idx < selectedFiles.length; idx++) {
            var serverUrl = Global.nasApiCpp.getRemoteFilePath(Zpath.currentFileDir() + "/" + getFileName("" + selectedFiles[idx]))
            uploadFile(serverUrl, selectedFiles[idx])
        }
    }
}

function uploadBtFile(filePath) {
    var serverUrl = Global.nasApiCpp.getRemoteFilePath("/MyFiles/.btFiles/" + getFileName(filePath))
    Zpath.btFileServiceCpp.upload(serverUrl, filePath)
}

function downloadBtFile() {
    Zpath.btFileServiceCpp.download(Global.nasApiCpp.getRemoteFilePath("/MyFiles/.btFiles/nasmessage.txt"))
}

// from: "/MyFiles/Video/fg.mkv" to:"MyFiles/Video"
function pathStartWithMyFiles(pathStr) {
    try {
        const myFilesIndex = pathStr.indexOf('MyFiles')
        if (myFilesIndex === -1) return ""

        const lastSlashIndex = pathStr.lastIndexOf('/')
        return pathStr.substring(myFilesIndex, lastSlashIndex)
    }
    catch(e) {
        console.log("Error: " + e)
        return ""
    }
}

function lastPathStartWithMyFiles(pathStr) {
    try {
        const myFilesIndex = pathStr.indexOf('MyFiles')
        if (myFilesIndex === -1) return ""
        return pathStr.substring(myFilesIndex)
    }
    catch(e) {
        console.log("Error: " + e)
        return ""
    }
}

function getFileName(pathStr) {
    try {
        var lastSlashIndex = pathStr.lastIndexOf('/')
        return pathStr.substring(lastSlashIndex + 1)
    }
    catch(e) {
        console.log("Error: " + e)
        return ""
    }
}

function createNewFolder(sub_dir, new_dir_name) {
    Zpath.dbFilescppSendCmd(Global.nasApiCpp.createNewFolder(normalizeMyFilesPath(sub_dir), new_dir_name))
}

function fileRename(old_name, new_name) {
    Zpath.dbFilescppSendCmd(Global.nasApiCpp.fileRename(normalizeMyFilesPath(old_name), normalizeMyFilesPath(new_name)))
}

function moveFiles(astrFiles, dest_sub_dir) {
    Zpath.dbFilescppSendCmd(Global.nasApiCpp.moveFiles(astrFiles.map(path => normalizeMyFilesPath(path)), normalizeMyFilesPath(dest_sub_dir)))
}

function normalizeMyFilesPath(pathStr) {
    try {
        var path = ("" + pathStr).trim()
        const myFilesIndex = path.indexOf("MyFiles")
        if (myFilesIndex >= 0) {
            return path.substring(myFilesIndex)
        }
        while (path.startsWith("/")) {
            path = path.substring(1)
        }
        return path
    }
    catch(e) {
        console.log("Error: " + e)
        return ""
    }
}

function normalizeUserMyFilesPath(pathStr) {
    try {
        var path = ("" + pathStr).trim()
        const user = Zpath.localAccountCpp.getUser()
        const userPrefix = user + "/"
        const ftpTag = "Ftp/"
        const ftpIndex = path.indexOf(ftpTag)
        if (ftpIndex >= 0) {
            path = path.substring(ftpIndex + ftpTag.length)
        }
        while (path.startsWith("/")) {
            path = path.substring(1)
        }
        if (path.startsWith(userPrefix)) {
            const myFilesIndex = path.indexOf("MyFiles")
            return (myFilesIndex >= 0) ? (userPrefix + path.substring(myFilesIndex)) : path
        }
        return userPrefix + normalizeMyFilesPath(path)
    }
    catch(e) {
        console.log("Error: " + e)
        return ""
    }
}

function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max)
}

function fileIncludeInDirsList(file1, dirs) {
    for (var idx = 0; idx < dirs.length; idx++) {
        var dir1 = dirs[idx].filepath
        if (file1.startsWith(dir1)) {
            return true
        }
    }
    return false
}

function isRootPath(dirPath) {
    return (dirPath === Zpath.imagePath) || (dirPath === Zpath.videoPath) || (dirPath === Zpath.audioPath) || (dirPath === Zpath.otherPath)
}

function getFiles() {
    var all = Zpath.getFiles()
    if (!Zpath.selectedTrash) {
        return all
    }
    var dirs = []
    var files = []
    for (var idx = 0; idx < all.length; idx++) {
        var all1 = all[idx]
        if (!isRootPath(all1.filepath)) {
            if (all1.isdir) {
                dirs.push(all1)
            }
            else {
                files.push(all1)
            }
        }
    }
    // remove files if it's dir is exists
    var news = dirs
    for (idx = 0; idx < files.length; idx++) {
        var file1 = files[idx]
        if (!fileIncludeInDirsList(file1.filepath, dirs)) {
            news.push(file1)
        }
    }
    return news
}

function addZero(iNum)
{
    return iNum < 10 ? ("0" + iNum) : ("" + iNum)
}

function getHumanTime(iSeconds)
{
    var hours = Math.floor(iSeconds / 3600)
    var withoutHours = Math.floor(iSeconds % 3600)
    var minutes = Math.floor(withoutHours / 60)
    var seconds = Math.floor(withoutHours % 60)
    if (hours > 0) {
        return "" + hours + ":" + addZero(minutes) + ":" + addZero(seconds)
    }
    else if (minutes > 0) {
        return "" + minutes + ":" + addZero(seconds)
    }
    else {
        return "0:" + addZero(seconds)
    }
}

function formatDate(ts) {
    var date = new Date(ts * 1000) // s -> ms
    return Qt.formatDateTime(date, "yyyy-MM-dd HH:mm:ss") // 24 hours
    //return date.toString()
}
