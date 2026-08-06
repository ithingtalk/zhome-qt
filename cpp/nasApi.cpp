#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QEventLoop>
#include <QTimer>
#include <himsgcenter.h>
#include "localSettings.h"
#include "nasApi.h"
#include "globalCpp.h"
#include "cmdService.h"
#include "libp2p_export.h"

QString NasApi::configureNewDevice(QString strAdminPass, QString strDeviceName, QString strEmail, QString strUserPass)
{
    QJsonObject jsonObject;
    jsonObject[CMD_KEY_USER_ROLE] = CMD_KEY_ADMIN_USER;
    jsonObject[CMD_KEY_CONFIG_DEVICE] = "now";
    jsonObject[CMD_KEY_ADMIN_PWD] = strAdminPass;
    jsonObject[CMD_KEY_DEVICE_NAME] = strDeviceName;
    jsonObject[CMD_KEY_USER_ID] = g_app->awsAccount.getUserId();
    jsonObject[CMD_KEY_USER_PASSWD] = strUserPass;
    jsonObject[CMD_KEY_USER_EMAIL] = strEmail;
    addIotAddr(jsonObject);
    QJsonDocument jsonDoc(jsonObject);
    QString strMsg = jsonDoc.toJson(QJsonDocument::Compact);
    qDebug() << "configure new device: " << strMsg;
    return strMsg;
}

bool NasApi::configureNewDeviceSuccess(QString strRet)
{
    return strRet.contains(CMD_KEY_CONFIG_DEVICE) && ( strRet.contains(RES_OK) || strRet.contains(RES_USER_EXISTS) );
}

// {"role":"admin","admin_pwd":"aA123456","get_user_list":"now"}
QString NasApi::getAdminCmd(QString strAdminPass, QString strKey, QString strVal, QString strKey2, QString strVal2, QString strKey3, QString strVal3)
{
    QJsonObject jsonObject;
    jsonObject[CMD_KEY_USER_ROLE] = CMD_KEY_ADMIN_USER;
    jsonObject[CMD_KEY_ADMIN_PWD] = strAdminPass;
    jsonObject[strKey] = strVal;
    if (strKey2 != "") {
        jsonObject[strKey2] = strVal2;
    }
    if (strKey3 != "") {
        jsonObject[strKey3] = strVal3;
    }
    addIotAddr(jsonObject);
    QJsonDocument jsonDoc(jsonObject);
    return jsonDoc.toJson(QJsonDocument::Compact);
}

QString NasApi::getUserList(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_GET_USER_LIST, "now");
}

QString NasApi::deleteUser(QString strAdminPass, QString strUser)
{
    return getAdminCmd(strAdminPass, CMD_KEY_DELETE_USER, strUser);
}

QString NasApi::allowUser(QString strAdminPass, QString strUser)
{
    return getAdminCmd(strAdminPass, CMD_KEY_ALLOW_USER, strUser);
}

QString NasApi::rejectUser(QString strAdminPass, QString strUser)
{
    return getAdminCmd(strAdminPass, CMD_KEY_REJECT_USER, strUser);
}

QString NasApi::getHddStatus(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_GET_HDD_STATUS, "now");
}

QString NasApi::initHdd(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_INIT_DISK, "now");
}

QString NasApi::repairHdd(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_REPAIR_DISK, "now");
}

QString NasApi::replaceHardDisk(QString strAdminPass, QString step)
{
    return getAdminCmd(strAdminPass, CMD_KEY_REPLACE_HARD_DISK, "now", CMD_KEY_STEP, step);
}

static QString jsonStringField(const QString &strRet, const char *key)
{
    QJsonDocument doc = QJsonDocument::fromJson(strRet.toUtf8());
    if (!doc.isObject())
        return QString();
    QJsonValue v = doc.object().value(QLatin1String(key));
    return v.isString() ? v.toString() : QString();
}

bool NasApi::parseReplaceHardDiskOk(QString strRet)
{
    QString cmd = jsonStringField(strRet, CMD_KEY_REPLACE_HARD_DISK);
    return cmd.isEmpty() || cmd.compare(QLatin1String(RES_OK), Qt::CaseInsensitive) == 0;
}

QString NasApi::parseReplaceHardDiskStatus(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_STATUS);
}

QString NasApi::parseReplaceHardDiskProgress(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_PROGRESS);
}

QString NasApi::parseReplaceHardDiskErrorCode(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_ERROR_CODE);
}

QString NasApi::parseReplaceHardDiskErrorMessage(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_ERR_MESSAGE);
}

QString NasApi::parseReplaceHardDiskUsbSize(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_USB_SIZE);
}

QString NasApi::parseReplaceHardDiskHddUsedSize(QString strRet)
{
    return jsonStringField(strRet, CMD_KEY_HDD_USED_SIZE);
}

QString NasApi::changeDeviceName(QString strAdminPass, QString strDeviceName)
{
    return getAdminCmd(strAdminPass, CMD_SAVE_DEVICE_NAME, strDeviceName);
}

bool NasApi::parseSaveDeviceNameResult(QString strRet)
{
    return strRet.contains(CMD_SAVE_DEVICE_NAME) && strRet.contains(RES_OK);
}

QString NasApi::changeAdminPass(QString strAdminPass, QString strNewPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_CHANGE_ADMIN_PWD, "now", CMD_KEY_NEW_PWD, strNewPass);
}

bool NasApi::parseChangeAdminPassSuccess(QString strRet)
{
    return strRet.contains(CMD_KEY_CHANGE_ADMIN_PWD) && strRet.contains(RES_OK);
}

bool NasApi::parseChangeAdminPassFail(QString strRet)
{
    return strRet.contains(CMD_KEY_CHANGE_ADMIN_PWD) && strRet.contains(RES_FAIL);
}

QString NasApi::adminLogin(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_ADMIN_LOGIN, "now");
}

bool NasApi::adminLoginSuccess(QString strRet)
{
    return strRet.contains(CMD_KEY_ADMIN_LOGIN) && strRet.contains(RES_OK);
}

QString NasApi::parseHddStatusFromResult(QString strRet)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(CMD_KEY_GET_HDD_STATUS)) {
            return jsonObject[CMD_KEY_GET_HDD_STATUS].toString();
        }
    }
    return "";
}

QString NasApi::parseHddFormatingProgressFromResult(QString strRet)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(CMD_KEY_GET_HDD_FORMAT_PROGRESS)) {
            return jsonObject[CMD_KEY_GET_HDD_FORMAT_PROGRESS].toString();
        }
    }
    return "";
}

int NasApi::parseUserNumFromResult(QString strRet)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(CMD_PAR_USER_NUMBER)) {
            return jsonObject[CMD_PAR_USER_NUMBER].toInt();
        }
    }
    return -1;
}

QString NasApi::getAdminDeviceStatus(QString strAdminPass)
{
    return getAdminCmd(strAdminPass, CMD_KEY_GET_ADMIN_DEVICE_STATUS, "now");
}

// Remote upgrade tools:
// CMD_KEY_CHECK_RFW:"now", check new fw
// CMD_KEY_REMOTE_UPGRADE:"now", start upgrade
// CMD_KEY_GET_RFWPROGRESS:"now", get progress
// tools to use new hdd replace old:
// usb: CMD_KEY_GET_NEW_DISK_STATE
// usb: CMD_KEY_COPY_HARD_DISK_CONTENT: replace old hdd with new

// user cmd

QString NasApi::getUserCmd(QMap<QString, QString> map, QString strKeyListString, QStringList listString)
{
    QJsonObject jsonObject;
    jsonObject[CMD_KEY_USER_ROLE] = "user";
    jsonObject[CMD_KEY_USER_ID] = LocalSettings::getUser();
    jsonObject[CMD_KEY_USER_PASSWD] = LocalSettings::getPass();
    jsonObject[CMD_KEY_USER_EMAIL] = LocalSettings::getUser();

    QMapIterator<QString, QString> it(map);
    while (it.hasNext()) {
        it.next();
        // qDebug() << "nasApi.cpp, add key val: " << it.key() << "=>" << it.value();
        jsonObject[it.key()] = it.value();
    }

    if (strKeyListString != "") {
        QJsonArray jsonArray;
        for (int iLoop=0; iLoop<listString.length(); iLoop++) {
            jsonArray.append(listString[iLoop]);
        }
        jsonObject[strKeyListString] = jsonArray;
    }

    addIotAddr(jsonObject);

    QJsonDocument jsonDoc(jsonObject);
    return jsonDoc.toJson(QJsonDocument::Compact);
}

QString NasApi::userLogin()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_USER_LOGIN, "now");
    return getUserCmd(map);
}

QString NasApi::userLoginResult(QString strRet) // RES_FAIL: error, RES_OK: success, none: new user, need administrator's permition
{
    return getStringVarByKey(strRet, CMD_KEY_USER_LOGIN);
}

bool NasApi::userLoginSuccess(QString strRet)
{
    return userLoginResult(strRet) == RES_OK;
}

bool NasApi::userLoginFail(QString strRet)
{
    return userLoginResult(strRet) == RES_FAIL;
}

bool NasApi::userLoginNeedAllow(QString strRet)
{
    return userLoginResult(strRet) == "none";
}

QString NasApi::userGetStatus()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_GET_STATUS, "now");
    return getUserCmd(map);
}

QString NasApi::parseGetStatusResult(QString strRet)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(CMD_KEY_HDD_STATUS)) {
            return jsonObject[CMD_KEY_HDD_STATUS].toString();
        }
    }
    return "";
}

QString NasApi::userGetDbFileDir()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_GET_USER_DB_DIR, "now");
    return getUserCmd(map);
}

QString NasApi::parseDbFileDir(QString strRet)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(CMD_KEY_RET_USER_DB_DIR)) {
            return jsonObject[CMD_KEY_RET_USER_DB_DIR].toString();
        }
    }
    return "";
}

QString NasApi::repairUserDatabase(QString subDir)
{
    QMap<QString, QString> map;
    map.insert(CMD_REPAIR_USER_DATABASE, subDir.isEmpty() ? QStringLiteral("MyFiles") : subDir);
    return getUserCmd(map);
}

bool NasApi::repairUserDatabaseSuccess(QString strRet)
{
    return strRet.contains(CMD_REPAIR_USER_DATABASE) && strRet.contains(RES_OK);
}

QString NasApi::normalizeMyFilesPath(QString path)
{
    QString p = path.trimmed();
    const int myFilesIndex = p.indexOf(QStringLiteral("MyFiles"));
    if (myFilesIndex >= 0)
        return p.mid(myFilesIndex);
    while (p.startsWith(QLatin1Char('/')))
        p = p.mid(1);
    return p;
}

QString NasApi::normalizeProbeFtpPath(QString remotePath)
{
    QString trimmed = remotePath.trimmed();
    if (trimmed.isEmpty())
        return QString();
    if (trimmed.startsWith(QLatin1String("/Ftp/")))
        return trimmed;
    if (trimmed.startsWith(QLatin1String("Ftp/")))
        return QLatin1Char('/') + trimmed;

    const QString user = LocalSettings::getUser();
    if (trimmed.startsWith(QLatin1String("/MyFiles/")))
        return QStringLiteral("/Ftp/%1%2").arg(user, trimmed);
    if (trimmed.startsWith(QLatin1String("MyFiles/")))
        return QStringLiteral("/Ftp/%1/%2").arg(user, trimmed);

    const int myFilesIdx = trimmed.indexOf(QLatin1String("MyFiles/"));
    if (myFilesIdx >= 0)
        return QStringLiteral("/Ftp/%1/%2").arg(user, trimmed.mid(myFilesIdx));
    return QString();
}

QString NasApi::addOneFile(QString relMyFilesPath)
{
    QMap<QString, QString> map;
    map.insert(CMD_ADD_ONE_FILE, normalizeMyFilesPath(relMyFilesPath));
    return getUserCmd(map);
}

bool NasApi::addOneFileSuccess(QString strRet)
{
    const QString v = getStringVarByKey(strRet, CMD_ADD_ONE_FILE);
    if (!v.isEmpty())
        return v.compare(QLatin1String(RES_OK), Qt::CaseInsensitive) == 0;
    return strRet.contains(QLatin1String(CMD_ADD_ONE_FILE)) && strRet.contains(QLatin1String(RES_OK));
}

QString NasApi::checkFileExists(QString ftpOrAppPath)
{
    QMap<QString, QString> map;
    const QString probe = normalizeProbeFtpPath(ftpOrAppPath);
    map.insert(CMD_KEY_CHECK_FILE_EXISTS, probe.isEmpty() ? ftpOrAppPath.trimmed() : probe);
    return getUserCmd(map);
}

bool NasApi::checkFileExistsOkAndTrue(QString strRet)
{
    const QJsonDocument jsonDoc = QJsonDocument::fromJson(strRet.toUtf8());
    if (!jsonDoc.isObject())
        return false;
    const QJsonObject obj = jsonDoc.object();
    const QString cmdResult = obj.value(QLatin1String(CMD_KEY_CHECK_FILE_EXISTS)).toString();
    if (cmdResult.compare(QLatin1String(RES_OK), Qt::CaseInsensitive) != 0)
        return false;
    const QJsonValue v = obj.value(QLatin1String(CMD_KEY_FILE_EXISTS));
    if (v.isBool())
        return v.toBool();
    if (v.isDouble())
        return v.toInt() != 0;
    if (v.isString()) {
        const QString s = v.toString().trimmed().toLower();
        return s == QLatin1String("1") || s == QLatin1String("true") || s == QLatin1String("yes")
            || s == QLatin1String("success") || s == QLatin1String("ok");
    }
    return false;
}

QString NasApi::resolvePlayableVideoPath(QString remoteVideoPath, int quality)
{
    if (quality <= 0)
        return remoteVideoPath;
    const QString candidate = videoRemotePathForQuality(remoteVideoPath, quality);
    if (candidate == remoteVideoPath)
        return remoteVideoPath;

    const QString probePath = normalizeProbeFtpPath(candidate);
    if (probePath.isEmpty()) {
        qDebug() << "resolvePlayableVideoPath: invalid probe path for" << candidate;
        return remoteVideoPath;
    }

    CmdService probe;
    probe.conn(g_app->awsIot);

    QString response;
    bool got = false;
    QEventLoop loop;
    QObject::connect(&probe, &CmdService::dataReceived, &loop, [&](const QString &, const QString &data) {
        response = data;
        got = true;
        loop.quit();
    });
    QObject::connect(&probe, &CmdService::errorOccurred, &loop, [&](const QString &, int) {
        loop.quit();
    });
    QTimer::singleShot(8000, &loop, &QEventLoop::quit);
    probe.send(checkFileExists(probePath));
    loop.exec();

    const bool exists = got && checkFileExistsOkAndTrue(response);
    qDebug() << "resolvePlayableVideoPath: probe" << probePath << "exists=" << exists;
    return exists ? candidate : remoteVideoPath;
}

QString NasApi::setFtp(QString strFtpEnabled, QString strFtpPass)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_FTP_ENABLED, strFtpEnabled);
    map.insert(CMD_KEY_FTP_PASSWD, strFtpPass);
    return getUserCmd(map);
}

QString NasApi::setSmb(QString strSmbEnabled, QString strSmbPass)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_SAMBA_ENABLED, strSmbEnabled);
    map.insert(CMD_KEY_SAMBA_PASSWD, strSmbPass);
    return getUserCmd(map);
}

QString NasApi::userDbFileName()
{
    return "file.db";
}

QString NasApi::userDbFileUrl()
{
    return dbFileDownloadAddress() + userDbFileName();
}

QString NasApi::shareDbFileName()
{
    return "shared.db";
}

QString NasApi::shareDbFileDownloadPath()
{
    return "../SHARED/" + shareDbFileName();
}

QString NasApi::shareDbFileUrl()
{
    return dbFileDownloadAddress() + shareDbFileDownloadPath();
}

bool NasApi::getIsShared()
{
    return m_isShared;
}

void NasApi::setIsShared(bool newIsShared)
{
    m_isShared = newIsShared;
}

QString NasApi::dbFileDownloadAddress()
{
    return "http://" + g_app->dbDevices.curr.ip + "/file/download.cgi?";
}

QString NasApi::uploadAddress()
{
    return "http://" + g_app->dbDevices.curr.ip + "/file/upload.cgi?";
}

// skip "/MyFiles/", got path "Video/xxx", "Image/xxx", "Audio/xxx", "Doc/xxx"
QString NasApi::subPathUnderMyFiles(const QString &strPath)
{
    return strPath.mid(strPath.indexOf(TAG_MYFILES) + TAG_MYFILES.length());
}

QString NasApi::getRemoteFilePath(QString strPath)
{
    QString strRet = "";
    qDebug() << "getRemoteFile Path: " << strPath;

    if (m_isShared) {
        strRet = "http://" + g_app->dbDevices.curr.ip + "/~share@nas" + strPath.mid(QString("/Ftp").length()); // skip "/Ftp", start from "/user/xxx"
    }
    else {
        strRet = "http://" + g_app->dbDevices.curr.ip + "/~" + LocalSettings::getUser() + subPathUnderMyFiles(strPath); // skip "MyFiles", start from "/type/xxx"
    }

    return strRet;
}

QString NasApi::p2pRemotePathFromHttpsUrl(QString strPath)
{
    // Already a libp2p relative path (Ftp/... or DB/...), or a logical /Ftp|/MyFiles path.
    if (!strPath.startsWith(QLatin1String("http"))) {
        const QString user = LocalSettings::getUser();
        QString trimmed = strPath.trimmed();
        if (trimmed.startsWith(QLatin1String("/Ftp/")) || trimmed.startsWith(QLatin1String("/DB/")))
            return trimmed.mid(1);
        if (trimmed.startsWith(QLatin1String("Ftp/")) || trimmed.startsWith(QLatin1String("DB/")))
            return trimmed;
        if (trimmed.startsWith(QLatin1String("/MyFiles/")))
            return QStringLiteral("Ftp/") + user + trimmed;
        if (trimmed.startsWith(QLatin1String("MyFiles/")))
            return QStringLiteral("Ftp/") + user + QLatin1Char('/') + trimmed;
        const int myFilesIdx = trimmed.indexOf(QLatin1String("/MyFiles/"));
        if (myFilesIdx >= 0)
            return QStringLiteral("Ftp/") + user + trimmed.mid(myFilesIdx);
        const int myFilesIdx2 = trimmed.indexOf(QLatin1String("MyFiles/"));
        if (myFilesIdx2 >= 0)
            return QStringLiteral("Ftp/") + user + QLatin1Char('/') + trimmed.mid(myFilesIdx2);
        qDebug() << "not a local-link url: " << strPath;
        return strPath;
    }

    // Shared: http://ip/~share@nas/user/MyFiles/... → Ftp/user/MyFiles/...
    if (strPath.contains(TAG_SHARED_FILE_URL)) {
        QString rest = strPath.mid(strPath.indexOf(TAG_SHARED_FILE_URL) + TAG_SHARED_FILE_URL.length());
        while (rest.startsWith(QLatin1Char('/')))
            rest = rest.mid(1);
        return rest.isEmpty() ? QString() : (QStringLiteral("Ftp/") + rest);
    }

    if (strPath.contains(TAG_BT_FILE)) { // bt
        return strPath.mid(strPath.lastIndexOf(TAG_BT_FILE));
    }

    if (strPath.endsWith(TAG_DB_FILE)) {
        // NAS home is HDD mount root (/mnt/sdaX); file.db lives at DB/<user>/file.db
        // (aligned with Android NasUrl.p2pUserDbPath / osxApp).
        return QStringLiteral("DB/") + LocalSettings::getUser() + QStringLiteral("/file.db");
    }

    if (strPath.endsWith(TAG_SHARED_DB_FILE)) {
        return QStringLiteral("DB/SHARED/shared.db");
    }

    // User file: http://ip/~user/Video/... → Ftp/user/MyFiles/Video/...
    // (aligned with Android NasUrl / osxApp; NAS P2P expects paths under Ftp/<user>/...)
    if (strPath.contains(TAG_USER_FILE_URL)) {
        const QString rest = strPath.mid(strPath.indexOf(TAG_USER_FILE_URL) + TAG_USER_FILE_URL.length());
        return QStringLiteral("Ftp/") + LocalSettings::getUser() + QStringLiteral("/MyFiles") + rest;
    }

    qDebug() << "unknown url cannot convert to p2p remote path: " << strPath;
    return "";
}

QString NasApi::videoRemotePathForQuality(QString remoteVideoPath, int quality)
{
    if (quality == 0)
        return remoteVideoPath;
    static const QString kVideoDir = QStringLiteral("/MyFiles/Video/");
    if (!remoteVideoPath.contains(kVideoDir))
        return remoteVideoPath;
    const int lastSlash = remoteVideoPath.lastIndexOf(QLatin1Char('/'));
    if (lastSlash < 0)
        return remoteVideoPath;
    const QString dirPath = remoteVideoPath.left(lastSlash);
    QString fileName = remoteVideoPath.mid(lastSlash + 1);
    if (fileName.startsWith(QLatin1Char('.')))
        return remoteVideoPath;
    const int dot = fileName.lastIndexOf(QLatin1Char('.'));
    const QString base = (dot > 0) ? fileName.left(dot) : fileName;
    if (base.isEmpty())
        return remoteVideoPath;
    const QString subDir = dirPath + QStringLiteral("/.") + base;
    if (quality == 1)
        return subDir + QStringLiteral("/.hd.mp4");
    if (quality == 2)
        return subDir + QStringLiteral("/.sd.mp4");
    return remoteVideoPath;
}

QUrl NasApi::getPlayerUrl(QString strVideoPath)
{
    QString strRemotePath = getRemoteFilePath(strVideoPath);

    if (!g_app->useLocalLink()) { // p2p
        strRemotePath = QString("http://") + P2P_HTTP_IP + ":" + P2P_HTTP_PORT + "/" + p2pRemotePathFromHttpsUrl(strRemotePath);
    }

    QUrl vUrl(strRemotePath);
    qDebug() << vUrl.path() << ", username: " << fileUser() << ", password: " << filePasswd();
    vUrl.setUserName(fileUser());
    vUrl.setPassword(filePasswd());
    return vUrl;
}

// remove files to recycle-bin
QString NasApi::removeFiles(QStringList astrFiles)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_REMOVE_FILES, "now");
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

bool NasApi::removeFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_REMOVE_FILES) == RES_OK;
}

QString NasApi::deleteFiles(QStringList astrFiles)
{

    QMap<QString, QString> map;
    map.insert(CMD_KEY_DOUBLE_DELETE_FILES, "now");
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

bool NasApi::deleteFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_DOUBLE_DELETE_FILES) == RES_OK;
}

QString NasApi::recoverFiles(QStringList astrFiles)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_RECOVER_FILES, "now");
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

bool NasApi::recoverFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_RECOVER_FILES) == RES_OK;
}

QString NasApi::jstrSetFileDate(QString remotePath, qint64 fileDate)
{
    QMap<QString, QString> map;
    map.insert(CMD_SET_FILE_TIME, QString::number(fileDate));
    map.insert(CMD_SET_FILE_PATH, remotePath);
    return getUserCmd(map);
}

// mkdir: CMD_KEY_MAKE_DIR: now, CMD_CURRENT_DIRECTORY: MyFiles/xxx/..., CMD_KET_SUBDIR: xxx
// mkdir result: CMD_KEY_MAKE_DIR: RES_OK / RES_FAIL

QString NasApi::createNewFolder(QString sub_dir, QString new_dir_name)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_MAKE_DIR, "now");
    map.insert(CMD_CURRENT_DIRECTORY, sub_dir);
    map.insert(CMD_KET_SUBDIR, new_dir_name);
    return getUserCmd(map);
}

bool NasApi::createNewFolderSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_MAKE_DIR) == RES_OK;
}

QString NasApi::getStringVarByKey(const QString &strJson, const QString &strKey)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strJson.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        if (jsonObject.contains(strKey)) {
            return jsonObject[strKey].toString();
        }
    }
    return "";
}

QString NasApi::addKeyValToJsonObj(const QString &strJson, const QString &strKey, const QString &strVal)
{
    QJsonDocument jsonDoc = QJsonDocument::fromJson(strJson.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObject = jsonDoc.object();
        jsonObject[strKey] = strVal;
        QJsonDocument jsonDoc2(jsonObject);
        QString strMsg = jsonDoc2.toJson(QJsonDocument::Compact);
        // qDebug() << "after add cmdService_id: " << strMsg;
        return strMsg;
    }
    return "";
}

/*
QString NasApi::getRemotePathFromResult(const QString &strRet)
{
    QString sub_dir = getStringVarByKey(strRet, CMD_CURRENT_DIRECTORY);
    QString new_dir_name = getStringVarByKey(strRet, CMD_KET_SUBDIR);
    return "Ftp/" + LocalSettings::getUser() + "/" + sub_dir + "/" + new_dir_name;
}
*/

// file rename: CMD_KEY_FILE_RENAME: "now", "from": "old_name", "to": "new_name"
QString NasApi::fileRename(QString strFrom, QString strTo)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_FILE_RENAME, "now");
    map.insert("from", strFrom);
    map.insert("to", strTo);
    return getUserCmd(map);
}

bool NasApi::fileRenameSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_FILE_RENAME) == RES_OK;
}

QString NasApi::moveFiles(QStringList astrFiles, QString strDestSubDir)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_MOVE_FILES, "now");
    map.insert("dest_sub_dir", strDestSubDir);
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

bool NasApi::moveFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_MOVE_FILES) == RES_OK;
}

// change password: CMD_KEY_CHANGE_PASSWD: "new password"
QString NasApi::userChangePasswd(QString newPasswd)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_CHANGE_PASSWD, newPasswd);
    return getUserCmd(map);
}

bool NasApi::userChangePasswdSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_CHANGE_PASSWD) == RES_OK;
}

// forget password: CMD_KEY_LOGIN_FORGET_PWD: "now"
QString NasApi::userForgetPasswd()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_LOGIN_FORGET_PWD, "now");
    return getUserCmd(map);
}

bool NasApi::userForgetPasswdSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_LOGIN_FORGET_PWD) == RES_OK;
}

// reset password: CMD_KEY_LOGIN_RESET_PWD: "", CMD_KEY_NEW_PWD: "new passwd", CMD_KEY_RANDOM_CODE: "confirm code"
QString NasApi::userResetPasswd(QString newPasswd, QString confirmCode)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_LOGIN_RESET_PWD, "");
    map.insert(CMD_KEY_NEW_PWD, newPasswd);
    map.insert(CMD_KEY_RANDOM_CODE, confirmCode);
    return getUserCmd(map);
}

bool NasApi::userResetPasswdSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_LOGIN_RESET_PWD) == RES_OK;
}

void NasApi::sharePwd(QString strPwd)
{
    m_sharePwd = strPwd;
}

QString NasApi::sharePwd()
{
    return m_sharePwd;
}

QString NasApi::shareUser()
{
    return "share@nas";
}

QString NasApi::cmdUser()
{
    return LocalSettings::getUser();
}

QString NasApi::cmdPass()
{
    return LocalSettings::getPass();
}

QString NasApi::fileUser(const QString &strRemoteUrl)
{
    if (strRemoteUrl.startsWith(dbFileDownloadAddress()) || !m_isShared) {
        return LocalSettings::getUser();
    }
    else {
        return shareUser();
    }
}

QString NasApi::filePasswd(const QString &strRemoteUrl)
{
    if (strRemoteUrl.startsWith(dbFileDownloadAddress()) || !m_isShared) {
        return LocalSettings::getPass();
    }
    else {
        return m_sharePwd;
    }
}

// CMD_KEY_ADD_SHARE: "now", CMD_KEY_USER_DIR: "user_name/MyFiles/xxx", CMD_KEY_FILE_LIST: "filename_array"
QString NasApi::shareFiles(QStringList astrFiles)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_ADD_SHARE, "now");
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

// CMD_KEY_DELETE_SHARE
QString NasApi::deleteShared(QStringList astrFiles)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_DELETE_SHARE, "now");
    return getUserCmd(map, CMD_KEY_FILE_LIST, astrFiles);
}

bool NasApi::shareFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, MSG_KEY_SHARE_RESULT) == RES_OK;
}

// MSG_KEY_CANCEL_SHARE_RESULT
bool NasApi::cancelShareFilesSuccess(QString strRet)
{
    return getStringVarByKey(strRet, MSG_KEY_CANCEL_SHARE_RESULT) == RES_OK;
}

// CMD_KEY_ADD_TORRENT: bt_url
QString NasApi::addBt(QString btUrl)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_ADD_TORRENT, btUrl);
    return getUserCmd(map);
}

bool NasApi::addBtSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_ADD_TORRENT) == RES_OK;
}

bool NasApi::addBtFail(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_ADD_TORRENT) == RES_FAIL;
}

// CMD_KEY_GET_DOWNLOAD_STATUS: "", CMD_KEY_USER_DIR: ""
QString NasApi::getBtStatus()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_GET_DOWNLOAD_STATUS, "");
    map.insert(CMD_KEY_USER_DIR, ""); // nas api
    return getUserCmd(map);
}

bool NasApi::getBtStatusInFile(QString strRet)
{
    return getStringVarByKey(strRet, MSG_KEY_TYPE) == MSG_KEY_TYPE_FILE; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

// CMD_KEY_DEL_TORRENT: bt_id
QString NasApi::delBt(QString btId)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_DEL_TORRENT, btId);
    return getUserCmd(map);
}

bool NasApi::delBtSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_DEL_TORRENT) == RES_OK; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

bool NasApi::delBtFail(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_DEL_TORRENT) == RES_FAIL; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

// CMD_KEY_START_DOWNLOAD: bt_id
QString NasApi::startBt(QString btId)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_START_DOWNLOAD, btId);
    return getUserCmd(map);
}

bool NasApi::startBtSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_START_DOWNLOAD) == RES_OK; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

bool NasApi::startBtFail(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_START_DOWNLOAD) == RES_FAIL; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

// CMD_KEY_STOP_DOWNLOAD: bt_id
QString NasApi::stopBt(QString btId)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_STOP_DOWNLOAD, btId);
    return getUserCmd(map);
}

bool NasApi::stopBtSuccess(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_STOP_DOWNLOAD) == RES_OK; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

bool NasApi::stopBtFail(QString strRet)
{
    return getStringVarByKey(strRet, CMD_KEY_STOP_DOWNLOAD) == RES_FAIL; // && getStringVarByKey(strRet, CMD_KEY_USER_ID) == LocalSettings::getUser();
}

// CMD_KEY_ADD_TORRENT_FILE: bt_file, CMD_KEY_USER_DIR: "MyFiles/.btFiles"
QString NasApi::uploadBtFile(QString btFile)
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_ADD_TORRENT_FILE, btFile);
    map.insert(CMD_KEY_USER_DIR, "MyFiles/.btFiles");
    return getUserCmd(map);
}

// CMD_KEY_GET_DOWNLOAD_FILE: "", CMD_KET_SUBDIR: ""
QString NasApi::getBtFiles()
{
    QMap<QString, QString> map;
    map.insert(CMD_KEY_GET_DOWNLOAD_FILE, "");
    map.insert(CMD_KET_SUBDIR, "");
    return getUserCmd(map);
}

QString NasApi::cmdUrlString()
{
    return QString("http://%1/cmd/cgi-bin/cmd.cgi").arg(g_app->dbDevices.curr.ip);
}

void NasApi::addIotAddr(QJsonObject &jsonObject)
{
    jsonObject[IOT_APP_CLIENT_ID] = g_app->awsIot.getIotClientId();
    // moved to libp2p.a
}

// p2p status recv from p2p module
//==============================================================
QString NasApi::fileStatusFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_STATUS);
}

QString NasApi::fileNameFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_NAME);
}

QString NasApi::fileRemoteNameFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_REMOTE_NAME);
}

QString NasApi::fileSizeFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_SIZE);
}

QString NasApi::fileOffsetFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_OFFSET);
}

QString NasApi::fileChTypeFromP2pCmd(QString strCmd)
{
    return getStringVarByKey(strCmd, P2P_CMD_FILE_CH_TYPE);
}
//==============================================================
