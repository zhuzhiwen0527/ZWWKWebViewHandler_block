//
//  ZWWKWebViewController.m
//  ZWWebViewHandler
//
//  Created by zzw on 2018/7/17.
//  Copyright © 2018年 zzw. All rights reserved.
//

#import "ZWWKWebViewController.h"
#import "ZWEventHandler.h"
@interface ZWWKWebViewController ()<WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) ZWEventHandler * handler;
@end

@implementation ZWWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self configureWKWebview];
    // 添加进入条
    _progressView = [[UIProgressView alloc] init];
    _progressView.frame = self.view.bounds;
    [self.view addSubview:_progressView];
    _progressView.backgroundColor = [UIColor blackColor];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"前进" style:UIBarButtonItemStyleDone target:self action:@selector(gofarward)];
}


- (void)configureWKWebview{

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = YES;


    // web内容处理池
    config.processPool = [[WKProcessPool alloc] init];

    // ZWEventHandler instance 不是单例
    ZWEventHandler * handle = [ZWEventHandler instance];
    //注册target  js methodName 在 target 内一一对应实现方法

    //注入js代码
    WKUserScript *usrScript = [[WKUserScript alloc] initWithSource:handle.handlerJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];

    // 通过JS与webview内容交互
    config.userContentController = [[WKUserContentController alloc] init];

    [config.userContentController addUserScript:usrScript];
    // 注入JS对象名称AppModel，当JS通过AppModel来调用时，
    // 我们可以在WKScriptMessageHandler代理中接收到
    
    [config.userContentController addScriptMessageHandler:handle name:EventHandler];




    //通过默认的构造器来创建对象
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                  configuration:config];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    [self.view addSubview:_webView];


    handle.webView = _webView;
    self.handler = handle;
    // 导航代理
    _webView.navigationDelegate = self;
    // 与webview UI交互代理
    _webView.UIDelegate = self;

    // 添加KVO监听
    [_webView addObserver:self
               forKeyPath:@"loading"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [_webView addObserver:self
               forKeyPath:@"title"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [_webView addObserver:self
               forKeyPath:@"estimatedProgress"
                  options:NSKeyValueObservingOptionNew
                  context:nil];

    //  js 调用 oc  注册 方法名  与html nativeMethodName 对应
    [self.handler registerHandler:@"sendInfoToNative" handler:^(id data, ZWResponseCallback responseCallback) {
        NSLog(@"sendInfoToNative %@",data);
    }];

    [self.handler registerHandler:@"getInfoFromNative" handler:^(id data, ZWResponseCallback responseCallback) {
        NSLog(@"sendInfoToNative %@",data);
        responseCallback(@"sendInfoToNative 回调");

    }];
}

- (void)goback {
    // oc 调用 js   注册方法名 与 html  methodName 对应
    [self.handler callHandler:@"firstCallHabler" data:@"传参无回调"];
//    if ([self.webView canGoBack]) {
//        [self.webView goBack];
//    }
}

- (void)gofarward {
    
    [self.handler callHandler:@"secondCallHandler" data:@"好奇哦" responseCallback:^(id responseData) {
        NSLog(@"%@",responseData);
    }];
//    if ([self.webView canGoForward]) {
//        [self.webView goForward];
//    }
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading");
    } else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"progress: %f", self.webView.estimatedProgress);
        self.progressView.progress = self.webView.estimatedProgress;
    }

    if (!self.webView.loading) {
        // 手动调用JS代码
        // 每次页面完成都弹出来，大家可以在测试时再打开
        //    NSString *js = @"callJsAlert()";
        //    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        //      NSLog(@"response: %@ error: %@", response, error);
        //    }];

        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0;
        }];
    }
}

#pragma mark - WKNavigationDelegate
// 请求开始前，会先调用此代理方法
// 与UIWebView的
// - (BOOL)webView:(UIWebView *)webView
// shouldStartLoadWithRequest:(NSURLRequest *)request
// navigationType:(UIWebViewNavigationType)navigationType;
// 类型，在请求先判断能不能跳转（请求）


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:
(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated
        && ![hostname containsString:@".lanou.com"]) {
        // 对于跨域，需要手动跳转
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];

        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        self.progressView.alpha = 1.0;
        decisionHandler(WKNavigationActionPolicyAllow);
    }

    NSLog(@"00===%s", __FUNCTION__);
}


// 在响应完成时，会回调此方法
// 如果设置为不允许响应，web内容就不会传过来
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
    NSLog(@"11===%s", __FUNCTION__);
}


// 开始导航跳转时会回调
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"22===%s", __FUNCTION__);
}

// 接收到重定向时会回调
- (void)webView:(WKWebView *)webView
didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"33===%s", __FUNCTION__);
}


// 导航失败时会回调
- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"44===%s", __FUNCTION__);
}


// 页面内容到达main frame时回调
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"55===%s", __FUNCTION__);
}


// 导航完成时，会回调（也就是页面载入完成了）
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"66===%s", __FUNCTION__);
}


// 导航失败时会回调
- (void)webView:(WKWebView *)webView didFailNavigation:
(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"77===%s", __FUNCTION__);
}


// 对于HTTPS的都会触发此代理，如果不要求验证，传默认就行
// 如果需要证书验证，与使用AFN进行HTTPS证书验证是一样的

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:
(NSURLAuthenticationChallenge *)challenge completionHandler:
(void (^)(NSURLSessionAuthChallengeDisposition disposition,
          NSURLCredential *__nullable credential))completionHandler {
    NSLog(@"88===%s", __FUNCTION__);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}


// 9.0才能使用，web内容处理中断时会触发
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"99===%s", __FUNCTION__);
}



// 在JS端调用alert函数时，会触发此代理方法。
// JS端调用alert时所传的数据可以通过message拿到
// 在原生得到结果后，需要回调JS，是通过completionHandler回调
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@"100===%s", __FUNCTION__);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:
                      UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                          completionHandler();
                      }]];

    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@", message);
}

// JS端调用confirm函数时，会触发此方法
// 通过message可以拿到JS端所传的数据
// 在iOS端显示原生alert得到YES/NO后
// 通过completionHandler回调给JS端
- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler {
    NSLog(@"101===%s", __FUNCTION__);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                                @"confirm" message:@"JS调用confirm"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                                                  completionHandler(YES);
                                              }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                                  completionHandler(NO);
                                              }]];
    [self presentViewController:alert animated:YES completion:NULL];
    NSLog(@"%@", message);
}


// JS端调用prompt函数时，会触发此方法
// 要求输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS
- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    NSLog(@"102===%s", __FUNCTION__);
    NSLog(@"%@", prompt);


    UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                                prompt message:defaultText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                  completionHandler([[alert.textFields lastObject] text]);
                                              }]];

    [self presentViewController:alert animated:YES completion:NULL];




}


- (void)dealloc{

    [_webView.configuration.userContentController removeScriptMessageHandlerForName:EventHandler];
    [_webView evaluateJavaScript:@"ZWEventHandler.removeAllCallBacks();" completionHandler:^(id _Nullable data, NSError * _Nullable error) {


    }];//删除所有的回调事件

}


@end
