/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

#import "HLPWebView.h"

#define UI_PAGE @"%@://%@/%@mobile.jsp?noheader&noclose&id=%@"

// override UIWebView accessibility to prevent reading Map contents
@implementation HLPWebView {
    NSString *_callback;
}

@synthesize delegate = _delegate;

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return nil;
}

- (NSInteger)accessibilityElementCount
{
    return 0;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self registerJSFunctions];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self registerJSFunctions];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerJSFunctions];
    }
    return self;
}

#pragma mark - public methods

- (void)setDelegate:(id<HLPWebViewDelegate>)delegate
{
    [super setDelegate:delegate];
    _delegate = delegate;
}

- (id<HLPWebViewDelegate>)delegate
{
    return _delegate;
}

- (void)setConfig:(NSDictionary *)config
{
    [super setConfig:config];
    
    _userMode = @"user_general";
}

- (NSURL*)buildTargetURL
{
    NSString *server = self.serverHost;
    NSString *context = self.serverContext;
    NSString *https = self.usesHttps ? @"https" : @"http";
    NSString *device_id = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:UI_PAGE, https, server, context, device_id]];
    
    return url;
}

- (void)setIsDeveloperMode:(BOOL)isDeveloperMode
{
    _isDeveloperMode = isDeveloperMode;
    [self updatePreferences];
}

- (void)setUserMode:(NSString *)userMode
{
    _userMode = userMode;
    [self updatePreferences];
}

- (void) registerJSFunctions
{
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *webView) {
        NSString *text = [param objectForKey:@"text"];
        BOOL flush = [[param objectForKey:@"flush"] boolValue];
        if ([_tts respondsToSelector:@selector(speak:force:)]) {
            [_tts speak:text force:flush];
        }
    }
                  withName:@"speak"
               inComponent:@"SpeechSynthesizer"];
    
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *wv) {
        NSString *result = @"false";
        if ([_tts respondsToSelector:@selector(isSpeaking)]) {
            result = [_tts isSpeaking] ? @"true" : @"false";
        }
        NSString *name = param[@"callbackname"];
        [wv stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@.%@(%@)", _callback, name, result]];
    }
                  withName:@"isSpeaking"
               inComponent:@"SpeechSynthesizer"];
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *wv) {
        if ([param objectForKey:@"value"]) {
            _callback = [param objectForKey:@"value"];
            //NSLog(@"callback method is %@", callback);
            [self updatePreferences];
        }
    }
                  withName:@"callback"
               inComponent:@"Property"];
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *wv) {
        if ([_delegate respondsToSelector:@selector(webView:didChangeLatitude:longitude:floor:synchronized:)]) {
            [_delegate webView:self didChangeLatitude:[param[@"lat"] doubleValue] longitude:[param[@"lng"] doubleValue] floor:[param[@"floor"] doubleValue] synchronized:[param[@"sync"] boolValue]];
        }
    }
                  withName:@"mapCenter"
               inComponent:@"Property"];
    
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *webView) {
        NSString *text = param[@"text"];
        //NSLog(@"%@", text);
        
        if ([text rangeOfString:@"buildingChanged,"].location == 0) {
            NSData *data = [[text substringFromIndex:[@"buildingChanged," length]] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *param = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([_delegate respondsToSelector:@selector(webView:didChangeBuilding:)]) {
                [_delegate webView:self didChangeBuilding:param[@"building"]];
            }
        }
        if ([text rangeOfString:@"stateChanged,"].location == 0) {
            NSData *data = [[text substringFromIndex:[@"stateChanged," length]] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *param = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([_delegate respondsToSelector:@selector(webView:didChangeUIPage:inNavigation:)]) {
                [_delegate webView:self didChangeUIPage:param[@"page"] inNavigation:[param[@"navigation"] boolValue]];
            }
        }
        if ([text rangeOfString:@"navigationFinished,"].location == 0) {
            NSData *data = [[text substringFromIndex:[@"navigationFinished," length]] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *param = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([_delegate respondsToSelector:@selector(webView:didFinishNavigationStart:end:from:to:)]) {
                [_delegate webView:self didFinishNavigationStart:[param[@"start"] doubleValue] end:[param[@"end"] doubleValue] from:param[@"from"] to:param[@"to"]];
            }
        }
        NSLog(@"%@", text);
    }
                  withName:@"log"
               inComponent:@"System"];
    
    [self registerNativeFunc:^(NSDictionary *param, UIWebView *webView) {
        if ([_tts respondsToSelector:@selector(vibrate)]) {
            [_tts vibrate];
        }
    }
                  withName:@"vibrate"
               inComponent:@"AudioServices"];

}

- (void)triggerWebviewControl:(HLPWebviewControl)control
{
    switch (control) {
        case HLPWebviewControlRouteSearchOptionButton:
            [self stringByEvaluatingJavaScriptFromString:@"$('a[href=\"#settings\"]').click()"];
            break;
        case HLPWebviewControlRouteSearchButton:
            [self stringByEvaluatingJavaScriptFromString:@"$('a[href=\"#control\"]').click()"];
            break;
        case HLPWebviewControlDoneButton:
            [self stringByEvaluatingJavaScriptFromString:@"$('div[role=banner]:visible a').click()"];
            break;
        case HLPWebviewControlEndNavigation:
            [self stringByEvaluatingJavaScriptFromString:@"$('#end_navi').click()"];
            break;
        case HLPWebviewControlBackToControl:
            [self stringByEvaluatingJavaScriptFromString:@"$('div[role=banner]:visible a').click()"];
            break;
        default:
            [self stringByEvaluatingJavaScriptFromString:@"$hulop.map.resetState()"];
            //[self evalScript:@"$('a[href=\"#map-page\"]:visible').click()"];
            break;
    }
}

- (void)sendData:(NSObject *)data withName:(NSString *)name
{
    if (_callback == nil) {
        return;
    }

    data = [self removeNaNValue:data];

    NSString *jsonstr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:nil] encoding:NSUTF8StringEncoding];

    NSString *script = [NSString stringWithFormat:@"%@.onData('%@',%@);", _callback, name, jsonstr];
    //NSLog(@"%@", script);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self stringByEvaluatingJavaScriptFromString:script];
    });
}


- (NSDictionary *)getState
{
    NSString *state = [self stringByEvaluatingJavaScriptFromString:@"(function(){return JSON.stringify($hulop.map.getState());})()"];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[state dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (json) {
        return json;
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
    return nil;
}


#pragma mark - private methods


- (void)updatePreferences
{
    if (_callback == nil) {
        return;
    }

    NSMutableDictionary *data = [@{} mutableCopy];
    data[@"developer_mode"] = @(_isDeveloperMode);
    data[@"user_mode"] = _userMode;
    NSString *jsonstr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:nil] encoding:NSUTF8StringEncoding];

    NSString *script = [NSString stringWithFormat:@"%@.onPreferences(%@);", _callback, jsonstr];
    //NSLog(@"%@", script);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stringByEvaluatingJavaScriptFromString:script];
    });
}

- (NSObject *)removeNaNValue:(NSObject *)obj
{
    NSObject *newObj;
    if ([obj isKindOfClass:NSArray.class]) {
        NSArray *arr = (NSArray *)obj;
        NSMutableArray *newArr = [arr mutableCopy];
        for (int i = 0; i < [arr count]; i++) {
            NSObject *tmp = arr[i];
            newArr[i] = [self removeNaNValue:tmp];
        }
        newObj = (NSObject *)newArr;
    } else if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)obj;
        NSMutableDictionary *newDict = [dict mutableCopy];
        for (id key in [dict keyEnumerator]) {
            NSObject *val = dict[key];
            if ([val isKindOfClass:NSNumber.class]) {
                double dVal = [(NSNumber *)val doubleValue];
                if (isnan(dVal)) {
                    [newDict removeObjectForKey:key];
                }
            }
        }
        newObj = (NSObject *)newDict;
    }
    return newObj;
}

#pragma mark - override HLPWebViewCoreDelegate

- (void)fireWebViewInsertBridge:(UIWebView *)webView
{
    [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if ([self insertHLPBridge]) {
            [timer invalidate];
            [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                if (_callback != nil) {
                    NSLog(@"%@", NSStringFromSelector(_cmd));
                    [timer invalidate];                    
                    if ([_delegate respondsToSelector:@selector(webViewDidInsertBridge:)]) {
                        [_delegate webViewDidInsertBridge:webView];
                    }
                }
            }];
        }
    }];
}

-(BOOL)insertHLPBridge
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSBundle *bundle = [NSBundle bundleForClass:[HLPWebView class]];
    NSString *path = [bundle pathForResource:@"hlp_bridge" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSString *result = [self stringByEvaluatingJavaScriptFromString:script];
    return [result isEqualToString:@"SUCCESS"];
}

- (void)webView:(UIWebView *)webView openURL:(NSURL *)url
{
    [_delegate webView:webView openURL:url];
}


@end
