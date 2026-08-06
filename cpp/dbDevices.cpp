#include <algorithm>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QtSql/qsqlerror.h>
#include "globalCpp.h"
#include "localSettings.h"
#include "dbDevices.h"

DbDevices::DbDevices(QObject *parent) : QObject(parent)
{
    qDebug() << "dbDevices";
    opendb();
    qDebug() << "dbDevices done";
}

void DbDevices::conn()
{
    qDebug() << "dbDevices conn";
    connect(&g_app->awsDbService, &AwsDbService::addSuccess, this, &DbDevices::add_done);
    connect(&g_app->awsDbService, &AwsDbService::delSuccess, this, &DbDevices::del_done);
    connect(&g_app->awsDbService, &AwsDbService::pullAdd, this, &DbDevices::awsPullAdd);
    qDebug() << "dbDevices conn done";
}

DbDevices::~DbDevices()
{
    qDebug() << "dbDevices destroy";
    closedb();
    qDebug() << "dbDevices destroy done";
}

void DbDevices::awsPullAdd(const QString strMac, const QString strSn, const QString strName, const QString strOnline)
{
    qDebug() << "DbDevices: pullAdd = " << strName;
    QString strIp = "";
    QString strPending = pendingString(PendingStatus::None);
    QList<DbDeviceData> dataList = all();
    dataList.append(all(PendingStatus::Add));
    for (int idx = 0; idx < dataList.length(); idx++) {
        if (dataList[idx].mac == strMac) {
            strIp = dataList[idx].ip;
            strPending = dataList[idx].pending;
            break;
        }
    }
    add(strMac, strSn, strName, strIp, pendingVal(strPending), strOnline);
}

bool DbDevices::updateIp(const QString strMac, const QString strSn, const QString strName, const QString strCfg, const QString strIp)
{
    if (strCfg == "1") {
        QList<DbDeviceData> dataList = all();
        dataList.append(all(PendingStatus::Add));
        for (int idx = 0; idx < dataList.length(); idx++) {
            if (dataList[idx].mac == strMac) {
                if (dataList[idx].ip != strIp) {
                    add(strMac, strSn, strName, strIp, pendingVal(dataList[idx].pending), dataList[idx].online);
                    emit dataChanged();
                }
                return true;
            }
        }
    }
    return false;
}

bool DbDevices::useLocalLink()
{
    return !LocalSettings::getForceP2p() && !curr.ip.isEmpty();
}

void DbDevices::clearIp()
{
    QList<DbDeviceData> dataList = all();
    dataList.append(all(PendingStatus::Add));
    for (int idx = 0; idx < dataList.length(); idx++) {
        if (dataList[idx].ip != "") {
            add(dataList[idx].mac, dataList[idx].sn, dataList[idx].name, "", pendingVal(dataList[idx].pending), dataList[idx].online);
        }
    }
}

void DbDevices::intoDevice(const QString strMac, const QString strSn, const QString strName, QString strCfg, const QString strIp)
{
    qDebug() << "intoDevice: " << strIp << ", mac: " << strMac << ", sn: " << strSn << ", name: " << strName << ", iscfg: " << strCfg;
    curr.sn = strSn;
    curr.name = strName;
    curr.cfg = strCfg;
    curr.ip = strIp;
    if (curr.mac != strMac) {
        curr.mac = strMac;
        if (strCfg == "1") {
            QDir().mkpath(LocalSettings::configDir() + "/" + g_app->dbDevices.curr.mac);
            emit currDeviceChanged();
        }
        else {
            qDebug() << "cfg device: " << strMac;
        }
    }
}

bool DbDevices::opendb()
{
    m_path = LocalSettings::configDir() + "/device.db";
    qDebug() << "open: " << m_path;
    if (QSqlDatabase::contains("zhome_db_devices_connection")) {
        m_db = QSqlDatabase::database("zhome_db_devices_connection");
    } else {
        m_db = QSqlDatabase::addDatabase("QSQLITE", "zhome_db_devices_connection");
    }
    m_db.setDatabaseName(m_path);
    if (!m_db.open()) { // open db, and check the result
        qWarning() << "dbdevices: open database fail: " << m_db.lastError().text();
        return false;
    }
    QSqlQuery query(m_db);
    if (!query.exec("CREATE TABLE IF NOT EXISTS device(mac TEXT PRIMARY KEY, sn TEXT, name TEXT, ip TEXT, pending TEXT, online TEXT)")) {
        qWarning() << "dbdevices: create table fail: " << query.lastError().text();
    }
    qDebug() << "dbDevices.cpp, opendb done";
    return true;
}

void DbDevices::closedb()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

/*
    Add or Change a device record, use INSERT or REPLACE DB Cmd.
*/
bool DbDevices::add(const QString strMac, const QString strSn, const QString strName, const QString strIp, const PendingStatus ePending, const QString strOnline)
{
    if (!m_db.isOpen()) {
        qWarning("add: open db fail");
        return false;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString("INSERT OR REPLACE INTO device(mac, sn, name, ip, pending, online) VALUES (:mac, :sn, :name, :ip, :pending, :online)");
    query.prepare(sqlStr);
    query.bindValue(":mac", strMac);
    query.bindValue(":sn", strSn);
    query.bindValue(":name", strName);
    query.bindValue(":ip", strIp);
    query.bindValue(":pending", pendingString(ePending));
    query.bindValue(":online", strOnline);
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
    emit dataChanged();
    if (ePending == PendingStatus::Add)
        emit addOne(strMac, strSn, strName);
    return true;
}

bool DbDevices::pending(const QString strMac, PendingStatus ePending)
{
    // qDebug() << "pending: " << pendingString(ePending);
    if (!m_db.isOpen()) {
        qDebug() << "pending: open db fail, " + pendingString(ePending);
        return false;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString("UPDATE device SET pending = :pending WHERE mac = :mac");
    query.prepare(sqlStr);
    query.bindValue(":mac", strMac);
    query.bindValue(":pending", pendingString(ePending));
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
    emit dataChanged();
    return true;
}

bool DbDevices::del(const QString strMac)
{
    bool bRet = pending(strMac, PendingStatus::Del);
    emit delOne(strMac);
    return bRet;
}

bool DbDevices::add_done(const QString strMac)
{
    return pending(strMac, PendingStatus::None);
}

bool DbDevices::del_done(const QString strMac)
{
    qDebug() << "dbDevices.cpp: del_done";
    if (!m_db.isOpen()) {
        qWarning("del: open db fail");
        return false;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString("DELETE FROM device WHERE mac = :mac");
    query.prepare(sqlStr);
    query.bindValue(":mac", strMac);
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
    emit dataChanged();
    return true;
}

/*
int DbDevices::count()
{
    if (!m_db.isOpen()) {
        qWarning("count: open db fail");
        return 0;
    }
    QSqlQuery query(m_db);
    QString sqlStr = "SELECT COUNT(*) FROM device";
    if (query.exec(sqlStr) && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}
*/

QList<DbDeviceData> DbDevices::all(PendingStatus pending)
{
    QList<DbDeviceData> pRetDeviceList = QList<DbDeviceData>();
    if (!m_db.isOpen()) {
        qWarning("all: open db fail");
        return pRetDeviceList;
    }
    QSqlQuery query(m_db);
    QString sqlStr = QString(
        "SELECT mac, sn, name, ip, online, pending FROM device WHERE pending = :pending ORDER BY name COLLATE NOCASE");
    query.prepare(sqlStr);
    query.bindValue(":pending", pendingString(pending));
    m_db.transaction();
    if (!query.exec()) {
        qWarning() << "all: query exec fail: " << query.lastError().text();
        return pRetDeviceList;
    }
    // qDebug() << "dbdevices.cpp: get all devices: ";
    while (query.next()) {
        DbDeviceData dataNow;
        dataNow.mac = query.value(0).toString();
        dataNow.sn = query.value(1).toString();
        dataNow.name = query.value(2).toString();
        dataNow.ip = query.value(3).toString();
        dataNow.online = query.value(4).toString();
        dataNow.pending = query.value(5).toString();
        pRetDeviceList.append(dataNow);
        // qDebug() << "mac: " << dataNow.mac << ", sn: " << dataNow.sn << ", name: " << dataNow.name << ", ip: " << dataNow.ip;
    }
    return pRetDeviceList;
}

QList<DbDeviceData> DbDevices::pendings_add() { return all(PendingStatus::Add); }
QList<DbDeviceData> DbDevices::pendings_del() { return all(PendingStatus::Del); }

bool DbDevices::empty()
{
    if (!m_db.isOpen()) {
        qWarning("empty: open db fail");
        return false;
    }
    QSqlQuery query(m_db);
    m_db.transaction();
    query.prepare("DELETE FROM device");
    if (!query.exec()) {
        m_db.rollback();
        qWarning() << "empty: query exec fail: " << query.lastError().text();
        return false;
    }
    if (!m_db.commit()) {
        qWarning() << "empty: commit fail: " << query.lastError().text();
        return false;
    }
    emit dataChanged();
    return true;
}

void DbDevices::add_test_devices()
{
    add("784476000001", "11111111", "Test111");
    add("784476000002", "22222222", "Test222");
    add("784476000003", "33333333", "Test333");
}

void DbDevices::empty_devices()
{ // delete db file and create new
    closedb();
    QFile::remove(m_path);
    opendb();
    emit dataChanged();
}

QVariantList DbDevices::getAll()
{
    QVariantList pRetDeviceList = QVariantList();
    QList<DbDeviceData> dataList = all();
    dataList.append(all(PendingStatus::Add));
    // 列表默认按设备名称排序；若以后支持按其它字段排序，可改为可配置比较器。
    std::sort(dataList.begin(), dataList.end(), [](const DbDeviceData &a, const DbDeviceData &b) {
        return QString::localeAwareCompare(a.name, b.name) < 0;
    });
    for (int i = 0; i < dataList.size(); i++) {
        const DbDeviceData *dataNow = &dataList.at(i);
        QVariantMap map;
        map["devmac"] = dataNow->mac;
        map["devsn"] = dataNow->sn;
        map["devname"] = dataNow->name;
        map["devip"] = dataNow->ip;
        map["online"] = dataNow->online;
        pRetDeviceList.append(map);
    }
    return pRetDeviceList;
}

void DbDevices::reset() {
    closedb();
    opendb();
}

QString DbDevices::pendingString(PendingStatus pending)
{
    switch (pending) {
        case PendingStatus::None: return "None";
        case PendingStatus::Add: return "Add";
        case PendingStatus::Del: return "Del";
        default:
            return "";
    }
}

PendingStatus DbDevices::pendingVal(QString strPending)
{
    if (strPending == "None") return PendingStatus::None;
    if (strPending == "Add") return PendingStatus::Add;
    if (strPending == "Del") return PendingStatus::Del;
    return PendingStatus::None;
}

QString DbDevices::buildQrSharePayload()
{
    const QString mac = curr.mac.trimmed();
    if (mac.isEmpty() || !m_db.isOpen())
        return {};

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT mac, sn, name, ip, online, pending FROM device WHERE mac = :mac AND IFNULL(pending,'') != 'Del' LIMIT 1"));
    query.bindValue(QStringLiteral(":mac"), mac);
    if (!query.exec() || !query.next())
        return {};

    QJsonObject o;
    o.insert(QStringLiteral("v"), 2);
    o.insert(QStringLiteral("m"), query.value(0).toString());
    o.insert(QStringLiteral("s"), query.value(1).toString());
    o.insert(QStringLiteral("n"), query.value(2).toString());
    o.insert(QStringLiteral("i"), query.value(3).toString());
    o.insert(QStringLiteral("c"), curr.cfg);
    o.insert(QStringLiteral("o"), query.value(4).toString());
    o.insert(QStringLiteral("p"), query.value(5).toString());

    const QJsonDocument doc(o);
    return QStringLiteral("zh2:") + QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
}
