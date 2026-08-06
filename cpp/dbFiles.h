#ifndef DBFILES_H
#define DBFILES_H

#include <QQmlEngine>
#include <QQueue>
#include "localFileService.h"
#include "cmdService.h"

//============================= files sql ==================================
// #define DBFILES_CREATE_TABLE "CREATE TABLE IF NOT EXISTS files_table(id INTEGER PRIMARY KEY, path varchar(255), name varchar(255) not null, type varchar(32), directory varchar(16), status varchar(16), remotePath varchar(512) not null unique, size integer not null, addTime integer, createdTime integer, md5 varchar(20))"
// #define DBFILES_CREATE_TABLE "CREATE TABLE IF NOT EXISTS device(mac TEXT PRIMARY KEY, sn TEXT, name TEXT, cfg TEXT, ip TEXT);"
//#define DBFILES_EMPTY "DELETE FROM files_table;"
//#define DBFILES_SET "INSERT or REPLACE INTO files_table(remotePath, size, createdTime) VALUES (:remotePath, :size, :createdTime)"
//#define DBFILES_COUNT "SELECT COUNT(*) FROM files_table"
// #define DBFILES_GET "SELECT remotePath,size,createdTime FROM files_table where remotePath = :remotePath;"
//#define DBFILES_GET_ALL "SELECT remotePath,size,createdTime FROM files_table;"
// #define DBFILES_DELETE "DELETE FROM files_table where remotePath = :remotePath;"
//===========================================================================

class DbFilesData
{
public:
    QString remotePath;
    qint64 size;
    qint64 date;
    bool isDir;
};

/** Pending post-upload NAS index via add_one_file (Android TransferEngine parity). */
struct PendingUploadIndex {
    QString remotePath;
    QString myFilesRel;
    qint64 size = 0;
    qint64 date = 0;
    int attemptsSent = 0;
};

class DbFiles : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int displayType READ getDisplayType WRITE setDisplayType NOTIFY displayTypeChanged)

public:
    explicit DbFiles(NasApi &nasApi, bool isShared = false, QObject *parent = nullptr);
    explicit DbFiles(NasApi &nasApi, LocalFileService &uploads, bool isShared = false, QObject *parent = nullptr);
    ~DbFiles();
    void initNormal();

public slots:
    void sendChangeSignal();

    // iType: 0:listview, 1:icon
    void setDisplayType(int iType);
    int getDisplayType();

    QVariantList getFiles(const QString strRequestDir, QString strFilter, const bool bIsRecycleBin, const bool bShareTypeOthers = true);
    Q_INVOKABLE int trashItemCount();
    bool add(const QString strRemotePath, qint64 iSize, qint64 iDate = 0, qint64 iIsDir = 0);
    bool del(const QString strRemotePath);
    int count();
    void replaceDbFile();
    QString localDbFileNew();
    void updateDbFile(bool force = false);
    void sendCmd(QString strCmd);
    qint64 getFileDateByRemotePath(QString);
    bool getSelectAll();
    void setSelectAll(bool newSelect_all);
    void reset();
    QString formatFileSize(qint64 size);
    QVariantList myFiles(QString strFilter = "");

private slots:
    void dbFileDownloadFinished(QString strFileName);
    void cmdServiceDataFinished(QString strCmd, QString strResult);
    void cmdServiceError(const QString errString, const int errCode);
    void updateDatabase();
    void tryStartNextUploadIndex();
    void sendAddOneFileForHead();
    void finalizeUploadIndexHead(bool nasIndexedOk);

signals:
    void dataChanged();
    void displayTypeChanged();
    void dbFileDownloadSuccess();
    void selectAllChanged();

private:
    const QString APP_FILE_DISPLAY_TYPE = "APP_FILE_DISPLAY_TYPE";
    QSqlDatabase m_db;
    QString m_localDbFilePath = "";
    QString getRequestPath(const QString &strFullRemotePath);
    bool opendb();
    void closedb();
    QList<DbFilesData> all(QString strStatus);
    QTimer *singleShotTimer;
    bool m_select_all = false;
    bool m_isShared = false;
    NasApi &m_nasApi;
    void filterAppend(const DbFilesData &dataNow, QList<DbFilesData> &dataListFiltered, QString strDir);
    bool filenameContainsFilter(const QString &strFile, const QString strFilter);

    /** Map NAS cmd path (MyFiles/... or user/MyFiles/...) to local files_table remotePath (/Ftp/...). */
    QString cmdPathToDbRemotePath(const QString &cmdPath) const;
    void updateStatusForPath(const QString &dbRemotePath, const QString &status);
    void deletePathPermanently(const QString &dbRemotePath);
    void renamePathPrefix(const QString &oldDbPath, const QString &newDbPath);
    /** Apply local SQLite mirror immediately so UI updates before file.db re-download. */
    void applyOptimisticLocalUpdate(const QString &strCmd, const QString &strResult);

    static constexpr qint64 ADD_ONE_FILE_LARGE_BYTES = 100LL * 1024 * 1024;
    static constexpr int ADD_ONE_FILE_LARGE_SETTLE_MS = 1000;
    static constexpr int ADD_ONE_FILE_MAX_ATTEMPTS = 5;
    static constexpr int ADD_ONE_FILE_RETRY_BASE_MS = 500;

    QQueue<PendingUploadIndex> m_pendingUploadIndex;
    bool m_uploadIndexBusy = false;
    bool m_awaitingAddOneFile = false;
    QTimer *m_uploadIndexTimer = nullptr;

public:
    LocalFileService m_fileService;
    const QString TYPE_NORMAL = "normal";
    const QString TYPE_INTRASH = "inTrash";
    bool isDownloadUserDbFile(QString strLocalFile);
    bool isDownloadShareDbFile(QString strLocalFile);
    const QString TRANSER_REMOTE_PATH_TYPE_BT = ".btFiles/";
    const QString TRANSER_REMOTE_PATH_TYPE_DB = "DB/";
    const QString TRANSER_REMOTE_PATH_TYPE_MYFILES = "MyFiles/";
    void conn();
protected slots:
    void uploadedListFileFinished(QString strRemotePath, qint64 iSize, qint64 iDate);
};

#endif // DBFILES_H
