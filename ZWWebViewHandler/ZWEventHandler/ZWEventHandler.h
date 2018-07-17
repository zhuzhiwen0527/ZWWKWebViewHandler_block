//
//  ZWEventHandler.h
//  ZWWebViewHandler
//
//  Created by zzw on 2018/7/17.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

extern NSString * const EventHandler;
typedef void (^ZWResponseCallback)(id responseData);
typedef void (^ZWHandler)(id data, ZWResponseCallback responseCallback);
@interface ZWEventHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSString  *handlerJS;
@property (nonatomic, strong) NSMutableDictionary * registerHandlers;
+ (instancetype)instance;
- (void)registerHandler:(NSString*)handlerName handler:(ZWHandler)handler;
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(ZWResponseCallback)responseCallback;
@end
