#import <UIKit/UIKit.h>
#import <substrate.h>

// ==========================================
// 1. توليد معرف عشوائي فريد (UUID)
// ==========================================
static NSString* getCleanRandomUUID() {
    return [[NSUUID UUID] UUIDString];
}

// ==========================================
// 2. تزوير الهوية في طبقة Objective-C (IronSource SDK)
// ==========================================
%hook IronSource
+ (void)setUserId:(id)arg1 {
    NSString *fakeUser = getCleanRandomUUID();
    %orig(fakeUser); // تمرير المعرف العشوائي للسيرفر بدلاً من الأصلي
}
%end

%hook IS_UserIdManager
- (id)getUserId {
    return getCleanRandomUUID();
}
%end


// ==========================================
// 3. كلاسات بيئة التوافق والقيود المحلية (تثبيت الجاهزية)
// ==========================================
%hook IS_CappingManager
- (BOOL)isDeliveryEnabled:(id)arg1 { return YES; }
- (BOOL)isCappingEnabled:(id)arg1 { return NO; }
%end

%hook IronSource
+ (BOOL)isInterstitialReady { return YES; }
+ (BOOL)isRewardedVideoAvailable { return YES; }
%end


// ==========================================
// 4. تزوير هويات جلسة الـ Swift (LPM) ديناميكياً عند التشغيل
// ==========================================

// دالة بديلة لتزوير الـ Session ID الخاص بـ Swift LevelPlay
static id (*orig_LPMSessionId)(id self, SEL _cmd);
id new_LPMSessionId(id self, SEL _cmd) {
    return getCleanRandomUUID(); // إعطاء جلسة عشوائية جديدة لمنع تتبع الـ Capping عبر السيرفر
}

%ctor {
    // استهداف كلاس إدارة الجلسات في Swift SDK
    Class lpmSessionClass = NSClassFromString(@"IronSource.LPMSessionManager");
    if (lpmSessionClass) {
        SEL sessionSelector = NSSelectorFromString(@"sessionId");
        if (class_getInstanceMethod(lpmSessionClass, sessionSelector)) {
            MSHookMessageEx(lpmSessionClass, sessionSelector, (IMP)new_LPMSessionId, (IMP *)&orig_LPMSessionId);
        }
    }

    // تنبيه نجاح تزوير الهوية
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Identity Spoofing"
                                                                           message:@"تم تفعيل تزوير هويات المستخدم والجلسة برمجياً!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"تجربة" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
