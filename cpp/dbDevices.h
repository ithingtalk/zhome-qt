#ifndef DBDEVICES_H
#define DBDEVICES_H

#include <QQmlEngine>
#include <QSqlDatabase>
#include <QString>

//============================= device sql ==================================
//#define DEVICEDB_CREATE_TABLE "CREATE TABLE IF NOT EXISTS device(mac TEXT PRIMARY KEY, sn TEXT, name TEXT, cfg TEXT, ip TEXT);"
//#define DEVICEDB_TRUNCATE "TRUNCATE TABLE device" // 高效，但受外键约束, 某些数据库中，如果表有外键引用，TRUNCATE TABLE 可能会失败
//#define DEVICEDB_EMPTY "DELETE FROM device;"
//#define DEVICEDB_SET "INSERT or REPLACE INTO device(mac, sn, name, cfg, ip) VALUES (:mac, :sn, :name, :cfg, :ip)"
//#define DEVICEDB_COUNT "select count(*) FROM device"
//#define DEVICEDB_GET "SELECT name,sn FROM device where mac = :mac;"
//#define DEVICEDB_GET_ALL "SELECT * FROM device;"
//#define DEVICEDB_DELETE "DELETE FROM device where mac = :mac;"
//===========================================================================

enum class PendingStatus {
    None,
    Add,
    Del
};

class DbDeviceData
{ // 88366C5F38E5/99066345/zhome/1/192.168.1.158
public:
    QString mac = "";
    QString sn = "";
    QString name = "";
    QString cfg = "";
    QString ip = "";
    QString online = "";
    QString pending = "";
};

class DbDevices: public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit DbDevices(QObject *parent = nullptr);
    ~DbDevices();
    bool opendb();
    void closedb();
    QList<DbDeviceData> all(PendingStatus pending = PendingStatus::None);
    DbDeviceData curr;
    bool add_done(const QString strMac);
    bool del_done(const QString strMac);
    QList<DbDeviceData> pendings_add();
    QList<DbDeviceData> pendings_del();
    void conn();
    bool updateIp(const QString strMac, const QString strSn, const QString strName, const QString strCfg, const QString strIp);
    bool useLocalLink();
public slots:
    bool add(const QString strMac, const QString strSn, const QString strName, const QString strIp = "", const PendingStatus ePending = PendingStatus::Add, const QString strOnline = "default");
    bool empty();
    void add_test_devices();
    void empty_devices();
    QVariantList getAll();
    void intoDevice(const QString strMac = "", const QString strSn = "", const QString strName = "", QString cfg = "", const QString strIp = "");
    void reset();
    bool del(const QString strMac);
    void clearIp();
    /** 当前设备完整库信息 JSON（前缀 zh2:），供 [Qrcode.qml] 生成二维码；与 Android [DeviceQrPayload] 一致。 */
    Q_INVOKABLE QString buildQrSharePayload();
signals:
    void dataChanged();
    void pullAll();
    void addOne(const QString strMac, const QString strSn, const QString strName);
    void delOne(const QString strMac);
    void currDeviceChanged();
private:
    QSqlDatabase m_db;
    QString m_path;
    QString pendingString(PendingStatus pending);
    bool pending(const QString strMac, PendingStatus pad);
    void awsPullAdd(const QString strMac, const QString strSn, const QString strName, const QString strOnline);
    QList<DbDeviceData> m_ips;
    PendingStatus pendingVal(QString strPending);
};

#endif // DBDEVICES_H
