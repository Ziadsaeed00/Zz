#import <UIKit/UIKit.h>

// اعتراض دوال كلاس قراءة الإعدادات الافتراضية للتطبيق لكسر عداد حظر الإعلانات
%hook NSUserDefaults

- (NSInteger)integerForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return 0; // إرجاع القيمة 0 دائماً لتخطي الحظر
    }
    return %orig;
}

- (BOOL)boolForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return NO; 
    }
    return %orig;
}

- (id)objectForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"IS_CappingManager.IS_DELIVERY_ENABLED_DefaultInterstitial"] ||
        [defaultName isEqualToString:@"BN_CappingManager.IS_DELIVERY_ENABLED_DefaultBanner"] ||
        [defaultName isEqualToString:@"RV_CappingManager.IS_DELIVERY_ENABLED_DefaultRewardedVideo"] ||
        [defaultName isEqualToString:@"IABGPP_TCFEU2_gdprApplies"]) {
        return @(0);
    }
    return %orig;
}

%end

// دالة البداية (Constructor): يتم تنفيذها فور إقلاع التطبيق وحقن الأداة
%ctor {
    // الانتظار حتى يكتمل تحميل واجهة التطبيق الرسومية لضمان ظهور التنبيه بدون كراش
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // إنشاء نافذة التنبيه
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تـم الـحـقـن بـنـجـاح"
                                                                       message:@"أداة تخطي حظر الإعلانات شغالّة الآن البركة فيك!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        // إضافة زر إغلاق للتنبيه
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"موافق"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [alert addAction:dismissAction];
        
        // عرض التنبيه فوق النافذة الرئيسية النشطة للتطبيق حالياً
        [[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
    });
}
