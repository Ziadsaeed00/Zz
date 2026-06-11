#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ==========================================
// 📢 دالة موحدة ومتوافقة مع جميع الإصدارات لعرض التنبيهات
// ==========================================
void showAlert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"تم" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        
        // طريقة متوافقة مع البيئات القديمة والحديثة بدون تسبب بأخطاء Compiler
        UIViewController *rootVC = nil;
        
        // محاولة جلب الواجهة عبر السلسلة الحديثة إذا كانت مدعومة
        if (@available(iOS 13.0, *)) {
            for (id scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:NSClassFromString(@"UIWindowScene")]) {
                    id windows = [scene valueForKey:@"windows"];
                    for (id window in windows) {
                        if ([[window valueForKey:@"isKeyWindow"] boolValue]) {
                            rootVC = [window valueForKey:@"rootViewController"];
                            break;
                        }
                    }
                }
                if (rootVC) break;
            }
        }
        
        // الحل البديل التقليدي في حال فشل الجلب أو إصدار أقدم
        if (!rootVC) {
            rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
        
        if (rootVC) {
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// ==========================================
// 🌐 اعتراض وتعديل طلبات الشبكة بالكامل
// ==========================================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = [[request URL] absoluteString];
    
    if ([urlStr containsString:@"api.codebysms.com"]) {
        
        showAlert(@"تتبع الـ Tweak", @"🎯 تم رصد رابط الإعلانات بنجاح! جاري تحويل الطلب وحقن البيانات الجديدة...");
        NSLog(@"[Zeyad_Debug] Intercepted api.codebysms.com request.");

        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        
        NSString *newURLStr = @"https://tn.maildisposable.com/api/v1/users/additional/points/data";
        [mutableRequest setURL:[NSURL URLWithString:newURLStr]];
        [mutableRequest setHTTPMethod:@"POST"];
        
        [mutableRequest setValue:@"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2YTI3NjA1YWM3ZGViNzkyZjdjMDMwZTkiLCJpYXQiOjE3ODExNDMxMjV9.kQjGLpYrtg63E4nd8pH9DwMgTpP_-Q28IUeVqMJTY9Q" forHTTPHeaderField:@"Authorization"];
        [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [mutableRequest setValue:@"1.5" forHTTPHeaderField:@"app-version"];
        [mutableRequest setValue:@"ios" forHTTPHeaderField:@"device-type"];
        
        NSDictionary *jsonBody = @{
            @"points": @10, 
            @"status": @"completed"
        };
        NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonBody options:0 error:nil];
        [mutableRequest setHTTPBody:postData];
        
        void (^customHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                showAlert(@"❌ خطأ في الاتصال", [NSString stringWithFormat:@"فشل إرسال البيانات للسيرفر الجديد: %@", error.localizedDescription]);
            } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = [httpResponse statusCode];
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                NSLog(@"[Zeyad_Debug] Server Status Code: %ld", (long)statusCode);
                
                if (statusCode == 200 || statusCode == 201) {
                    showAlert(@"🎉 نجاح العملية", @"السيرفر قبل طلب النقاط بنجاح! تحقق من رصيدك الآن.");
                } else {
                    showAlert(@"⚠️ رفض من السيرفر", [NSString stringWithFormat:@"رمز الاستجابة: %ld\nالرد: %@", (long)statusCode, responseStr]);
                }
            }
            
            if (completionHandler) {
                completionHandler(data, response, error);
            }
        };
        
        return %orig(mutableRequest, customHandler);
    }
    
    if ([urlStr containsString:@"tn.maildisposable.com"] && completionHandler) {
        void (^customHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = [httpResponse statusCode];
                if (statusCode == 200 || statusCode == 201) {
                    showAlert(@"🎉 نجاح العملية (مباشر)", @"تم قبول النقاط في الخلفية!");
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
    NSLog(@"[Zeyad_Debug] Tweak injected successfully!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        showAlert(@"🔥 حالة الأداة", @"تم حقن ملف الـ dylib بنجاح عبر ESign والأداة الآن نشطة وتراقب الإعلانات في الخلفية!");
    });
}
