#include "audioService.h"

#include <QVariant>

#if defined(Q_OS_IOS)

// ====== audioPlayerManager api for C++ ========================================================
extern "C" AudioPlayerManager* audioPlayerManager_new();
extern "C" void audioPlayerManager_delete(AudioPlayerManager* m_player);
extern "C" void audioPlayerManager_load(AudioPlayerManager* m_player, QStringList &tracks);
extern "C" void audioPlayerManager_playPause(AudioPlayerManager* m_player);
extern "C" void audioPlayerManager_playNext(AudioPlayerManager* m_player);
extern "C" void audioPlayerManager_playPrevious(AudioPlayerManager* m_player);
extern "C" bool audioPlayerManager_startDamon(AudioPlayerManager* m_player, bool isActive);
extern "C" void audioPlayerManager_setPosition(AudioPlayerManager* m_player, double lfPos);
extern "C" bool audioPlayerManager_isPlaying(AudioPlayerManager* m_player);
extern "C" int audioPlayerManager_getDuration(AudioPlayerManager* m_player);
extern "C" int audioPlayerManager_getCurrentTime(AudioPlayerManager* m_player);
QString audioPlayerManager_getTrackName(AudioPlayerManager* m_player);
extern "C" void audioPlayerManager_setRepeatMode(AudioPlayerManager* m_player, int iMode);
// ===============================================================================================

AudioService::AudioService(QObject *parent) : QObject(parent) { m_player = audioPlayerManager_new(); }
AudioService::~AudioService() { audioPlayerManager_delete(m_player); }
void AudioService::configure(bool isActive) { audioPlayerManager_startDamon(m_player, isActive); }
void AudioService::load(QStringList tracks) { audioPlayerManager_load(m_player, tracks); }
void AudioService::play() { audioPlayerManager_playPause(m_player); }
void AudioService::next() { audioPlayerManager_playNext(m_player); }
void AudioService::prev() { audioPlayerManager_playPrevious(m_player); }
void AudioService::setPosition(double lfPos) { audioPlayerManager_setPosition(m_player, lfPos); }
void AudioService::setRepeatMode(int iMode) { audioPlayerManager_setRepeatMode(m_player, iMode); }
QVariantMap AudioService::allStatus()
{
    QVariantMap sItem;
    sItem["trackName"] = audioPlayerManager_getTrackName(m_player);
    sItem["isPlaying"] = audioPlayerManager_isPlaying(m_player);
    sItem["timeTotal"] = audioPlayerManager_getDuration(m_player);
    sItem["timeNow"] = audioPlayerManager_getCurrentTime(m_player);
    //qDebug() << "audioService.cpp: " << sItem["trackName"] << ", " << sItem["isPlaying"] << ", time ... " << sItem["timeNow"] << ":" << sItem["timeTotal"];
    return sItem;
}

#elif defined(Q_OS_ANDROID)

AudioService::AudioService(QObject *parent) : QObject(parent) { m_player = new AndroidAudioPlayer(this); }
AudioService::~AudioService() {}
void AudioService::configure(bool isActive) {}
void AudioService::load(QStringList tracks) { m_player->load(tracks); }
void AudioService::play() { m_player->play(); }
void AudioService::next() { m_player->next(); }
void AudioService::prev() { m_player->prev(); }
void AudioService::setPosition(double lfPos) { m_player->seekTo(lfPos); }
void AudioService::setRepeatMode(int iMode) { m_player->repeatMode(iMode); }
QVariantMap AudioService::allStatus() {
    //qDebug() << "audioService.cpp: " << "allStatus";
    return m_player->allStatus();
}

#endif
