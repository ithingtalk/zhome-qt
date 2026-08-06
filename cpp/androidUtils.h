#ifndef ANDROIDUTILS_H
#define ANDROIDUTILS_H

#include <QMutex>
#include <QObject>
#include <QStringList>
#include <QQmlEngine>
#include <QColor>
#include <QJniObject>
#include <QJniEnvironment>
// #include <private/qandroidextras_p.h>

class AndroidUtils : public QObject //, public QAndroidActivityResultReceiver
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit AndroidUtils(QObject *parent = nullptr);
    ~AndroidUtils();

public slots:
    static void moveFileToGallery(const QString& sourceFilePath);
    void setStatusBarStyle(const QColor &bgColor, bool darkText);
    void uploadFiles(int iTypeImageVideo, QString strCurrSubDir);
    void selectFiles(const int iType);

private:
    void handleActivityResult(int receiverRequestCode, int resultCode, const QJniObject &data); // override;
    QString copyToPrivateDir(const QJniObject &uri) const;
    QString m_sub_dir;
    int m_type_image_video;
};

#endif // ANDROIDUTILS_H
