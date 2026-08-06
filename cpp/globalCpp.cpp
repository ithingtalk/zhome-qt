#include "globalCpp.h"

GlobalCpp::GlobalCpp() :
    nasApi(NasApi()),
    awsIot(awsAccount),
    uploadsFileService(LocalFileService(nasApi, DbFileTransfer::TYPE_UPLOAD, dbFileTransfer)),
    downloadsFileService(LocalFileService(nasApi, DbFileTransfer::TYPE_DOWNLOAD, dbFileTransfer)),
    previewDocFileService(LocalFileService(nasApi)),
    previewImageFileService(LocalFileService(nasApi)),
    btFileService(LocalFileService(nasApi)),
    dbFiles(DbFiles(nasApi, uploadsFileService)),
    dbFilesShared(DbFiles(nasApi, true)),
    awsDbService(awsAccount, dbDevices),
    searchLocalIdevice(dbDevices)
{
    qDebug() << "globalCpp";
}

void GlobalCpp::conn()
{
    qDebug() << "globalCpp conn";
    dbDevices.conn();
    awsIot.conn();
    cmdServiceBt.conn(awsIot);
    cmdServiceDbFiles.conn(awsIot);
    cmdServiceConnectDevice.conn(awsIot);
    cmdServiceDeviceManagment.conn(awsIot);
    cmdServiceDeviceUser.conn(awsIot);
    cmdServiceLogin.conn(awsIot);
    cmdServiceUserService.conn(awsIot);
    dbFiles.conn();
	dbFilesShared.conn();
    dbFileTransfer.conn();
    qDebug() << "globalCpp conn done";
}

bool GlobalCpp::useLocalLink()
{
    return dbDevices.useLocalLink();
}
