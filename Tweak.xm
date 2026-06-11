#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ==========================================
// 📢 دالة موحدة ومضمونة لعرض التنبيهات على الشاشة
// ==========================================
void showAlert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"تم" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// ==========================================
// 🌐 اعتراض وتعديل طلبات الشبكة بالكامل (أضمن وأقوى برمجياً)
// ==========================================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = [[request URL] absoluteString];
    
    // فحص ما إذا كان التطبيق يحاول طلب رابط الإعلانات القديم
    if ([urlStr containsString:@"api.codebysms.com"]) {
        
        // تنبيه فوري يخبرك بأن الأداة أمسكت بالرابط أثناء محاولة فتح الإعلان
        showAlert(@"تتبع الـ Tweak", @"🎯 تم رصد رابط الإعلانات بنجاح! جاري تحويل الطلب وحقن البيانات الجديدة...");
        NSLog(@"[Zeyad_Debug] Intercepted api.codebysms.com request.");

        // تحويل الطلب الأصلي إلى نسخة قابلة للتعديل (Mutable) للتلاعب بها في نفس اللحظة
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        
        // 1. تحويل الرابط إلى السيرفر الجديد
        NSString *newURLStr = @"https://tn.maildisposable.com/api/v1/users/additional/points/data";
        [mutableRequest setURL:[NSURL URLWithString:newURLStr]];
        
        // 2. تغيير نوع الطلب إجبارياً إلى POST
        [mutableRequest setHTTPMethod:@"POST"];
        
        // 3. حقن جميع الهيدرز (Headers) المطلوبة دفعة واحدة لضمان عدم تجاوزها
        [mutableRequest setValue:@"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2YTI3NjA1YWM3ZGViNzkyZjdjMDMwZTkiLCJpYXQiOjE3ODExNDMxMjV9.kQjGLpYrtg63E4nd8pH9DwMgTpP_-Q28IUeVqMJTY9Q" forHTTPHeaderField:@"Authorization"];
        [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [mutableRequest setValue:@"1.5" forHTTPHeaderField:@"app-version"];
        [mutableRequest setValue:@"ios" forHTTPHeaderField:@"device-type"];
        
        // 4. بناء وحقن الـ JSON Body (إضافة النقاط)
        NSDictionary *jsonBody = @{
            @"points": @10, 
            @"status": @"completed"
        };
        NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonBody options:0 error:nil];
        [mutableRequest setHTTPBody:postData];
        
        // 5. إنشاء الـ Completion Handler الذكي لقراءة رد السيرفر وفك تشفيره قبل تمريره للتطبيق
        void (^customHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                showAlert(@"❌ خطأ في الاتصال", [NSString stringWithFormat:@"فشل إرسال البيانات للسيرفر الجديد: %@", error.localizedDescription]);
                NSLog(@"[Zeyad_Debug] Connection Error: %@", error.localizedDescription);
            } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = [httpResponse statusCode];
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                NSLog(@"[Zeyad_Debug] Server Status Code: %ld", (long)statusCode);
                NSLog(@"[Zeyad_Debug] Server Response: %@", responseStr);
                
                if (statusCode == 200 || statusCode == 201) {
                    showAlert(@"🎉 نجاح العملية", @"السيرفر قبل طلب النقاط بنجاح! تحقق من رصيدك الآن.");
                } else {
                    showAlert(@"⚠️ رفض من السيرفر", [NSString stringWithFormat:@"رمز الاستجابة: %ld\nالرد: %@", (long)statusCode, responseStr]);
                }
            }
            
            // تمرير البيانات للتطبيق بشكل طبيعي لمنع الـ Crash
            if (completionHandler) {
                completionHandler(data, response, error);
            }
        };
        
        // تنفيذ الطلب المعدل الجديد كلياً بدلاً من القديم
        return %orig(mutableRequest, customHandler);
    }
    
    // فحص احتياطي في حال كان التطبيق يرسل للسيرفر الجديد مباشرة من مكان آخر
    if ([urlStr containsString:@"tn.maildisposable.com"] && completionHandler) {
        void (^customHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = [httpResponse statusCode];
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (statusCode == 200 || statusCode == 201) {
                    showAlert(@"🎉 نجاح العملية (مباشر)", @"تم قبول النقاط في الخلفية!");
                } else {
                    showAlert(@"⚠️ رفض السيرفر (مباشر)", [NSString stringWithFormat:@"كود الرد: %ld\nالرد: %@", (long)statusCode, responseStr]);
                }
            }
            completionHandler(data, response, error);
        };
        return %orig(request, customHandler);
    }

    return %orig(request, completionHandler);
}

%end

// ==========================================
// 🚀 الـ Constructor (يعمل فوراً عند فتح التطبيق)
// ==========================================
%ctor {
    NSLog(@"[Zeyad_Debug] Tweak injected and initialized successfully!");
    
    // إظهار تنبيه على الشاشة بعد ثانيتين من فتح التطبيق للتأكد 100% أن الـ dylib محقون وشغال
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showAlert(@"🔥 حالة الأداة", @"تم حقن ملف الـ dylib بنجاح عبر ESign والأداة الآن نشطة وتراقب الإعلانات في الخلفية!");
    });
}
