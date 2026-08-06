#include "androidAudioPlayer.h"
#include <QCoreApplication>

AndroidAudioPlayer::AndroidAudioPlayer(QObject *parent) : QObject(parent)
{
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "initialize",
        "(Landroid/content/Context;)V",
        context.object<jobject>()
        );
}

AndroidAudioPlayer::~AndroidAudioPlayer()
{
    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "release",
        "()V"
        );
}

void AndroidAudioPlayer::load(const QStringList &urls)
{
    QJniEnvironment env;
    jclass stringClass = env->FindClass("java/lang/String");
    jobjectArray jArray = env->NewObjectArray(urls.size(), stringClass, nullptr);

    for (int i = 0; i < urls.size(); ++i) {
        QJniObject jString = QJniObject::fromString(urls.at(i));
        env->SetObjectArrayElement(jArray, i, jString.object<jstring>());
    }

    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "load",
        "([Ljava/lang/String;)V",
        jArray
        );

    env->DeleteLocalRef(jArray);
}

void AndroidAudioPlayer::play()
{
    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "play",
        "()V"
        );
}

void AndroidAudioPlayer::next()
{
    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "next",
        "()V"
        );
}

void AndroidAudioPlayer::prev()
{
    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "prev",
        "()V"
        );
}

void AndroidAudioPlayer::seekTo(long seconds)
{
    QMutexLocker locker(&m_mutex);
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "seekTo",
        "(J)V",
        seconds
        );
}

QVariantMap AndroidAudioPlayer::allStatus() {
    //qDebug() << "androidAudioPlayer.cpp: " << "allStatus, waiting locker";
    QMutexLocker locker(&m_mutex);
    //qDebug() << "androidAudioPlayer.cpp: " << "allStatus, getPlayerState from QtAudioBridge";
    QJniObject state = QJniObject::callStaticMethod<jobject>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "getPlayerState",
        "()Lcom/ithingtalk/zhome/PlayerState;"
        );
    //qDebug() << "androidAudioPlayer.cpp: " << "allStatus, getPlayerState from QtAudioBridge done";
    return {
        {"isPlaying", state.getField<jboolean>("isPlaying")},
        {"trackName", state.getObjectField<jstring>("trackName").toString()},
        {"timeNow", qint64(state.getField<jlong>("timeNow"))},
        {"timeTotal", qint64(state.getField<jlong>("timeTotal"))}
    };
}

void AndroidAudioPlayer::repeatMode(int iMode)
{
    QMutexLocker locker(&m_mutex);
    qDebug() << "==================> androidAudioPlayer.cpp, repeatMode: " << iMode;
    QJniObject::callStaticMethod<void>(
        "com/ithingtalk/zhome/QtAudioBridge",
        "repeatMode",
        "(I)V",
        iMode
        );
}
