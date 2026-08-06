#include "localSettings.h"

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <QtCore/QList>
#import <QtCore/QString>

@interface MediaPickerDelegate : NSObject <PHPickerViewControllerDelegate>
@property (nonatomic, copy) void (^callback)(NSArray<NSURL *> *);
- (instancetype)initWithCallback:(void (^)(NSArray<NSURL *> *))callback;
- (NSURL *)createSecureCopy:(NSURL *)sourceURL originalName:(NSString *)originalName;
@end

@implementation MediaPickerDelegate

- (void)dealloc {
    self.callback = nil;
}

- (instancetype)initWithCallback:(void (^)(NSArray<NSURL *> *))callback {
    self = [super init];
    if (self) {
        _callback = [callback copy];
    }
    return self;
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    if (self.callback) {
        NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];
        __unsafe_unretained __typeof__(self) weakSelf = self;

        dispatch_group_t group = dispatch_group_create();

        for (PHPickerResult *result in results) {
            BOOL isImage = [result.itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier];
            BOOL isVideo = [result.itemProvider hasItemConformingToTypeIdentifier:UTTypeMovie.identifier];
            if (!isImage && !isVideo) {
                continue;
            }

            dispatch_group_enter(group);
            NSString *typeIdentifier = isImage ? UTTypeImage.identifier : UTTypeMovie.identifier;
            if (!typeIdentifier) {
                dispatch_group_leave(group);
                continue;
            }

            if ([result.itemProvider hasItemConformingToTypeIdentifier:UTTypeImage.identifier] ||
                [result.itemProvider hasItemConformingToTypeIdentifier:UTTypeMovie.identifier]) {

                [result.itemProvider loadFileRepresentationForTypeIdentifier:typeIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                    @autoreleasepool {
                        NSString *originalName = url ? [[url.lastPathComponent componentsSeparatedByString:@"&"] firstObject] : @"unknown"; // ✅ 空安全处理
                        
                        [result.itemProvider loadItemForTypeIdentifier:typeIdentifier options:nil completionHandler:^(NSURL *securityScopedURL, NSError *error) {
                            if (error) {
                                NSLog(@"Load item error: %@", error.localizedDescription);
                                dispatch_group_leave(group);
                                return;
                            }

                            if (securityScopedURL) {
                                NSURL *tempCopy = [self createSecureCopy:securityScopedURL originalName:originalName];
                                if (tempCopy) {
                                    @synchronized (fileURLs) {
                                        [fileURLs addObject:tempCopy];
                                    }
                                }
                            }
                            dispatch_group_leave(group);
                        }];
                    }
                }];
            }
            else {
                dispatch_group_leave(group);
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (weakSelf.callback) {
                weakSelf.callback(fileURLs);
            }
            weakSelf.callback = nil;
        });
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (NSURL *)createSecureCopy:(NSURL *)sourceURL originalName:(NSString *)originalName {
    @try {
        NSString *cleanName = [[originalName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"=&?"]] componentsJoinedByString:@""];
        NSString *fileExtension = [sourceURL pathExtension];

        //NSString *uuid = [[NSUUID UUID] UUIDString];
        //NSString *finalName = [NSString stringWithFormat:@"%@_%@.%@", [cleanName stringByDeletingPathExtension], uuid, fileExtension];
        NSString *finalName = [NSString stringWithFormat:@"%@.%@", [cleanName stringByDeletingPathExtension], fileExtension];
        NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:finalName]];

        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
        __block NSError *copyError = nil;

        [coordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newURL) {
            if (!newURL || !tempURL || !tempURL.path) {
                NSLog(@"Invalid file URLs");
                return;
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempURL.path]) {
                [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
            }
            if (![[NSFileManager defaultManager] copyItemAtURL:newURL toURL:tempURL error:&copyError]) {
                NSLog(@"Copy failed: %@ -> %@ \nError: %@", newURL, tempURL, copyError);
            }
        }];

        return copyError ? nil : tempURL;
    } @finally {}
}

@end

@interface MediaPickerController : NSObject
@property (nonatomic, strong) MediaPickerDelegate *currentDelegate;
+ (instancetype)sharedInstance;
- (void)pickMedia:(void (^)(NSArray<NSURL *> *))callback ofType:(NSInteger)iTypeImageOrMovie;
- (UIViewController *)rootViewController;
@end

@implementation MediaPickerController

+ (instancetype)sharedInstance {
    static MediaPickerController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
    self.currentDelegate = nil;
}

- (void)pickMedia:(void (^)(NSArray<NSURL *> *))callback ofType:(NSInteger)iTypeImageOrMovie {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
        config.selectionLimit = 0;
        
        if (iTypeImageOrMovie == 0) {
            config.filter = [PHPickerFilter imagesFilter];
        } else if (iTypeImageOrMovie == 1) {
            config.filter = [PHPickerFilter videosFilter];
        }

        PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
        
        self.currentDelegate = [[MediaPickerDelegate alloc] initWithCallback:callback];
        picker.delegate = self.currentDelegate;

        UIViewController *rootVC = [self rootViewController];
        if (rootVC) {
            [rootVC presentViewController:picker animated:YES completion:nil];
        } else {
            NSLog(@"connot obtaion rootVC");
        }
    });
}

- (UIViewController *)rootViewController {
    NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
    for (UIScene *scene in scenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window.rootViewController;
                }
            }
        }
    }
    return nil;
}

@end

void mediaPickerController_selectPhoto(int iTypeImageVideo, void (^callback)(QList<QString>))
{
    if(!callback) {
        NSLog(@"no callback for selectPhoto");
        return;
    }
    [[MediaPickerController sharedInstance] pickMedia:^(NSArray<NSURL *> *urls) {
        if (!urls) {
            callback(QList<QString>());
            return;
        }
        NSString *appUploadPath = LocalSettings::uploadDir().toNSString();

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:appUploadPath]) {
            NSError *error = nil;
            if (![fileManager createDirectoryAtPath:appUploadPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create upload directory: %@", error.localizedDescription);
                callback(QList<QString>());
                return;
            }
        }

        QList<QString> selectedFiles;
        for (NSURL *url in urls) {
            NSString *fileName = [url lastPathComponent];
            if(!fileName) {
                continue;
            }

            if (!url || !url.path || ![NSFileManager.defaultManager fileExistsAtPath:url.path]) {
                NSLog(@"file is not exists: %@", url.path);
                continue;
            }

            NSString *safeFileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSString *destinationPath = [appUploadPath stringByAppendingPathComponent:safeFileName];
            NSError *error = nil;
            if ([NSFileManager.defaultManager fileExistsAtPath:destinationPath]) {
                if (![NSFileManager.defaultManager removeItemAtPath:destinationPath error:&error]) {
                    NSLog(@"remove file error: %@", error.localizedDescription);
                    continue;
                }
            }
            if ([[NSFileManager defaultManager] moveItemAtURL:url toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
                NSLog(@"======> copy file done: %@", destinationPath);
                selectedFiles.append("file://" + QString::fromNSString(destinationPath));
            }
            else {
                NSLog(@"copy file error: %@", error.localizedDescription);
            }
        }
        callback(selectedFiles);
    } ofType:iTypeImageVideo];
}
