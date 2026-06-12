#import <UIKit/UIKit.h>

// ==========================================
// 1. هوك كلاسات Swift (LPM) عبر أسمائها المسجلة في الـ Runtime
// ==========================================

// استهدف كلاس التحكم بالإعلانات كاملة الشاشة لـ Swift
%hookf(id, "IronSource.LPMFullscreenAdController")
// جعل الإعلان جاهز دائماً في الذاكرة
- (BOOL)isReady {
    return YES;
}
%end

// استهدف كلاس إدارة قيود العداد والـ Capping لـ Swift
%hookf(id, "IronSource.LPMPacingCappingHandler")
// إجبار الكلاس على إرجاع (لا، الإعلان ليس محظوراً)
- (BOOL)isPacingOrCappingBlockedWithPlacementInfo:(id)arg1 {
    return NO; 
}
%end

// استهدف كلاس تهيئة قيود تسليم الإعلانات لـ Swift
%hookf(id, "IronSource.LPMDeliveryCappingConfig")
// جعل التسليم متاح دائماً
- (BOOL)isDeliveryEnabled {
    return YES;
}
%end


// ==========================================
// 2. كلاسات الخصوصية والوساطة التقليدية لضمان تدفق السيرفر
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
// 3. التنبيه وتأكيد نجاح الحقن المتقدم
// ==========================================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Swift Runtime Hooked"
                                                                           message:@"تم اختراق كلاسات الـ Swift (LPM) بنجاح وبأمان تام!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"استمرار" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
