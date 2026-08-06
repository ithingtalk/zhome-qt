#include <algorithm>
#include <QDateTime>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlQuery>
#include <QtSql/qsqlerror.h>
#include <himsgcenter.h>
#include "dbFiles.h"
#include "localSettings.h"
#include "nasApi.h"
#include "globalCpp.h"

namespace {

QString fileEntryDisplayName(const DbFilesData &d)
{
    const QStringList parts = d.remotePath.split(QLatin1Char('/'), Qt::SkipEmptyParts);
    return parts.isEmpty() ? d.remotePath : parts.constLast();
}

} // namespace

void DbFiles::initNormal()
{
    singleShotTimer = new QTimer(this);
    singleShotTimer->setInterval(500);
    singleShotTimer->setSingleShot(true);
    connect(singleShotTimer, &QTimer::timeout, this, &DbFiles::updateDatabase);
    connect(&m_fileService, &LocalFileService::downloadFinish, this, &DbFiles::dbFileDownloadFinished);

    m_uploadIndexTimer = new QTimer(this);
    m_uploadIndexTimer->setSingleShot(true);
    connect(m_uploadIndexTimer, &QTimer::timeout, this, &DbFiles::sendAddOneFileForHead);
}

DbFiles::DbFiles(NasApi &nasApi, bool isShared, QObject *parent) : QObject(parent), m_isShared(isShared), m_nasApi(nasApi), m_fileService(LocalFileService(nasApi))
{
    qDebug() << "dbFiles share";
    initNormal();
    qDebug() << "dbFiles share done";
}

DbFiles::DbFiles(NasApi &nasApi, LocalFileService &uploads, bool isShared, QObject *parent) : QObject(parent), m_isShared(isShared), m_nasApi(nasApi), m_fileService(LocalFileService(nasApi))
{
    qDebug() << "dbFiles";
    initNormal();
    connect(&uploads, &LocalFileService::uploadFinish, this, &DbFiles::uploadedListFileFinished);
    qDebug() << "dbFiles done";
}

void DbFiles::conn()
{
    qDebug() << "dbFiles conn";
    connect(&g_app->cmdServiceDbFiles, &CmdService::dataReceived, this, &DbFiles::cmdServiceDataFinished);
    connect(&g_app->cmdServiceDbFiles, &CmdService::errorOccurred, this, &DbFiles::cmdServiceError);
    connect(&g_app->dbDevices, &DbDevices::currDeviceChanged, this, &DbFiles::reset);
    qDebug() << "dbFiles conn done";
}

DbFiles::~DbFiles()
{
    qDebug() << "dbFiles destroy " << m_isShared;
    closedb();
    qDebug() << "dbFiles destroy done";
}

void DbFiles::uploadedListFileFinished(QString strRemotePath, qint64 iSize, qint64 iDate)
{
    qDebug() << "update db after uploaded: " << strRemotePath << ", " << iSize;
    PendingUploadIndex pending;
    pending.remotePath = strRemotePath;
    pending.myFilesRel = g_app->nasApi.normalizeMyFilesPath(strRemotePath);
    if (pending.myFilesRel.isEmpty())
        pending.myFilesRel = strRemotePath;
    pending.size = iSize;
    pending.date = iDate;
    pending.attemptsSent = 0;
    m_pendingUploadIndex.enqueue(pending);
    tryStartNextUploadIndex();
}

void DbFiles::tryStartNextUploadIndex()
{
    if (m_uploadIndexBusy || m_pendingUploadIndex.isEmpty())
        return;
    m_uploadIndexBusy = true;

    const PendingUploadIndex &head = m_pendingUploadIndex.head();
    if (head.size >= ADD_ONE_FILE_LARGE_BYTES && head.attemptsSent == 0) {
        qDebug() << "add_one_file: large file settle" << ADD_ONE_FILE_LARGE_SETTLE_MS << "ms for" << head.myFilesRel;
        m_uploadIndexTimer->start(ADD_ONE_FILE_LARGE_SETTLE_MS);
        return;
    }
    sendAddOneFileForHead();
}

void DbFiles::sendAddOneFileForHead()
{
    if (m_pendingUploadIndex.isEmpty()) {
        m_uploadIndexBusy = false;
        m_awaitingAddOneFile = false;
        return;
    }
    PendingUploadIndex &head = m_pendingUploadIndex.head();
    head.attemptsSent++;
    m_awaitingAddOneFile = true;
    qDebug() << "add_one_file attempt" << head.attemptsSent << "/" << ADD_ONE_FILE_MAX_ATTEMPTS
             << "nasRel=" << head.myFilesRel;
    sendCmd(g_app->nasApi.addOneFile(head.myFilesRel));
}

void DbFiles::finalizeUploadIndexHead(bool nasIndexedOk)
{
    if (m_pendingUploadIndex.isEmpty()) {
        m_uploadIndexBusy = false;
        m_awaitingAddOneFile = false;
        return;
    }
    const PendingUploadIndex head = m_pendingUploadIndex.dequeue();
    m_awaitingAddOneFile = false;
    m_uploadIndexBusy = false;

    if (!nasIndexedOk) {
        qWarning() << "add_one_file failed after" << head.attemptsSent << "attempts for" << head.myFilesRel
                    << "; writing local row anyway (use repair_user_database if list is incomplete)";
    } else {
        qDebug() << "add_one_file ok for" << head.myFilesRel;
    }

    add(head.remotePath, head.size, head.date);
    // post upload file: update file date to remote, do not check response now !!!
    sendCmd(g_app->nasApi.jstrSetFileDate(head.remotePath, head.date));

    tryStartNextUploadIndex();
}

void DbFiles::sendCmd(QString strCmd)
{
    g_app->cmdServiceDbFiles.send(strCmd);
}

void DbFiles::updateDatabase()
{
    updateDbFile(true);
}

void DbFiles::cmdServiceError(const QString errString, const int errCode)
{
    if (!m_awaitingAddOneFile || m_pendingUploadIndex.isEmpty())
        return;
    qWarning() << "add_one_file transport error:" << errString << errCode;
    m_awaitingAddOneFile = false;

    PendingUploadIndex &head = m_pendingUploadIndex.head();
    if (head.attemptsSent < ADD_ONE_FILE_MAX_ATTEMPTS) {
        const int attempt = head.attemptsSent; // already incremented on send
        const int shift = qMin(attempt - 1, 3);
        const int waitMs = ADD_ONE_FILE_RETRY_BASE_MS * (1 << shift);
        qWarning() << "add_one_file retry after transport error in" << waitMs << "ms";
        m_uploadIndexTimer->start(waitMs);
        return;
    }
    finalizeUploadIndexHead(false);
}

void DbFiles::cmdServiceDataFinished(QString strCmd, QString strResult)
{
    // Post-upload NAS index (may interleave with other dbFiles cmds; match by response keys).
    if (m_awaitingAddOneFile && !m_pendingUploadIndex.isEmpty()
        && (strResult.contains(QLatin1String(CMD_ADD_ONE_FILE)) || strCmd.contains(QLatin1String(CMD_ADD_ONE_FILE)))) {
        if (g_app->nasApi.addOneFileSuccess(strResult)) {
            finalizeUploadIndexHead(true);
            return;
        }
        m_awaitingAddOneFile = false;
        PendingUploadIndex &head = m_pendingUploadIndex.head();
        if (head.attemptsSent < ADD_ONE_FILE_MAX_ATTEMPTS) {
            const int attempt = head.attemptsSent;
            const int shift = qMin(attempt - 1, 3);
            const int waitMs = ADD_ONE_FILE_RETRY_BASE_MS * (1 << shift);
            qWarning() << "add_one_file retry" << (attempt + 1) << "/" << ADD_ONE_FILE_MAX_ATTEMPTS
                        << "after" << waitMs << "ms nasRel=" << head.myFilesRel << "last=" << strResult;
            m_uploadIndexTimer->start(waitMs);
            return;
        }
        finalizeUploadIndexHead(false);
        return;
    }

    const bool privateFileOp =
        g_app->nasApi.removeFilesSuccess(strResult)
        || g_app->nasApi.deleteFilesSuccess(strResult)
        || g_app->nasApi.recoverFilesSuccess(strResult)
        || g_app->nasApi.fileRenameSuccess(strResult)
        || g_app->nasApi.createNewFolderSuccess(strResult)
        || g_app->nasApi.moveFilesSuccess(strResult)
        || g_app->nasApi.repairUserDatabaseSuccess(strResult);

    const bool shareAddOk = g_app->nasApi.shareFilesSuccess(strResult);
    const bool shareCancelOk = g_app->nasApi.cancelShareFilesSuccess(strResult);

    // Private file ops: only the user file.db instance updates (avoid clobbering shared connection/UI).
    if (privateFileOp) {
        if (m_isShared)
            return;
        applyOptimisticLocalUpdate(strCmd, strResult);
        sendChangeSignal();
        singleShotTimer->start();
        return;
    }

    if (shareAddOk) {
        // Share mutates user file.db flags and shared.db; refresh this instance's mirror.
        applyOptimisticLocalUpdate(strCmd, strResult);
        sendChangeSignal();
        singleShotTimer->start();
        return;
    }

    if (shareCancelOk) {
        if (!m_isShared)
            return;
        applyOptimisticLocalUpdate(strCmd, strResult);
        sendChangeSignal();
        singleShotTimer->start();
    }
}

bool DbFiles::isDownloadUserDbFile(QString strLocalFile)
{
    return strLocalFile.startsWith(LocalSettings::configDir()) && strLocalFile.contains(g_app->nasApi.userDbFileName());
}

bool DbFiles::isDownloadShareDbFile(QString strLocalFile)
{
    return strLocalFile.startsWith(LocalSettings::configDir()) && strLocalFile.contains(g_app->nasApi.shareDbFileName());
}

void DbFiles::updateDbFile(bool force)
{
    if (g_app->dbDevices.curr.mac.isEmpty()) {
        qDebug() << "updateDbFile: no current device mac, ignore";
        return;
    }

    const QString dbFileName = m_isShared ? g_app->nasApi.shareDbFileName() : g_app->nasApi.userDbFileName();
    m_localDbFilePath = LocalSettings::configDir() + "/" + g_app->dbDevices.curr.mac + "/" + dbFileName;
    const QString dbTmpFile = localDbFileNew();

    if (!force) {
        if (QFile::exists(dbTmpFile)) {
            qDebug() << "updateDbFile: db temp file exists, skip duplicate request:" << dbTmpFile;
            return;
        }
        if (QFile::exists(m_localDbFilePath)) {
            qDebug() << "updateDbFile: local db exists, skip non-forced download";
            return;
        }
    }

    QString serverUrl;
    if (m_isShared) {
        serverUrl = g_app->nasApi.shareDbFileUrl();
    }
    else {
        serverUrl = g_app->nasApi.userDbFileUrl();
    }
    m_fileService.download(serverUrl, g_app->utils.addLocalFilePrefix(dbTmpFile));
}

void DbFiles::dbFileDownloadFinished(QString strFileName)
{
    Q_UNUSED(strFileName);
    const QString tmpPath = localDbFileNew();
    if (!QFile::exists(tmpPath))
        return;

    // P2P may report "success" when size/offset are both 0 after a reset; reject empty junk.
    const qint64 sz = QFileInfo(tmpPath).size();
    if (sz < 100) {
        qWarning() << "db file download too small (" << sz << "bytes), discard:" << tmpPath;
        QFile::remove(tmpPath);
        // Keep optimistic local edits visible even when NAS mirror re-download fails.
        sendChangeSignal();
        return;
    }

    replaceDbFile();
    emit dbFileDownloadSuccess();
}

QString DbFiles::localDbFileNew()
{
    return m_localDbFilePath + "~";
}

void DbFiles::sendChangeSignal()
{
    emit dataChanged();
}

bool DbFiles::opendb()
{
    if (g_app->dbDevices.curr.mac.isEmpty()) {
        qDebug() << "dbFiels.cpp, opendb, no dbDevices.curr.mac, ignore";
        return false;
    }
    if (m_isShared) {
        m_localDbFilePath = LocalSettings::configDir() + "/" + g_app->dbDevices.curr.mac + "/" + g_app->nasApi.shareDbFileName();
    }
    else {
        m_localDbFilePath = LocalSettings::configDir() + "/" + g_app->dbDevices.curr.mac + "/" + g_app->nasApi.userDbFileName();
    }
    qDebug() << "dbfiles: " << m_localDbFilePath;
    // Private and shared must use separate QSqlDatabase connections — one connection name
    // cannot safely switch between file.db and shared.db without clobbering the other UI.
    const QString connName = m_isShared
        ? QStringLiteral("zhome_db_files_shared")
        : QStringLiteral("zhome_db_files_private");
    if (QSqlDatabase::contains(connName)) {
        m_db = QSqlDatabase::database(connName);
    } else {
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
    }
    if (m_db.isOpen())
        m_db.close();
    m_db.setDatabaseName(m_localDbFilePath);
    if (!m_db.open()) { // open db, and check the result
        qWarning() << "dbfiles: open database fail: " << m_db.lastError().text();
        return false;
    }
    return true;
}

void DbFiles::closedb()
{
    if (m_db.isOpen()) {
        m_db.close();
        qDebug() << "dbfiles: closedb done";
    }
}

bool DbFiles::add(const QString strRemotePath, qint64 iSize, qint64 iDate, qint64 iIsDir)
{
    if (!m_db.isOpen()) {
        qWarning("add: open db fail");
        return false;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString("INSERT or REPLACE INTO files_table(remotePath, size, name, directory, status, createdTime) VALUES (:remotePath, :size, :name, :directory, :status, :createdTime)");
    query.prepare(sqlStr);
    query.bindValue(":remotePath", strRemotePath);
    query.bindValue(":size", iSize);
    query.bindValue(":createdTime", iDate);
    query.bindValue(":name", strRemotePath.mid(strRemotePath.lastIndexOf("/") + 1));
    query.bindValue(":directory", iIsDir);
    query.bindValue(":status", "normal");
    m_db.transaction();
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "add: query exec fail: " << query.lastError().text();
        return false;
    }
    if (!m_db.commit()) {
        qWarning() << "add: commit fail: " << m_db.lastError().text();
        return false;
    }
    sendChangeSignal();
    return true;
}

bool DbFiles::del(const QString strRemotePath)
{
    if (!m_db.isOpen()) {
        qWarning("del: open db fail");
        return false;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString("DELETE FROM files_table where remotePath = :remotePath;");
    query.prepare(sqlStr);
    query.bindValue(":remotePath", strRemotePath);
    m_db.transaction();
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "del query exec fail: " << query.lastError().text();
        return false;
    }
    if (!m_db.commit()) {
        qWarning() << "del commit fail: " << query.lastError().text();
        return false;
    }

    sendChangeSignal();

    return true;
}

int DbFiles::count()
{
    if (!m_db.isOpen()) {
        qWarning("count: open db fail");
        return 0;
    }

    QSqlQuery query(m_db);
    QString sqlStr = "SELECT COUNT(*) FROM files_table";
    if (query.exec(sqlStr) && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

int DbFiles::trashItemCount()
{
    if (!m_db.isOpen())
        return 0;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT COUNT(*) FROM files_table WHERE status = :st"));
    query.bindValue(QStringLiteral(":st"), TYPE_INTRASH);
    if (query.exec() && query.next())
        return query.value(0).toInt();
    return 0;
}

QList<DbFilesData> DbFiles::all(QString strStatus)
{
    QList<DbFilesData> pRet = QList<DbFilesData>();

    if (!m_db.isOpen()) {
        qWarning("all: open db fail");
        return pRet;
    }

    if (count() <= 0) {
        return pRet;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString(
        "SELECT remotePath,size,createdTime,directory FROM files_table where status = :status ORDER BY remotePath COLLATE NOCASE");
    query.prepare(sqlStr);
    query.bindValue(":status", strStatus);
    m_db.transaction();
    if (!query.exec()) {
        qWarning() << "all: query exec fail: " << query.lastError().text();
        return pRet;
    }
    if (!m_db.commit()) {
        qWarning() << "all commit fail: " << query.lastError().text();
        return pRet;
    }

    //qDebug() << "dbfiles.cpp: get all files: ";

    while (query.next()) {
        DbFilesData dataNow;
        dataNow.remotePath = query.value(0).toString();
        dataNow.size = query.value(1).toLongLong();
        dataNow.date = query.value(2).toLongLong();
        dataNow.isDir = query.value(3).toBool();
        pRet.append(dataNow);
        // qDebug() << "dbFiles all: " << dataNow.remotePath << ", shared? " << m_isShared << ", filename: " << m_localDbFilePath;
    }

    return pRet;
}

void DbFiles::replaceDbFile()
{ // delete db file and create new, or use new db file download from server
    closedb();
    QFile::remove(m_localDbFilePath);
    if (QFile::exists(localDbFileNew())) {
        qDebug() << "rename " << localDbFileNew() << "to " << m_localDbFilePath;
        QFile::rename(localDbFileNew(), m_localDbFilePath);
    }
    opendb();
    sendChangeSignal();
}

QString DbFiles::getRequestPath(const QString &strFullRemotePath)
{
    if (m_isShared) {
        const qsizetype iIndex = strlen("/Ftp");
        return (iIndex == -1) ? "" : strFullRemotePath.mid(iIndex); // skip "/Ftp" and return /~user/MyFiles/xxx
    }
    else {
        const QString targetString = "/MyFiles";
        const qsizetype iIndex = strFullRemotePath.indexOf(targetString);
        return (iIndex == -1) ? "" : strFullRemotePath.mid(iIndex);
    }
}

void DbFiles::filterAppend(const DbFilesData& dataNow, QList<DbFilesData> &dataListFiltered, QString strRequestPath)
{
    // qDebug() << "FilterAppend: " << dataNow.remotePath << " ==> " << strRequestPath;
    bool bDone = false;
    for (int idx = 0; idx < dataListFiltered.length(); idx++) {
        if (dataListFiltered[idx].remotePath == strRequestPath) {
            // qDebug() << "add file which exists, dir size+1";
            dataListFiltered[idx].size ++;
            if (dataListFiltered[idx].date < dataNow.date) {
                dataListFiltered[idx].date = dataNow.date;
            }
            bDone = true;
            break;
        }
    }
    if (!bDone) {
        // qDebug() << "!bDone: " << dataNow.remotePath << " <==> " << strRequestPath;
        if (dataNow.remotePath == strRequestPath) {
            // qDebug() << "add new file";
            DbFilesData newItem = dataNow;
            if (newItem.isDir) {
                newItem.size = 0;
            }
            dataListFiltered.append(newItem);
        }
        else {
            // qDebug() << "add new dir";
            DbFilesData newItem;
            newItem.remotePath = strRequestPath;
            newItem.size = 1;
            newItem.isDir = true;
            newItem.date = dataNow.date;
            dataListFiltered.append(newItem);
        }
    }
}

QVariantList DbFiles::getFiles(QString strRequestDir, QString strFilter, const bool bIsRecycleBin, const bool bShareTypeOthers)
{ // "/MyFiles/Doc" etc.
    qDebug() << "getFiles: filter = " << strRequestDir << ", isRecycleBin = " << bIsRecycleBin << ", dbfile: " << m_localDbFilePath << ", shared = " << m_isShared;
    QString strStatus = bIsRecycleBin ? TYPE_INTRASH : TYPE_NORMAL;
    QList<DbFilesData> dataListAll = all(strStatus);
    QList<DbFilesData> dataList = QList<DbFilesData>();
    QList<DbFilesData> dataListFiltered = QList<DbFilesData>();

    // qDebug() << "dataListAll count: " << dataListAll.length();

    // remove prefix before "/MyFiles/"
    for (int iLoop = 0; iLoop < dataListAll.length(); iLoop++) {
        // dataListAll[iLoop].remotePath = getRequestPath(dataListAll[iLoop].remotePath);
        if (dataListAll[iLoop].remotePath.contains(strRequestDir + "/")) { // filter
            if (strRequestDir != "/MyFiles" || !dataListAll[iLoop].remotePath.contains("/MyFiles/.")) { // skip files: /MyFiles/.xxx
                bool bMyfile = dataListAll[iLoop].remotePath.contains(LocalSettings::getUser());
                if ( !m_isShared || ( bShareTypeOthers && !bMyfile ) || ( !bShareTypeOthers && bMyfile ) ) { // shareAll, shareMy
                    // qDebug() << "dataList addpend: " << dataListAll[iLoop].remotePath;
                    dataList.append(dataListAll[iLoop]);
                }
            }
        }
    }

    // qDebug() << "dataList count: " << dataList.length();

    // get files and dir under request dir, first level
    const qsizetype iNum = strRequestDir.split('/', Qt::SkipEmptyParts).length() + 2; // + "/Ftp/user"
    foreach (const DbFilesData& dataNow, dataList) {
        if (bIsRecycleBin) {
            dataListFiltered.append(dataNow);
        }
        else if (!strFilter.isEmpty()) {
            if (!dataNow.isDir && filenameContainsFilter(dataNow.remotePath, strFilter)) {
                dataListFiltered.append(dataNow);
            }
            else {
                // qDebug() << "search skip: " << dataNow.remotePath;
            }
        }
        else {
            // qDebug() << "dataNow.remotePath: " << dataNow.remotePath << ", strRequestDir: " << strRequestDir;
            if (dataNow.remotePath.contains(strRequestDir)) {
                QStringList fields = dataNow.remotePath.split('/', Qt::SkipEmptyParts);
                if (fields.size() > iNum) {
                    QString strRequestPath = "";
                    for (int idx = 0; idx <= iNum; idx++) { // files under request dir, request level + 1, so use "idx <= iNum"
                        // qDebug() << "field " << idx << ": " << fields[idx];
                        strRequestPath += "/" + fields[idx];
                    }
                    filterAppend(dataNow, dataListFiltered, strRequestPath);
                }
            }
        }
    }

    // qDebug() << "dataListFiltered count: " << dataListFiltered.length();

    // 当前目录下列表按「显示名」（路径最后一段）排序；以后可扩展为日期/大小等。
    std::sort(dataListFiltered.begin(), dataListFiltered.end(), [](const DbFilesData &a, const DbFilesData &b) {
        return QString::localeAwareCompare(fileEntryDisplayName(a), fileEntryDisplayName(b)) < 0;
    });

    // convert to qml data type
    QVariantList pRet = QVariantList();
    foreach (const DbFilesData& dataNow, dataListFiltered) {
        // qDebug() << "append: " << dataNow.remotePath;
        QVariantMap sItem;
        sItem["fileuser"] = LocalSettings::getUser();
        if (m_isShared) {
            sItem["fileuser"] = dataNow.remotePath.split('/', Qt::SkipEmptyParts)[0];
        }
        sItem["filepath"] = dataNow.remotePath;
        sItem["filesize"] = dataNow.isDir ? QString::number(dataNow.size) : QString::number(dataNow.size); // formatFileSize(dataNow.size);
        sItem["filedate"] = dataNow.date;
        sItem["isdir"] = dataNow.isDir;
        sItem["filedisplay"] = dataNow.remotePath.split('/', Qt::SkipEmptyParts)[dataNow.remotePath.split('/', Qt::SkipEmptyParts).length() - 1];
        sItem["selected"] = false;
        pRet.append(sItem);
    }

    // qDebug() << "dbFiles file: " << m_localDbFilePath << ", pRet count: " << pRet.length();

    return pRet;
}

bool DbFiles::filenameContainsFilter(const QString &strFile, const QString strFilter)
{
    QStringList fields = strFile.split('/', Qt::SkipEmptyParts);
    return fields[fields.length() - 1].contains(strFilter);
}

QVariantList DbFiles::myFiles(QString strFilter)
{
    QList<DbFilesData> dataListAll = all(TYPE_NORMAL);
    int iImage = 0;
    int iVideo = 0;
    int iAudio = 0;
    int iDoc = 0;
    const QString TAG_IMAGE = "/MyFiles/Image";
    const QString TAG_VIDEO = "/MyFiles/Video";
    const QString TAG_AUDIO = "/MyFiles/Audio";
    const QString TAG_DOC = "/MyFiles/Doc";
    QVariantList pRet = QVariantList();
    QVariantMap sItem;

    for (int iLoop = 0; iLoop < dataListAll.length(); iLoop++) {
        if (dataListAll[iLoop].isDir) {
            continue; // only count files
        }
        if (strFilter.isEmpty() || filenameContainsFilter(dataListAll[iLoop].remotePath, strFilter)) {
            QString rpath = dataListAll[iLoop].remotePath;
            if (rpath.contains(TAG_IMAGE)) {
                iImage++;
            }
            if (rpath.contains(TAG_VIDEO)) {
                iVideo++;
            }
            if (rpath.contains(TAG_AUDIO)) {
                iAudio++;
            }
            if (rpath.contains(TAG_DOC)) {
                iDoc++;
            }
        }
    }

    sItem["fileuser"] = LocalSettings::getUser();
    sItem["filepath"] = TAG_IMAGE;
    sItem["filesize"] = iImage;
    sItem["filedate"] = 0;
    sItem["isdir"] = 0;
    sItem["filedisplay"] = "Image";
    sItem["selected"] = false;
    pRet.append(sItem);

    sItem["fileuser"] = LocalSettings::getUser();
    sItem["filepath"] = TAG_VIDEO;
    sItem["filesize"] = iVideo;
    sItem["filedate"] = 0;
    sItem["isdir"] = 0;
    sItem["filedisplay"] = "Video";
    sItem["selected"] = false;
    pRet.append(sItem);

    sItem["fileuser"] = LocalSettings::getUser();
    sItem["filepath"] = TAG_AUDIO;
    sItem["filesize"] = iAudio;
    sItem["filedate"] = 0;
    sItem["isdir"] = 0;
    sItem["filedisplay"] = "Audio";
    sItem["selected"] = false;
    pRet.append(sItem);

    sItem["fileuser"] = LocalSettings::getUser();
    sItem["filepath"] = TAG_DOC;
    sItem["filesize"] = iDoc;
    sItem["filedate"] = 0;
    sItem["isdir"] = 0;
    sItem["filedisplay"] = "Doc";
    sItem["selected"] = false;
    pRet.append(sItem);

    std::sort(pRet.begin(), pRet.end(), [](const QVariant &a, const QVariant &b) {
        const QString na = a.toMap().value(QStringLiteral("filedisplay")).toString();
        const QString nb = b.toMap().value(QStringLiteral("filedisplay")).toString();
        return QString::localeAwareCompare(na, nb) < 0;
    });

    return pRet;
}

QString DbFiles::formatFileSize(qint64 size)
{
    if (size < 1024) {
        return QString("%1 B").arg(size);
    } else if (size < 1024 * 1024) {
        double kbSize = size / 1024.0;
        return QString::number(kbSize, 'f', kbSize == static_cast<int>(kbSize) ? 0 : 1) + " KB";
    } else if (size < 1024 * 1024 * 1024) {
        double mbSize = size / (1024.0 * 1024);
        return QString::number(mbSize, 'f', mbSize == static_cast<int>(mbSize) ? 0 : 1) + " MB";
    } else {
        double gbSize = size / (1024.0 * 1024 * 1024);
        return QString::number(gbSize, 'f', gbSize == static_cast<int>(gbSize) ? 0 : 1) + " GB";
    }
}

bool DbFiles::getSelectAll()
{
    return m_select_all;
}

void DbFiles::setSelectAll(bool newSelect_all)
{
    if (m_select_all == newSelect_all)
        return;
    m_select_all = newSelect_all;
    emit selectAllChanged();
}

// iType: 0:listview, 1:icon
void DbFiles::setDisplayType(int iType)
{
    LocalSettings::setInt(APP_FILE_DISPLAY_TYPE, iType);
    emit displayTypeChanged();
}

int DbFiles::getDisplayType()
{
    return LocalSettings::getInt(APP_FILE_DISPLAY_TYPE);
}

qint64 DbFiles::getFileDateByRemotePath(QString remotePath)
{
    qint64 iRet = -1;

    if (!m_db.isOpen()) {
        qWarning("all: open db fail");
        return iRet;
    }

    if (count() <= 0) {
        return iRet;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString("SELECT createdTime FROM files_table where remotePath = :remotePath");
    query.prepare(sqlStr);
    query.bindValue(":remotePath", remotePath);
    m_db.transaction();
    if (!query.exec()) {
        qWarning() << "all: query exec fail: " << query.lastError().text();
        return iRet;
    }
    if (!m_db.commit()) {
        qWarning() << "all commit fail: " << query.lastError().text();
        return iRet;
    }

    //qDebug() << "dbfiles.cpp: get all files: ";

    if (query.next()) {
        return query.value(0).toLongLong(); 
    }

    return iRet;
}

QString DbFiles::cmdPathToDbRemotePath(const QString &cmdPath) const
{
    QString p = cmdPath.trimmed();
    while (p.startsWith(QLatin1Char('/')))
        p = p.mid(1);
    if (p.startsWith(QLatin1String("Ftp/")))
        return QLatin1Char('/') + p;

    const QString user = LocalSettings::getUser();
    if (p.startsWith(user + QLatin1Char('/')))
        return QStringLiteral("/Ftp/") + p;
    if (p.startsWith(QLatin1String("MyFiles")))
        return QStringLiteral("/Ftp/") + user + QLatin1Char('/') + p;
    return QStringLiteral("/Ftp/") + user + QStringLiteral("/MyFiles/") + p;
}

void DbFiles::updateStatusForPath(const QString &dbRemotePath, const QString &status)
{
    if (!m_db.isOpen() || dbRemotePath.isEmpty())
        return;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "UPDATE files_table SET status = :st WHERE remotePath = :p OR remotePath LIKE :pchild"));
    query.bindValue(QStringLiteral(":st"), status);
    query.bindValue(QStringLiteral(":p"), dbRemotePath);
    query.bindValue(QStringLiteral(":pchild"), dbRemotePath + QStringLiteral("/%"));
    if (!query.exec())
        qWarning() << "updateStatusForPath fail:" << query.lastError().text() << dbRemotePath;
}

void DbFiles::deletePathPermanently(const QString &dbRemotePath)
{
    if (!m_db.isOpen() || dbRemotePath.isEmpty())
        return;
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "DELETE FROM files_table WHERE remotePath = :p OR remotePath LIKE :pchild"));
    query.bindValue(QStringLiteral(":p"), dbRemotePath);
    query.bindValue(QStringLiteral(":pchild"), dbRemotePath + QStringLiteral("/%"));
    if (!query.exec())
        qWarning() << "deletePathPermanently fail:" << query.lastError().text() << dbRemotePath;
}

void DbFiles::renamePathPrefix(const QString &oldDbPath, const QString &newDbPath)
{
    if (!m_db.isOpen() || oldDbPath.isEmpty() || newDbPath.isEmpty())
        return;

    m_db.transaction();
    QSqlQuery q1(m_db);
    q1.prepare(QStringLiteral(
        "UPDATE files_table SET remotePath = :np, name = :nm WHERE remotePath = :op"));
    q1.bindValue(QStringLiteral(":np"), newDbPath);
    q1.bindValue(QStringLiteral(":nm"), newDbPath.mid(newDbPath.lastIndexOf(QLatin1Char('/')) + 1));
    q1.bindValue(QStringLiteral(":op"), oldDbPath);
    if (!q1.exec())
        qWarning() << "renamePathPrefix self fail:" << q1.lastError().text();

    QSqlQuery q2(m_db);
    q2.prepare(QStringLiteral(
        "UPDATE files_table SET remotePath = replace(remotePath, :op, :np) WHERE remotePath LIKE :opchild"));
    q2.bindValue(QStringLiteral(":op"), oldDbPath);
    q2.bindValue(QStringLiteral(":np"), newDbPath);
    q2.bindValue(QStringLiteral(":opchild"), oldDbPath + QStringLiteral("/%"));
    if (!q2.exec())
        qWarning() << "renamePathPrefix children fail:" << q2.lastError().text();
    m_db.commit();
}

void DbFiles::applyOptimisticLocalUpdate(const QString &strCmd, const QString &strResult)
{
    if (!m_db.isOpen()) {
        if (!opendb())
            return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(strCmd.toUtf8());
    if (!doc.isObject())
        return;
    const QJsonObject obj = doc.object();

    auto fileListFromCmd = [&]() -> QStringList {
        QStringList out;
        const QJsonValue v = obj.value(QLatin1String(CMD_KEY_FILE_LIST));
        if (v.isArray()) {
            const QJsonArray arr = v.toArray();
            for (const QJsonValue &item : arr)
                out.append(item.toString());
        }
        return out;
    };

    if (g_app->nasApi.removeFilesSuccess(strResult)) {
        for (const QString &p : fileListFromCmd())
            updateStatusForPath(cmdPathToDbRemotePath(p), TYPE_INTRASH);
        return;
    }
    if (g_app->nasApi.recoverFilesSuccess(strResult)) {
        for (const QString &p : fileListFromCmd())
            updateStatusForPath(cmdPathToDbRemotePath(p), TYPE_NORMAL);
        return;
    }
    if (g_app->nasApi.deleteFilesSuccess(strResult)) {
        for (const QString &p : fileListFromCmd())
            deletePathPermanently(cmdPathToDbRemotePath(p));
        return;
    }
    if (g_app->nasApi.fileRenameSuccess(strResult)) {
        const QString from = obj.value(QLatin1String("from")).toString();
        const QString to = obj.value(QLatin1String("to")).toString();
        if (!from.isEmpty() && !to.isEmpty())
            renamePathPrefix(cmdPathToDbRemotePath(from), cmdPathToDbRemotePath(to));
        return;
    }
    if (g_app->nasApi.moveFilesSuccess(strResult)) {
        const QString dest = obj.value(QLatin1String("dest_sub_dir")).toString();
        if (dest.isEmpty())
            return;
        const QString destDb = cmdPathToDbRemotePath(dest);
        for (const QString &p : fileListFromCmd()) {
            const QString oldDb = cmdPathToDbRemotePath(p);
            const QString name = oldDb.mid(oldDb.lastIndexOf(QLatin1Char('/')) + 1);
            renamePathPrefix(oldDb, destDb + QLatin1Char('/') + name);
        }
        return;
    }
    if (g_app->nasApi.createNewFolderSuccess(strResult)) {
        const QString cur = obj.value(QLatin1String(CMD_CURRENT_DIRECTORY)).toString();
        const QString name = obj.value(QLatin1String(CMD_KET_SUBDIR)).toString();
        if (cur.isEmpty() || name.isEmpty())
            return;
        QString parent = cmdPathToDbRemotePath(cur);
        while (parent.endsWith(QLatin1Char('/')))
            parent.chop(1);
        add(parent + QLatin1Char('/') + name, 0, QDateTime::currentSecsSinceEpoch(), 1);
        return;
    }
    // share / cancel share / repair: rely on re-download of file.db / shared.db
}

void DbFiles::reset() {
    if (m_uploadIndexTimer)
        m_uploadIndexTimer->stop();
    m_pendingUploadIndex.clear();
    m_uploadIndexBusy = false;
    m_awaitingAddOneFile = false;
    closedb();
    opendb();
}
