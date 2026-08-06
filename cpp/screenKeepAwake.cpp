#include <QQmlEngine>
#include <QObject>
#include <QGuiApplication>
#include "screenKeepAwake.h"

#ifdef Q_OS_ANDROID
// #include <QtCore/private/qandroidextras_p.h>
#include <QtCore/QJniObject>
#elif defined(Q_OS_LINUX)
#include <QDBusInterface>
#include <QDBusReply>
#include <QTimer>
#ifdef X11_AVAILABLE
#include <X11/Xlib.h>
#include <QtGui/6.11.1/QtGui/qpa/qplatformnativeinterface.h>
#endif
#endif

#ifdef Q_OS_MACOS
// #include <QtCore/private/qcore_mac_p.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

#ifdef Q_OS_IOS
extern "C" void ios_screenKeepAwake_set(bool bStart);
#endif

#ifdef Q_OS_WIN
#include <Windows.h>
#endif


ScreenKeepAwake::ScreenKeepAwake(QObject *parent) : QObject(parent) {}
ScreenKeepAwake::~ScreenKeepAwake() {
    qDebug() << "screenKeepAwake destroy done";
    stop();
    qDebug() << "screenKeepAwake destroy";
}

void ScreenKeepAwake::start() {
    qDebug() << "start ScreenKeepAwake";
#if defined(Q_OS_ANDROID)
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]{
        /*QJniObject activity = QtAndroidPrivate::activity();
        if (activity.isValid()) {
            QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
            if (window.isValid()) {
                window.callMethod<void>("addFlags", "(I)V", 0x00000080); // FLAG_KEEP_SCREEN_ON
            }
        }*/
    });
#elif defined(Q_OS_IOS)
    ios_screenKeepAwake_set(true);
#elif defined(Q_OS_WIN)
    SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED);
#elif defined(Q_OS_MACOS)
    IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                kIOPMAssertionLevelOn,
                                CFSTR("Video Playback"),
                                &assertionID);
#elif defined(Q_OS_LINUX)
    if (m_timer_linux) {
        m_timer_linux->deleteLater();
    }
    m_timer_linux = new QTimer(this);
    connect(m_timer_linux, &QTimer::timeout, this, [=]() { // use this->m_inhibitCookie
        if (QGuiApplication::platformName().contains("xcb")) { // X11
#ifdef X11_AVAILABLE
            if (auto *native = QGuiApplication::platformNativeInterface()) {
                auto *display = reinterpret_cast<Display*>(native->nativeResourceForIntegration("display"));
                if (display) {
                    XResetScreenSaver(display);
                    XFlush(display);
                }
                qDebug() << "x11 refresh screen locker done.";
            }
            else {
                qDebug() << "x11 refresh screen locker fail";
            }
#endif
        }
        else { // wayland
            QDBusInterface screenSaver(
                "org.freedesktop.ScreenSaver",
                "/org/freedesktop/ScreenSaver",
                "org.freedesktop.ScreenSaver",
                QDBusConnection::sessionBus()
                );

            // try two way
            QDBusReply<void> reply = screenSaver.call("SimulateUserActive");
            if (!reply.isValid()) {
                qDebug() << "screenSaver fail, try other method ...";
                // Fallback: 使用抑制接口
                QDBusReply<uint> inhibitReply = screenSaver.call(
                    "Inhibit",
                    QCoreApplication::applicationName(),
                    "Prevent screen locking"
                    );

                if (inhibitReply.isValid()) {
                    m_inhibitCookie = inhibitReply.value();
                    qDebug() << "inhibit ok, save id";
                } else {
                    qWarning() << "all fail:"
                               << reply.error().message()
                               << inhibitReply.error().message();
                }
            }
            else {
                qDebug() << "screenSaver ok.";
            }
        }
    });
    m_timer_linux->start(50 * 1000); // reset per 50s
#endif
}

void ScreenKeepAwake::stop() {
    qDebug() << "stop ScreenKeepAwake";
#if defined(Q_OS_ANDROID)
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]{
        /*QJniObject activity = QtAndroidPrivate::activity();
        if (activity.isValid()) {
            QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
            if (window.isValid()) {
                window.callMethod<void>("clearFlags", "(I)V", 0x00000080); // FLAG_KEEP_SCREEN_ON
            }
        }*/
    });
#elif defined(Q_OS_IOS)
    ios_screenKeepAwake_set(false);
#elif defined(Q_OS_WIN)
    SetThreadExecutionState(ES_CONTINUOUS);
#elif defined(Q_OS_MACOS)
    IOPMAssertionRelease(assertionID);
#elif defined(Q_OS_LINUX)
    if (m_timer_linux) {
        m_timer_linux->deleteLater();
        m_timer_linux = nullptr;
    }
    releaseInhibition();
#endif
}

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
void ScreenKeepAwake::releaseInhibition()
{
    qDebug() << "releaseInhibition";
    if (m_inhibitCookie != 0) {
        QDBusInterface screenSaver(
            "org.freedesktop.ScreenSaver",
            "/org/freedesktop/ScreenSaver",
            "org.freedesktop.ScreenSaver",
            QDBusConnection::sessionBus()
            );

        QDBusReply<void> reply = screenSaver.call("UnInhibit", m_inhibitCookie);
        if (!reply.isValid()) {
            qWarning() << "解除抑制失败:" << reply.error().message();
        }
        m_inhibitCookie = 0;
        qDebug() << "releaseInhibition done";
    }
}
#endif
