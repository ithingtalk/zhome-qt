#ifndef AWSDBSERVICE_H
#define AWSDBSERVICE_H

#include "awsAccount.h"
#include "dbDevices.h"
#include <QQmlEngine>
#include <aws/crt/io/Bootstrap.h>
#include <QNetworkAccessManager>
#include <aws/crt/auth/Credentials.h>

using namespace Aws::Crt;
using namespace Aws::Crt::Auth;
using namespace Aws::Crt::Http;
using namespace Aws::Crt::Io;
using ResponseCallback = std::function<void(std::string response, bool success)>;

class AwsDbService : public QObject
{
    Q_OBJECT

public:
    explicit AwsDbService(AwsAccount &awsAccount, DbDevices &dbDevice);
    ~AwsDbService();
    bool success();
public slots:
    void all();
    void del(const QString &devMac);
    void add(const QString &devMac, const QString &devId, const QString &devName);
signals:
    void addSuccess(const QString strMac = "");
    void delSuccess(const QString strMac = "");
    void pullAdd(const QString strMac, const QString strSn, const QString strName, const QString strOnline);
    void pullAllSuccess();
private:
    AwsAccount& m_awsAccount;
    DbDevices& m_dbDevice;
    QNetworkAccessManager* m_networkManager;
    struct aws_allocator* m_pAllocator = NULL;
    // std::shared_ptr<Aws::Crt::Io::ClientBootstrap> clientBootstrap;
    std::string buildJsonBody(const std::map<std::string, std::string>& body);
    void invoke(const std::string &strPath, std::map<std::string, std::string> &strBody, ResponseCallback callback);
    auto getCrtHttpRequest(const std::string &strPath, const std::map<std::string, std::string> &strBody);
    void onAuthenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator);
    void onFinished(QNetworkReply *reply);
    void onSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);
    Aws::Crt::DateTime getCurrentAwsDateTime();
    std::shared_ptr<CredentialsProvider> s_MakeAsyncStaticProvider(Allocator *allocator);
    void onAddDevice(const QString strMac, const QString strSn, const QString strName);
    void onDelDevice(const QString strMac);
    void onPullAll();
    void pullAll();
    bool m_bPullAll = false;
    Aws::String m_apiHost;
    void syncLocal();
    void onError();
};

#endif // AWSDBSERVICE_H
