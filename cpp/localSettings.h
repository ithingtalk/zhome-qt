#ifndef LOCALSETTINGS_H
#define LOCALSETTINGS_H

#include <QDir>
#include <QSettings>
#include <QStandardPaths>

class LocalSettings
{
#define MY_ORG "ithingtalk"
#define MY_APP "zhome"

public:
    LocalSettings();

    static void set(QString NAME_STRING, const QString& strVal) {
        QSettings settings(MY_ORG, MY_APP);
        settings.setValue(NAME_STRING, strVal);
        //qDebug() << "set " << NAME_STRING << "=" << strVal;
    }

    static QString get(QString NAME_STRING)
    {
        QString strVal = "";
        QSettings settings(MY_ORG, MY_APP);
        if (settings.contains(NAME_STRING)) {
            strVal = settings.value(NAME_STRING).toString();
        }
        //qDebug() << "got " << NAME_STRING << "=" << strVal;
        return strVal;
    }

    static void setBool(QString NAME_STRING, const bool bVal) {
        QSettings settings(MY_ORG, MY_APP);
        settings.setValue(NAME_STRING, bVal);
        //qDebug() << "set " << NAME_STRING << "=" << bVal;
    }

    static bool getBool(QString NAME_STRING)
    {
        bool bVal = false;
        QSettings settings(MY_ORG, MY_APP);
        if (settings.contains(NAME_STRING)) {
            bVal = settings.value(NAME_STRING).toBool();
        }
        //qDebug() << "got " << NAME_STRING << "=" << bVal;
        return bVal;
    }

    static void setInt(QString NAME_STRING, const int iVal) {
        QSettings settings(MY_ORG, MY_APP);
        settings.setValue(NAME_STRING, iVal);
        //qDebug() << "set " << NAME_STRING << "=" << iVal;
    }

    static int getInt(QString NAME_STRING)
    {
        int iVal = 0;
        QSettings settings(MY_ORG, MY_APP);
        if (settings.contains(NAME_STRING)) {
            iVal = settings.value(NAME_STRING).toInt();
        }
        //qDebug() << "got " << NAME_STRING << "=" << iVal;
        return iVal;
    }

    static QString configDir()
    {
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/" + getUser();
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    static QString dataDir()
    {
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/" + getUser();
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    static QString downloadDir()
    {
#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID)
        QString appDataPath = dataDir() + "/zhome";
#else
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/zhome" + "/" + getUser();
#endif
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    static QString cacheDir()
    {
        QString appDataPath = downloadDir() + "/cache";
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    static QString uploadDir()
    {
        QString appDataPath = downloadDir() + "/upload";
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    static QString pictureDir()
    {
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/" + getUser();
        QDir().mkpath(appDataPath);
        return appDataPath;
    }

    // cache for localAccount
    static QString getUser()
    {
        return LocalSettings::get("USER_NAME");
    }

    static void setUser(const QString& strVal) {
        LocalSettings::set("USER_NAME", strVal);
    }

    static QString getPass()
    {
        return LocalSettings::get("USER_PASSWD");
    }

    static void setPass(const QString& strVal) {
        LocalSettings::set("USER_PASSWD", strVal);
    }

    static bool getForceP2p()
    {
        return LocalSettings::getBool("ALWAYS_USE_P2P");
    }

    static void setForceP2p(bool bYes)
    {
        LocalSettings::setBool("ALWAYS_USE_P2P", bYes);
    }
};

#endif // LOCALSETTINGS_H
