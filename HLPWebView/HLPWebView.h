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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

//! Project version number for HLPWebView.
FOUNDATION_EXPORT double HLPWebViewVersionNumber;

//! Project version string for HLPWebView.
FOUNDATION_EXPORT const unsigned char HLPWebViewVersionString[];

#import <HLPWebView/HLPWebViewCore.h>


typedef NS_ENUM(NSInteger, HLPWebviewControl) {
    HLPWebviewControlRouteSearchOptionButton,
    HLPWebviewControlRouteSearchButton,
    HLPWebviewControlDoneButton,
    HLPWebviewControlEndNavigation,
    HLPWebviewControlBackToControl,
    HLPWebviewControlNone,
};

@class HLPWebView;

@protocol HLPWebViewDelegate <HLPWebViewCoreDelegate>
@optional
- (void)webView:(HLPWebView *_Nonnull)webView didChangeLatitude:(double)lat longitude:(double)lng floor:(double)floor synchronized:(BOOL)sync;
- (void)webView:(HLPWebView *_Nonnull)webView didChangeBuilding:(NSString *_Nonnull)building;
- (void)webView:(HLPWebView *_Nonnull)webView didChangeUIPage:(NSString *_Nonnull)page inNavigation:(BOOL)inNavigation;
- (void)webView:(HLPWebView *_Nonnull)webView didFinishNavigationStart:(NSTimeInterval)start end:(NSTimeInterval)end from:(NSString *_Nonnull)from to:(NSString *_Nonnull)to;
@end

@protocol HLPTTSProtocol <NSObject>
@required
- (void)speak:(NSString *_Nonnull)text force:(BOOL)isForce completionHandler:(void(^_Nullable)(void))completion;
- (BOOL)isSpeaking;
- (void)vibrate;
@end

@interface HLPWebView : HLPWebViewCore <WKUIDelegate, WKNavigationDelegate>

@property (nullable, nonatomic, assign) id<HLPWebViewDelegate> delegate;
@property (nullable, nonatomic, assign) id<HLPTTSProtocol> tts;

@property (nonatomic) BOOL isDeveloperMode;
@property (nonatomic) BOOL isAccessible;
@property (nonatomic) NSString *_Nullable userMode;

- (void)triggerWebviewControl:(HLPWebviewControl)control;
- (void)sendData:(NSObject *_Nonnull)data withName:(NSString *_Nonnull)name;
- (void)getStateWithCompletionHandler:(void(^_Nonnull)(NSDictionary *_Nullable))completion;
- (void)setFullScreenForView:(UIView* _Nonnull)view;
@end
