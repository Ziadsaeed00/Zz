#import <UIKit/UIKit.h>

// 1. تعريف واجهات كلاسات ironSource الأساسية لمنع أخطاء التجميع
@interface IronSource : NSObject
+ (BOOL)isInterstitialReady;
+ (BOOL)isRewardedVideoAvailable;
@end

@interface ISInterstitialManager : NSObject
+ (id)sharedManager;
- (BOOL)isInterstitialReady;
@end

@interface ISRewardedVideoManager : NSObject
+ (id)sharedManager;
- (BOOL)isRewardedVideoAvailable;
@end


// ==========================================
// 2. عمل Hook على الكلاس الرئيسي لـ ironSource
// ==========================================
%hook IronSource

+ (BOOL)isInterstitialReady {
    return YES; // إجبار الإعلانات البينية على أن تكون جاهزة دائماً
}

+ (BOOL)isRewardedVideoAvailable {
    return YES; // إجبار فيديوهات المكافآت على أن تكون متاحة دائماً
}

%end


// ==========================================
// 3. عمل Hook على مدراء الإعلانات الداخليين لضمان تخطي الفحص
// ==========================================
%hook ISInterstitialManager

- (BOOL)isInterstitialReady {
    return YES;
}

%end

%hook ISRewardedVideoManager

- (BOOL)isRewardedVideoAvailable {
    return YES;
}

%end


// ==========================================
// 4. إبقاء كلاسات الـ Capping السابقة كخط دفاع إضافي
// ==========================================
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

%hook BN_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
%end

%hook RV_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
%end


// ==========================================
// 5. دالة التحقق والتنبيه للتأكد من عمل الأداة
// ==========================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تـحـديـث الـحـقـن الـشـامـل"
                                                                           message:@"تم إجبار جاهزية إعلانات ironSource في الذاكرة!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
