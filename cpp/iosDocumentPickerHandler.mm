#include "localSettings.h"

#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <QtCore/QList>
#import <QtCore/QString>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface IosDocumentPickerHandler : NSObject <UIDocumentPickerDelegate>

@property (nonatomic, copy) void (^completionHandler)(NSArray<NSURL*>*);
@property (nonatomic, strong) NSMutableArray<NSURL*>* tempFiles;

+ (instancetype)sharedInstance;
- (void)openDocumentPicker:(void (^)(NSArray<NSURL*>*))completion;

@end

@implementation IosDocumentPickerHandler

+ (instancetype)sharedInstance {
    static IosDocumentPickerHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tempFiles = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSURL *url in _tempFiles) {
        [fm removeItemAtURL:url error:nil];
    }
}

- (void)openDocumentPicker:(void (^)(NSArray<NSURL*>*))completion {
    __weak typeof(self) weakSelf = self;
    self.completionHandler = [^(NSArray<NSURL*>* urls) {
        @autoreleasepool {
            if (!weakSelf) {
                return;
            }
            if (completion) {
                completion(urls);
            }
            [weakSelf.tempFiles removeAllObjects];
        }
    } copy];

    NSArray<UTType*>* contentTypes = @[
        UTTypeContent,       // Genaral data (iOS 14+)
        UTTypeData,          // binary data (iOS 14+)
        UTTypeItem           // all (iOS 14+)
    ];
    
    // iOS 14+
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:contentTypes
        asCopy:YES];
    picker.allowsMultipleSelection = YES;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;

    // iOS 15+
    UIViewController *rootVC = nil;
    NSSet<UIScene*> *scenes = [[UIApplication sharedApplication] connectedScenes];
    for (UIScene *scene in scenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] 
            && scene.activationState == UISceneActivationStateForegroundActive) 
        {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    rootVC = window.rootViewController;
                    break;
                }
            }
            if (rootVC) break;
        }
    }

    if (!rootVC) {
        NSLog(@"Failed to get root view controller");
        return;
    }

    [rootVC presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<NSURL*>* processedFiles = [NSMutableArray array];
    self.tempFiles = processedFiles;

    for (NSURL *sourceURL in urls) {
        dispatch_group_enter(group);
        [sourceURL startAccessingSecurityScopedResource];

        NSString *safeFileName = [sourceURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@""];
        NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        if(!safeFileName) {
            continue;
        }
        NSURL *tempURL = [tempDir URLByAppendingPathComponent:safeFileName];
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
        [coordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newURL) {
            @autoreleasepool {
                NSError *copyError = nil;
                if (!newURL || !tempURL || !tempURL.path) {
                    NSLog(@"Invalid file URLs");
                    return;
                }
                if ([[NSFileManager defaultManager] fileExistsAtPath:tempURL.path]) {
                    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
                }
                if ([[NSFileManager defaultManager] copyItemAtURL:newURL toURL:tempURL error:&copyError]) {
                    @synchronized (self.tempFiles) {
                        [self.tempFiles addObject:tempURL];
                    }
                } else {
                    NSLog(@"Copy failed: %@", copyError.localizedDescription);
                }
                [sourceURL stopAccessingSecurityScopedResource];
                dispatch_group_leave(group);
            }
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (self.completionHandler) {
            self.completionHandler(processedFiles);
        }
        [controller dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if (self.completionHandler) {
        self.completionHandler(nil);
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end

void documentPickerController_selectDocument(void (^callback)(QList<QString>)) {
    [[IosDocumentPickerHandler sharedInstance] openDocumentPicker:^(NSArray<NSURL *> *filesInTmpDir) {
        if (!filesInTmpDir) {
            callback(QList<QString>());
            return;
        }

        NSString *appUploadPath = LocalSettings::uploadDir().toNSString();
        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:appUploadPath]) {
            [fm createDirectoryAtPath:appUploadPath
                withIntermediateDirectories:YES
                attributes:nil
                error:nil];
        }

        QList<QString> selectedFiles;

        for (NSURL *tempUrl in filesInTmpDir) {
            NSString *fileName = [tempUrl lastPathComponent];
            NSString *safeName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSURL *destURL = [NSURL fileURLWithPath:[appUploadPath stringByAppendingPathComponent:safeName]];

            if (destURL && destURL.path && [fm fileExistsAtPath:destURL.path]) {
                [fm removeItemAtURL:destURL error:nil];
            }

            if (tempUrl && destURL && [fm moveItemAtURL:tempUrl toURL:destURL error:nil]) {
                NSString *qtPath = [NSString stringWithFormat:@"file://%@", destURL.path];
                selectedFiles.append(QString::fromNSString(qtPath));
            }
        }

        [filesInTmpDir enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL *stop) {
            [fm removeItemAtURL:obj error:nil];
        }];

        callback(selectedFiles);
    }];
}
