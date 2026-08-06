#include <QFile>
#include <QGuiApplication>
#include <QPermissions>
#include <QCryptographicHash>
#include <QMimeDatabase>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>
#include <QDir>
#include "globalCpp.h"
#include "localSettings.h"
#include "utils.h"
#include <QString>
#include <QBuffer>
#include <QRandomGenerator>
#include "VER.h"

#if defined(HAS_QZXING)
#include <QZXing.h>
#endif

// 生成8位十六进制随机字符串 (如: A1B2C3D4)
QString Utils::generateRandomString() {
    quint32 randomValue = QRandomGenerator::global()->generate();
    return QString("%1").arg(randomValue, 12, 16, QChar('0')).toUpper();
}

Utils::Utils(QObject *parent) : QObject(parent) {}

void Utils::checkCamoraPermission()
{
    auto status = qApp->checkPermission(QCameraPermission{});

    if (status == Qt::PermissionStatus::Undetermined) {
        qApp->requestPermission(QCameraPermission{}, [](const QPermission &permission) {
            if (permission.status() == Qt::PermissionStatus::Granted) {
                qDebug() << "Camera permission granted";
            } else {
                qWarning() << "Camera permission denied";
                // 处理拒绝逻辑（如弹窗引导用户去设置）
                // QMessageBox::warning(nullptr, "Permission Required", "Please enable camera permission in system settings");
            }
        });
    }
    else if (status == Qt::PermissionStatus::Granted) {

    }
    else {
        qWarning() << "Camera permission denied";
    }
}

bool Utils::copyFile(const QString &sourcePath, const QString &destinationPath)
{
    QFile sourceFile(sourcePath);
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open source file:" << sourcePath;
        return false;
    }

    QFile destinationFile(destinationPath);
    if (!destinationFile.open(QIODevice::WriteOnly)) {
        qWarning() << "Failed to open destination file:" << destinationPath;
        sourceFile.close();
        return false;
    }

    char buffer[4096];
    qint64 bytesRead;
    while ((bytesRead = sourceFile.read(buffer, sizeof(buffer))) > 0) {
        if (destinationFile.write(buffer, bytesRead) != bytesRead) {
            qWarning() << "Failed to write to destination file:" << destinationPath;
            sourceFile.close();
            destinationFile.close();
            return false;
        }
    }

    if (bytesRead == -1) {
        qWarning() << "Error reading from source file:" << sourcePath;
        sourceFile.close();
        destinationFile.close();
        return false;
    }

    sourceFile.close();
    destinationFile.close();
    return true;
}

void Utils::appendUploadFiles(const QString &strCurrSubDir, const QStringList &strFiles)
{
    for (int iLoop = 0; iLoop < strFiles.size(); iLoop++) {
        QString strFileName = strFiles[iLoop].mid(strFiles[iLoop].lastIndexOf("/") + 1);
        QString serverUrl = g_app->nasApi.getRemoteFilePath(strCurrSubDir + "/" + strFileName);
        g_app->dbFileTransfer.add(0, serverUrl, strFiles[iLoop]);
    }
}

QString Utils::fileSha256(const QString &filePath)
{
    QFile file(filePath);
    if (file.open(QIODevice::ReadOnly)) {
        QCryptographicHash hash(QCryptographicHash::Sha256);
        if (hash.addData(&file)) { // 分块计算哈希值
            QByteArray result = hash.result();
            return QString(result.toHex());
        }
    }
    return QString();
}

bool Utils::isReadableDocument(const QString &filePath)
{
    QMimeDatabase mimeDb;
    QMimeType mimeType = mimeDb.mimeTypeForFile(filePath);

    // 检查是否是文档类型
    return mimeType.name().startsWith("text/") ||
           mimeType.name().contains("pdf") ||
           mimeType.name().contains("document") ||
           mimeType.name().contains("wordprocessing") ||
           mimeType.name().contains("spreadsheet");
}

bool Utils::isBinaryFile(const QString &filePath)
{
    QMimeDatabase mimeDb;
    QMimeType mimeType = mimeDb.mimeTypeForFile(filePath);

    // 检查是否是二进制类型（如压缩包、可执行文件）
    return mimeType.name().startsWith("application/x-") ||
           mimeType.name().contains("executable") ||
           mimeType.name().contains("archive") ||
           mimeType.name().contains("binary");
}

void Utils::openFileDirectory(const QString &filePath) {
#if !defined(Q_OS_IOS) && !defined(Q_OS_ANDROID)
#if defined(Q_OS_WIN)
    QProcess::startDetached("explorer", QStringList() << "/select," + QDir::toNativeSeparators(filePath));
#elif defined(Q_OS_MACOS)
    QProcess::startDetached("open", QStringList() << "-R" << QDir::toNativeSeparators(filePath));
#elif defined(Q_OS_LINUX)
    QFileInfo fileInfo(filePath);
    if (!QProcess::startDetached("xdg-open", QStringList() << fileInfo.absolutePath())) {
        QProcess::startDetached("nautilus", QStringList() << "--no-desktop" << "--select" << QDir::toNativeSeparators(filePath));
    }
#endif
#endif
}

QString Utils::readFile(const QString &filePath)
{
    QFile file(filePath);
    if (file.open(QIODevice::ReadOnly))
        return QTextStream(&file).readAll();
    return "";
}

bool Utils::fileExists(const QUrl &filePath) {
    return QFileInfo::exists(filePath.toLocalFile());
}

qint64 Utils::fileSize(const QUrl &filePath) {
    const QString localPath = filePath.toLocalFile();
    QFileInfo fileInfo(localPath);
    return fileInfo.exists() ? fileInfo.size() : -1;
}

bool Utils::delCache()
{
    QDir dir(LocalSettings::cacheDir());
    if (!dir.exists()) {
        qDebug() << "delCache: dir is not exists";
        return false;
    }
    if (dir.removeRecursively()) {
        qDebug() << "delCache success";
        return true;
    } else {
        qDebug() << "delCache: fail";
        return false;
    }
}

QString Utils::addLocalFilePrefix(QString filePath)
{
    QUrl url = QUrl::fromLocalFile(filePath);
    return url.toString();  // return: "file:///C:/path" or "file:///home/user"
}

QString Utils::removeLocalFilePrefix(const QString &fileUrl)
{
    QUrl url(fileUrl);
    return url.toLocalFile();  // return: "C:/path" or "/home/user"
}

#if defined(HAS_QZXING)
QString Utils::qrEncode(const QString &strMsg)
{
    if (strMsg.isEmpty()) {
        return QString();
    }
    // QImage image = QZXing::encodeData(strMsg);
    QImage image = QZXing::encodeData(strMsg, QZXing::EncoderFormat_QR_CODE, QSize(240, 240), QZXing::EncodeErrorCorrectionLevel_L, true, false);
    if (image.isNull()) {
        return QString();
    }
    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "PNG");
    QString base64 = QString("data:image/png;base64,") + byteArray.toBase64().data();
    return base64;
}

QString Utils::qrDecode(const QImage &imageToDecode)
{
    // QImage imageToDecode("file.png");
    QZXing decoder;
    //mandatory settings
    decoder.setDecoder( QZXing::DecoderFormat_QR_CODE | QZXing::DecoderFormat_EAN_13 );
    //optional settings
    //decoder.setSourceFilterType(QZXing::SourceFilter_ImageNormal | QZXing::SourceFilter_ImageInverted);
    decoder.setSourceFilterType(QZXing::SourceFilter_ImageNormal);
    decoder.setTryHarderBehaviour(QZXing::TryHarderBehaviour_ThoroughScanning | QZXing::TryHarderBehaviour_Rotate);
    return decoder.decodeImage(imageToDecode);
}

QString Utils::qrDecodeFromBase64(const QString &base64Image)
{
    QString base64Data = base64Image;
    if (base64Data.startsWith("data:image/png;base64,")) {
        base64Data = base64Data.mid(QString("data:image/png;base64,").length());
    }
    QByteArray imageData = QByteArray::fromBase64(base64Data.toUtf8());
    QImage image;
    if (!image.loadFromData(imageData)) {
        return QString("Invalid image data");
    }
    return qrDecode(image);
}
#endif

QString Utils::appVer()
{
    return APP_VERSION_STR;
}
