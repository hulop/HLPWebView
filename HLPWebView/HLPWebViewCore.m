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

#import "HLPWebView/HLPWebViewCore.h"
#import "ResourceBundle.h"

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

- (instancetype)init
{
    [NSException raise:@"Invalid init" format:@"use initWithFrame:configuration:"];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [NSException raise:@"Invalid init" format:@"use initWithFrame:configuration:"];
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    [NSException raise:@"Invalid init" format:@"use initWithFrame:configuration:"];
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(nonnull WKWebViewConfiguration *)configuration
{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        _funcs = [[NSMutableDictionary alloc] init];
        _callbacks = [[NSMutableDictionary alloc] init];
        
        [super setUIDelegate:self];
        [super setNavigationDelegate:self];
        self.scrollView.bounces = NO;
        
        if (!self.configuration.userContentController) {
            self.configuration.userContentController = [[WKUserContentController alloc] init];
        }        
        NSString *path = [SWIFTPM_MODULE_BUNDLE pathForResource:@"ios_bridge" ofType:@"js"];
        NSString *script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [self.configuration.userContentController addUserScript: userScript];
        [self.configuration.userContentController addScriptMessageHandler:self name:@"nativeCallbackHandler"];
    }
    return self;
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary *body = message.body;
   
    NSString *component = body[@"component"];
    NSString *func = body[@"func"];
    NSDictionary *params = body[@"params"];

    NSString *name = [NSString stringWithFormat:@"%@.%@", component, func];
    NSString *name2 = [NSString stringWithFormat:@"%@.%@.webview", component, func];
    
    NSString *callbackStr = [params objectForKey:@"callback"];
    if (callbackStr) {
        [_callbacks setObject:callbackStr forKey:name];
        [_callbacks setObject:self forKey:name2];
    }
    void (^f)(NSDictionary *, WKWebView *) = (void (^)(NSDictionary *, WKWebView *))[_funcs objectForKey:name];
    if (f) {
        f(params, self);
    }
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
    [self evaluateJavaScript:script completionHandler:nil];
}

- (void)reload
{
    NSLog(@"loadUIPage %@", _currentRequest.URL);
    [self loadRequest:_currentRequest];
    _lastRequestTime = [[NSDate date] timeIntervalSince1970];
}

- (void)registerNativeFunc:(void (^)(NSDictionary *, WKWebView *))func withName:(NSString *)name inComponent:(NSString *)component
{
    [_funcs setObject:[func copy] forKey:[NSString stringWithFormat:@"%@.%@", component, name]];
}

#pragma mark - HLPWebViewCoreDelegate

- (void)fireWebView:(WKWebView *)webView openURL:(NSURL*)url
{
    if ([_delegate respondsToSelector:@selector(webView:openURL:)]) {
        [_delegate webView:self openURL:url];
    }
}

- (void)fireWebViewInsertBridge:(WKWebView *)webView
{
    if ([_delegate respondsToSelector:@selector(webViewDidInsertBridge:)]) {
        [_delegate webViewDidInsertBridge:webView];
    }
}

#pragma mark - WKWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (_serverHost) {
        NSURLRequest *request = navigationAction.request;
        NSRange range = [request.URL.absoluteString rangeOfString:_serverHost];
        if (range.location == NSNotFound) {
            [self fireWebView:webView openURL:request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad");

    if ([_delegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [_delegate webView:webView didStartProvisionalNavigation:navigation];
    }
    
    [self fireWebViewInsertBridge:webView];
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    //TODO
    //int status = [[[navigation request] valueForHTTPHeaderField:@"Status"] intValue];
    //NSLog(@"webViewDidFinishLoad %d %@", status, webView.request.URL.absoluteString);
    //if (status == 404) {
    //}
    if ([_delegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [_delegate webView:webView didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%@", error);
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self reload];
    });
}

@end
