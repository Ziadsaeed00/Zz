#import <UIKit/UIKit.h>
#import <substrate.h>

// ==========================================
// 1. كلاسات بيئة التوافق التقليدية لـ Objective-C
// ==========================================
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

%hook IronSource
+ (BOOL)isInterstitialReady { return YES; }
+ (BOOL)isRewardedVideoAvailable { return YES; }
%end

%hook ISConsentManager
- (BOOL)isConsentGiven { return YES; }
%end


// ==========================================
// 2. الدوال البديلة لكلاسات Swift (LPM) الديناميكية
// ==========================================

// بديل لدالة الجاهزية (isReady) في LPMFullscreenAdController
static BOOL (*orig_LPMisReady)(id self, SEL _cmd);
BOOL new_LPMisReady(id self, SEL _cmd) {
    return YES; // جاهز دائماً
}

// بديل لدالة الفحص (isPacingOrCappingBlocked) في LPMPacingCappingHandler
static BOOL (*orig_LPMisBlocked)(id self, SEL _cmd, id arg1);
BOOL new_LPMisBlocked(id self, SEL _cmd, id arg1) {
    return NO; // غير محظور دائماً
}

// بديل لدالة التسليم (isDeliveryEnabled) في LPMDeliveryCappingConfig
static BOOL (*orig_LPMisDeliveryEnabled)(id self, SEL _cmd);
BOOL new_LPMisDeliveryEnabled(id self, SEL _cmd) {
    return YES; // متاح دائماً
}


// ==========================================
// 3. التهيئة والحقن الديناميكي (Runtime Injection)
// ==========================================
%ctor {
    // حقن كلاس IronSource.LPMFullscreenAdController
    Class swiftFullscreenController = NSClassFromString(@"IronSource.LPMFullscreenAdController");
    if (swiftFullscreenController) {
        MSHookMessageEx(swiftFullscreenController, @selector(isReady), (IMP)new_LPMisReady, (IMP *)&orig_LPMisReady);
    }

    // حقن كلاس IronSource.LPMPacingCappingHandler
    Class swiftCappingHandler = NSClassFromString(@"IronSource.LPMPacingCappingHandler");
    if (swiftCappingHandler) {
        // نستخدم المنهجية الديناميكية للتحقق من وجود الاسم البرمجي للدالة الملوثة داخل الـ Runtime
        SEL pacingSelector = NSSelectorFromString(@"isPacingOrCappingBlockedWithPlacementInfo:");
        if (class_getInstanceMethod(swiftCappingHandler, pacingSelector)) {
            MSHookMessageEx(swiftCappingHandler, pacingSelector, (IMP)new_LPMisBlocked, (IMP *)&orig_LPMisBlocked);
        }
    }

    // حقن كلاس IronSource.LPMDeliveryCappingConfig
    Class swiftDeliveryConfig = NSClassFromString(@"IronSource.LPMDeliveryCappingConfig");
    if (swiftDeliveryConfig) {
        MSHookMessageEx(swiftDeliveryConfig, @selector(isDeliveryEnabled), (IMP)new_LPMisDeliveryEnabled, (IMP *)&orig_LPMisDeliveryEnabled);
    }

    // إظهار تنبيه نجاح الحقن المستقر بعد ثانيتين
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dynamic Runtime Active"
                                                                           message:@"تم تجاوز خطأ القوالب وحقن كلاسات الشبكة ديناميكياً!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"استمرار" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
