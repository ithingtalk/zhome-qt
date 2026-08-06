#include "cmdService.h"
#include "globalCpp.h"
#include <libp2p_export.h>

CmdService::CmdService(QObject *parent) : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{
    m_cmdService_id = Utils::generateRandomString();
    qDebug() << "cmdService id: " << m_cmdService_id;
    connect(m_networkManager, &QNetworkAccessManager::authenticationRequired, this, &CmdService::onAuthenticationRequired);
    connect(m_networkManager, &QNetworkAccessManager::finished, this, &CmdService::onFinished);
    connect(m_networkManager, QOverload<QNetworkReply *, const QList<QSslError> &>::of(&QNetworkAccessManager::sslErrors), this, &CmdService::onSslErrors);
    qDebug() << "cmdService done";
}

CmdService::~CmdService()
{
    qDebug() << "CmdService destroy done";
}

void CmdService::conn(AwsIot &iot)
{
    qDebug() << "cmdService conn";
    connect(&iot, &AwsIot::recvAppData, this, &CmdService::onP2pCmdFinished);
    qDebug() << "cmdService conn done";
}

void CmdService::send(const QString &strCommand, const QString strUser, const QString strPass, int transferTimeoutMs)
{
    if (g_app->useLocalLink()) { // local link
        QUrl url(g_app->nasApi.cmdUrlString());
        QNetworkRequest request(url);
        if (transferTimeoutMs > 0) {
            request.setTransferTimeout(transferTimeoutMs);
        }
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

        QSslConfiguration config = request.sslConfiguration();
        // config.setProtocol(QSsl::TlsV1_2OrLater);
        config.setPeerVerifyMode(QSslSocket::VerifyNone);
        request.setSslConfiguration(config);

        QUrlQuery postData;
        postData.addQueryItem("command", strCommand.toUtf8().toBase64()); // http queryItem should usr base64 format

        // qDebug() << "cmdService send: " << strCommand;
        // qDebug() << "cmdService base64 send: " << strCommand.toUtf8().toBase64();

        m_networkManager->post(request, postData.toString().toUtf8());

        m_user = strUser;
        m_pass = strPass;
        m_cmd = strCommand;
    }
    else { // remote link
        QString strMsg = g_app->nasApi.addKeyValToJsonObj(strCommand, KEY_CMD_SERVICE_ID, m_cmdService_id);
        g_app->awsIot.pub(strMsg);
    }
}

void CmdService::onAuthenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator)
{
    //Q_UNUSED(reply);
    // 验证服务器证书:
    /*
    QSslConfiguration config = reply->sslConfiguration();
    // config.setProtocol(QSsl::TlsV1_2OrLater);
    config.setPeerVerifyMode(QSslSocket::VerifyPeer);
    reply->setSslConfiguration(config);
    */
    authenticator->setUser(m_user);
    authenticator->setPassword(m_pass);
}

void CmdService::onFinished(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        QString responseString = QString::fromUtf8(QByteArray::fromBase64(reply->readAll()));
        qDebug() << "cmdService onFinished return:" << responseString << ", cmd: " << m_cmd;
        emit dataReceived(m_cmd, responseString);
    } else {
        qDebug() << "Network error: " << reply->errorString() << reply->error();
        emit errorOccurred(reply->errorString(), reply->error());
    }
    reply->deleteLater();
}

void CmdService::onP2pCmdFinished(QString strResult)
{
    QString strCmdId = g_app->nasApi.getStringVarByKey(strResult, KEY_CMD_SERVICE_ID);
    if (strCmdId == m_cmdService_id) {
        // qDebug() << "recv p2p cmd finish signal from awsIot, send my dataReceived signal";
        emit dataReceived(m_cmd, strResult);
    }
}

void CmdService::onSslErrors(QNetworkReply *reply, const QList<QSslError> &errors)
{
    foreach (const QSslError &error, errors) {
        //qDebug() << "SSL error:" << error.errorString();
    }
    reply->ignoreSslErrors();
}
