#include "awsDbService.h"
#include "globalCpp.h"
#include <aws/auth/signable.h>
#include <aws/auth/signing.h>
#include <aws/auth/signing_result.h>
#include <aws/crt/Api.h>
#include <aws/crt/auth/Sigv4Signing.h>
#include <aws/crt/io/TlsOptions.h>
#include <aws/crt/auth/Credentials.h>
#include <aws/common/date_time.h>
#include <aws/crt/http/HttpRequestResponse.h>
#include <aws/auth/credentials.h>
#include <aws/http/request_response.h>
#include <QNetworkReply>
#include <condition_variable>
#include <mutex>
#include <QDateTime>
#include <QJsonParseError>
#include <QJsonDocument>
#include <aws/crt/DateTime.h>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>

class SignWaiter {
public:
    SignWaiter() : m_done(false) {}
    void OnSigningComplete(const std::shared_ptr<HttpRequest>&, int errorCode) {
        std::unique_lock<std::mutex> lock(m_lock);
        m_done = true;
        m_signal.notify_one();
    }
    void Wait() {
        std::unique_lock<std::mutex> lock(m_lock);
        m_signal.wait(lock, [this]() { return m_done; });
    }
private:
    std::mutex m_lock;
    std::condition_variable m_signal;
    bool m_done;
};

AwsDbService::AwsDbService(AwsAccount &awsAccount, DbDevices &dbDevice) : m_dbDevice(dbDevice), m_awsAccount(awsAccount), m_pAllocator(aws_default_allocator()), m_networkManager(new QNetworkAccessManager(this))
{
    qDebug() << "awsDbService";
    connect(&m_dbDevice, &DbDevices::addOne, this, &AwsDbService::add);
    connect(&m_dbDevice, &DbDevices::delOne, this, &AwsDbService::del);
    connect(&m_dbDevice, &DbDevices::pullAll, this, &AwsDbService::all);
    connect(&m_awsAccount, &AwsAccount::signInSuccess, this, &AwsDbService::pullAll);
    m_apiHost = QString::fromStdString(m_awsAccount.getApiGatewayUrl()).remove("https://").remove("/prod").toStdString().c_str();
    qDebug() << "awsDbService done";
}

AwsDbService::~AwsDbService() {
    qDebug() << "awsDbService destroy done";
}

void AwsDbService::syncLocal()
{
    // 1 Add or Change padding
    QList<DbDeviceData> devices = m_dbDevice.pendings_add();
    for (int idx=0; idx<devices.length(); idx++) {
        add(devices[idx].mac, devices[idx].sn, devices[idx].name);
    }
    // 2 Del padding
    devices = m_dbDevice.pendings_del();
    for (int idx=0; idx<devices.length(); idx++) {
        del(devices[idx].mac);
    }
}

void AwsDbService::pullAll()
{
    if (!m_bPullAll) {
        all();
    }
}

void AwsDbService::all()
{
    qDebug() << "awsDbService: all";
    std::map<std::string, std::string> body;
    invoke("/idevices/all", body, [=](const std::string response, bool success) {
        if (success) {
            m_bPullAll = true;
            qDebug() << "===> awsDbService.app, got devices: \n" << response << "\n";
            // TODO: parse response ... and merge to m__dbDevice
            QJsonParseError parseError;
            QJsonDocument jsonDoc = QJsonDocument::fromJson(response.c_str(), &parseError);
            if ((parseError.error == QJsonParseError::NoError) && jsonDoc.isArray()) {
                QJsonArray ja = jsonDoc.array();
                for (int idx=0; idx<ja.count(); idx++) {
                    QJsonObject obj = ja[idx].toObject();
                    QString strMac;
                    QString strSn;
                    QString strName;
                    QString strOnline;
                    if (obj.contains("deviceId")) { strMac = obj["deviceId"].toString(); }
                    if (obj.contains("deviceSn")) { strSn = obj["deviceSn"].toString(); }
                    if (obj.contains("deviceName")) { strName = obj["deviceName"].toString(); }
                    if (obj.contains("online")) { strOnline = obj["online"].toString(); }
                    if (strMac.isEmpty() || strSn.isEmpty() || strName.isEmpty() || strOnline.isEmpty()) {
                        qDebug() << "all parse error";
                    }
                    else {
                        emit pullAdd(strMac, strSn, strName, strOnline);
                    }
                }
            }
            syncLocal();
            emit this->pullAllSuccess();
        }
        else {
            qDebug() << "AwsDbService::all Fail: " << response.c_str();
            onError();
        }
    });
}

void AwsDbService::add(const QString &strMac, const QString &strSn, const QString &strName)
{
    qDebug() << "awsDbService.cpp: add mac = " << strMac << ", sn = " << strSn << ", name = " << strName;
    std::map<std::string, std::string> body;
    body["deviceId"] = strMac.toStdString();
    body["deviceSn"] = strSn.toStdString();
    body["deviceName"] = strName.toStdString();
    body["deviceType"] = "IDEVICE";
    invoke("/idevices", body, [=](const std::string response, bool success) { // [&] refrence local "strMac" val will cause CRASH !!!
        if (success) {
            qDebug() << "add success: " << response;
            // m_dbDevice.add_done(strMac);
            emit addSuccess(strMac);
        }
        else {
            qDebug() << "add Failed" << response;
            onError();
        }
    });
}

void AwsDbService::del(const QString &strMac)
{
    qDebug() << "awsDbService.cpp: del mac = " << strMac;
    std::map<std::string, std::string> body;
    body["deviceId"] = strMac.toStdString();
    invoke("/idevices/me", body, [=](const std::string response, bool success) {
        if (success) {
            qDebug() << "del success: " << response;
            // m_dbDevice.del_done(strMac);
            emit delSuccess(strMac);
        }
        else {
            qDebug() << "del fail: " << response;
            onError();
        }
    });
}

DateTime AwsDbService::getCurrentAwsDateTime()
{
    qint64 msecsSinceEpoch = QDateTime::currentMSecsSinceEpoch();
    auto timePoint = std::chrono::system_clock::time_point(std::chrono::milliseconds(msecsSinceEpoch));
    return DateTime(timePoint);
}

std::shared_ptr<CredentialsProvider> AwsDbService::s_MakeAsyncStaticProvider(Allocator *allocator)
{
    aws_credentials_provider_static_options static_options;
    AWS_ZERO_STRUCT(static_options);
    static_options.access_key_id = aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetAWSAccessKeyId().c_str());
    static_options.secret_access_key = aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetAWSSecretKey().c_str());
    static_options.session_token = aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetSessionToken().c_str());
    struct aws_credentials_provider *pProvider = aws_credentials_provider_new_static(allocator, &static_options);
    struct aws_credentials_provider *providers[1] = { pProvider };
    aws_credentials_provider_chain_options options;
    AWS_ZERO_STRUCT(options);
    options.providers = providers;
    options.provider_count = 1;
    struct aws_credentials_provider *provider_chain = aws_credentials_provider_new_chain(allocator, &options);
    aws_credentials_provider_release(pProvider);
    // if (provider_chain == NULL) return nullptr;
    return MakeShared<CredentialsProvider>(allocator, provider_chain, allocator);
}

// README: "z36o41g9nk.execute-api.ap-northeast-1.amazonaws.com"
auto AwsDbService::getCrtHttpRequest(const std::string& strPath, const std::map<std::string, std::string>& strBody)
{
    // qDebug() << "======> getCrtHttpRequest start";
    // 1 CREATE CRT HTTP REQUEST
    auto pHttpRequest = MakeShared<HttpRequest>(m_pAllocator);
    pHttpRequest->SetMethod(aws_byte_cursor_from_c_str("POST"));
    pHttpRequest->SetPath(aws_byte_cursor_from_c_str( (m_awsAccount.getApiGatewayUrl() + strPath).c_str() ));
    // 2 Set Header
    HttpHeader sHttpHeaderHost;
    HttpHeader sHttpHeaderContentType;
    HttpHeader sHttpHeaderAccept;
    sHttpHeaderHost.name = aws_byte_cursor_from_c_str("Host");
    sHttpHeaderHost.value = aws_byte_cursor_from_c_str(m_apiHost.c_str());
    pHttpRequest->AddHeader(sHttpHeaderHost);
    sHttpHeaderContentType.name = aws_byte_cursor_from_c_str("Content-Type");
    sHttpHeaderContentType.value = aws_byte_cursor_from_c_str("application/json");
    pHttpRequest->AddHeader(sHttpHeaderContentType);
    sHttpHeaderAccept.name = aws_byte_cursor_from_c_str("Accept");
    sHttpHeaderAccept.value = aws_byte_cursor_from_c_str("application/json");
    pHttpRequest->AddHeader(sHttpHeaderAccept);
    // 3 Create JSON Request Body
    std::string jsonBody = buildJsonBody(strBody);
    auto bodyStream = MakeShared<std::stringstream>(m_pAllocator, jsonBody.c_str());
    pHttpRequest->SetBody(bodyStream);
    // 4 Create CRT Credentials
    auto credentials = MakeShared<Credentials>(
        m_pAllocator,
        aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetAWSAccessKeyId().c_str()),
        aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetAWSSecretKey().c_str()),
        aws_byte_cursor_from_c_str(m_awsAccount.getCdt().GetSessionToken().c_str()),
        UINT64_MAX);
    // 5 Create signing config
    auto strRegion = m_awsAccount.getRegion().c_str();
    AwsSigningConfig signingConfig(m_pAllocator);
    signingConfig.SetSigningTimepoint(DateTime().Now());
    signingConfig.SetRegion(strRegion);
    signingConfig.SetService("execute-api");
    signingConfig.SetCredentials(credentials);
    signingConfig.SetCredentialsProvider(s_MakeAsyncStaticProvider(m_pAllocator));
    // 6 Signing
    auto signer = MakeShared<Sigv4HttpRequestSigner>(m_pAllocator, m_pAllocator);
    SignWaiter waiter;
    signer->SignRequest(pHttpRequest, signingConfig, [&waiter](const std::shared_ptr<HttpRequest> &signedRequest, int errorCode) {
        waiter.OnSigningComplete(signedRequest, errorCode);
    });
    waiter.Wait();
    return pHttpRequest;
}

void AwsDbService::invoke(const std::string& strPath, std::map<std::string, std::string>& strBody, ResponseCallback callback)
{
    if (!m_awsAccount.hasValidCredentials()) {
        callback("Cred Invalid", false);
        return;
    }
    auto sRequest = getCrtHttpRequest(strPath, strBody);
    // qDebug() << "======> header count: " << sRequest->GetHeaderCount();
    Aws::String strUrl = m_awsAccount.getApiGatewayUrl() + strPath;
    QUrl qtUrl(QString::fromStdString(strUrl));
    QNetworkRequest qtRequest(qtUrl);

    for (int idx = 0; idx < sRequest->GetHeaderCount(); idx++) {
        const auto& header = sRequest->GetHeader(idx);
        QString strKeyValue = QString::fromUtf8(header->name.ptr);
        strKeyValue.resize(header->name.len + header->value.len);
        QString strKey = strKeyValue.mid(0, header->name.len);
        QString strVal = strKeyValue.mid(header->name.len, header->name.len + header->value.len);
        qtRequest.setRawHeader(strKey.toUtf8(), strVal.toUtf8());
        // qDebug() << "\n======> invoke\n\nkey=" << strKey << ", len=" << header->name.len << "\n\nval=" << strVal << ", len=" << header->value.len << "\n";
    }

    QNetworkReply *pReply = m_networkManager->post(qtRequest, buildJsonBody(strBody).c_str());

    connect(pReply, &QNetworkReply::finished, this, [pReply, callback]() {
        if (pReply->error() == QNetworkReply::NoError) {
            callback(pReply->readAll().toStdString(), true);
        } else {
            qDebug() << "QNetworkReply error: " << pReply->error() << ", " << pReply->errorString();
            callback(pReply->errorString().toStdString(), false);
        }
        pReply->deleteLater();
    });

    // qDebug() << "\n======> invoke done\n";
}

std::string AwsDbService::buildJsonBody(const std::map<std::string, std::string>& body) {
    std::string json = "{";
    bool first = true;
    for (const auto& pair : body) {
        if (!first) json += ",";
        json += "\"" + pair.first + "\":\"" + pair.second + "\"";
        first = false;
    }
    json += "}";
    // qDebug() << "======> buildJsonBody done: " << json;
    return json;
}

void AwsDbService::onError()
{
    g_app->awsAccount.clearCurrLogin();
}

bool AwsDbService::success()
{
    return m_bPullAll;
}
