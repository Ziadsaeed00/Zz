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
    %orig(getCleanRandomUUID());
}
%end

%hook IS_UserIdManager
- (id)getUserId {
    return getCleanRandomUUID();
}
%end

// ==========================================
// 3. التحكم بدورة حياة الإعلان وإلغاء القيود
// ==========================================
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
- (BOOL)isBannerCappingEnabled:(id)arg1 { return NO; }
%end

// تحديث الطلب تلقائياً فور إظهار الإعلان الحالي
%hook IronSource
+ (void)showInterstitialWithViewController:(UIViewController *)vc {
    %orig(vc);
    
    Class ironSourceClass = NSClassFromString(@"IronSource");
    if (ironSourceClass) {
        if ([ironSourceClass respondsToSelector:@selector(sharedInstance)]) {
            id instance = [ironSourceClass performSelector:@selector(sharedInstance)];
            if ([instance respondsToSelector:@selector(loadInterstitial)]) {
                [instance performSelector:@selector(loadInterstitial)];
            }
        } else if ([ironSourceClass respondsToSelector:@selector(loadInterstitial)]) {
            [ironSourceClass performSelector:@selector(loadInterstitial)];
        }
    }
}
%end

// كسر حظر السيرفر التكراري في حال حدوث فشل في التحميل
%hook IS_AdStateManager
- (void)onAdLoadFailed:(id)arg1 error:(id)arg2 {
    %orig(arg1, arg2);
    
    Class ironSourceClass = NSClassFromString(@"IronSource");
    if (ironSourceClass && [ironSourceClass respondsToSelector:@selector(setUserId:)]) {
        [ironSourceClass performSelector:@selector(setUserId:) withObject:getCleanRandomUUID()];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (ironSourceClass) {
            if ([ironSourceClass respondsToSelector:@selector(sharedInstance)]) {
                id instance = [ironSourceClass performSelector:@selector(sharedInstance)];
                if ([instance respondsToSelector:@selector(loadInterstitial)]) {
                    [instance performSelector:@selector(loadInterstitial)];
                }
            } else if ([ironSourceClass respondsToSelector:@selector(loadInterstitial)]) {
                [ironSourceClass performSelector:@selector(loadInterstitial)];
            }
        }
    });
}
%end

// ==========================================
// 4. تهيئة وحقن التعديلات مع التنبيه الآمن
// ==========================================
%ctor {
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = nil;
        
        // جلب الـ Root View Controller بشكل متوافق مع إصدارات iOS الحديثة لضمان استقرار التنبيه
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow* window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            rootViewController = window.rootViewController;
                            break;
                        }
                    }
                }
            }
        }
        
        if (!rootViewController) {
            rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        }

        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dynamic Ad Injection"
                                                                           message:@"تم تفعيل محرك إدارة الإعلانات الديناميكي بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"ابدأ التدفق الحقيقي" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                // الاستدعاء الآمن لمنع كراش الـ Selector الديناميكي عند الضغط
                Class ironSourceClass = NSClassFromString(@"IronSource");
                if (ironSourceClass) {
                    if ([ironSourceClass respondsToSelector:@selector(sharedInstance)]) {
                        id instance = [ironSourceClass performSelector:@selector(sharedInstance)];
                        if ([instance respondsToSelector:@selector(loadInterstitial)]) {
                            [instance performSelector:@selector(loadInterstitial)];
                        }
                    } else if ([ironSourceClass respondsToSelector:@selector(loadInterstitial)]) {
                        [ironSourceClass performSelector:@selector(loadInterstitial)];
                    }
                }
                
            }]];
            
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
