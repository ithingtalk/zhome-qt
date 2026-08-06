#ifndef IOSORIENTATIONCONTROLLER_H
#define IOSORIENTATIONCONTROLLER_H

#include <QObject>
#include <qqmlintegration.h>

class MobileOrientationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit MobileOrientationController(QObject *parent = nullptr);

    Q_INVOKABLE void request(bool bLand);
};

#endif // IOSORIENTATIONCONTROLLER_H
