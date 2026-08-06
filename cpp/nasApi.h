#ifndef NASAPI_H
#define NASAPI_H

#include <QQmlEngine>
#include <QString>
#include <QJsonArray>
#include <QList>
#include "localSettings.h"

class NasApi : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public slots:
    QString configureNewDevice(QString strAdminPass, QString strDeviceName, QString strEmail, QString strUserPass);
    bool configureNewDeviceSuccess(QString strRet);
    QString getUserList(QString strAdminPass);
    QString getAdminCmd(QString strAdminPass, QString strKey, QString strVal, QString strKey2 = "", QString strVal2 = "", QString strKey3 = "", QString strVal3 = "");
    QString deleteUser(QString strAdminPass, QString strUser);
    QString allowUser(QString strAdminPass, QString strUser);
    QString rejectUser(QString strAdminPass, QString strUser);
    QString getHddStatus(QString strAdminPass);
    QString initHdd(QString strAdminPass);
    QString repairHdd(QString strAdminPass);
    QString replaceHardDisk(QString strAdminPass, QString step);
    bool parseReplaceHardDiskOk(QString strRet);
    QString parseReplaceHardDiskStatus(QString strRet);
    QString parseReplaceHardDiskProgress(QString strRet);
    QString parseReplaceHardDiskErrorCode(QString strRet);
    QString parseReplaceHardDiskErrorMessage(QString strRet);
    QString parseReplaceHardDiskUsbSize(QString strRet);
    QString parseReplaceHardDiskHddUsedSize(QString strRet);
    QString changeDeviceName(QString strAdminPass, QString strDeviceName);
    bool parseSaveDeviceNameResult(QString strRet);
    QString changeAdminPass(QString strAdminPass, QString strNewPass);
    bool parseChangeAdminPassSuccess(QString strRet);
    bool parseChangeAdminPassFail(QString strRet);
    QString adminLogin(QString strAdminPass);
    bool adminLoginSuccess(QString strRet);
    QString parseHddStatusFromResult(QString strRet);
    QString parseHddFormatingProgressFromResult(QString strRet);
    int parseUserNumFromResult(QString strRet);
    QString getAdminDeviceStatus(QString strAdminPass);
    // user cmd
    QString getUserCmd(QMap<QString, QString> map, QString strKeyListString = "", QStringList listString = QStringList());
    QString userLogin();
    QString userLoginResult(QString strRet);
    bool userLoginSuccess(QString strRet);
    bool userLoginFail(QString strRet);
    bool userLoginNeedAllow(QString strRet);
    QString userGetStatus();
    QString parseGetStatusResult(QString strRet);
    QString userGetDbFileDir();
    QString parseDbFileDir(QString strRet);
    /** NAS: rescan user directory on disk and merge missing rows into file.db (default subdir MyFiles). */
    QString repairUserDatabase(QString subDir = QStringLiteral("MyFiles"));
    bool repairUserDatabaseSuccess(QString strRet);
    /** Index one uploaded file into NAS file.db. [relMyFilesPath] must be MyFiles/... */
    QString addOneFile(QString relMyFilesPath);
    bool addOneFileSuccess(QString strRet);
    /** Probe whether a path exists on NAS. [ftpOrAppPath] normalized to /Ftp/user/MyFiles/... */
    QString checkFileExists(QString ftpOrAppPath);
    /** True when check_file_exists == success and file_exists is truthy. */
    bool checkFileExistsOkAndTrue(QString strRet);
    /** Strip to MyFiles/... (aligned with QML Logic.normalizeMyFilesPath / Android). */
    QString normalizeMyFilesPath(QString path);
    /** Normalize path for check_file_exists to /Ftp/<user>/MyFiles/... */
    QString normalizeProbeFtpPath(QString remotePath);
    /**
     * Pick a playable path for quality (0=original, 1=HD, 2=SD).
     * Probes check_file_exists for transcodes; falls back to original if missing.
     */
    QString resolvePlayableVideoPath(QString remoteVideoPath, int quality);
    QString setFtp(QString strFtpEnabled, QString strFtpPass);
    QString setSmb(QString strSmbEnabled, QString strSmbPass);
    QString userDbFileName();
    QString userDbFileUrl();
    QString dbFileDownloadAddress();
    QString uploadAddress();
    QUrl getPlayerUrl(QString strVideoPath);
    /** 0=原文件, 1=同目录下 .<basename>/.hd.mp4, 2=.sd.mp4（与 NAS video_cvt 一致）；非 MyFiles/Video 下路径返回原路径。 */
    QString videoRemotePathForQuality(QString remoteVideoPath, int quality);
    QString subPathUnderMyFiles(const QString &strPath);
    QString getRemoteFilePath(QString strVideoPath);
    QString removeFiles(QStringList astrFiles);
    bool removeFilesSuccess(QString strRet);
    QString deleteFiles(QStringList strFiles);
    bool deleteFilesSuccess(QString strRet);
    QString recoverFiles(QStringList astrFiles);
    bool recoverFilesSuccess(QString strRet);
    QString jstrSetFileDate(QString remotePath, qint64 fileDate);
    QString createNewFolder(QString sub_dir, QString new_dir_name);
    bool createNewFolderSuccess(QString strRet);
    QString getStringVarByKey(const QString &strJson, const QString &strKey);
    // QString getRemotePathFromResult(const QString &strRet);
    QString fileRename(QString strFrom, QString strTo);
    bool fileRenameSuccess(QString strRet);
    QString moveFiles(QStringList astrFiles, QString strDestSubDir);
    bool moveFilesSuccess(QString strRet);
    QString userChangePasswd(QString newPasswd);
    bool userChangePasswdSuccess(QString strRet);
    QString userForgetPasswd();
    bool userForgetPasswdSuccess(QString strRet);
    QString userResetPasswd(QString confirmCode, QString newPasswd);
    bool userResetPasswdSuccess(QString strRet);
    QString shareUser();
    QString sharePwd();
    void sharePwd(QString strPwd);
    QString shareDbFileDownloadPath();
    QString shareDbFileUrl();
    bool getIsShared();
    void setIsShared(bool newIsShared);
    QString shareDbFileName();
    QString shareFiles(QStringList astrFiles);
    bool shareFilesSuccess(QString strRet);
    QString deleteShared(QStringList astrFiles);
    QString cmdUser();
    QString cmdPass();
    QString fileUser(const QString &strRemoteUrl = "");
    QString filePasswd(const QString &strRemoteUrl = "");
    bool cancelShareFilesSuccess(QString strRet);
    QString addBt(QString btUrl);
    bool addBtSuccess(QString strRet);
    bool addBtFail(QString strRet);
    QString getBtStatus();
    bool getBtStatusInFile(QString strRet);
    QString delBt(QString btId);
    bool delBtSuccess(QString strRet);
    bool delBtFail(QString strRet);
    QString startBt(QString btId);
    bool startBtSuccess(QString strRet);
    bool startBtFail(QString strRet);
    QString stopBt(QString btId);
    bool stopBtSuccess(QString strRet);
    bool stopBtFail(QString strRet);
    QString uploadBtFile(QString btFile);
    QString getBtFiles();
    QString cmdUrlString();
    QString p2pRemotePathFromHttpsUrl(QString strPath);
public:
    const QString TAG_MYFILES = "/MyFiles";
    const QString TAG_IMAGE = TAG_MYFILES + "/Image";
    const QString TAG_VIDEO = TAG_MYFILES + "/Video";
    const QString TAG_AUDIO = TAG_MYFILES + "/Audio";
    const QString TAG_DOC = TAG_MYFILES + "/Doc";
    const QString TAG_SHARED_FILE_URL = "/~share@nas";
    const QString TAG_USER_FILE_URL = "/~" + LocalSettings::getUser();
    const QString TAG_DB_FILE = "download.cgi?file.db";
    const QString TAG_SHARED_DB_FILE = "../SHARED/shared.db";
    const QString TAG_BT_FILE = ".btFiles/";
    QString m_sharePwd;
    bool m_isShared;
    void addIotAddr(QJsonObject &jsonObject);
    bool isP2pCmd(QString strPkg);
    bool isP2pNewCmd(QString &strPkg);
    QString p2pSrcSdp(QString &strPkg);
    QString p2pDstSdp(QString &strPkg);
    QString p2pNew(QString localSdk, QString remoteSdp);
    QString p2pTerminate(QString localSdp, QString remoteSdp);
    QString p2pCmd(QString strCmd, QString localSdp, QString remoteSdp, QString strNegoStarted);
    bool isP2pTerminateCmd(QString &strPkg);
    bool isNegoStarted(QString &strPkg);
    QString fileStatusFromP2pCmd(QString strCmd);
    QString fileNameFromP2pCmd(QString strCmd);
    QString fileSizeFromP2pCmd(QString strCmd);
    QString fileOffsetFromP2pCmd(QString strCmd);
    QString fileChTypeFromP2pCmd(QString strCmd);
    QString fileRemoteNameFromP2pCmd(QString strCmd);
    QString addKeyValToJsonObj(const QString &strJson, const QString &strKey, const QString &strVal);
    QString cmdServiceIdFromJsonStr(const QString &strJson);
};

#endif // NASAPI_H
