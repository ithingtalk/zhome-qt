#include "iosUtils.h"
#include <qdebug.h>
#include <globalCpp.h>
#include "localSettings.h"

extern "C" void ios_enableIOSSlideBack();

extern void mediaPickerController_selectPhoto(int iTypeImageVideo, void (^callback)(QStringList));
extern void documentPickerController_selectDocument(void (^callback)(QStringList));

IosUtils::IosUtils(QObject *parent) : QObject(parent) {}
IosUtils::~IosUtils() {}

// strCurrSubDir: "/MyFiles/xxx"
void IosUtils::appendUploadFiles(const QString &strCurrSubDir, const QStringList &strFiles)
{
    for (int iLoop = 0; iLoop < strFiles.size(); iLoop++) {
        QString strFileName = strFiles[iLoop].mid(strFiles[iLoop].lastIndexOf("/") + 1);
        QString serverUrl = g_app->nasApi.getRemoteFilePath(strCurrSubDir + "/" + strFileName);
        g_app->dbFileTransfer.add(0, serverUrl, strFiles[iLoop]);
    }
}

void IosUtils::uploadFiles(int iTypeImageVideo, QString strCurrSubDir) {
    if (iTypeImageVideo == 0 || iTypeImageVideo == 1) { // video or image, select from picture folder
        mediaPickerController_selectPhoto(iTypeImageVideo, ^(QStringList strFiles) {
            appendUploadFiles(strCurrSubDir, strFiles);
        });
    }
    else {
        documentPickerController_selectDocument(^(QStringList strFiles) {
            appendUploadFiles(strCurrSubDir, strFiles);
        });
    }
}

bool IosUtils::isGestureLeftEnabled()
{
    return LocalSettings::getBool(LOCAL_SETTING_GESTURE_LEFT_ENABLED);
}

bool IosUtils::isGestureRightEnabled()
{
    return LocalSettings::getBool(LOCAL_SETTING_GESTURE_RIGHT_ENABLED);
}

void IosUtils::enableGestureLeft(bool bEnabled)
{
    if (bEnabled != isGestureLeftEnabled()) {
        LocalSettings::setBool(LOCAL_SETTING_GESTURE_LEFT_ENABLED, bEnabled);
        emit leftGestureEnabledChanged();
    }
}

void IosUtils::enableGestureRight(bool bEnabled)
{
    if (bEnabled != isGestureRightEnabled()) {
        LocalSettings::setBool(LOCAL_SETTING_GESTURE_RIGHT_ENABLED, bEnabled);
        emit rightGestureEnabledChanged();
    }
}
