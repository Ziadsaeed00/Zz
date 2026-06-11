#import <UIKit/UIKit.h>

// اعتراض دوال كلاس قراءة الإعدادات الافتراضية للتطبيق
%hook NSUserDefaults

- (NSInteger)integerForKey:(NSString *)defaultName {
    // تصفير عدادات حد الإعلانات (Capping) وتعطيل حظر الخصوصية (GDPR)
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return 0;
    }
    return %orig;
}

- (BOOL)boolForKey:(NSString *)defaultName {
    // إرجاع قيمة خطأ (NO) لمنع تفعيل قيود الحظر الإعلاني في الحالات المنطقية
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return NO;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    // معالجة القراءة في حال تم طلب المتغير ككائن (Object) بدلاً من قيمة رقمية مباشرة
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return @(0);
    }
    return %orig;
}

%end

// دالة التحقق والتأكيد للتأكد من حقن الأداة بنجاح داخل سجل النظام (Console Log)
%ctor {
    NSLog(@"[AdBypassTweak] Ad bypass module has been successfully injected via ESign.");
}
