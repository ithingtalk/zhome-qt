#ifndef SEARCHLOCALIDEVICE_H
#define SEARCHLOCALIDEVICE_H

#include "dbDevices.h"
#include <QQmlEngine>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QUdpSocket>

// localcmd
//#define P2P_CMD_TAG_BROADCAST_SEARCH_TNAS   "T-NAS?"
//#define HI_LOCALCMD_PORT 						"12345"

class SearchLocalIdevice : public QObject
{
    Q_OBJECT

public:
    explicit SearchLocalIdevice(DbDevices &dbDevices, QObject *parent = nullptr);

signals:
    void foundNewDevice(const QString strMac, const QString strSn, const QString strName, const QString strCfg, const QString strIp);
    void configureReturn(const bool bReturn);
    void ipUpdated();

public slots:
    void startServer(QString strMac = "");

private:
    void stopServer();
    void onNewConnection();
    void readClient();
    void sendBroadcast();
    void StopSearch();

private:
    QTcpServer *tcpServer;
    QUdpSocket *udpSocket;
    quint16 udpPort;
    quint16 tcpPort;
    int broadcastCount;
    QString m_mac;
    void delay1SStopServer();
    DbDevices &m_dbDevices;
};

#endif // SEARCHLOCALIDEVICE_H
