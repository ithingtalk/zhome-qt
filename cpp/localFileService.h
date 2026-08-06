#ifndef LOCALFILESERVICE_H
#define LOCALFILESERVICE_H

#include <QQmlEngine>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <QFileInfo>
#include <QDebug>
#include <QSslConfiguration>
#include <QSslSocket>
#include <QMap>
#include <QTimer>
#include "dbFileTransfer.h"
#include "nasApi.h"

class DbTransferData;

class LocalFileService : public QObject
{
    Q_OBJECT

public:
    explicit LocalFileService(NasApi &nasApi, int iType = DbFileTransfer::TYPE_SINGLE_FILE, QObject *parent = nullptr);
    explicit LocalFileService(NasApi &nasApi, int iType, DbFileTransfer &fileTransfer, QObject *parent = nullptr);
    ~LocalFileService();
    void initNormal();

public slots:
    void upload(const QString &strLocalFile, const QString &strRemotePath);
    void download(const QString &strRemotePath, const QString &strLocalFile = "");
    QString configDir();
    QString dataDir();
    QString cacheDir();
    void stop();
    void doStart();
    void start();
	void uploadProgressSlot(qint64, qint64);
    void uploadFinishedSlot();
    void uploadErrorSlot(QNetworkReply::NetworkError errorCode);
    void downloadProgressSlot(qint64, qint64);
    void downloadFinishedSlot();
    void downloadErrorSlot(QNetworkReply::NetworkError errorCode);

signals:
    void uploadProgress(QString, qint64, qint64);
    void downloadProgress(QString, qint64, qint64);
    void netError(QString, qint64);
    void uploadFinish(QString, qint64, qint64);
    void downloadFinish(QString);

private slots:
    void dbDataChanged(qint64 bType);

public:
    QUrl m_urlRemote;
    QString m_strLocalFile;
    QString getRemoteRPath();
    QString getRemotePath();

private:
    QNetworkAccessManager *m_networkManager;
    QSslConfiguration m_sslConfig;
    QString m_user;
    QString m_pass;
    QFile *m_filePut = nullptr;
    QFile *m_fileGet = nullptr;
    QNetworkReply *m_replyPut = nullptr;
    QNetworkReply *m_replyGet = nullptr;

    void setAuthorizationHeader(QNetworkRequest &sRequest);
    void onAuthenticationRequired(QNetworkReply *pReply, QAuthenticator *pAuthenticator);
    QMap<QString, qint64> parseListResult(QString strList);
    void deletePutFile();
    void deleteGetFile(bool bRemoveFile = false);
    void deleteFromDb();
	bool isTransferFileList();
    QString typeName();
    void moveToPictureDir(const QString &strSourceFilePath);
    bool fileIsPictureOrVideo();
    int fileType();
    bool isTransfering();
    void setupRequest(QNetworkRequest &sRequest);
    void clearAll();

private:
    int m_transferType = DbFileTransfer::TYPE_SINGLE_FILE;
    QList<DbTransferData> m_default_list;
    QList<DbTransferData> &m_sList;
    QTimer * m_startTimer = nullptr;
    bool isCachedFile(const QString &strFile);
    NasApi &m_nasApi;
};


#ifdef Q_OS_IOS
void ios_moveFileToNativeFolder(const QString& strSourceFile, int iType);
#endif

#endif // LOCALFILESERVICE_H
