#ifndef GLOBALCPP_H
#define GLOBALCPP_H

#include "dbDevices.h"
#include "dbFileTransfer.h"
#include "dbFiles.h"
#include "localFileService.h"
#include "nasApi.h"
#include "searchLocalIdevice.h"
#include "themeManager.h"
#include "localAccount.h"
#include "utils.h"
#include "awsAccount.h"
#include "awsDbService.h"
#include "awsIot.h"
#include "libp2p_export.h"

#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID)
#include "mobileOrientationController.h"
#endif

#if defined(Q_OS_IOS)
#include "iosUtils.h"
#endif

#if defined(Q_OS_ANDROID)
#include "androidUtils.h"
#endif

class GlobalCpp
{
public:
    GlobalCpp();

public:
    CmdService cmdServiceBt;
    CmdService cmdServiceDbFiles;

    CmdService cmdServiceConnectDevice;
    CmdService cmdServiceDeviceManagment;
    CmdService cmdServiceDeviceUser;
    CmdService cmdServiceLogin;
    CmdService cmdServiceUserService;

    NasApi nasApi;
    ThemeManager themeManager;
#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID)
    MobileOrientationController mobileOrientationController;
#endif
#if defined(Q_OS_ANDROID)
    AndroidUtils androidUtils;
#endif
#if defined(Q_OS_IOS)
    IosUtils iosUtils;
#endif
    DbFileTransfer dbFileTransfer;
    LocalFileService uploadsFileService;
    LocalFileService downloadsFileService;
    LocalFileService previewDocFileService;
    LocalFileService previewImageFileService;
    LocalFileService btFileService;
    DbFiles dbFiles;
    DbFiles dbFilesShared;
    Utils utils;
    DbDevices dbDevices;
    LocalAccount localAccount;
    SearchLocalIdevice searchLocalIdevice;
    AwsAccount awsAccount;
    AwsDbService awsDbService;
    AwsIot awsIot;

public:
    void conn();
    bool useLocalLink();
};

extern GlobalCpp *g_app;

#endif // GLOBALCPP_H
