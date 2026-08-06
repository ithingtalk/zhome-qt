#include <QByteArray>
#include <QCryptographicHash>
#include <QSslSocket>
#include <QDebug>
#include <QFile>
#include <QNetworkAddressEntry>
#include <QNetworkInterface>
#include <QSslConfiguration>
#include <QJsonObject>
#include <QJsonDocument>
#include "searchLocalIdevice.h"
#include "himsgcenter.h"

SearchLocalIdevice::SearchLocalIdevice(DbDevices &dbDevices, QObject *parent) : QObject(parent),
    m_dbDevices(dbDevices),
    tcpServer(new QTcpServer(this)),
    udpSocket(new QUdpSocket(this)),
    udpPort(8877),
    tcpPort(10001)
{
    qDebug() << "searchLocalIdevice";
    connect(tcpServer, &QTcpServer::newConnection, this, &SearchLocalIdevice::onNewConnection);
    const bool bindOk = udpSocket->bind(QHostAddress::AnyIPv4, 0, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint);
    if (!bindOk) {
        qDebug() << "udpSocket bind failed:" << udpSocket->errorString();
    } else {
        qDebug() << "udpSocket bound:" << udpSocket->localAddress().toString() << udpSocket->localPort();
    }

    connect(udpSocket, &QUdpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        qDebug() << "udpSocket error:" << udpSocket->errorString();
    });
    qDebug() << "searchLocalIdevice done";
}

void SearchLocalIdevice::delay1SStopServer()
{
    QTimer::singleShot(1000, this, [=]() { stopServer(); });
}

void SearchLocalIdevice::startServer(QString strMac)
{
    m_mac = strMac;
    if (tcpServer->isListening()) {
        stopServer();
    }
    if (tcpServer->listen(QHostAddress::Any, tcpPort)) {
        // qDebug() << "start server";
        sendBroadcast();
        delay1SStopServer();
    }
}

void SearchLocalIdevice::stopServer()
{
    // qDebug() << "stop server";
    tcpServer->close();
}

void SearchLocalIdevice::onNewConnection()
{
    QTcpSocket *clientSocket = tcpServer->nextPendingConnection();
    connect(clientSocket, &QTcpSocket::readyRead, this, &SearchLocalIdevice::readClient);
    connect(clientSocket, &QTcpSocket::disconnected, clientSocket, &QTcpSocket::deleteLater);
}

// 88366C5F38E5/99066345/zhome/1/192.168.1.158
void SearchLocalIdevice::readClient()
{
    QTcpSocket *clientSocket = qobject_cast<QTcpSocket*>(sender());
    if (clientSocket) {
        QByteArray data = clientSocket->readAll();
        QString decodedData = QByteArray::fromBase64(data);
        QStringList parts = decodedData.split('/');
        if (parts.length() == 5) {
            if (m_dbDevices.updateIp(parts[0], parts[1], parts[2], parts[3], parts[4])) {
                emit ipUpdated();
            }
            else {
                emit foundNewDevice(parts[0], parts[1], parts[2], parts[3], parts[4]);  // not in deviceDb, cfg=1 or cfg=0
            }
        }
    }
}

void SearchLocalIdevice::sendBroadcast()
{
    QString strCmd = (m_mac == "") ? P2P_CMD_TAG_BROADCAST_SEARCH_TNAS : (QString(P2P_CMD_TAG_BROADCAST_FIND_TNAS) + "/" + m_mac);
    QByteArray encodedMessage = strCmd.toUtf8().toBase64();

    QList<QHostAddress> targets;
    const QList<QNetworkInterface> interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : interfaces) {
        const auto flags = iface.flags();
        if (!(flags & QNetworkInterface::IsUp) ||
            !(flags & QNetworkInterface::IsRunning) ||
            !(flags & QNetworkInterface::CanBroadcast) ||
            (flags & QNetworkInterface::IsLoopBack)) {
            continue;
        }

        for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
            if (entry.ip().protocol() != QAbstractSocket::IPv4Protocol) {
                continue;
            }
            const QHostAddress bcast = entry.broadcast();
            if (!bcast.isNull() && !targets.contains(bcast)) {
                targets.append(bcast);
            }
        }
    }

    if (targets.isEmpty()) {
        targets.append(QHostAddress::Broadcast);
    }

    bool hasSuccess = false;
    for (const QHostAddress &target : targets) {
        const qint64 sent = udpSocket->writeDatagram(encodedMessage, target, udpPort);
        if (sent < 0) {
            qDebug() << "udpSocket send failed to" << target.toString() << ":" << udpSocket->errorString();
        } else {
            hasSuccess = true;
            qDebug() << "Broadcast sent, bytes:" << sent << "target:" << target.toString() << "payload:" << encodedMessage;
        }
    }

    if (!hasSuccess) {
        qDebug() << "Broadcast send failed for all targets, udpPort:" << udpPort;
    }
}
