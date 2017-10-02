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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol HLPWebViewCoreDelegate <UIWebViewDelegate>
@optional
- (void)webViewDidInsertBridge:(UIWebView *_Nonnull)webView;
- (void)webView:(UIWebView *_Nonnull)webView openURL:(NSURL *_Nonnull)url;
@end

@interface HLPWebViewCore : UIWebView <UIWebViewDelegate>

@property (readonly) BOOL isReady;
@property (nullable, nonatomic, assign) id<HLPWebViewCoreDelegate> delegate;

@property NSDictionary* _Nullable config;
@property (readonly) NSString * _Nullable serverHost;
@property (readonly) NSString * _Nullable serverContext;
@property (readonly) BOOL usesHttps;

- (void)setLocationHash:(NSString *_Nonnull)hash;
- (void)reload;
- (void)registerNativeFunc:(void (^_Nonnull)(NSDictionary * _Nonnull param, UIWebView * _Nonnull webView))func withName:(NSString *_Nonnull)name inComponent:(NSString *_Nonnull)component;

@end

