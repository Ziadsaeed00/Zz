#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>

// ==========================================
// 1. عزل الـ Keychain لمنع تتبع الجهاز القديم
// ==========================================
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result);

OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    @autoreleasepool {
        NSDictionary *queryDict = (__bridge NSDictionary *)query;
        NSString *account = queryDict[(__bridge id)kSecAttrAccount];
        NSString *service = queryDict[(__bridge id)kSecAttrService];
        
        if ([account containsString:@"DeviceID"] || 
            [account containsString:@"userID"] || 
            [account containsString:@"accessToken"] ||
            [service containsString:@"appmetrica"] ||
            [service containsString:@"firebase"]) {
            
            return errSecItemNotFound;
        }
    }
    return orig_SecItemCopyMatching(query, result);
}

// ==========================================
// 2. إدارة الهويات الديناميكية المتجددة
// ==========================================
static NSString* getCleanRandomUUID() {
    return [[NSUUID UUID] UUIDString];
}

%hook IronSource
+ (void)setUserId:(id)arg1 {
    // تزوير المعرف عند كل محاولة تعيين يدوي
    %orig(getCleanRandomUUID());
}
%end

%hook IS_UserIdManager
- (id)getUserId {
    return getCleanRandomUUID();
}
%end

// ==========================================
// 3. التحكم الذكي بدورة حياة الإعلان (Ad Lifecycle)
// ==========================================

%hook IS_CappingManager
// إلغاء قيود التكرار تماماً لضمان السماح بطلب إعلانات متتالية
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
- (BOOL)isBannerCappingEnabled:(id)arg1 { return NO; }
%end

/* 
   ملاحظة هامة: قمنا بإزالة الهوك الإجباري لـ (isInterstitialReady = YES) 
   للسماح للـ SDK بتحميل الإعلان الفعلي من السيرفر أولاً وتجنب الإظهار الوهمي الفارغ.
*/

// هوك لإجبار التطبيق على إعادة طلب إعلان جديد فوراً عند إغلاق أو فشل الإعلان السابق
%hook IronSource
+ (void)showInterstitialWithViewController:(UIViewController *)vc {
    %orig(vc);
    // بمجرد إظهار الإعلان الحالي، نأمر الـ SDK بالبدء في تحميل الإعلان التالي في الخلفية فوراً
    [NSClassFromString(@"IronSource") performSelector:@selector(loadInterstitial)];
}
%end

// في حال فشل تحميل الإعلان بسبب السيرفر، نغير الجلسة فوراً ونعيد المحاولة
%hook IS_AdStateManager
- (void)onAdLoadFailed:(id)arg1 error:(id)arg2 {
    %orig(arg1, arg2);
    
    // توليد جلسة جديدة كلياً لكسر حظر السيرفر المؤقت
    [NSClassFromString(@"IronSource") performSelector:@selector(setUserId:) withObject:getCleanRandomUUID()];
    
    // إعادة محاولة الطلب بعد ثانية واحدة تلقائياً
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSClassFromString(@"IronSource") performSelector:@selector(loadInterstitial)];
    });
}
%end


// ==========================================
// 4. تهيئة وتنبيه التشغيل
// ==========================================
%ctor {
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dynamic Ad Injection"
                                                                           message:@"تم تفعيل محرك إدارة الإعلانات الديناميكي بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"ابدأ التدفق الحقيقي" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                // بدء أول عملية تحميل حقيقية للإعلان عند تشغيل التطبيق
                [NSClassFromString(@"IronSource") performSelector:@selector(loadInterstitial)];
            }]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
