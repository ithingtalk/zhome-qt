#ifndef SCREENKEEPAWAKE_H
#define SCREENKEEPAWAKE_H

#include <QQmlEngine>
#include <QTimer>

#ifdef Q_OS_MACOS
#include <IOKit/pwr_mgt/IOPMLib.h>
#endif

class ScreenKeepAwake : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ScreenKeepAwake(QObject *parent = nullptr);
    ~ScreenKeepAwake();

public slots:
    void start();
    void stop();

private:
#if defined(Q_OS_MACOS)
    IOPMAssertionID assertionID;
#endif
#if defined(Q_OS_LINUX)
    QTimer *m_timer_linux = nullptr;
    uint m_inhibitCookie = 0;
#endif

    void releaseInhibition();
};


#endif // SCREENKEEPAWAKE_H

