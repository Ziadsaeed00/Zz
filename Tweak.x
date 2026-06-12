#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>

static UIWindow *alertWindow = nil;

// ==========================================
// 1. عزل الـ Keychain لمنع تتبع الهوية القديمة
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
// 2. هوك التنشيط التلقائي فور تهيئة الـ SDK (Initialization Hook)
// ==========================================
%hook IronSource

// هوك على دالة التهيئة الأساسية لـ IronSource لضمان طلب الإعلان في الوقت المناسب تماماً
+ (void)initWithAppKey:(id)arg1 adUnits:(id)arg2 {
    %orig(arg1, adUnits); // دع التهيئة الأصلية تتم أولاً
    
    // فور انتهاء التهيئة، اطلب تحميل الإعلان تلقائياً في الخلفية
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class ironSourceClass = NSClassFromString(@"IronSource");
        if ([ironSourceClass respondsToSelector:@selector(loadInterstitial)]) {
            [ironSourceClass performSelector:@selector(loadInterstitial)];
        }
    });
}

// طلب إعلان جديد تلقائياً فور إغلاق الإعلان الحالي لضمان التكرار والتدفق
+ (void)showInterstitialWithViewController:(UIViewController *)vc {
    %orig(vc);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class ironSourceClass = NSClassFromString(@"IronSource");
        if ([ironSourceClass respondsToSelector:@selector(loadInterstitial)]) {
            [ironSourceClass performSelector:@selector(loadInterstitial)];
        }
    });
}
%end

// ==========================================
// 3. إلغاء قيود التكرار المحلية (Capping)
// ==========================================
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

// ==========================================
// 4. تهيئة وعرض التنبيه المستقر (بدون التسبب في كراش)
// ==========================================
%ctor {
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    alertWindow = [[UIWindow alloc] initWithWindowScene:windowScene];
                    break;
                }
            }
        }
        
        if (!alertWindow) {
            alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        
        alertWindow.rootViewController = [[UIViewController alloc] init];
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        [alertWindow makeKeyAndVisible];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ad Injection Active"
                                                                       message:@"تم ربط الدايلب بدورة حياة التطبيق والـ SDK بنجاح!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            alertWindow.hidden = YES;
            alertWindow = nil;
        }]];
        
        [alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
