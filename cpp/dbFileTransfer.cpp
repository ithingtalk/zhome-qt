#include <QStandardPaths>
#include <QUrl>
#include <QDesktopServices>
#include <QSqlQuery>
#include <QtSql/qsqlerror.h>
#include "dbFileTransfer.h"
#include "globalCpp.h"
#include "localSettings.h"

DbFileTransfer::DbFileTransfer(QObject *parent) : QObject(parent)
{
    qDebug() << "dbfiletransfer done";
}

DbFileTransfer::~DbFileTransfer()
{
    qDebug() << "dbfiletransfer destroy";
    stop(TYPE_UPLOAD);
    stop(TYPE_DOWNLOAD);
    closedb();
    qDebug() << "dbfiletransfer destroy done";
}

void DbFileTransfer::conn()
{
    qDebug() << "dbfiletransfer conn";
    connect(&g_app->dbDevices, &DbDevices::currDeviceChanged, this, &DbFileTransfer::reset);
    qDebug() << "dbfiletransfer conn done";
}

bool DbFileTransfer::opendb()
{
    if (g_app->dbDevices.curr.mac.isEmpty()) {
        qDebug() << "dbFileTransfer.cpp, opendb, no dbDevices.curr.mac, ignore";
        return false;
    }
    m_path = LocalSettings::configDir() + "/" + g_app->dbDevices.curr.mac + "/transfer.db";
    qDebug() << "dbfiletransfer: " << m_path;
    if (QSqlDatabase::contains("zhome_db_transfer_connection")) {
        m_db = QSqlDatabase::database("zhome_db_transfer_connection");
    } else {
        m_db = QSqlDatabase::addDatabase("QSQLITE", "zhome_db_transfer_connection");
    }
    m_db.setDatabaseName(m_path);

    if (!m_db.open()) { // open db, and check the result
        qWarning() << "dbtransfer: open database fail: " << m_db.lastError().text();
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.exec("CREATE TABLE IF NOT EXISTS transfer(fpath TEXT PRIMARY KEY, lpath TEXT, ftype integer, fstatus integer)")) {
        qWarning() << "dbtransfer: create table fail: " << query.lastError().text();
    }

    return true;
}

void DbFileTransfer::closedb()
{
    if (m_db.isOpen()) {
        m_db.close();
        qDebug() << "dbtransfer: closedb done";
    }
}

bool DbFileTransfer::add(const qint64 iType, const QString& strPath, const QString& strLocalPath, const qint64 bStarted)
{
    qDebug() << "add, type: " << iType;
    if (!m_db.isOpen()) {
        qWarning("add: open db fail");
        return false;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString("INSERT OR REPLACE INTO transfer(fpath,lpath,ftype,fstatus) VALUES (:fpath,:lpath,:ftype,:fstatus)");
    query.prepare(sqlStr);
    query.bindValue(":fpath", strPath);
    query.bindValue(":lpath", strLocalPath);
    query.bindValue(":ftype", iType);
    query.bindValue(":fstatus", bStarted);
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

    postDataChanged(iType);
    return true;
}

bool DbFileTransfer::del(const qint64 iType, const QString& strPath)
{
    if (!m_db.isOpen()) {
        qWarning("del: open db fail");
        return false;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString("DELETE FROM transfer WHERE ftype = :ftype AND fpath = :fpath");
    query.prepare(sqlStr);
    query.bindValue(":ftype", iType);
    query.bindValue(":fpath", strPath);
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

    postDataChanged(iType);

    return true;
}

bool DbFileTransfer::startStop(const qint64 iType, const qint64 bStatus, const QString& strPath)
{
    if (!m_db.isOpen()) {
        qWarning("del: open db fail");
        return false;
    }

    qDebug() << "===> startStop, " << "type=" << iType << ", status=" << bStatus << ", path=" << strPath;

    QSqlQuery query(m_db);
    QString sqlStr = QString("UPDATE transfer SET fstatus = :fstatus WHERE ftype = :ftype %1")
                     .arg(strPath.isEmpty() ? "" : "AND fpath = :fpath");
    
    query.prepare(sqlStr);
    query.bindValue(":fstatus", bStatus);
    query.bindValue(":ftype", iType);
    if (!strPath.isEmpty()) {
        query.bindValue(":fpath", strPath);
    }

    m_db.transaction();
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "start query exec fail: " << query.lastError().text();
        return false;
    }
    if (!m_db.commit()) {
        qWarning() << "start commit fail: " << query.lastError().text();
        return false;
    }

    postDataChanged(iType);
    return true;
}

bool DbFileTransfer::start(const qint64 iType, const QString& strPath)
{
    return startStop(iType, started_status(), strPath);
}

bool DbFileTransfer::stop(const qint64 iType, const QString& strPath)
{
    return startStop(iType, stopped_status(), strPath);
}

int DbFileTransfer::count()
{
    if (!m_db.isOpen()) {
        qWarning("count: open db fail");
        return 0;
    }

    QSqlQuery query(m_db);
    QString sqlStr = "SELECT COUNT(*) FROM transfer";
    if (query.exec(sqlStr) && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

QList<DbTransferData> DbFileTransfer::all(const qint64 iType)
{
    QList<DbTransferData> pRet = QList<DbTransferData>();

    if (!m_db.isOpen()) {
        qWarning("all: open db fail");
        return pRet;
    }

    if (count() <= 0) {
        return pRet;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString(
        "SELECT fpath,lpath,ftype,fstatus FROM transfer WHERE ftype = :ftype ORDER BY fpath COLLATE NOCASE");
    query.prepare(sqlStr);
    query.bindValue(":ftype", iType);
    m_db.transaction();
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "all query exec fail: " << query.lastError().text();
        return pRet;
    }
    if (!m_db.commit()) {
        qWarning() << "all commit fail: " << query.lastError().text();
        return pRet;
    }

    while (query.next()) {
        DbTransferData dataNow;
        dataNow.fpath = query.value(0).toString();
        dataNow.lpath = query.value(1).toString();
        dataNow.ftype = query.value(2).toLongLong();
        dataNow.fstatus = query.value(3).toLongLong();
        pRet.append(dataNow);
    }

    return pRet;
}

void DbFileTransfer::postDataChanged(const qint64 iType)
{
    // update active list
    QList<DbTransferData> &currList = (iType == TYPE_UPLOAD ? uploadList : downloadList);
    QList<DbTransferData> sAll = all(iType);

    currList.clear();

    if (sAll.empty()) {
        qDebug() << "activeList: " << iType << "set to empty";
    }
    else {
        qDebug() << "";
        for (DbTransferData& sData: sAll) {
            if (sData.fstatus == started_status()) {
                currList.append(sData);
                qDebug() << "activeList: " << iType << ", append " << sData.fpath << "<==>" << sData.lpath;
            }
        }
        qDebug() << "";
    }

    emit transferDataChanged(iType);
}

bool DbFileTransfer::empty(const qint64 iType)
{
    if (!m_db.isOpen()) {
        qWarning("empty: open db fail");
        return false;
    }

    QSqlQuery query(m_db);
    QString sqlStr = QString("DELETE FROM transfer WHERE ftype = :ftype");
    query.prepare(sqlStr);
    query.bindValue(":ftype", iType);
    m_db.transaction();
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "empty: query exec fail: " << query.lastError().text();
        return false;
    }
    if (!m_db.commit()) {
        qWarning() << "empty: commit fail: " << query.lastError().text();
        return false;
    }

    postDataChanged(iType);

    return true;
}

void DbFileTransfer::empty_all()
{ // delete db file and create new
    closedb();
    QFile::remove(m_path);
    opendb();

    postDataChanged(TYPE_UPLOAD);
    postDataChanged(TYPE_DOWNLOAD);
}

QVariantList DbFileTransfer::getAll(const qint64 iType)
{
    QVariantList pRet = QVariantList();
    QList<DbTransferData> dataList = all(iType);
    for (int i = 0; i < dataList.size(); ++i) {
        const DbTransferData *dataNow = &dataList.at(i);
        QVariantMap map;
        map["transferPath"] = dataNow->fpath;
        map["transferLPath"] = dataNow->lpath;
        map["transferType"] = dataNow->ftype;
        map["transferStatus"] = dataNow->fstatus;
        pRet.append(map);
    }
    return pRet;
}

int DbFileTransfer::upload_type()
{
    return TYPE_UPLOAD;
}

int DbFileTransfer::download_type()
{
    return TYPE_DOWNLOAD;
}

int DbFileTransfer::started_status()
{
    return STATUS_STARTED;
}

int DbFileTransfer::stopped_status()
{
    return STATUS_STOPPED;
}

void DbFileTransfer::openDownloadDir()
{
    QUrl url = QUrl::fromLocalFile(LocalSettings::downloadDir());
    QDesktopServices::openUrl(url);
}

void DbFileTransfer::reset() {
    closedb();
    opendb();
}
