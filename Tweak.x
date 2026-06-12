#import <UIKit/UIKit.h>

// دالة لمسح وتعديل الإعدادات مجبرة داخل كاش التطبيق الحالية
void applyAdBypassSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // قائمة المفاتيح المسؤول عن حظر وتقييد الإعلانات
    NSArray *keys = @[
        @"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial",
        @"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner",
        @"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo",
        @"IABGPP_TCFEU2_gdprApplies"
    ];
    
    // إجبار القيم على التصفير وإلغاء القيود (Capping) في ملف الإعدادات النشط
    for (NSString *key in keys) {
        [defaults setInteger:0 forKey:key];
        [defaults setBool:NO forKey:key];
        [defaults setObject:@(0) forKey:key];
    }
    
    // حفظ التغييرات فوراً في الهارد ديسك الخاص بالتطبيق لكي يراها FLEX
    [defaults synchronize];
    NSLog(@"[AdBypassTweak] All Ad-Capping constraints forced to 0 inside NSUserDefaults.");
}

// الـ Hook الافتراضي كخط دفاع ثاني لحماية القيم من التعديل العكسي أثناء تشغيل التطبيق
%hook NSUserDefaults

- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName containsString:@"CappingManager.IS_DELIVERY_ENABLED"] || [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return 0;
    }
    return %orig;
}

- (BOOL)boolForKey:(NSString *)defaultName {
    if ([defaultName containsString:@"CappingManager.IS_DELIVERY_ENABLED"] || [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return NO;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    if ([defaultName containsString:@"CappingManager.IS_DELIVERY_ENABLED"] || [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return @(0);
    }
    return %orig;
}

%end

%ctor {
    // تفعيل التعديل الإجباري فور تشغيل الأداة
    applyAdBypassSettings();
    
    // إظهار التنبيه للتأكد من أن الأداة تعمل ولا توجد مشكلة في توقيع الـ dylib
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تـم الـتـعـديـل الإجـبـاري"
                                                                           message:@"تم تصفير عدادات الحظر داخل ملفات التطبيق بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
