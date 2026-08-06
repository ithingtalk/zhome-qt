#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLocale>
#include <QTranslator>
#include <QPermissions>
#include "singleInstance.h"
#include "globalCpp.h"

#if defined(HAS_QZXING) && defined(QZXING_QML)
#include <QZXing.h>
#endif

extern "C" void configureAudioSessionIos();

GlobalCpp *g_app = nullptr;

int main(int argc, char *argv[])
{
    // QCoreApplication::setOrganizationName("Ithingtalk");
    // QCoreApplication::setApplicationName("Zhome");

    QGuiApplication app(argc, argv);

    QString appKey = "MyUniqueAppKey";
    SingleInstance singleInstance(appKey);

    if (singleInstance.isRunning()) {
        qDebug() << "\n===========================================";
        qDebug() << "Another instance is already running.";
        qDebug() << "===========================================\n";
        return -1;
    }

    QQmlApplicationEngine engine;

#if defined(HAS_QZXING) && defined(QZXING_QML)
    QZXing::registerQMLTypes();
    QZXing::registerQMLImageProvider(engine);
#endif
#if defined(HAS_QZXING)
    QCameraPermission cameraPermission;
    if (qApp->checkPermission(cameraPermission) != Qt::PermissionStatus::Granted) {
        qApp->requestPermission(QCameraPermission{}, [](const QPermission &permission) {
            if (permission.status() != Qt::PermissionStatus::Granted)
                qDebug() << "camera permission is not granted";
        });
    }
#endif

    Aws::SDKOptions m_aws_options;
    m_aws_options.loggingOptions.logLevel = Aws::Utils::Logging::LogLevel::Off;
    Aws::InitAPI(m_aws_options);

    g_app = new GlobalCpp();
    g_app->conn();

    engine.rootContext()->setContextProperty("cmdServiceBtFromCpp", &g_app->cmdServiceBt);

    engine.rootContext()->setContextProperty("cmdServiceDbFilesFromCpp", &g_app->cmdServiceDbFiles);
    engine.rootContext()->setContextProperty("cmdServiceConnectDeviceFromCpp", &g_app->cmdServiceConnectDevice);
    engine.rootContext()->setContextProperty("cmdServiceDeviceManagmentFromCpp", &g_app->cmdServiceDeviceManagment);
    engine.rootContext()->setContextProperty("cmdServiceDeviceUserFromCpp", &g_app->cmdServiceDeviceUser);
    engine.rootContext()->setContextProperty("cmdServiceLoginFromCpp", &g_app->cmdServiceLogin);
    engine.rootContext()->setContextProperty("cmdServiceUserServiceFromCpp", &g_app->cmdServiceUserService);

    engine.rootContext()->setContextProperty("nasApiFromCpp", &g_app->nasApi);
    engine.rootContext()->setContextProperty("themeManagerFromCpp", &g_app->themeManager);
#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID)
    engine.rootContext()->setContextProperty("mobileOrientationControllerFromCpp", &g_app->mobileOrientationController);
#endif
#if defined(Q_OS_ANDROID)
    engine.rootContext()->setContextProperty("androidUtilsFromCpp", &g_app->androidUtils);
#endif
#if defined(Q_OS_IOS)
    engine.rootContext()->setContextProperty("iosUtilsFromCpp", &g_app->iosUtils);
#endif
    engine.rootContext()->setContextProperty("dbFileTransferFromCpp", &g_app->dbFileTransfer);
    // must init after g_pDbFileTransferCpp !!!
    engine.rootContext()->setContextProperty("uploadingListFromCpp", &g_app->uploadsFileService);
    engine.rootContext()->setContextProperty("downloadingListFromCpp", &g_app->downloadsFileService);
    engine.rootContext()->setContextProperty("previewDocFromCpp", &g_app->previewDocFileService);
    engine.rootContext()->setContextProperty("previewImageFromCpp", &g_app->previewImageFileService);
    engine.rootContext()->setContextProperty("dbFilesFromCpp", &g_app->dbFiles);
    engine.rootContext()->setContextProperty("dbFilesSharedFromCpp", &g_app->dbFilesShared);
    engine.rootContext()->setContextProperty("utilsFromCpp", &g_app->utils);
    engine.rootContext()->setContextProperty("dbDevicesFromCpp", &g_app->dbDevices);
    engine.rootContext()->setContextProperty("localAccountFromCpp", &g_app->localAccount);
    engine.rootContext()->setContextProperty("searchLocalIdeviceFromCpp", &g_app->searchLocalIdevice);
    engine.rootContext()->setContextProperty("btFileServiceFromCpp", &g_app->btFileService);
    engine.rootContext()->setContextProperty("awsAccountFromCpp", &g_app->awsAccount);
    engine.rootContext()->setContextProperty("awsDbServiceFromCpp", &g_app->awsDbService);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    QTranslator translator;
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString &locale : uiLanguages) {
		qDebug() << "locale: " << locale;
        const QString baseName = "Zhome_" + QLocale(locale).name();
        if (translator.load(":/i18n/" + baseName)) {
            app.installTranslator(&translator);
            break;
        }
    }

    // MainDefault.qml Universal.qml, Material.qml, Fusion.qml, etc.
    QString strMainPage = g_app->themeManager.getStyle();
    if (g_app->themeManager.isStyleDefault() || g_app->themeManager.isStyleF()) {
        strMainPage = "MainDefault";
    }
    engine.loadFromModule("Zhome", strMainPage);

    int iRet = app.exec();

    qDebug() << "app.exec done";

    delete g_app;

    qDebug() << "delete g_app done";

    Aws::ShutdownAPI(m_aws_options);

    qDebug() << "shutdown aws api done";

    return iRet;
}
