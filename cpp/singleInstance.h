#ifndef SINGLEINSTANCE_H
#define SINGLEINSTANCE_H

#include <QQmlEngine>
#include <QCoreApplication>
#include <QLockFile>
#include <QDebug>

class SingleInstance : public QObject
{
    Q_OBJECT
public:
    explicit SingleInstance(const QString &key, QObject *parent = nullptr);
    bool isRunning();

private:
    QLockFile lockFile;
};

#endif // SINGLEINSTANCE_H
