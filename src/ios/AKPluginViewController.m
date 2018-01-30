#import "AKPluginViewController.h"

#import <Cordova/CDVPlugin.h>


@implementation AKPluginViewController {
  AKPluginViewController *_instance;
  AKFAccountKit *_accountKit;
}

#pragma mark - View Management

- (instancetype)init:(AKFAccountKit *)accountKit {
  self = [super init];
  _accountKit = accountKit;
  _instance = self;

  return self;
}

- (void)loginWithPhoneNumber:(AKFPhoneNumber *)preFillPhoneNumber
          defaultCountryCode:(NSString *)defaultCountryCode
        enableSendToFacebook:(BOOL)facebookNotificationsEnabled
                       theme:(NSDictionary *)theme
                    callback:(NSString *)callbackId {
  NSString *inputState = [[NSUUID UUID] UUIDString];
  self.callbackId = callbackId;

  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController<AKFViewController> *vc = [_accountKit viewControllerForPhoneLoginWithPhoneNumber:preFillPhoneNumber
                                                                                                state:inputState];
    vc.enableSendToFacebook = facebookNotificationsEnabled;
    vc.defaultCountryCode = defaultCountryCode;
    [self _prepareLoginViewController:vc withTheme:theme];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController presentViewController:vc animated:YES completion:nil];
  });
}

- (void)loginWithEmailAddress:(NSString *)preFillEmailAddress
           defaultCountryCode:(NSString *)defaultCountryCode
         enableSendToFacebook:(BOOL)facebookNotificationsEnabled
                        theme:(NSDictionary *)theme
                     callback:(NSString *)callbackId {
  NSString *inputState = [[NSUUID UUID] UUIDString];
  self.callbackId = callbackId;

  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController<AKFViewController> *vc = [_accountKit viewControllerForEmailLoginWithEmail:preFillEmailAddress
                                                                                          state:inputState];
    vc.enableSendToFacebook = facebookNotificationsEnabled;
    vc.defaultCountryCode = defaultCountryCode;
    [self _prepareLoginViewController:vc withTheme:theme];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController presentViewController:vc animated:YES completion:nil];
  });
}

- (void)_prepareLoginViewController:(UIViewController<AKFViewController> *)viewController withTheme:(NSDictionary *)themeInfo
{
    viewController.delegate = self;
    //set a theme to customize the UI.
    if (themeInfo) {
        AKFTheme *theme = [AKFTheme defaultTheme];
        theme.backgroundColor = [self colorWithRGBHexValue:themeInfo[@"backgroundColor"]];
        theme.buttonBackgroundColor = [self colorWithRGBHexValue:themeInfo[@"buttonBackgroundColor"]];
        theme.buttonBorderColor = [self colorWithRGBHexValue:themeInfo[@"buttonBorderColor"]];
        theme.buttonTextColor = [self colorWithRGBHexValue:themeInfo[@"buttonTextColor"]];
        theme.headerBackgroundColor = [self colorWithRGBHexValue:themeInfo[@"headerBackgroundColor"]];
        theme.headerTextColor = [self colorWithRGBHexValue:themeInfo[@"headerTextColor"]];
        theme.iconColor = [self colorWithRGBHexValue:themeInfo[@"iconColor"]];
        theme.inputBackgroundColor = [self colorWithRGBHexValue:themeInfo[@"inputBackgroundColor"]];
        theme.inputBorderColor = [self colorWithRGBHexValue:themeInfo[@"inputBorderColor"]];
        theme.inputTextColor = [self colorWithRGBHexValue:themeInfo[@"inputTextColor"]];
        theme.textColor = [self colorWithRGBHexValue:themeInfo[@"textColor"]];
        theme.titleColor = [self colorWithRGBHexValue:themeInfo[@"titleColor"]];
        theme.statusBarStyle = UIStatusBarStyleDefault;
        viewController.theme = theme;
    }
}

- (UIColor *)colorWithRGBHexValue:(NSString *)hexValue {
    NSString *cString = [[hexValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0];
}


# pragma mark - AKFViewControllerDelegate

/*!
 @abstract Called when the login completes with an authorization code response type.
 
 @param viewController the AKFViewController that was used
 @param code the authorization code that can be exchanged for an access token with the app secret
 @param state the state param value that was passed in at the beginning of the flow
 */
- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAuthorizationCode:(NSString *)code state:(NSString *)state {
  NSDictionary* response = @{
                             @"callbackId": self.callbackId,
                             @"data": @{
                                 @"code": code,
                                 @"state": state
                                 },
                             @"name": @"didCompleteLoginWithAuthorizationCode"
                             };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountKitDone"
                                                      object:nil
                                                    userInfo:response];
}

/*!
 @abstract Called when the login completes with an access token response type.
 
 @param viewController the AKFViewController that was used
 @param accessToken the access token for the logged in account
 @param state the state param value that was passed in at the beginning of the flow
 */
- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAccessToken:(id<AKFAccessToken>)accessToken state:(NSString *)state {
  NSDictionary* response = @{
                             @"callbackId": self.callbackId,
                             @"data": accessToken,
                             @"name": @"didCompleteLoginWithAccessToken"
                             };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountKitDone"
                                                      object:nil
                                                    userInfo:response];
}

/*!
 @abstract Called when the login failes with an error
 
 @param viewController the AKFViewController that was used
 @param error the error that occurred
 */
- (void)viewController:(UIViewController<AKFViewController> *)viewController
      didFailWithError:(NSError *)error {
  NSDictionary* response = @{
                             @"callbackId": self.callbackId,
                             @"data": [error localizedDescription],
                             @"name": @"didFailWithError"
                             };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountKitDone"
                                                      object:nil
                                                    userInfo:response];
}

/*!
 @abstract Called when the login flow is cancelled through the UI.
 
 @param viewController the AKFViewController that was used
 */
- (void)viewControllerDidCancel:(UIViewController<AKFViewController> *)viewController {
  NSDictionary* response = @{
                             @"callbackId": self.callbackId,
                             @"data": @"User cancelled",
                             @"name": @"didFailWithError"
                             };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountKitDone"
                                                      object:nil
                                                    userInfo:response];
}

@end
