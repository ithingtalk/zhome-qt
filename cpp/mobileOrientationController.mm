#include "mobileOrientationController.h"
#include <UIKit/UIKit.h>

@interface CustomViewController : UIViewController
@property (nonatomic, assign) UIInterfaceOrientationMask supportedOrientations;
@end

@implementation CustomViewController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.supportedOrientations;
}
@end

static CustomViewController *currentCustomVC = nil;

MobileOrientationController::MobileOrientationController(QObject *parent) : QObject(parent) {}

void MobileOrientationController::request(bool bLand)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientationMask request_ori = 0;
        if (currentCustomVC) {
            [currentCustomVC dismissViewControllerAnimated:NO completion:nil];
        }
        currentCustomVC = [[CustomViewController alloc] init];
        request_ori = bLand ? UIInterfaceOrientationMaskLandscapeRight : UIInterfaceOrientationMaskPortrait;
        currentCustomVC.supportedOrientations = request_ori;
        // Get the current root view controller
        UIViewController *rootVC = nil;
        UIWindowScene *windowScene = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    windowScene = (UIWindowScene *)scene;
                    if (windowScene.windows.count > 0) {
                        rootVC = windowScene.windows.firstObject.rootViewController;
                        break;
                    }
                }
            }
        }
        if (rootVC && windowScene) {
            [rootVC presentViewController:currentCustomVC animated:NO completion:^{
                if (@available(iOS 16.0, *)) {
                    NSLog(@"request ori for ios16 newer: %d", bLand);
                    UIInterfaceOrientationMask targetOrientationMask = 0;
                    if (request_ori & UIInterfaceOrientationMaskLandscapeLeft) {
                        targetOrientationMask |= UIInterfaceOrientationMaskLandscapeLeft;
                    } else if (request_ori & UIInterfaceOrientationMaskLandscapeRight) {
                        targetOrientationMask |= UIInterfaceOrientationMaskLandscapeRight;
                    } else {
                        targetOrientationMask = UIInterfaceOrientationMaskPortrait;
                    }
                    [windowScene requestGeometryUpdateWithPreferences:[[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:targetOrientationMask]
                                                       errorHandler:^(NSError * _Nonnull error) {
                        NSLog(@"Failed to update orientation: %@", error);
                    }];
                } else {
                    UIDevice *device = [UIDevice currentDevice];
                    UIDeviceOrientation request_ori_device = bLand ? UIDeviceOrientationLandscapeRight : UIDeviceOrientationPortrait;
                    [device setValue:@(request_ori_device) forKey:@"orientation"];
                }
                [currentCustomVC dismissViewControllerAnimated:NO completion:nil];
            }];
        }
    });
}
