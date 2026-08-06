#ifndef CMDSERVICE_H
#define CMDSERVICE_H

#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QByteArray>
#include <QSslError>
#include <QAuthenticator>
#include <QDebug>
#include <QUrlQuery>
#include "awsIot.h"
#include "localSettings.h"

class CmdService : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit CmdService(AwsIot *iot, QObject *parent = nullptr);
    explicit CmdService(QObject *parent = nullptr);
    ~CmdService();
    QString m_cmd;
    QString m_cmdService_id;
    void onP2pCmdFinished(QString strCmd);
    void conn(AwsIot &iot);
public slots:
    /** @param transferTimeoutMs LAN HTTP only; >0 sets QNetworkRequest transfer timeout (ms). 0 = Qt default. */
    void send(const QString &strCommand, const QString strUser = LocalSettings::getUser(), const QString strPass = LocalSettings::getPass(), int transferTimeoutMs = 0);

signals:
    void dataReceived(const QString &strCmd, const QString &data);
    void errorOccurred(const QString errString, const int errCode);

private slots:
    void onAuthenticationRequired(QNetworkReply *reply, QAuthenticator *authenticator);
    void onFinished(QNetworkReply *reply);
    void onSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);

private:
    QNetworkAccessManager *m_networkManager;
    QString m_user;
    QString m_pass;
};

#endif // CMDSERVICE_H
