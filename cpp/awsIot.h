#ifndef AWSIOT_H
#define AWSIOT_H

#include "awsAccount.h"
#include "dbDevices.h"
#include <QQmlEngine>
#include <aws/crt/Allocator.h>
#include <aws/crt/mqtt/MqttTypes.h>

using namespace Aws::Crt;
using namespace Aws::Crt::Mqtt;

class AwsIot : public QObject
{
    Q_OBJECT

public:
    explicit AwsIot(AwsAccount &awsAccount, QObject *parent = nullptr);
    ~AwsIot();
    void conn();
    QString getIotClientId();
    bool isReady();
    bool connIot();
    void startP2p();
    void p2p_upload_file(const QString strLocalAPath, const QString strRemoteRPath);
    void p2p_download_file(const QString strRemoteRPath, const QString strLocalAPath);

public slots:
    void pub(const QString strMsg);
    void getDeviceStatus();

signals:
    void receivedP2pCmd(QString strSdp);
    void receivedCmd(QString strSdp);
    void iotDisconnected();
    void recvAppData(QString strMsg);

private:
    Aws::Crt::Allocator *m_allocator;
    AwsAccount &m_awsAccount;
    Aws::String m_uuidStr;
    bool m_bConnected = false;
    std::shared_ptr<Aws::Crt::Mqtt::MqttConnection> m_connection;
    struct aws_string *m_endpoint = NULL;
    struct aws_string *m_region = NULL;
    struct aws_string *m_accessKeyId = NULL;
    struct aws_string *m_secretAccessKey = NULL;
    struct aws_string *m_sessionToken = NULL;
    void clearCred();
    void updateCred();
    void disconnIot();
    Aws::String subTopic();
    Aws::String pubTopic();
    void onSigninSuccess();
    void currDeviceChanged();
    Aws::String m_iotClientId;
    bool m_bDestroy = false;
    QString m_currSubtopic;
    void sub();
    void resub();
    void restart();
    void InitP2p();
    /** Bind home/cache/IoT client/NAS id into libip2p (required before upload/download). */
    void bindP2pDevice();
    void processPendingCmds();
    QList<QString> m_pendingCmds;
    bool m_bSubscribed = false;
};

#endif // AWSIOT_H
