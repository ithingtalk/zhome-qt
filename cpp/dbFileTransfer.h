#ifndef DBFILETRANSFER_H
#define DBFILETRANSFER_H

#include <QQmlEngine>
#include <QSqlDatabase>
#include <QString>

class DbTransferData
{
public:
    QString fpath;
    QString lpath;
    qint64 ftype; // upload / download, default 0: upload
    qint64 fstatus; // started / stopped, default 0: started
};

class DbFileTransfer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit DbFileTransfer(QObject *parent = nullptr);
    ~DbFileTransfer();
    bool opendb();
    void closedb();
    QList<DbTransferData> all(const qint64 iType);
    void postDataChanged(const qint64 iType);

public slots:
    bool add(const qint64 iType, const QString& strPath, const QString& strLocalPath = "", const qint64 bStatus = STATUS_STARTED);
    bool del(const qint64 iType, const QString& strPath);
    bool empty(const qint64 iType);
    int count();
    void empty_all();
    QVariantList getAll(const qint64 iType);
    bool startStop(const qint64 iType, const qint64 bStatus, const QString& strPath = ""); // start/stop a file or all this type files when strPath is ""
    bool start(const qint64 iType, const QString& strPath = "");
    bool stop(const qint64 iType, const QString& strPath = "");
    int upload_type();
    int download_type();
    int started_status();
    int stopped_status();
    void openDownloadDir();
    void reset();
signals:
    void transferDataChanged(qint64 bType); // usage: emit dataChanged();

private:
    QSqlDatabase m_db;
    QString m_path;

public:
    static const int TYPE_SINGLE_FILE = -1;
    static const int TYPE_UPLOAD = 0;
    static const int TYPE_DOWNLOAD = 1;
    static const int STATUS_STARTED = 0;
    static const int STATUS_STOPPED = 1;
    QList<DbTransferData> uploadList;
    QList<DbTransferData> downloadList;
    void conn();
};

#endif // DBFILETRANSFER_H
