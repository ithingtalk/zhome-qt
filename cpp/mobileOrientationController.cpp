#include "mobileOrientationController.h"
#include <QtCore/QJniObject>
#include <QtCore/QCoreApplication>

MobileOrientationController::MobileOrientationController(QObject *parent) : QObject(parent)
{

}

void MobileOrientationController::request(bool bLand)
{
    QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");
    if (activity.isValid()) {
        // SCREEN_ORIENTATION_LANDSCAPE: 0, SCREEN_ORIENTATION_PORTRAIT: 1
        activity.callMethod<void>("setRequestedOrientation", "(I)V", bLand ? 0 : 1);
    }
}
