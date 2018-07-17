//
//  ZWEventHandler.m
//  ZWWebViewHandler
//
//  Created by zzw on 2018/7/17.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ZWEventHandler.h"
#if DEBUG
#define ZWLog(FORMAT, ...) fprintf(stderr,"\nfunction:%s line:%d content:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define ZWLog(FORMAT, ...) nil
#endif
 NSString * const EventHandler = @"ZWEventHandler";

@interface ZWEventHandlerEmptyObject :NSObject

@end

@implementation ZWEventHandlerEmptyObject

@end

@implementation ZWEventHandler

+ (instancetype)instance{

    ZWEventHandler * handler  = [[self alloc] init];
    handler.handlerJS = [handler getJsString];
    return handler;

}

#pragma mark -- lazy

- (NSMutableDictionary *)registerHandlers{
    if (!_registerHandlers) {
        _registerHandlers = [[NSMutableDictionary alloc] init];
    }
    return _registerHandlers;
}
- (NSString *)getJsString{

    NSString *path =[[NSBundle bundleForClass:[self class]] pathForResource:@"ZWEventHandler" ofType:@"js"];
    NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
    handlerJS = [handlerJS stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return handlerJS;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    // NSLog(@"message :%@",message.body);
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wincompatible-pointer-types-discards-qualifiers"
    if ([message.name isEqualToString:EventHandler]) {
#pragma clang diagnostic pop
        NSString *methodName = message.body[@"methodName"];
        NSDictionary *params = message.body[@"params"];
        NSString *callBackName = message.body[@"callBackID"];

        ZWHandler hanler = self.registerHandlers[methodName];


        if (hanler) {
                __weak typeof(self) weakSelf = self;
            if (callBackName) {

                hanler(params,^(id response) {

                    [weakSelf _zwCallJSCallBackWithCallBackName:callBackName response:response];
                });
            }else{

                hanler(params,^(id response) {

                });

            }
        }
    }


}

- (void)_zwCallJSCallBackWithCallBackName:(NSString *)callBackName response:(id)response{
    __weak  WKWebView *weakWebView = _webView;
    NSString *js = [NSString stringWithFormat:@"ZWEventHandler.callBack('%@','%@');",callBackName,response];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {

        }];
    });
}


#pragma mark -- callHandler & registerHandler


- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(ZWResponseCallback)responseCallback {
    [self _zwCallJSCallBackWithCallBackName:handlerName response:data];
    if (responseCallback) {
        [self.registerHandlers setObject:responseCallback forKey:handlerName];
    }

}
- (void)registerHandler:(NSString *)handlerName handler:(ZWHandler)handler {
    if (handler) {

        [self.registerHandlers setObject:handler forKey:handlerName];
    }
}

@end
