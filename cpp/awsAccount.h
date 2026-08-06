#ifndef AWSACCOUNT_H
#define AWSACCOUNT_H

#include <QFutureWatcher>
#include <QQmlEngine>
#include <QSettings>
#include <QString>
#include <QTimer>
#include <memory>
#include <aws/core/Aws.h>
#include <aws/cognito-idp/CognitoIdentityProviderClient.h>
#include <aws/cognito-identity/CognitoIdentityClient.h>
#include <aws/core/auth/AWSCredentialsProvider.h>

using namespace Aws::CognitoIdentityProvider;
using namespace Aws::CognitoIdentityProvider::Model;

class ClientWorker : public QObject
{
    Q_OBJECT

public:
    explicit ClientWorker(const QString& region, QObject *parent = nullptr) : m_region(region) {}

signals:
    void initializationCompleted(std::shared_ptr<CognitoIdentityProviderClient> cognitoClient, std::shared_ptr<Aws::CognitoIdentity::CognitoIdentityClient> identityClient);
    void initializationError(const QString& error);

public slots:
    void initializeClients()
    {
        try {
            Aws::Client::ClientConfiguration clientConfig;
            clientConfig.region = m_region.toStdString();
            // clientConfig.connectTimeoutMs = 5000;
            // clientConfig.requestTimeoutMs = 30000;
            auto cognitoClient = std::make_shared<CognitoIdentityProviderClient>(clientConfig);
            auto identityClient = std::make_shared<Aws::CognitoIdentity::CognitoIdentityClient>(clientConfig);
            emit initializationCompleted(cognitoClient, identityClient);
        }
        catch (const std::exception& e) {
            emit initializationError(QString::fromStdString(e.what()));
        }
    }

private:
    QString m_region;
};

enum class LoginStatus {
    Uninit,
    Running,
    Success,
    Error_signIn,
    Error_getId,
    Error_getCred
};

class AwsAccount : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit AwsAccount(QObject *parent = nullptr);
    ~AwsAccount();
    const Aws::String& getRegion();
    const Aws::Auth::AWSCredentials& getCdt();
    const Aws::String& getApiGatewayUrl();
    const Aws::String& getIotHost();
    bool hasValidCredentials() const;
    QString getUserId();
    void clearCurrLogin();
    bool loginSuccess();
public slots:
    void signUp(const QString &email, const QString &phone, const QString &password);
    void autoSignIn(const QString &strUser = "", const QString &strPass = "");
    void signIn(const QString &username = "", const QString &password = "", const bool &bCallFromUI = true);
    void changePassword(const QString &oldPassword, const QString &newPassword);
    void forgotPassword(const QString &username);
    void resetPassword(const QString &username, const QString &code, const QString &newPassword);
    void getAwsCredentials();
    void stop();
    void resendConfirmationCode(const QString &username);
    void confirmAccount(const QString &username, const QString &confirmationCode);
    void deleteUser(const QString &accessToken);
    void globalSignOut(const QString &accessToken);
    void signOut();
    void signOutAll();
    QString getUser();
    void setUser(QString userName);
    QString getPass();
    void setPass(QString passWd);
    bool haveSignInInfo();

    void testTS();
signals:
    void signUpSuccess(const QString &strInfo = "");
    void signUpFailed(const QString &strInfo = "");
    void resendCodeSuccess(const QString &strInfo = "");
    void resendCodeFailed(const QString &strInfo = "");
    void confirmAccountSuccess(const QString &strInfo = "");
    void confirmAccountFailed(const QString &strInfo = "");
    void signInSuccess(const QString &strInfo = "");
    void signInFailed(const QString &strInfo = "");
    void changePasswordSuccess(const QString &strInfo = "");
    void changePasswordFailed(const QString &strInfo = "");
    void forgotPasswordSuccess(const QString &strInfo = "");
    void forgotPasswordFailed(const QString &strInfo = "");
    void resetPasswordSuccess(const QString &strInfo = "");
    void resetPasswordFailed(const QString &strInfo = "");
    void signoutUserSuccess(const QString &strInfo = "");
    void signoutUserFailed(const QString &strInfo = "");
    void deleteUserSuccess(const QString &strInfo = "");
    void deleteUserFailed(const QString &strInfo = "");
    void invalidPasswd();
    void signOutSuccess();
    void signOutFailed(QString strErrorMsg);
    void logoutSuccess();
    void awsClientsReady();
    void iotReady();

private:
    void initializeAwsClients();
    bool readConfigFile();

private:
    Aws::String m_cfgAwsApiGatewayInvokeUrl = "";
    Aws::String m_cfgUserPoolId = "";
    Aws::String m_cfgUserPoolClientId = "";
    Aws::String m_cfgIdentityPoolId = "";
    Aws::String m_cfgAwsIotHost = "";
    Aws::String m_cfgAwsRegion = "YOUR_REGION";
    Aws::String m_accessToken;
    Aws::String m_idToken;
    Aws::String m_refreshToken;
    Aws::String m_identityId;
    Aws::Auth::AWSCredentials m_awsCredentials;
    std::shared_ptr<Aws::CognitoIdentityProvider::CognitoIdentityProviderClient> m_cognitoClient;
    std::shared_ptr<Aws::CognitoIdentity::CognitoIdentityClient> m_identityClient;
    QFutureWatcher<std::pair<std::shared_ptr<CognitoIdentityProviderClient>, std::shared_ptr<Aws::CognitoIdentity::CognitoIdentityClient>>> m_watcher;
    QString loginKeyForProvider(const QString &providerName = "");
    void updateAwsCredentials();
    // Local cache
    QSettings m_settings;
    qint64 m_tokenExpiry;
    Aws::String m_credAccessKeyId;
    Aws::String m_credSecretKey;
    Aws::String m_credSessionToken;
    void saveTokensToStorage();
    void loadTokensFromStorage(bool bInit = false, bool resetPass = true);
    bool hasRefreshToken() const;
    bool isExpiry() const;
    QTimer* m_timer;
    void loginChecker();
    LoginStatus m_login_status = LoginStatus::Uninit;
    void initializeClientsWithWorker();
    bool m_init_ready;
};

#endif // AWSACCOUNT_H
