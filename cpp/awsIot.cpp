#include "awsIot.h"
#include "globalCpp.h"
#include <string>
#include <aws/crt/Api.h>
#include <aws/crt/auth/Credentials.h>
#include <aws/iot/MqttClient.h>
#include <libp2p_export.h>

AwsIot::AwsIot(AwsAccount &awsAccount, QObject *parent) : m_awsAccount(awsAccount), QObject(parent), m_allocator(Aws::Crt::ApiAllocator())
{
    qDebug() << "awsIot";
    Aws::Utils::UUID uuid = Aws::Utils::UUID::RandomUUID();
    m_uuidStr = uuid;
    m_bDestroy = false;
    m_connection = NULL;
    InitP2p();
    qDebug() << "awsIot done";
}

AwsIot::~AwsIot()
{
    qDebug() << "awsIot destroy";
    libp2p_exit();
    m_bDestroy = true;
    // disconnIot(); // macos crash
    clearCred();
    qDebug() << "awsIot destroy done";
}

void AwsIot::conn()
{
    qDebug() << "awsIot conn";
    // connect(&g_app->awsDbService, &AwsDbService::pullAllSuccess, this, &AwsIot::onSigninSuccess);
    connect(&g_app->awsAccount, &AwsAccount::signInSuccess, this, &AwsIot::onSigninSuccess);
    connect(&g_app->dbDevices, &DbDevices::currDeviceChanged, this, &AwsIot::currDeviceChanged);
    // connect(&g_app->awsAccount, &AwsAccount::awsClientsReady, this, &AwsIot::InitP2p);
    qDebug() << "awsIot conn done";
}

// test call by ui
void AwsIot::getDeviceStatus()
{
    pub(g_app->nasApi.userGetStatus());
}

void AwsIot::restart()
{
    qDebug() << "awsIot: restart";
    m_connection = NULL;
    QTimer::singleShot(1000, this, [this]() { connIot(); });
}

QString AwsIot::getIotClientId()
{
    return m_uuidStr.c_str();
}

void AwsIot::onSigninSuccess()
{
    qDebug() << "awsIot: onSigninSuccess";
    if (!m_connection) {
        connIot();
    }
}

void AwsIot::currDeviceChanged()
{
    if (!m_connection && g_app->awsDbService.success()) {
        connIot();
    } else {
        resub();
    }
}

Aws::String AwsIot::subTopic()
{
    m_currSubtopic = g_app->dbDevices.curr.mac + "/" + m_uuidStr.c_str();
    return m_currSubtopic.toStdString();
}

Aws::String AwsIot::pubTopic()
{
    return (g_app->dbDevices.curr.mac + "/control").toStdString();
}

void AwsIot::resub()
{
    if (m_currSubtopic.isEmpty()) {
        return;
    }
    qDebug() << "unsub: " << m_currSubtopic;
    m_connection->Unsubscribe(m_currSubtopic.toStdString().c_str(), NULL);
    sub();
}

void AwsIot::sub()
{
    qDebug() << "sub: " << g_app->dbDevices.curr.mac << ", " << g_app->dbDevices.curr.name;

    auto onMsg = [&](MqttConnection &, const Aws::Crt::String &topic, const Aws::Crt::ByteBuf &payload) {
        const Aws::String strPayload(reinterpret_cast<const char*>(payload.buffer), payload.len);
        const QString decodedData = QByteArray::fromBase64(strPayload.c_str());
        if ( !libp2p_recv_p2p_cmd_from_iot(decodedData.toStdString().c_str()) ) {
            qDebug() << "unknown iot msg to app ??? " << decodedData;
            emit recvAppData(decodedData);
        }
    };

    auto onSub = [&](MqttConnection &, uint16_t packetId, const Aws::Crt::String &topic, QOS qos, int errorCode) {
        if (errorCode) {
            qDebug() << "===> iot subscribe error: " << errorCode;
            disconnIot();
        }
        else {
            qDebug() << "===> iot subscribe success. SUBACK id =" << packetId << ", topic =" << topic.c_str() << ", qos =" << qos;
            m_bConnected = true;
            m_bSubscribed = true;
            processPendingCmds();
            emit m_awsAccount.iotReady();
            startP2p();
            qDebug() << "===> startp2p done";
        }
    };

    if (!m_connection->Subscribe(subTopic().c_str(), QOS::AWS_MQTT_QOS_AT_LEAST_ONCE, onMsg, onSub)) {
        qDebug() << "===> iot Subscribe fail";
        disconnIot();
    }
    else {
        qDebug() << "===> iot Subscribing";
    }
}

bool AwsIot::connIot() {
    if ( m_bDestroy || g_app->dbDevices.curr.mac.isEmpty() || m_connection != NULL ) {
        qDebug() << "awsIot: connIot, invalid param";
        return true;
    }
    qDebug() << "awsIot: connIot";

    updateCred();

    std::shared_ptr<Aws::Crt::Auth::ICredentialsProvider> provider = nullptr;
    Aws::Crt::Auth::CredentialsProviderStaticConfig providerConfig;
    providerConfig.AccessKeyId = aws_byte_cursor_from_c_str(aws_string_c_str(m_accessKeyId));
    providerConfig.SecretAccessKey = aws_byte_cursor_from_c_str(aws_string_c_str(m_secretAccessKey));
    providerConfig.SessionToken = aws_byte_cursor_from_c_str(aws_string_c_str(m_sessionToken));
    provider = Aws::Crt::Auth::CredentialsProvider::CreateCredentialsProviderStatic(providerConfig);
    if (!provider) {
        qDebug() << "===> iot: provider failed";
        return false;
    }

    Aws::Iot::WebsocketConfig config(aws_string_c_str(m_region), provider);

    Aws::Iot::MqttClient client;
    auto clientConfigBuilder = Aws::Iot::MqttClientConnectionConfigBuilder(config);
    clientConfigBuilder.WithEndpoint(aws_string_c_str(m_endpoint));
    auto clientConfig = clientConfigBuilder.Build();
    if (!clientConfig) {
        qDebug() << "awsIot: connIot, null clientConfig";
        return false;
    }

    m_connection = client.NewConnection(clientConfig);
    if (!*m_connection) {
        qDebug() << "awsIot: null *m_connection";
        restart();
        return false;
    }

    auto onConnectionCompleted = [=](Aws::Crt::Mqtt::MqttConnection &, int errorCode, Aws::Crt::Mqtt::ReturnCode returnCode, bool) {
        (void)returnCode;
        if (errorCode) {
            qDebug() << "===> awsiot, Connection failed with error:" << errorCode;
            restart();
        } else {
            qDebug() << "===> awsiot, Connection succeeded";
            sub();
        }
    };

    auto onDisconnect = [=](Aws::Crt::Mqtt::MqttConnection &) {
        qDebug() << "===> awsiot, Disconnected ==========================";
        emit iotDisconnected();
        m_bConnected = false;
        restart();
    };

    m_connection->OnConnectionCompleted = std::move(onConnectionCompleted);
    m_connection->OnDisconnect = std::move(onDisconnect);

    qDebug() << "===> awsiot, clientid: " << m_uuidStr;

    // connect ===========================================================
    if (!m_connection->Connect(m_uuidStr.c_str(), true, 5000)) {
        qDebug() << "===> awsiot, Connect failed";
        return false;
    }
    // ===================================================================

    qDebug() << "===> awsiot, done";
    return true;
}

void AwsIot::disconnIot()
{
    m_bSubscribed = false;
    libp2p_leave_device();
    m_connection->Disconnect();
}

void AwsIot::pub(const QString strMsg)
{
    auto onPubCompleate = [&](MqttConnection &, uint16_t packetId, int errorCode) {
        if (errorCode) {
            qDebug() << "===> iot pub error, reconnect: " << errorCode;
            disconnIot();
        }
    };

    if (m_connection != NULL && m_bSubscribed) {
        qDebug() << "===> iot pub: " << strMsg.length() << ", " << strMsg;
        QByteArray strBase64 = strMsg.toUtf8().toBase64();
        Aws::Crt::ByteBuf payload = Aws::Crt::ByteBufFromArray((uint8_t*)strBase64.data(), strBase64.length());
        m_connection->Publish(pubTopic().c_str(), QOS::AWS_MQTT_QOS_AT_LEAST_ONCE, false, payload, onPubCompleate);
    } else {
        qDebug() << "===> iot not ready, queueing cmd: " << strMsg;
        m_pendingCmds.append(strMsg);

        // if not connected at all, trigger connection
        if (m_connection == NULL) {
            connIot();
        }
    }
}

void AwsIot::processPendingCmds()
{
    if (m_pendingCmds.isEmpty()) return;
    qDebug() << "===> processing pending cmds: " << m_pendingCmds.size();
    while(!m_pendingCmds.isEmpty()) {
        QString msg = m_pendingCmds.takeFirst();
        pub(msg);
    }
}

void AwsIot::clearCred()
{
    if (m_endpoint) {
        aws_string_destroy(m_endpoint);
        aws_string_destroy(m_region);
        aws_string_destroy(m_accessKeyId);
        aws_string_destroy(m_secretAccessKey);
        aws_string_destroy(m_sessionToken);
    }
}

void AwsIot::updateCred()
{
    clearCred();
    m_endpoint = aws_string_new_from_c_str(m_allocator, m_awsAccount.getIotHost().c_str());
    m_region = aws_string_new_from_c_str(m_allocator, m_awsAccount.getRegion().c_str());
    m_accessKeyId = aws_string_new_from_c_str(m_allocator, m_awsAccount.getCdt().GetAWSAccessKeyId().c_str());
    m_secretAccessKey = aws_string_new_from_c_str(m_allocator, m_awsAccount.getCdt().GetAWSSecretKey().c_str());
    m_sessionToken = aws_string_new_from_c_str(m_allocator, m_awsAccount.getCdt().GetSessionToken().c_str());
}

bool AwsIot::isReady()
{
    return m_bConnected;
}

extern "C" void iot_send(const char* pMsg)
{
    g_app->awsIot.pub(pMsg);
}

extern "C" void p2p_recv_cb(const char* pMsg)
{
    // qDebug() << "recv p2p msg from p2p module: " << pMsg;
    if (g_app->useLocalLink()) {
        qDebug() << "local link, ignore p2p message";
        return;
    }

    QString strFileStatus = g_app->nasApi.fileStatusFromP2pCmd(pMsg);
    QString strFileName = g_app->nasApi.fileNameFromP2pCmd(pMsg);
    QString strFileRemoteName = g_app->nasApi.fileRemoteNameFromP2pCmd(pMsg);
    QString strFileSize = g_app->nasApi.fileSizeFromP2pCmd(pMsg);
    QString strFileOffset = g_app->nasApi.fileOffsetFromP2pCmd(pMsg);
    QString strFileChType = g_app->nasApi.fileChTypeFromP2pCmd(pMsg);
    LocalFileService *pFileService = NULL;

    /*
    qDebug() << "strFileStatus: " << strFileStatus;
    qDebug() << "strFileName: " << strFileName;
    qDebug() << "strFileRemoteName: " << strFileRemoteName;
    qDebug() << "strFileSize: " << strFileSize;
    qDebug() << "strFileOffset: " << strFileOffset;
    qDebug() << "strFileChType: " << strFileChType;
    */

    if (strFileRemoteName.isEmpty() || strFileName.isEmpty() || strFileStatus.isEmpty() || strFileSize.isEmpty() || strFileOffset.isEmpty() || strFileChType.isEmpty()) {
        qDebug() << "p2p_recv_cb: empty ctx";
        return;
    }

    if (strFileRemoteName.contains("/.btFiles/")) { // bt upload and download
        pFileService = &g_app->btFileService;
    }
    else if (strFileRemoteName.contains(QLatin1String("DB/"))) { // user db and share db download
        if (strFileRemoteName.contains(QLatin1String("DB/SHARED/shared.db"))) {
            pFileService = &g_app->dbFilesShared.m_fileService;
        }
        else {
            pFileService = &g_app->dbFiles.m_fileService;
        }
    }
    else if (strFileChType == "upload") {
        pFileService = &g_app->uploadsFileService;
    }
    else { // other download
        if (strFileName.startsWith(LocalSettings::cacheDir())) {
            if (strFileRemoteName.contains("Doc/")) { // preview doc
                pFileService = &g_app->previewDocFileService;
            }
            else { // if (strFileRemoteName.contains("Image/")) { // preview image
                pFileService = &g_app->previewImageFileService;
            }
        }
        else { // if (strFileName.startsWith(LocalSettings::downloadDir())) { // download normal file
            pFileService = &g_app->downloadsFileService;
        }
    }

    if (strFileStatus.contains(P2P_CMD_FILE_SUCCESSED)) {
        emit ( strFileChType == "upload" ? pFileService->uploadFinishedSlot() : pFileService->downloadFinishedSlot() );
    }
    else if (strFileStatus.contains(P2P_CMD_FILE_TERMINATED)) {
        emit ( strFileChType == "upload" ? pFileService->uploadErrorSlot(QNetworkReply::NetworkError::UnknownNetworkError) : pFileService->downloadErrorSlot(QNetworkReply::NetworkError::UnknownNetworkError) );
    }
    else if (strFileStatus.contains(P2P_CMD_FILE_SENDING)) {
        emit pFileService->uploadProgressSlot(strFileOffset.toLongLong(), strFileSize.toLongLong());
    }
    else { // if (strFileStatus.contains(P2P_CMD_FILE_RECEIVING)) {
        emit pFileService->downloadProgressSlot(strFileOffset.toLongLong(), strFileSize.toLongLong());
    }
}

void AwsIot::InitP2p(void)
{
    // iceGatherMode: 0=both STUN+TURN (settings may call libp2p_update_ice_gather_mode later).
    libp2p_init(iot_send, p2p_recv_cb, 0);
}

void AwsIot::bindP2pDevice()
{
    const std::string home = LocalSettings::downloadDir().toStdString();
    const std::string cache = LocalSettings::cacheDir().toStdString();
    const std::string clientId = getIotClientId().toStdString();
    const std::string nasId = g_app->dbDevices.curr.mac.toStdString();
    if (home.empty() || cache.empty() || clientId.empty() || nasId.empty()) {
        qWarning() << "libp2p_into_device skipped: empty home/cache/clientId/nasId";
        return;
    }
    qDebug() << "libp2p_into_device clientId=" << clientId.c_str() << "nasId=" << nasId.c_str();
    libp2p_into_device(home.c_str(), cache.c_str(), clientId.c_str(), nasId.c_str());
}

void AwsIot::p2p_upload_file(const QString strLocalAPath, const QString strRemoteAPath)
{
    QString strRemoteRPath = g_app->nasApi.p2pRemotePathFromHttpsUrl(strRemoteAPath);
    qDebug() << "set_p2p_upload_file:";
    qDebug() << strLocalAPath << " -> " << strRemoteAPath;
    qDebug() << "strRemote: " << strRemoteRPath;

    bindP2pDevice();
    const std::string localPath = strLocalAPath.toStdString();
    const std::string remotePath = strRemoteRPath.toStdString();
    libp2p_upload_file(localPath.c_str(), remotePath.c_str());
}

void AwsIot::p2p_download_file(const QString strRemoteAPath, const QString strLocalAPath)
{
    QString strRemoteRPath = g_app->nasApi.p2pRemotePathFromHttpsUrl(strRemoteAPath);
    qDebug() << "===> p2p download file: " << strLocalAPath << " <- " << strRemoteAPath;
    qDebug() << "===> p2p remote: " << strRemoteRPath;

    // remote uncomplete download previus
    if (strLocalAPath == g_app->dbFiles.localDbFileNew() || strLocalAPath == g_app->dbFilesShared.localDbFileNew()) {
        qDebug() << "remote previus uncomplete download: " << strLocalAPath;
        QFile::remove(strLocalAPath);
    }

    bindP2pDevice();
    const std::string remotePath = strRemoteRPath.toStdString();
    const std::string localPath = strLocalAPath.toStdString();
    libp2p_download_file(remotePath.c_str(), localPath.c_str());
}

void AwsIot::startP2p()
{
    qDebug() << "startP2p: bind device context for libip2p";
    bindP2pDevice();
}
