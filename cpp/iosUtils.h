#ifndef IOSUTILS_H
#define IOSUTILS_H

#include <QObject>
#include <qqmlintegration.h>
#include <qtmetamacros.h>


class IosUtils : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool leftGestureEnabled READ isGestureLeftEnabled WRITE enableGestureLeft NOTIFY leftGestureEnabledChanged)
    Q_PROPERTY(bool rightGestureEnabled READ isGestureRightEnabled WRITE enableGestureRight NOTIFY rightGestureEnabledChanged)

signals:
    void leftGestureEnabledChanged();
    void rightGestureEnabledChanged();

public:
    explicit IosUtils(QObject *parent = nullptr);
    ~IosUtils();

public slots:
    void appendUploadFiles(const QString &strCurrSubDir, const QStringList &strFiles);
    void uploadFiles(int iTypeImageVideo, QString strCurrSubDir);

    bool isGestureLeftEnabled();
    bool isGestureRightEnabled();
    void enableGestureLeft(bool bEnabled);
    void enableGestureRight(bool bEnabled);

private:
    const QString LOCAL_SETTING_GESTURE_LEFT_ENABLED = "LOCAL_SETTING_GESTURE_LEFT_ENABLED";
    const QString LOCAL_SETTING_GESTURE_RIGHT_ENABLED = "LOCAL_SETTING_GESTURE_RIGHT_ENABLED";
};

#endif // IOSUTILS_H
