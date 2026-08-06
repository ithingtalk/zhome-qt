#ifndef UTILS_H
#define UTILS_H

#include <QQmlEngine>
#include <QImage>

class Utils: public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    Utils(QObject *parent = nullptr);
public slots:
    void checkCamoraPermission();
    bool isReadableDocument(const QString &filePath);
    bool isBinaryFile(const QString &filePath);
    void openFileDirectory(const QString &filePath);
    QString readFile(const QString &filePath);
    bool fileExists(const QUrl &filePath);
    qint64 fileSize(const QUrl &filePath);
    bool delCache();
    QString addLocalFilePrefix(QString filePath);
    QString removeLocalFilePrefix(const QString &fileUrl);

#if defined(HAS_QZXING)
    QString qrEncode(const QString &strMsg);
    QString qrDecode(const QImage &imagePath);
    QString qrDecodeFromBase64(const QString &base64Image);
#endif

    QString appVer();
public:
    static bool copyFile(const QString &sourcePath, const QString &destinationPath);
    static void appendUploadFiles(const QString &strCurrSubDir, const QStringList &strFiles);
    static QString fileSha256(const QString &filePath);
    static QString generateRandomString();
};

#endif // UTILS_H
