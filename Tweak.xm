#import <Foundation/Foundation.h>

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)expectedURL {
    NSString *urlStr = [expectedURL absoluteString];
    
    if ([urlStr containsString:@"api.codebysms.com"]) {
        NSString *newURLStr = @"https://tn.maildisposable.com/api/v1/users/additional/points/data";
        NSURL *newURL = [NSURL URLWithString:newURLStr];
        %orig(newURL);
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
