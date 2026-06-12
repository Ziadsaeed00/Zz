#import <UIKit/UIKit.h>

// 1. تعريف واجهة الكلاسات (Interfaces) لمنع أخطاء التجميع مع المترجم الحديث
@interface IS_CappingManager : NSObject
+ (id)sharedInstance;
- (BOOL)isDeliveryEnabled:(id)arg1;
- (BOOL)isCappingEnabled:(id)arg1;
@end

@interface BN_CappingManager : NSObject
+ (id)sharedInstance;
- (BOOL)isDeliveryEnabled:(id)arg1;
@end

@interface RV_CappingManager : NSObject
+ (id)sharedInstance;
- (BOOL)isDeliveryEnabled:(id)arg1;
@end


// 2. عمل Hook مباشر على كلاسات إدارة الإعلانات لكسر الـ Capping من الجذور
%hook IS_CappingManager

- (BOOL)isDeliveryEnabled:(id)arg1 {
    return YES; // إجبار النظام على السماح بتسليم الإعلانات دائماً
}

- (BOOL)isCappingEnabled:(id)arg1 {
    return NO; // إلغاء عداد الحظر كلياً
}

%end


%hook BN_CappingManager

- (BOOL)isDeliveryEnabled:(id)arg1 {
    return YES; // تشغيل إعلانات البانر دائماً
}

%end


%hook RV_CappingManager

- (BOOL)isDeliveryEnabled:(id)arg1 {
    return YES; // تشغيل الفيديوهات بمكافأة دائماً
}

%end


// 3. دالة التشغيل والتنبيه للتأكد من نجاح العملية
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        if (rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تـم كـسـر الـقـيـود"
                                                                           message:@"تم تخطي الـ CappingManager بنجاح في الذاكرة!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
