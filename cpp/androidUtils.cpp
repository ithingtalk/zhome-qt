#include "androidUtils.h"
#include "localSettings.h"
#include "utils.h"
// #include <QtCore/private/qandroidextras_p.h>
#include <QtCore/QJniObject>
#include <QColor>
#include <QFile>
#include <QFileInfo>
#include <QColor>
#include <QJniObject>
#include <QJniEnvironment>
#include <QDir>
#include "globalCpp.h"


AndroidUtils::AndroidUtils(QObject *parent) : QObject(parent) {}

AndroidUtils::~AndroidUtils() {}

void AndroidUtils::moveFileToGallery(const QString& sourceFilePath)
{
#if 0
    QJniObject context = QtAndroidPrivate::context();
    if (context.isValid()) {
        QFileInfo fileInfo(sourceFilePath);
        QString targetDir = "/sdcard/DCIM/Camera/"; // gallery dir
        QString targetFilePath = targetDir + fileInfo.fileName();

        QJniObject sourceFile = QJniObject("java/io/File", "(Ljava/lang/String;)V", QJniObject::fromString(sourceFilePath).object<jstring>());
        QJniObject targetFile = QJniObject("java/io/File", "(Ljava/lang/String;)V", QJniObject::fromString(targetFilePath).object<jstring>());

        if (sourceFile.callMethod<jboolean>("exists") && sourceFile.callMethod<jboolean>("canRead")) {
            QJniObject parentDir = targetFile.callObjectMethod("getParentFile", "()Ljava/io/File;");
            if (parentDir.callMethod<jboolean>("exists") || parentDir.callMethod<jboolean>("mkdirs")) {
                if (sourceFile.callMethod<jboolean>("renameTo", "(Ljava/io/File;)Z", targetFile.object<jobject>())) {
                    qDebug() << "File moved successfully";

                    // refresh multimedia library
                    QJniEnvironment env;
                    jclass stringClass = env->FindClass("java/lang/String");
                    jobjectArray paths = env->NewObjectArray(1, stringClass, QJniObject::fromString(targetFilePath).object<jstring>());
                    env->DeleteLocalRef(stringClass);

                    QJniObject::callStaticMethod<void>("android/media/MediaScannerConnection",
                                                       "scanFile",
                                                       "(Landroid/content/Context;[Ljava/lang/String;[Ljava/lang/String;Landroid/media/MediaScannerConnection$OnScanCompletedListener;)V",
                                                       context.object<jobject>(),
                                                       paths,
                                                       nullptr,
                                                       nullptr);
                    env->DeleteLocalRef(paths);
                } else {
                    qDebug() << "Failed to move file";
                }
            } else {
                qDebug() << "Failed to create target directory";
            }
        } else {
            qDebug() << "Source file does not exist or cannot be read";
        }
    } else {
        qDebug() << "Failed to get Android context";
    }
#endif
}

void AndroidUtils::setStatusBarStyle(const QColor &bgColor, bool darkText)
{
#if 0
    qDebug() << "setStatusBarstyle, darkText: " << darkText;
    auto task = [=]() {
        QJniObject activity = QNativeInterface::QAndroidApplication::context();
        if (!activity.isValid()) return;

        const int argb = (bgColor.alpha() << 24) | (bgColor.red() << 16) | (bgColor.green() << 8) | bgColor.blue();
        QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
        if (!window.isValid()) return;

        /*// set statusbar backgroud color
        window.callMethod<void>("addFlags", "(I)V", 0x80000000); // FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
        // window.callMethod<void>("addFlags", "(I)V", 0x00000400); // FLAG_LAYOUT_NO_LIMITS
        window.callMethod<void>("setStatusBarColor", "(I)V", argb);*/

        // set font color
        QJniObject decorView = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
        if (!decorView.isValid()) return;
        jint flags = decorView.callMethod<jint>("getSystemUiVisibility");
        // SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        flags = darkText ? (flags | 0x00002000) : (flags & ~0x00002000);
        // Xiaomi and HUAWEI setting
        QJniObject build = QJniObject::getStaticObjectField("android/os/Build", "MANUFACTURER", "Ljava/lang/String;");
        if (build.toString().contains("Xiaomi", Qt::CaseInsensitive)) {
            flags |= 0x00000100;
        }
        else if (build.toString().contains("HUAWEI", Qt::CaseInsensitive)) {
            flags |= 0x00000200;
        }
        decorView.callMethod<void>("setSystemUiVisibility", "(I)V", flags);
    };

    QNativeInterface::QAndroidApplication::runOnAndroidMainThread(task);
#endif
}

void AndroidUtils::selectFiles(const int iType)
{
    QJniObject intent("android/content/Intent");
    intent.callObjectMethod("setAction", "(Ljava/lang/String;)Landroid/content/Intent;", QJniObject::fromString("android.intent.action.GET_CONTENT").object());
    
    // Set MIME type based on iType
    QString mimeType;
    if (iType == 0) {
        mimeType = "image/*";
    } else if (iType == 1) {
        mimeType = "video/*";
    } else if (iType == 2) {
        mimeType = "audio/*";
    } else {
        mimeType = "*/*"; // For documents/other types
    }
    
    intent.callObjectMethod("setType", "(Ljava/lang/String;)Landroid/content/Intent;", QJniObject::fromString(mimeType).object());
    intent.callObjectMethod("putExtra", "(Ljava/lang/String;Z)Landroid/content/Intent;", QJniObject::fromString("android.intent.extra.ALLOW_MULTIPLE").object(), true);
/*
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([this, intent]() {
        QtAndroidPrivate::startActivity(intent.object(), 1001, this);
    });
*/
}

void AndroidUtils::handleActivityResult(int requestCode, int resultCode, const QJniObject &data)
{
    if (requestCode != 1001 || resultCode != QJniObject::getStaticField<jint>("android/app/Activity", "RESULT_OK")) {
        return;
    }

    QStringList filePaths;
    QJniObject clipData = data.callObjectMethod("getClipData", "()Landroid/content/ClipData;");
    
    if (clipData.isValid()) {
        const int count = clipData.callMethod<jint>("getItemCount");
        for (int i = 0; i < count; ++i) {
            QJniObject item = clipData.callObjectMethod("getItemAt", "(I)Landroid/content/ClipData$Item;", i);
            QJniObject uri = item.callObjectMethod("getUri", "()Landroid/net/Uri;");
            const QString path = copyToPrivateDir(uri);
            if (!path.isEmpty()) {
                filePaths << g_app->utils.addLocalFilePrefix(path);
            }
        }
    } else {
        QJniObject uri = data.callObjectMethod("getData", "()Landroid/net/Uri;");
        const QString path = copyToPrivateDir(uri);
        if (!path.isEmpty()) {
            filePaths << g_app->utils.addLocalFilePrefix(path);
        }
    }

    if (!filePaths.isEmpty()) {
        Utils::appendUploadFiles(m_sub_dir, filePaths);
    }
}

QString AndroidUtils::copyToPrivateDir(const QJniObject &uri) const
{
#if 0
    qDebug() << "copyToPrivateDir: " << uri.toString();
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject resolver = context.callObjectMethod("getContentResolver", "()Landroid/content/ContentResolver;");
    
    QJniObject inputStream = resolver.callObjectMethod("openInputStream", 
        "(Landroid/net/Uri;)Ljava/io/InputStream;", uri.object());
    if (!inputStream.isValid()) {
        return QString();
    }

    // Get filename using OpenableColumns
    QJniObject cursor = resolver.callObjectMethod(
        "query",
        "(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;",
        uri.object(),
        nullptr,  // Projection
        nullptr,  // Selection
        nullptr,  // Selection args
        nullptr   // Sort order
    );

    QString fileName;
    if (cursor.isValid()) {
        if (cursor.callMethod<jboolean>("moveToFirst")) {
            QJniObject name = cursor.callObjectMethod(
                "getString",
                "(I)Ljava/lang/String;",
                cursor.callMethod<jint>(
                    "getColumnIndex",
                    "(Ljava/lang/String;)I",
                    QJniObject::getStaticObjectField(
                        "android/provider/OpenableColumns",
                        "DISPLAY_NAME",
                        "Ljava/lang/String;"
                    ).object<jstring>()
                )
            );
            fileName = name.toString();
        }
        cursor.callMethod<void>("close");
    }

    // Fallback if name not found
    if (fileName.isEmpty()) {
        fileName = QJniObject(uri.object()).callObjectMethod("getLastPathSegment", "()Ljava/lang/String;").toString();
    }

    QString fullPath = LocalSettings::uploadDir() + "/" + fileName;
    
    QFile file(fullPath);
    if (file.open(QIODevice::WriteOnly)) {
        QJniEnvironment env;
        jbyteArray buffer = env->NewByteArray(4096);
        jint bytesRead;
        do {
            bytesRead = inputStream.callMethod<jint>("read", "([B)I", buffer);
            if (bytesRead > 0) {
                jbyte *bytes = env->GetByteArrayElements(buffer, nullptr);
                file.write(reinterpret_cast<char*>(bytes), bytesRead);
                env->ReleaseByteArrayElements(buffer, bytes, 0);
            }
        } while (bytesRead > 0);
        file.close();
        return fullPath;
    }
#endif
    return QString();
}

void AndroidUtils::uploadFiles(int iTypeImageVideo, QString strCurrSubDir)
{
    m_sub_dir = strCurrSubDir;
    m_type_image_video = iTypeImageVideo;
    selectFiles(iTypeImageVideo);
}
