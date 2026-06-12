#import <UIKit/UIKit.h>
#import <substrate.h>

// ==========================================
// 1. تعريف الدوال البديلة (Replacements) بأسلوب C التقليدي
// ==========================================

// بديل لدالة حظر القيود (LPMPacingCappingHandler)
static BOOL (*orig_LPMBlockCheck)(id arg1);
BOOL new_LPMBlockCheck(id arg1) {
    return NO; // لا: الإعلانات غير محظورة
}

// بديل لدالة جاهزية التسليم (LPMDeliveryCappingConfig)
static BOOL (*orig_LPMDeliveryCheck)(void);
BOOL new_LPMDeliveryCheck(void) {
    return YES; // نعم: التسليم متاح
}

// بديل لدالة فحص الجاهزية (LPMFullscreenAdController)
static BOOL (*orig_LPMReadyCheck)(void);
BOOL new_LPMReadyCheck(void) {
    return YES; // نعم: جاهز دائماً
}


// ==========================================
// 2. كلاسات التوافق التقليدية لـ Objective-C
// ==========================================
%hook IronSource
+ (BOOL)isInterstitialReady { return YES; }
+ (BOOL)isRewardedVideoAvailable { return YES; }
%end

%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

%hook ISConsentManager
- (BOOL)isConsentGiven { return YES; }
%end


// ==========================================
// 3. حقن الدوال ديناميكياً عند تشغيل التطبيق
// ==========================================
%ctor {
    // حل مشكلة Swift Mangling عبر البحث عن الرموز النصية مباشرة في الذاكرة لضمان نجاح الـ Compile
    
    // 1. هوك دالة LPMPacingCappingHandler
    void *lpmBlockSign = MSFindSymbol(NULL, "_$s10IronSource25LPMPacingCappingHandlerC010isPacingOrD7Blocked3forSbAA16LPMPlacementInfoC_tF");
    if (lpmBlockSign) {
        MSHookFunction(lpmBlockSign, (void *)new_LPMBlockCheck, (void **)&orig_LPMBlockCheck);
    }
    
    // 2. هوك دالة LPMDeliveryCappingConfig
    void *lpmDeliverySign = MSFindSymbol(NULL, "_$s10IronSource24LPMDeliveryCappingConfigC17isDeliveryEnabledSbyF");
    if (lpmDeliverySign) {
        MSHookFunction(lpmDeliverySign, (void *)new_LPMDeliveryCheck, (void **)&orig_LPMDeliveryCheck);
    }
    
    // 3. هوك دالة LPMFullscreenAdController
    void *lpmReadySign = MSFindSymbol(NULL, "_$s10IronSource26LPMFullscreenAdControllerC7isReadySbyF");
    if (lpmReadySign) {
        MSHookFunction(lpmReadySign, (void *)new_LPMReadyCheck, (void **)&orig_LPMReadyCheck);
    }

    // إظهار التنبيه لتأكيد الحقن
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"LevelPlay Multi-Hook"
                                                                           message:@"تم تخطي الـ Capping وحقن الذاكرة بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
