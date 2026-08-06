#ifndef AUDIOCONFIG_H
#define AUDIOCONFIG_H

#include <QObject>
#include <QDebug>
#include <qqmlintegration.h>
#include <QStringList>

#if defined(Q_OS_IOS)
class AudioPlayerManager;
#elif defined(Q_OS_ANDROID)
#include "androidAudioPlayer.h"
#endif

class AudioService : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit AudioService(QObject *parent = nullptr);
    ~AudioService();

public slots:
    void configure(bool isActive);
    void load(QStringList tracks);
    void play();
    void next();
    void prev();
    void setPosition(double lfPos);
    void setRepeatMode(int iMode);
    QVariantMap allStatus();

private:

#if defined(Q_OS_IOS)
    class AudioPlayerManager *m_player;
#elif defined(Q_OS_ANDROID)
    AndroidAudioPlayer *m_player;
#endif

};

#endif // AUDIOCONFIG_H
