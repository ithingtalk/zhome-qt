#ifndef LOCALACCOUNT_H
#define LOCALACCOUNT_H

#include <QQmlEngine>

class LocalAccount : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit LocalAccount(QObject *parent = nullptr);

signals:
    void userChanged();
    void passChanged();
    void loginChanged();

public slots:
    void setUser(const QString& strVal);
    QString getUser();
    void setPass(const QString& strVal);
    QString getPass();
    bool getForceP2p();
    void setForceP2p(const bool bYes);

private:
    const QString USER_NAME = "USER_NAME";
    const QString USER_PASSWD = "USER_PASSWD";
    const QString IS_LOGIN = "IS_LOGIN";
};

#endif // LOCALACCOUNT_H
