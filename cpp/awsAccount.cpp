#include "awsAccount.h"
#include "localSettings.h"
#include <aws/cognito-idp/model/SignUpRequest.h>
#include <aws/cognito-idp/model/InitiateAuthRequest.h>
#include <aws/cognito-idp/model/ChangePasswordRequest.h>
#include <aws/cognito-idp/model/ForgotPasswordRequest.h>
#include <aws/cognito-idp/model/ConfirmForgotPasswordRequest.h>
#include <aws/cognito-idp/model/AttributeType.h>
#include <aws/cognito-idp/model/ResendConfirmationCodeRequest.h>
#include <aws/cognito-idp/model/ConfirmSignUpRequest.h>
#include <aws/cognito-idp/model/DeleteUserRequest.h>
#include <aws/cognito-idp/model/GlobalSignOutRequest.h>
#include <aws/cognito-idp/model/RevokeTokenRequest.h>
#include <aws/cognito-identity/model/GetCredentialsForIdentityRequest.h>
#include <aws/cognito-identity/model/GetIdRequest.h>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QGuiApplication>
#include <globalCpp.h>
// [=]: copy this pointer and local val; [&]: ATTENTION!!! ref local val may case app crash

void AwsAccount::initializeClientsWithWorker()
{
    QThread* workerThread = new QThread(this);
    ClientWorker* worker = new ClientWorker(QString::fromStdString(m_cfgAwsRegion.c_str()));
    worker->moveToThread(workerThread);

    connect(workerThread, &QThread::started, worker, &ClientWorker::initializeClients);
    connect(worker, &ClientWorker::initializationCompleted, this,
            [this, workerThread](auto cognitoClient, auto identityClient) {
                m_cognitoClient = cognitoClient;
                m_identityClient = identityClient;
                workerThread->quit();
                qDebug() << "awsAccount clients init done";
                qDebug() << "awsAccount loadTokensFromStorage";
                loadTokensFromStorage();
                m_init_ready = true;
                loginChecker();
                emit awsClientsReady();
            });
    connect(worker, &ClientWorker::initializationError, this,
            [workerThread](const QString& error) {
                workerThread->quit();
                qDebug() << "AWS clients initialization failed:" << error;
            });
    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);
    connect(workerThread, &QThread::finished, worker, &QObject::deleteLater);
    workerThread->start();
}

AwsAccount::AwsAccount(QObject *parent) : QObject(parent), m_settings("Ithingtalk", "appZhome"), m_init_ready(false)
{
    qDebug() << "awsAccount initClients";
    readConfigFile();
    initializeClientsWithWorker();

    m_timer = new QTimer(this);
    m_timer->setSingleShot(false);
    connect(m_timer, &QTimer::timeout, this, &AwsAccount::loginChecker);
    m_timer->start(15*1000); // org: 15

    QTimer::singleShot(500, this, [=]() { loginChecker(); });
    qDebug() << "awsAccount done";
}

AwsAccount::~AwsAccount() {
    qDebug() << "awsAccount destroy";
    stop();
    qDebug() << "awsAccount destroy done";
}

void AwsAccount::loginChecker() {
    if(!m_init_ready) {
        return;
    }
    if (m_login_status != LoginStatus::Running) {
        autoSignIn();
    }
}

void AwsAccount::stop()
{
    m_cognitoClient.reset();
    m_identityClient.reset();
}

void AwsAccount::signOut() // only revoke refresh token
{
    qDebug() << "signOut start";
    RevokeTokenRequest revokeRequest;
    revokeRequest.SetToken(m_refreshToken);
    revokeRequest.SetClientId(m_cfgUserPoolClientId);
    m_cognitoClient->RevokeTokenAsync(revokeRequest, [=](const CognitoIdentityProviderClient*, const RevokeTokenRequest&, const RevokeTokenOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess()) {
            qDebug() << "signOut success";
            emit signOutSuccess();
        }
        else {
            qDebug() << "signOut fail: " << QString::fromStdString(outcome.GetError().GetMessage());
            emit signOutFailed(QString::fromStdString(outcome.GetError().GetMessage()));
        }
    });
    loadTokensFromStorage(true);
}

void AwsAccount::signOutAll() // revoke all token and signout all device
{
    GlobalSignOutRequest signoutRequest;
    signoutRequest.SetAccessToken(m_accessToken);
    m_cognitoClient->GlobalSignOutAsync(signoutRequest, [=](const CognitoIdentityProviderClient*, const GlobalSignOutRequest&, const GlobalSignOutOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess()) {
            qDebug() << "signOut success";
            emit signOutSuccess();
        }
        else {
            qDebug() << "signOut fail: " << QString::fromStdString(outcome.GetError().GetMessage());
            emit signOutFailed(QString::fromStdString(outcome.GetError().GetMessage()));
        }
    });
    loadTokensFromStorage(true);
}

void AwsAccount::signUp(const QString &strEmail, const QString &strPhone, const QString &strPassword)
{
    Aws::String strUser = "";
    SignUpRequest signUpRequest;
    signUpRequest.SetClientId(m_cfgUserPoolClientId);
    if (!strEmail.isEmpty()) {
        signUpRequest.AddUserAttributes(
            AttributeType().WithName("email").WithValue(strEmail.toStdString()));
        strUser = strEmail.toStdString();
    }
    if (!strPhone.isEmpty()) {
        signUpRequest.AddUserAttributes(
            AttributeType().WithName("phone_number").WithValue(strPhone.toStdString()));
        strUser = strPhone.toStdString();
    }
    signUpRequest.SetUsername(strUser);
    signUpRequest.SetPassword(strPassword.toStdString());
    m_cognitoClient->SignUpAsync(signUpRequest, [this](const CognitoIdentityProviderClient*, const SignUpRequest&, const SignUpOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit signInFailed("UserNotConfirmed");
        else
            emit signUpFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::resendConfirmationCode(const QString &username)
{
    ResendConfirmationCodeRequest resendRequest;
    resendRequest.SetClientId(m_cfgUserPoolClientId);
    resendRequest.SetUsername(username.toStdString());
    m_cognitoClient->ResendConfirmationCodeAsync(resendRequest, [this](const CognitoIdentityProviderClient*, const ResendConfirmationCodeRequest&, const ResendConfirmationCodeOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit resendCodeSuccess("");
        else
            emit resendCodeFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::confirmAccount(const QString &username, const QString &confirmationCode)
{
    ConfirmSignUpRequest request;
    request.SetClientId(m_cfgUserPoolClientId);
    request.SetUsername(username.toStdString());
    request.SetConfirmationCode(confirmationCode.toStdString());
    m_cognitoClient->ConfirmSignUpAsync(request, [this](const CognitoIdentityProviderClient*, const ConfirmSignUpRequest&, const ConfirmSignUpOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit confirmAccountSuccess("");
        else
            emit confirmAccountFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::signIn(const QString &strUsername, const QString &strPassword, const bool &bCallFromUI)
{
    qDebug() << "reSignIn: " << strUsername << ", " << strPassword;
    InitiateAuthRequest request;
    request.SetClientId(m_cfgUserPoolClientId);
    if (!strUsername.isEmpty()) {
        request.SetAuthFlow(AuthFlowType::USER_PASSWORD_AUTH);
        Aws::Map<Aws::String, Aws::String> authParams;
        request.AddAuthParameters("USERNAME", strUsername.toStdString());
        request.AddAuthParameters("PASSWORD", strPassword.toStdString());
    }
    else {
        request.SetAuthFlow(AuthFlowType::REFRESH_TOKEN_AUTH);
        request.AddAuthParameters("REFRESH_TOKEN", m_refreshToken);
    }
    m_login_status = LoginStatus::Running;
    m_cognitoClient->InitiateAuthAsync(request, [=](const CognitoIdentityProviderClient*, const InitiateAuthRequest&, const InitiateAuthOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess()) {
            qDebug() << "signIn success";
            auto result = outcome.GetResult();
            if (!strUsername.isEmpty()) {
                setUser(strUsername);
                setPass(strPassword);
                m_refreshToken = result.GetAuthenticationResult().GetRefreshToken();
            }
            m_accessToken = result.GetAuthenticationResult().GetAccessToken();
            m_idToken = result.GetAuthenticationResult().GetIdToken();
            getAwsCredentials();
        }
        else {
            m_login_status = LoginStatus::Error_signIn;
            qDebug() << "Signin fail: " << outcome.GetError().GetExceptionName();
            if (outcome.GetError().GetExceptionName() == "UserNotFoundException") {
                loadTokensFromStorage(true);
                if (bCallFromUI)
                    signUp(strUsername, "", strPassword); // auto signUp
            }
            else if (outcome.GetError().GetExceptionName() == "UserNotConfirmedException") {
                loadTokensFromStorage(true);
                if (bCallFromUI)
                    resendConfirmationCode(strUsername); // auto resend confirm code
            }
            else if (outcome.GetError().GetExceptionName() == "NotAuthorizedException") {
                loadTokensFromStorage(true);
                emit invalidPasswd();
            }
            else {
				emit signInFailed(QString::fromStdString(outcome.GetError().GetMessage()));
            }
        }
    });
}

void AwsAccount::getAwsCredentials()
{
    Aws::CognitoIdentity::Model::GetIdRequest getIdRequest;
    getIdRequest.SetIdentityPoolId(m_cfgIdentityPoolId);
    Aws::Map<Aws::String, Aws::String> getIdRogins;
    QString providerName = loginKeyForProvider();
    getIdRogins[providerName.toStdString()] = m_idToken;
    getIdRequest.SetLogins(getIdRogins);
    m_identityClient->GetIdAsync(getIdRequest, [this](const Aws::CognitoIdentity::CognitoIdentityClient*, const Aws::CognitoIdentity::Model::GetIdRequest&, const Aws::CognitoIdentity::Model::GetIdOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess()) {
            m_identityId = outcome.GetResult().GetIdentityId();
            qDebug() << "\n\ngetId success: " << m_identityId << "\n\n";
            Aws::CognitoIdentity::Model::GetCredentialsForIdentityRequest getCredRequest;
            getCredRequest.SetIdentityId(m_identityId);
            Aws::Map<Aws::String, Aws::String> credLogins;
            QString providerName = loginKeyForProvider();
            credLogins[providerName.toStdString()] = m_idToken;
            getCredRequest.SetLogins(credLogins);
            m_identityClient->GetCredentialsForIdentityAsync(getCredRequest, [this](const Aws::CognitoIdentity::CognitoIdentityClient*, const Aws::CognitoIdentity::Model::GetCredentialsForIdentityRequest&, const Aws::CognitoIdentity::Model::GetCredentialsForIdentityOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
                if (outcome.IsSuccess()) {
                    m_login_status = LoginStatus::Success;
                    auto credentials = outcome.GetResult().GetCredentials();
                    m_tokenExpiry = credentials.GetExpiration().Seconds(); // compare with : QDateTime::currentSecsSinceEpoch()
                    qDebug() << "datetime: " << credentials.GetExpiration().Seconds() << ", " << QDateTime::currentSecsSinceEpoch();
                    m_credAccessKeyId = credentials.GetAccessKeyId();
                    m_credSecretKey = credentials.GetSecretKey();
                    m_credSessionToken = credentials.GetSessionToken();
                    updateAwsCredentials();
                    saveTokensToStorage();
                    emit signInSuccess();
                    qDebug() << "\n\nAWS credentials obtained successfully\n\n";
                }
                else {
                    m_login_status = LoginStatus::Error_getCred;
                    QString error = QString::fromStdString(outcome.GetError().GetMessage());
                    emit signInFailed(error);
                    qDebug() << "\n\nFailed to get AWS credentials:" << error << "\n\n";
                    clearCurrLogin();
                }
            });
        } else {
            m_login_status = LoginStatus::Error_getId;
            QString error = QString::fromStdString(outcome.GetError().GetMessage());
            qDebug() << "\n\nFailed to get identity ID: " << error << "\n\n";
            emit signInFailed(error);
            clearCurrLogin();
        }
    });
}

void AwsAccount::updateAwsCredentials()
{
    if (m_credAccessKeyId.empty() || m_credSecretKey.empty() || m_credSessionToken.empty())
        m_awsCredentials = Aws::Auth::AWSCredentials();
    else
        m_awsCredentials = Aws::Auth::AWSCredentials(m_credAccessKeyId, m_credSecretKey, m_credSessionToken);
}

// deleteUser stage1: sign out all users
void AwsAccount::globalSignOut(const QString& accessToken)
{
    GlobalSignOutRequest request;
    request.SetAccessToken(accessToken.toStdString());
    m_cognitoClient->GlobalSignOutAsync(request, [=](const CognitoIdentityProviderClient*, const GlobalSignOutRequest&, const GlobalSignOutOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess()) {
            emit signoutUserSuccess("");
            deleteUser(accessToken);
        } else
            emit signoutUserFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::deleteUser(const QString& accessToken)
{
    DeleteUserRequest request;
    request.SetAccessToken(accessToken.toStdString()); // deleteUser should first signIn
    m_cognitoClient->DeleteUserAsync (request, [this](const CognitoIdentityProviderClient*, const DeleteUserRequest&, const DeleteUserOutcome& outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit deleteUserSuccess("");
        else
            emit deleteUserFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::changePassword(const QString &oldPassword, const QString &newPassword)
{
    ChangePasswordRequest request;
    request.SetAccessToken(m_accessToken);
    request.SetPreviousPassword(oldPassword.toStdString());
    request.SetProposedPassword(newPassword.toStdString());
    m_cognitoClient->ChangePasswordAsync(request, [this](const CognitoIdentityProviderClient*, const ChangePasswordRequest&, ChangePasswordOutcome outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit changePasswordSuccess();
        else
            emit changePasswordFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::forgotPassword(const QString &username)
{
    ForgotPasswordRequest request;
    request.SetClientId(m_cfgUserPoolClientId);
    request.SetUsername(username.toStdString());
    m_cognitoClient->ForgotPasswordAsync(request, [this](const CognitoIdentityProviderClient*, const ForgotPasswordRequest&, ForgotPasswordOutcome outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit forgotPasswordSuccess();
        else
            emit forgotPasswordFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

void AwsAccount::resetPassword(const QString &username, const QString &code, const QString &newPassword)
{
    ConfirmForgotPasswordRequest request;
    request.SetClientId(m_cfgUserPoolClientId);
    request.SetUsername(username.toStdString());
    request.SetConfirmationCode(code.toStdString());
    request.SetPassword(newPassword.toStdString());
    m_cognitoClient->ConfirmForgotPasswordAsync(request, [this](const CognitoIdentityProviderClient*, const ConfirmForgotPasswordRequest&, ConfirmForgotPasswordOutcome outcome, const std::shared_ptr<const Aws::Client::AsyncCallerContext>&) {
        if (outcome.IsSuccess())
            emit resetPasswordSuccess();
        else
            emit resetPasswordFailed(QString::fromStdString(outcome.GetError().GetMessage()));
    });
}

bool AwsAccount::readConfigFile()
{
    QStringList paths = {
        qApp->applicationDirPath() + "/awsconfig.json",
        qApp->applicationDirPath() + "/cfg/awsconfig.json",
        ":/Zhome/cfg/awsconfig.json",
        ":/qt/qml/Zhome/cfg/awsconfig.json",
        ":/cfg/awsconfig.json"
    };
    QFile sFile;
    for (const QString &path : paths) {
        sFile.setFileName(path);
        if (sFile.exists()) {
            qDebug() << "aws configure path:" << path;
            break;
        }
    }
    if (sFile.open(QIODevice::ReadOnly)) {
        QByteArray data = sFile.readAll();
        sFile.close();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (auto it = obj.begin(); it != obj.end(); ++it) {
                QString strKey = it.key();
                QJsonValue strValue = it.value();
                if (strValue.isString()) {
                    if (strKey == "AwsRegion")
                        m_cfgAwsRegion = strValue.toString().toStdString();
                    else if (strKey == "UserPoolId")
                        m_cfgUserPoolId = strValue.toString().toStdString();
                    else if (strKey == "UserPoolClientId")
                        m_cfgUserPoolClientId = strValue.toString().toStdString();
                    else if (strKey == "IdentityPoolId")
                        m_cfgIdentityPoolId = strValue.toString().toStdString();
                    else if (strKey == "AwsApiGatewayInvokeUrl")
                        m_cfgAwsApiGatewayInvokeUrl = strValue.toString().toStdString();
                    else if (strKey == "AwsIotHost")
                        m_cfgAwsIotHost = strValue.toString().toStdString();
                }
            }
            qDebug() << "load aws configure file success, region:" << QString::fromUtf8(m_cfgAwsRegion.c_str());
            return true;
        }
    }
    else {
        qDebug() << "load aws configure file fail";
    }
    return false;
}

const Aws::String& AwsAccount::getRegion() { return m_cfgAwsRegion; }
const Aws::Auth::AWSCredentials& AwsAccount::getCdt() { return m_awsCredentials; }
const Aws::String& AwsAccount::getApiGatewayUrl() { return m_cfgAwsApiGatewayInvokeUrl; }
const Aws::String& AwsAccount::getIotHost() { return m_cfgAwsIotHost; }
QString AwsAccount::getUser() { return LocalSettings::getUser(); }
void AwsAccount::setUser(QString userName) { LocalSettings::setUser(userName); }
QString AwsAccount::getPass() { return LocalSettings::getPass(); }
void AwsAccount::setPass(QString passWd) { LocalSettings::setPass(passWd); }

QString AwsAccount::loginKeyForProvider(const QString& providerName) { return QString("cognito-idp.%1.amazonaws.com/%2").arg(m_cfgAwsRegion, m_cfgUserPoolId); }

// TODO: crypt value
void AwsAccount::saveTokensToStorage()
{
    m_settings.beginGroup("CognitoTokens");
    m_settings.setValue("AccessToken", QString::fromStdString(m_accessToken));
    m_settings.setValue("IdToken", QString::fromStdString(m_idToken));
    m_settings.setValue("RefreshToken", QString::fromStdString(m_refreshToken));
    m_settings.setValue("IdentityId", QString::fromStdString(m_identityId));
    m_settings.setValue("TokenExpiry", m_tokenExpiry);
    m_settings.setValue("CredAccessKeyId", QString::fromStdString(m_credAccessKeyId));
    m_settings.setValue("CredSecretKey", QString::fromStdString(m_credSecretKey));
    m_settings.setValue("CredSessionToken", QString::fromStdString(m_credSessionToken));
    m_settings.endGroup();
    m_settings.sync();
}

void AwsAccount::loadTokensFromStorage(bool bInit, bool resetPass)
{
    m_settings.beginGroup("CognitoTokens");
    if (bInit && resetPass)
        setPass("");
    m_accessToken = bInit ? "" : m_settings.value("AccessToken").toString().toStdString();
    m_idToken = bInit ? "" : m_settings.value("IdToken").toString().toStdString();
    m_refreshToken = bInit ? "" : m_settings.value("RefreshToken").toString().toStdString();
    m_identityId = bInit ? "" : m_settings.value("IdentityId").toString().toStdString();
    m_tokenExpiry = bInit ? 0 : m_settings.value("TokenExpiry").toInt();
    m_credAccessKeyId = bInit ? "" : m_settings.value("CredAccessKeyId").toString().toStdString();
    m_credSecretKey = bInit ? "" : m_settings.value("CredSecretKey").toString().toStdString();
    m_credSessionToken = bInit ? "" : m_settings.value("CredSessionToken").toString().toStdString();
    updateAwsCredentials();
    m_settings.endGroup();
    if (bInit)
        saveTokensToStorage();
}

bool AwsAccount::hasValidCredentials() const { return !m_awsCredentials.IsEmpty() && !isExpiry(); }
bool AwsAccount::hasRefreshToken() const { return !m_refreshToken.empty() && isExpiry(); }
bool AwsAccount::isExpiry() const { return QDateTime::currentSecsSinceEpoch() + 300 > m_tokenExpiry; }  // pretime: 5 minutes

void AwsAccount::autoSignIn(const QString& strUser, const QString& strPass)
{
    if (hasValidCredentials()) {
        // qDebug() << "======> credentials existing";
        // m_login_status = LoginStatus::Success;
        emit signInSuccess();
        return;
    }

    if (hasRefreshToken()) {
        qDebug() << "======> Refreshing tokens";
        signIn();
        return;
    }

    if (!strUser.isEmpty() && !strPass.isEmpty()) {
        qDebug() << "======> Login from UI";
        signIn(strUser, strPass, true);
        return;
    }

    if (!getUser().isEmpty() && !getPass().isEmpty()) {
        qDebug() << "======> Login from loginChecker";
        signIn(getUser().toStdString().c_str(), getPass().toStdString().c_str(), false);
        return;
    }

    qDebug() << "autoSignIn: is logout";
    emit signOutSuccess();
}

bool AwsAccount::haveSignInInfo()
{
    return !getUser().isEmpty() && !getPass().isEmpty();
}

QString AwsAccount::getUserId()
{
    return m_identityId.c_str();
}

extern "C" void test_ts_once();
void AwsAccount::testTS()
{
/*
    test_ts_once();
    QTimer::singleShot(100, this, [=]() { testTS(); });
*/
}

void AwsAccount::clearCurrLogin()
{
    if(!loginSuccess()) {
        loadTokensFromStorage(true, false);
    }
}

bool AwsAccount::loginSuccess()
{
    return m_login_status == LoginStatus::Success;
}
