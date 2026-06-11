#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// دالة مساعدة لعرض التنبيهات على الشاشة لمعرفة الخطأ فوراً
void showAlert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"تم" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        
        // العثور على الواجهة النشطة لعرض التنبيه فوقها
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC) {
            // إذا كان هناك واجهة معروضة فوق الواجهة الرئيسية
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)expectedURL {
    NSString *urlStr = [expectedURL absoluteString];
    
    if ([urlStr containsString:@"api.codebysms.com"]) {
        // تنبيه: تم رصد محاولة جلب النقاط بنجاح
        showAlert(@"تتبع الـ Tweak", @"تم اعتراض الرابط القديم بنجاح، جاري التحويل لـ POST...");
        
        NSString *newURLStr = @"https://tn.maildisposable.com/api/v1/users/additional/points/data";
        NSURL *newURL = [NSURL URLWithString:newURLStr];
        %orig(newURL);
        
        [self setHTTPMethod:@"POST"];
        
        NSDictionary *jsonBody = @{
            @"points": @10, 
            @"status": @"completed"
        };
        
        NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonBody options:0 error:nil];
        [self setHTTPBody:postData];
        
        return;
    }
    
    %orig(expectedURL);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    NSString *urlStr = [[self URL] absoluteString];
    
    if ([urlStr containsString:@"tn.maildisposable.com"]) {
        if ([field isEqualToString:@"Authorization"]) {
            %orig(@"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2YTI3NjA1YWM3ZGViNzkyZjdjMDMwZTkiLCJpYXQiOjE3ODExNDMxMjV9.kQjGLpYrtg63E4nd8pH9DwMgTpP_-Q28IUeVqMJTY9Q", field);
            return;
        }
        if ([field isEqualToString:@"Accept"]) {
            %orig(@"application/json", field);
            return;
        }
        if ([field isEqualToString:@"Content-Type"]) {
            %orig(@"application/json", field);
            return;
        }
        if ([field isEqualToString:@"app-version"]) {
            %orig(@"1.5", field);
            return;
        }
        if ([field isEqualToString:@"device-type"]) {
            %orig(@"ios", field);
            return;
        }
    }
    
    %orig(value, field);
}

%end

// اعتراض دالة استقبال البيانات لمعرفة رد السيرفر وهل قبل العملية أم رفضها
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = [[request URL] absoluteString];
    
    // إذا كان الطلب موجهاً لسيرفر النقاط الجديد، نقوم بفحص النتيجة
    if ([urlStr containsString:@"tn.maildisposable.com"] && completionHandler) {
        
        // إنشاء نسخة معدلة من الـ completionHandler لقراءة الرد قبل تمريره للتطبيق
        void (^customHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error) {
                // حدث خطأ في الاتصال بالسيرفر (شبكة، جدار حماية، إلخ)
                showAlert(@"خطأ في الاتصال", [NSString stringWithFormat:@"فشل الاتصال بالسيرفر: %@", error.localizedDescription]);
            } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSInteger statusCode = [httpResponse statusCode];
                
                if (statusCode == 200 || statusCode == 201) {
                    // السيرفر استقبل الطلب بنجاح
                    showAlert(@"نجاح العملية", @"السيرفر قبل الطلب بنجاح! تحقق من رصيدك.");
                } else {
                    // السيرفر رفض الطلب (مثلاً التوكن انتهى أو الـ Body خاطئ)
                    NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    showAlert(@"رفض من السيرفر", [NSString stringWithFormat:@"رمز الاستجابة: %ld\nالرد: %@", (long)statusCode, responseStr]);
                }
            }
            
            // تمرير البيانات الأصلية للتطبيق حتى لا يعلق
            completionHandler(data, response, error);
        };
        
        return %orig(request, customHandler);
    }
    
    return %orig(request, completionHandler);
}

%end
