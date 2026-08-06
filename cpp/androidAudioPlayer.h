#ifndef ANDROIDAUDIOPLAYER_H
#define ANDROIDAUDIOPLAYER_H

#include <QMutex>
#include <QObject>
#include <QStringList>

class AndroidAudioPlayer : public QObject {

public:
    explicit AndroidAudioPlayer(QObject *parent = nullptr);
    ~AndroidAudioPlayer();

    void load(const QStringList &urls);
    void play();
    void next();
    void prev();
    void seekTo(long seconds);
    void repeatMode(int mode);
    QVariantMap allStatus();

private:
    QMutex m_mutex;
};

#endif // ANDROIDAUDIOPLAYER_H
