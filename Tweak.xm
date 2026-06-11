#import <Foundation/Foundation.h>

%hook NSMutableURLRequest

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    NSString *urlStr = [[self URL] absoluteString];
    
    // 1. تحويل مسار السيرفر الميت إلى السيرفر الجديد تلقائياً
    if ([urlStr containsString:@"api.codebysms.com"]) {
        NSString *newURLStr = [urlStr stringByReplacingOccurrencesOfString:@"api.codebysms.com/v1" withString:@"tn.maildisposable.com/api/v1"];
        [self setURL:[NSURL URLWithString:newURLStr]];
    }
    
    // 2. حقن التوكن ورؤوس الطلبات الخاصة بحسابك عند الاتصال بالسيرفر الجديد
    if ([[self URL].host isEqualToString:@"tn.maildisposable.com"]) {
        if ([field isEqualToString:@"Authorization"]) {
            %orig(@"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2YTI3NjA1YWM3ZGViNzkyZjdjMDMwZTkiLCJpYXQiOjE3ODExNDMxMjV9.kQjGLpYrtg63E4nd8pH9DwMgTpP_-Q28IUeVqMJTY9Q", field);
            return;
        }
        if ([field isEqualToString:@"Accept"]) {
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
