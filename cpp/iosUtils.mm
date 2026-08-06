#include <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#include <QString>
#include <QFile>
#include <QCoreApplication>

extern "C" void ios_screenKeepAwake_set(bool bStart)
{
    UIApplication *app = [UIApplication sharedApplication];
    app.idleTimerDisabled = bStart ? YES : NO;
}

void requestPhotoLibraryAuthorization() {
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            NSLog(@"no authorization");
        }
    }];
}

void saveFileToPhotoAlbum(NSURL *fileURL, int iType) {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetChangeRequest = nil;
        if(iType == 1) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        }
        else { // if(iType == 0) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        }

        if (assetChangeRequest) {
            NSLog(@"assetChangeRequest ok");
        } else {
            NSLog(@"assetChangeRequest fail");
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"saveFileToPhotoAlbum success");
        } else {
            NSLog(@"saveFileToPhotoAlbum fail: %@", error.localizedDescription);
        }
        // always delete source file when copy compleate, even if success or fail
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *deleteError = nil;
        if ([fileManager removeItemAtURL:fileURL error:&deleteError]) {
            NSLog(@"delete source file success");
        } else {
            NSLog(@"delete source file fail: %@", deleteError.localizedDescription);
        }
    }];
}

bool moveFileToDocumentFolder(NSURL *sourceURL) {
    @autoreleasepool {

        if(sourceURL == nil) { return false; }

        NSFileManager *fileManager = [NSFileManager defaultManager];

        // get Zhome dir
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *zhomeURL = [documentsURL URLByAppendingPathComponent:@"Zhome" isDirectory:YES];

        if(zhomeURL == nil) { return false; }

        // create Zhome dir if none
        NSError *error;
        if (![fileManager createDirectoryAtURL:zhomeURL
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error]) {
            NSLog(@"moveItemToZhome create Zhome dir fail: %@", error);
            return false;
        }

        NSString *lastPathComponent = [sourceURL lastPathComponent];
        if (lastPathComponent == nil) {
            return false;
        }
        NSURL *destURL = [zhomeURL URLByAppendingPathComponent:lastPathComponent];
        if(destURL == nil) { return false; }

        // moveItem
        if (![fileManager moveItemAtURL:sourceURL
                                  toURL:destURL
                                  error:&error]) {
            NSLog(@"moveItemToZhome fail: %@", error);
            return false;
        }

        return true;
    }
}

void ios_moveFileToNativeFolder(const QString& strSourceFile, int iType)
{
    requestPhotoLibraryAuthorization();

    NSString *sourceFilePath = [NSString stringWithUTF8String:strSourceFile.toUtf8().constData()];
    if (sourceFilePath == nil) {
        NSLog(@"source file invalid");
        return;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:sourceFilePath];

    if(iType == 0 || iType == 1) {
        saveFileToPhotoAlbum(fileURL, iType);
    }
    else {
        // moveFileToDocumentFolder(fileURL); // just proccess image and video now
    }
}
