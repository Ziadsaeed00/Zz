#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>

// ==========================================
// 1. هوك نظام الـ Keychain لمنع التطبيق من قراءة الهوية القديمة
// ==========================================

// تخزين الدالة الأصلية للنظام
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result);

// الدالة البديلة المعززة
OSStatus new_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    @autoreleasepool {
        NSDictionary *queryDict = (__bridge NSDictionary *)query;
        NSString *account = queryDict[(__bridge id)kSecAttrAccount];
        NSString *service = queryDict[(__bridge id)kSecAttrService];
        
        // إذا كان التطبيق يحاول قراءة معرف الجهاز أو الـ Token المحظور، نخدعه بأنه غير موجود
        if ([account containsString:@"DeviceID"] || 
            [account containsString:@"userID"] || 
            [account containsString:@"accessToken"] ||
            [service containsString:@"appmetrica"] ||
            [service containsString:@"firebase"]) {
            
            return errSecItemNotFound; // إرجاع خطأ (العنصر غير موجود) مجبراً
        }
    }
    // إذا كان طلب الـ Keychain لشيء آخر عادي، ندعه يمر بشكل طبيعي
    return orig_SecItemCopyMatching(query, result);
}


// ==========================================
// 2. تزوير الهويات والجلسات في الذاكرة (الطبقة الديناميكية)
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

// تثبيت جاهزية الإعلان محلياً
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

%hook IronSource
+ (BOOL)isInterstitialReady { return YES; }
+ (BOOL)isRewardedVideoAvailable { return YES; }
%end


// ==========================================
// 3. حقن التعديلات عند بدء التشغيل
// ==========================================
%ctor {
    // هوك مباشر على مستوى نظام الحماية C-Function للـ Keychain
    MSHookFunction((void *)SecItemCopyMatching, (void *)new_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching);

    // تنبيه نجاح قفل الـ Keychain والتزوير
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Keychain Blocked"
                                                                           message:@"تم عزل الـ Keychain وتوليد هويات صفرية بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"شغل الإعلانات" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
