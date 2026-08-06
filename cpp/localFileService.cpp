#include "localFileService.h"
#include "localSettings.h"
#include "globalCpp.h"
#include "dbFileTransfer.h"

#if defined(Q_OS_ANDROID)
#include "androidUtils.h"
#endif

void LocalFileService::dbDataChanged(qint64 iType)
{
    if (m_transferType == iType) {
        qDebug() << typeName() << "fileService.cpp, dbData_Changed: " << m_sList.length();

        if (g_app->useLocalLink()) { // local link: stop old one or ignore same one
            QString oldPath = m_urlRemote.toString();
            if (isTransfering()) {
                if (!oldPath.isEmpty() && !m_sList.isEmpty()) {
                    for (DbTransferData& item: m_sList) {
                        if (oldPath == item.fpath) {
                            qDebug() << typeName() << "current transfering file is in new list, continue transfer and return: " << item.fpath;
                            return;
                        }
                    }
                }
            }
            if (!m_urlRemote.isEmpty()) {
                // stop current transfer
                stop();
            }
        }

        if (!m_sList.isEmpty()) {
            start();
        }
    }
}

bool LocalFileService::isTransfering()
{
    if (g_app->useLocalLink()) { // local link
        return (m_replyGet && m_replyGet->isRunning()) || (m_replyPut && m_replyPut->isRunning());
    }
    return false; // p2p will auto stop old link before new
}

void LocalFileService::initNormal()
{
    // qDebug() << "FileService autodeleteReply: " << m_networkManager->autoDeleteReplies();
    // qDebug() << "FileService type: " << m_transferType;
    m_networkManager->setAutoDeleteReplies(true);
    connect(m_networkManager, &QNetworkAccessManager::authenticationRequired, this, &LocalFileService::onAuthenticationRequired);
    m_sslConfig.setProtocol(QSsl::TlsV1_2OrLater);
    m_sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    m_sslConfig.setPeerVerifyDepth(0);

    m_startTimer = new QTimer(this);
    m_startTimer->setInterval(2000);
    m_startTimer->setSingleShot(true);
    connect(m_startTimer, &QTimer::timeout, this, &LocalFileService::doStart);

    qDebug() << "supported: " << m_networkManager->supportedSchemes();
}

LocalFileService::LocalFileService(NasApi &nasApi, int iType, QObject *parent) :
    QObject(parent),
    m_nasApi(nasApi),
    m_transferType(iType),
    m_sList(m_default_list),
    m_networkManager(new QNetworkAccessManager(this))
{
    qDebug() << "localFileService " << iType;
    initNormal();
    qDebug() << "localFileService done";
}

LocalFileService::LocalFileService(NasApi &nasApi, int iType, DbFileTransfer &fileTransfer, QObject *parent) :
    QObject(parent),
    m_nasApi(nasApi),
    m_transferType(iType),
    m_sList(m_transferType == DbFileTransfer::TYPE_UPLOAD ? fileTransfer.uploadList : fileTransfer.downloadList),
    m_networkManager(new QNetworkAccessManager(this))
{
    qDebug() << "localFileService fileTransfer " << iType;
    initNormal();
    if (isTransferFileList()) {
        connect(&fileTransfer, &DbFileTransfer::transferDataChanged, this, &LocalFileService::dbDataChanged);
    }
    qDebug() << "localFileService fileTransfer done";
}

LocalFileService::~LocalFileService()
{
    qDebug() << "localFileService destroy";
    deleteGetFile();
    deletePutFile();
    qDebug() << "localFileService destroy done";
}

void LocalFileService::upload(const QString &strRemotePath, const QString &strLocalFile)
{
    QUrl localPath(strLocalFile);
    m_user = m_nasApi.fileUser();
    m_pass = m_nasApi.filePasswd();
    m_urlRemote = QUrl(strRemotePath);
    m_strLocalFile = localPath.toLocalFile();
    qDebug() << typeName() << m_urlRemote << " <== " << m_strLocalFile;

    if (g_app->useLocalLink()) { // local link
        deletePutFile();
        m_filePut = new QFile(m_strLocalFile, this);
        if (m_filePut->open(QIODevice::ReadOnly)) {
            QNetworkRequest sRequest(m_urlRemote);
            setupRequest(sRequest);
            sRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/octet-stream");

            m_replyPut = m_networkManager->put(sRequest, m_filePut);

            connect(m_replyPut, &QNetworkReply::uploadProgress, this, &LocalFileService::uploadProgressSlot);
            connect(m_replyPut, &QNetworkReply::finished, this, &LocalFileService::uploadFinishedSlot);
            connect(m_replyPut, &QNetworkReply::errorOccurred, this, &LocalFileService::uploadErrorSlot);
        }
        else {
            qDebug() << typeName() << "open upload file fail, stop";
            deletePutFile();
        }
    }
    else { // remote link, p2p upload
        qDebug() << "p2p upload: " << strRemotePath << " <- " << m_strLocalFile;
        g_app->awsIot.p2p_upload_file(m_strLocalFile, strRemotePath);
    }
}

void LocalFileService::download(const QString &strRemoteUrl, const QString &strLocalFile)
{
    m_user = m_nasApi.fileUser(strRemoteUrl);
    m_pass = m_nasApi.filePasswd(strRemoteUrl);
    m_urlRemote = QUrl(strRemoteUrl);
    QString downloadLocalFile = strLocalFile;
    if (downloadLocalFile.isEmpty()) {
        QString strFileName = strRemoteUrl.mid(strRemoteUrl.lastIndexOf("/") + 1);
        // qDebug() << typeName() << "filename=" << strFileName;
        downloadLocalFile = g_app->utils.addLocalFilePrefix(LocalSettings::downloadDir() + "/" + strFileName);
    }
    // qDebug() << typeName() << "localfile: " << downloadLocalFile;
    QUrl localPath(downloadLocalFile);
    m_strLocalFile = localPath.toLocalFile();
    qDebug() << typeName() << m_urlRemote << " ==> " << m_strLocalFile;

    if (g_app->useLocalLink()) { // local link
        deleteGetFile();
        m_fileGet = new QFile(m_strLocalFile, this);
        if (m_fileGet->open(QIODevice::WriteOnly | QFile::Truncate)) {

            QNetworkRequest sRequest(m_urlRemote);
            setupRequest(sRequest);

            m_replyGet = m_networkManager->get(sRequest);

            connect(m_replyGet, &QNetworkReply::downloadProgress, this, &LocalFileService::downloadProgressSlot);
            connect(m_replyGet, &QNetworkReply::finished, this, &LocalFileService::downloadFinishedSlot);
            connect(m_replyGet, &QNetworkReply::errorOccurred, this, &LocalFileService::downloadErrorSlot);
        }
        else {
            deleteGetFile();
        }
    }
    else { // remote link, p2p download
        qDebug() << "p2p download: " << strRemoteUrl << " -> " << m_strLocalFile;
        g_app->awsIot.p2p_download_file(strRemoteUrl, m_strLocalFile);
    }
}

void LocalFileService::setupRequest(QNetworkRequest &sRequest)
{
    // sRequest.setUrl(m_urlRemote);
    sRequest.setSslConfiguration(m_sslConfig);
    setAuthorizationHeader(sRequest);
    // sRequest.setTransferTimeout(8000);
}

void LocalFileService::uploadProgressSlot(qint64 bytesSent, qint64 bytesTotal)
{
    if (g_app->useLocalLink()) {
        if (!m_replyPut || m_replyPut->isFinished()) {
            qDebug() << typeName() << "uploadProgressSlot, ignore because put reply is finished";
            return;
        }

        if (bytesTotal == 0 && bytesSent == 0) {
            return;
        }
    }
    emit uploadProgress(m_urlRemote.toString(), bytesSent, bytesTotal);
}

void LocalFileService::uploadFinishedSlot() {
    if (!g_app->useLocalLink() || ( m_replyPut && m_replyPut->error() == QNetworkReply::NoError ) ) {
        qDebug() << typeName() << "uploadFinishedSlot success, send signal uploadFinished(" << m_strLocalFile << ")";
        QFile localFile(m_strLocalFile);
        qint64 localFileSize = localFile.size();
        qint64 modifiedTime = localFile.fileTime(QFileDevice::FileModificationTime).toSecsSinceEpoch();
        emit uploadFinish(getRemotePath(), localFileSize, modifiedTime);
        deletePutFile();
        deleteFromDb();
    }
    else {
        qDebug() << typeName() << "uploadFinishedSlot ignored with error: " << m_strLocalFile;
    }
}

void LocalFileService::uploadErrorSlot(QNetworkReply::NetworkError errorCode)
{
    qDebug() << typeName() << "upload error code: " << errorCode;
    // (errorCode == QNetworkReply::OperationCanceledError)
    deletePutFile();
    emit netError(m_strLocalFile, errorCode);
}

void LocalFileService::downloadProgressSlot(qint64 bytesSent, qint64 bytesTotal)
{
    if (g_app->useLocalLink()) {
        if (m_fileGet && m_fileGet->isOpen()) {
            m_fileGet->write(m_replyGet->readAll());
            emit downloadProgress(m_urlRemote.toString(), bytesSent, bytesTotal);
        }
        else {
            qDebug() << typeName() << "downloadProgressSlot, ignore because get file is closed";
        }
    }
    else {
        // qDebug() << typeName() << "download progress. " << "m_urlRemote: " << (m_urlRemote.isEmpty() ? "empty" : m_urlRemote.toString());
        emit downloadProgress(m_urlRemote.toString(), bytesSent, bytesTotal);
    }
}

void LocalFileService::downloadFinishedSlot() {
    qDebug() << typeName() << "downloadFinishedSlot: " << m_strLocalFile;

    if (!g_app->useLocalLink() || ( m_replyGet && m_replyGet->error() == QNetworkReply::NoError ) ) {

        qDebug() << typeName() << "downloadFinishedSlot: success";

        if (fileIsPictureOrVideo() && !isCachedFile(m_strLocalFile)) {
#if defined(Q_OS_ANDROID)
            AndroidUtils::moveFileToGallery(m_strLocalFile); // m_fileGet->fileName()
#elif defined(Q_OS_IOS)
            ios_moveFileToNativeFolder(m_strLocalFile, fileType()); // m_fileGet->fileName()
#endif
        }

        deleteGetFile();
        emit downloadFinish(m_strLocalFile);
        deleteFromDb();
    }
}

void LocalFileService::downloadErrorSlot(QNetworkReply::NetworkError errorCode)
{
    qDebug() << typeName() << "download error code: " << errorCode;
    deleteGetFile();
    emit netError(m_strLocalFile, errorCode);
}

bool LocalFileService::isCachedFile(const QString &strFile)
{
    qDebug() << "======> isCachedFile: " << strFile << " ?= " << LocalSettings::cacheDir();
    return strFile.contains(LocalSettings::cacheDir());
}

void LocalFileService::setAuthorizationHeader(QNetworkRequest &sRequest)
{
    if (!m_user.isEmpty() && !m_pass.isEmpty()) {
        QString credentials = m_user + ":" + m_pass;
        QByteArray data = credentials.toLocal8Bit().toBase64();
        QString headerData = "Basic " + data;
        sRequest.setRawHeader("Authorization", headerData.toLocal8Bit());
    }
}

void LocalFileService::onAuthenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator)
{
    Q_UNUSED(reply);
    emit netError(m_strLocalFile, QNetworkReply::NetworkError::AuthenticationRequiredError); // 204
}

void LocalFileService::deletePutFile()
{
    if (m_filePut) {
        if (m_filePut->isOpen()) {
            m_filePut->close();
#ifdef Q_OS_IOS
            m_filePut->remove();
#endif
        }
        m_filePut->deleteLater();
        m_filePut = nullptr;
    }
}

void LocalFileService::deleteGetFile(bool bRemoveFile)
{
    if (m_fileGet) {
        if (m_fileGet->isOpen()) {
            { // TODO: update file date
                const qint64 iDate = g_app->dbFiles.getFileDateByRemotePath(getRemotePath());
                // change m_fileGet createdTime to iDate
                if (iDate > 0) {
                    m_fileGet->setFileTime(QDateTime::fromSecsSinceEpoch(iDate), QFileDevice::FileModificationTime);
                }
            }
            m_fileGet->close();
            if (bRemoveFile) {
                m_fileGet->remove();
            }
        }
        m_fileGet->deleteLater();
        m_fileGet = nullptr;
    }
}

void LocalFileService::stop()
{
    m_networkManager->deleteLater();
    m_networkManager = new QNetworkAccessManager(this);
    m_networkManager->setAutoDeleteReplies(true);
    clearAll();
}

void LocalFileService::clearAll()
{
    qDebug() << typeName() << "clear all";
    if (m_replyPut) {
        m_replyPut = nullptr;
    }
    deleteGetFile();

    if (m_replyGet) {
        m_replyGet = nullptr;
    }
    deletePutFile();

    m_urlRemote.clear();
}

void LocalFileService::start()
{
    //m_startTimer->start();
    doStart();
}

void LocalFileService::doStart()
{
    if (m_sList.isEmpty()) {
        qDebug() << typeName() << "got empty list";
        return;
    }

    const QString strPath = m_sList.first().fpath;
    const QString strLPath = m_sList.first().lpath;

    if (m_transferType == DbFileTransfer::TYPE_UPLOAD) {
        upload(strPath, strLPath);
    }
    else if (m_transferType == DbFileTransfer::TYPE_DOWNLOAD) {
        download(strPath);
    }
}

QString LocalFileService::configDir()
{
    return LocalSettings::configDir();
}

QString LocalFileService::dataDir()
{
    return LocalSettings::dataDir();
}

QString LocalFileService::cacheDir()
{
    return LocalSettings::cacheDir();
}

void LocalFileService::deleteFromDb()
{
    if (isTransferFileList()) {
        // delete from transfer db --> receive dbData_Changed signal --> start next transfer
        g_app->dbFileTransfer.del(m_transferType, m_urlRemote.toString());
    }
}

bool LocalFileService::isTransferFileList()
{
    return m_transferType != DbFileTransfer::TYPE_SINGLE_FILE;
}

QString LocalFileService::typeName()
{
    if (m_transferType == DbFileTransfer::TYPE_UPLOAD) {
        return "Uploading LIST";
    }
    else if (m_transferType == DbFileTransfer::TYPE_DOWNLOAD) {
        return "Downloading LIST";
    }
    else {
        return "SINGLE FILE";
    }
}

bool LocalFileService::fileIsPictureOrVideo()
{
    return fileType() == 0 || fileType() == 1;
}

int LocalFileService::fileType()
{
    if (m_urlRemote.path().contains("/Image/")) {
        return 0;
    }
    else if (m_urlRemote.path().contains("/Video/")) {
        return 1;
    }
    return 99;
}

void LocalFileService::moveToPictureDir(const QString &sourceFilePath)
{
    if (fileIsPictureOrVideo()) {
        QString galleryPath = LocalSettings::pictureDir();
        if (galleryPath.isEmpty()) {
            qDebug() << typeName() << "cannot optain picture dir";
            return;
        }

        QFile sourceFile(sourceFilePath);
        if (!sourceFile.exists()) {
            qDebug() << typeName() << "source file is not exists";
            return;
        }

        QFileInfo fileInfo(sourceFilePath);
        QString destinationFilePath = galleryPath + "/" + fileInfo.fileName();

        QFile destinationFile(destinationFilePath);
        if (destinationFile.exists()) {
            qDebug() << typeName() << "dist file is already exists";
            destinationFile.remove();
        }

        if (sourceFile.copy(destinationFilePath)) {
            qDebug() << typeName() << "saved to photo dir success: " << destinationFilePath;
            QFile::remove(sourceFilePath);
        } else {
            qDebug() << typeName() << "save to photo dir fail: " << sourceFile.errorString();
        }
    }
}

QString LocalFileService::getRemotePath()
{
    QString remotePath = m_urlRemote.path(); // "/~345766218@qq.com/Doc/Zhome_zh_CN.qm"
    QString rootPath = "~" + m_user;
    remotePath.replace(rootPath, "Ftp/" + m_user + "/MyFiles"); // "/Ftp/345766218@qq.com/MyFiles/Doc/Zhome_zh_CN.qm"
    return remotePath;
}

QString LocalFileService::getRemoteRPath()
{
    QString remotePath = m_urlRemote.path(); // "/~345766218@qq.com/Doc/Zhome_zh_CN.qm"
    QString rootPath = "/~" + m_user;
    remotePath.replace(rootPath, "MyFiles"); // "MyFiles/Doc/Zhome_zh_CN.qm"
    return remotePath;
}
