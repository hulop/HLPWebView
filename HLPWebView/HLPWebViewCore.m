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

#import "HLPWebViewCore.h"

#define URL_FORMAT @"%@://%@/%@"
#define LOADING_TIMEOUT 30

@implementation HLPWebViewCore {
    NSTimer *_timer;
    NSDictionary *_config;
    NSURLRequest *_currentRequest;
    NSTimeInterval _lastRequestTime;
    
    NSMutableDictionary *_funcs;
    NSMutableDictionary *_callbacks;
}

@synthesize delegate = _delegate;

- (void)_init
{
    [super setDelegate:self];
    self.scrollView.bounces = NO;
    self.suppressesIncrementalRendering = YES;
    _funcs = [[NSMutableDictionary alloc] init];
    _callbacks = [[NSMutableDictionary alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)setDelegate:(id<HLPWebViewCoreDelegate>)delegate
{
    _delegate = delegate;
}

- (id<HLPWebViewCoreDelegate>)delegate
{
    return _delegate;
}

- (void)dealloc
{
    _currentRequest = nil;
    _serverHost = nil;
    _serverContext = nil;
}


- (void)setConfig:(NSDictionary *)config
{
    _config = config;
    
    _serverHost = _config[@"serverHost"];
    _serverContext = _config[@"serverContext"];
    _usesHttps = [_config[@"usesHttps"] boolValue];
        
    _currentRequest = [NSMutableURLRequest requestWithURL:[self buildTargetURL]];

    [self reload];
}

- (NSDictionary*)config
{
    return _config;
}

- (NSURL*)buildTargetURL
{
    NSString *server = _serverHost;
    NSString *context = _serverContext;
    NSString *https = _usesHttps ? @"https" : @"http";

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:URL_FORMAT, https, server, context]];
    
    return url;
}

- (void)setLocationHash:(NSString *)hash
{
    NSString *script = [NSString stringWithFormat:@"location.hash=\"%@\"", hash];
    [self stringByEvaluatingJavaScriptFromString:script];
}

- (void)reload
{
    NSLog(@"loadUIPage %@", _currentRequest.URL);
    [self loadRequest:_currentRequest];
    _lastRequestTime = [[NSDate date] timeIntervalSince1970];
}

- (void)registerNativeFunc:(void (^)(NSDictionary *, UIWebView *))func withName:(NSString *)name inComponent:(NSString *)component
{
    [_funcs setObject:[func copy] forKey:[NSString stringWithFormat:@"%@.%@", component, name]];
}

#pragma mark - private method

- (void)waitForReady:(NSTimer *)timer
{
    NSString *ret = [self stringByEvaluatingJavaScriptFromString:@"(function(){return document.readyState != 'loading'})();"];
    
    if ([ret isEqualToString:@"true"]) {
        [timer invalidate];
        _isReady = YES;
        [self insertBridge];
        return;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastRequestTime > LOADING_TIMEOUT) {
        [timer invalidate];
        [self stopLoading];
        if ([_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
            NSError *error = [[NSError alloc] initWithDomain:@"ConnectionError"
                                                        code:1001
                                                    userInfo:nil];
            [_delegate webView:self didFailLoadWithError:error];
        }
    }
}

- (void)insertBridge
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSBundle *bundle = [NSBundle bundleForClass:[HLPWebViewCore class]];
    NSString *path = [bundle pathForResource:@"ios_bridge" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    [self stringByEvaluatingJavaScriptFromString:script];
    [self fireWebViewInsertBridge:self];
}

#pragma mark - HLPWebViewCoreDelegate

- (void)fireWebView:(UIWebView *)webView openURL:(NSURL*)url
{
    if ([_delegate respondsToSelector:@selector(webView:openURL:)]) {
        [_delegate webView:self openURL:url];
    }
}

- (void)fireWebViewInsertBridge:(UIWebView *)webView
{
    if ([_delegate respondsToSelector:@selector(webViewDidInsertBridge:)]) {
        [_delegate webViewDidInsertBridge:webView];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    
    if ([@"about:blank" isEqualToString:[url absoluteString]]) {
        return NO;
    } else if ([@"native" isEqualToString:[url scheme]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [webView stringByEvaluatingJavaScriptFromString:@"$IOS.readyForNext=true;"];
        });
        NSString *component = [url host];
        NSString *func = [[url pathComponents] objectAtIndex:1];
        NSString *paramString = [url query];
        
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        NSArray *keyValues = [paramString componentsSeparatedByString:@"&"];
        for (int i = 0; i < [keyValues count]; i++) {
            NSArray *keyValue = [[keyValues objectAtIndex:i] componentsSeparatedByString:@"="];
            if ([keyValue count] == 2) {
                NSString *key = [keyValue objectAtIndex:0];
                NSString *value = [[keyValue objectAtIndex:1] stringByRemovingPercentEncoding];
                [param setObject:value forKey:key];
            }
        }
        NSString *name = [NSString stringWithFormat:@"%@.%@", component, func];
        NSString *name2 = [NSString stringWithFormat:@"%@.%@.webview", component, func];
        NSString *callbackStr = [param objectForKey:@"callback"];
        if (callbackStr) {
            [_callbacks setObject:callbackStr forKey:name];
            [_callbacks setObject:webView forKey:name2];
        }
        void (^f)(NSDictionary *, UIWebView *) = (void (^)(NSDictionary *, UIWebView *))[_funcs objectForKey:name];
        if (f) {
            f(param, webView);
        }
        return NO;
    }
    
    NSRange range = [request.URL.absoluteString rangeOfString:_serverHost];
    if (range.location == NSNotFound) {
        [self fireWebView:webView openURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(waitForReady:) userInfo:nil repeats:YES];
    if ([_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    int status = [[[webView request] valueForHTTPHeaderField:@"Status"] intValue];
    
    NSLog(@"webViewDidFinishLoad %d %@", status, webView.request.URL.absoluteString);
    if (status == 404) {
    }
    if ([_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_delegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%@", error);
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self reload];
    });
}

@end
