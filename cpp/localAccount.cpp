#include "localAccount.h"
#include "localSettings.h"

LocalAccount::LocalAccount(QObject *parent) : QObject(parent) {}

QString LocalAccount::getUser()
{
    return LocalSettings::getUser();
}

void LocalAccount::setUser(const QString& strVal) { // email
    LocalSettings::setUser(strVal);
}

QString LocalAccount::getPass()
{
    return LocalSettings::getPass();
}

void LocalAccount::setPass(const QString& strVal) {
    LocalSettings::setPass(strVal);
}

bool LocalAccount::getForceP2p()
{
    return LocalSettings::getForceP2p();
}

void LocalAccount::setForceP2p(const bool bYes) {
    LocalSettings::setForceP2p(bYes);
}
