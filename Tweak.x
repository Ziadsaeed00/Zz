#import <UIKit/UIKit.h>

// ==========================================
// 1. استهداف كلاسات الـ Swift المكتشفة في الـ Heap لحقن الاستجابات
// ==========================================

// استهداف مدير القيود الرئيسي (LPMPacingCappingHandler)
%hookf(BOOL, "_$s10IronSource25LPMPacingCappingHandlerC010isPacingOrD7Blocked3forSbAA16LPMPlacementInfoC_tF", id arg1) {
    return NO; // إرجاع لا: الإعلانات غير محظورة نهائياً بالـ Capping أو الـ Pacing
}

// استهداف دالة التحقق من التسليم (LPMDeliveryCappingConfig)
%hookf(BOOL, "_$s10IronSource24LPMDeliveryCappingConfigC17isDeliveryEnabledSbyF") {
    return YES; // نعم: التسليم متاح دائماً
}

// استهداف فحص الجاهزية للإعلانات كاملة الشاشة (LPMFullscreenAdController)
%hookf(BOOL, "_$s10IronSource26LPMFullscreenAdControllerC7isReadySbyF") {
    return YES; // نعم: الإعلان جاهز ومحمل دائماً في الذاكرة
}


// ==========================================
// 2. كلاسات بيئة التوافق لـ Objective-C (IronSource & UnityAds Core)
// ==========================================
%hook IronSource
+ (BOOL)isInterstitialReady { return YES; }
+ (BOOL)isRewardedVideoAvailable { return YES; }
%end

%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end


// ==========================================
// 3. التعامل مع خيارات الموافقة (InMobi CMP المكتشفة في الشبكة)
// ==========================================
%hook ISConsentManager
- (BOOL)isConsentGiven { return YES; }
%end


// ==========================================
// 4. دالة التحقق عند تشغيل التطبيق
// ==========================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"LevelPlay Multi-Hook"
                                                                           message:@"تم محاكاة موافقة الإعلانات وتخطي الـ Capping محلياً بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
