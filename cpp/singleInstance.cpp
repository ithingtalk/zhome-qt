#include <QDir>
#include "singleInstance.h"

SingleInstance::SingleInstance(const QString &key, QObject *parent)
    : QObject(parent), lockFile(QDir::tempPath() + "/" + key + ".lock")
{
}

bool SingleInstance::isRunning()
{
    if (lockFile.tryLock(100)) {
        // No other instance is running
        return false;
    } else {
        // Another instance is running
        return true;
    }
}
