//
//  LFShareManager.m
//  UmengSharePlugInDemo
//
//  Created by Xiao Xiao on 2018/8/27.
//  Copyright © 2018年 Xiao Xiao. All rights reserved.
//

#import "LFShareAndLogInManager.h"
#import "LFShareConst.h"
#import "LFQQApiPlugIn.h"
#import "LFWBApiPlugIn.h"
#import "LFWXApiPlugIn.h"
@interface LFShareAndLogInManager()<LFQQApiPlugInDelegate,LFWXApiPlugInDelegate,LFWBApiPlugInDelegate>
//qq的管理类
@property(strong,nonatomic)LFQQApiPlugIn * qqPlugIn;
//微信的管理类
@property(strong,nonatomic)LFWXApiPlugIn * wxPlugIn;
//微博的管理类
@property(strong,nonatomic)LFWBApiPlugIn * wbPlugIn;
@end
@implementation LFShareAndLogInManager
/**
 * 创建单例
 */
+ (LFShareAndLogInManager *)sharedInstance
{
    static LFShareAndLogInManager * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LFShareAndLogInManager alloc] init];
    });
    return sharedInstance;
}
#pragma mark- public方法
-(void)registerThirdPlatform{
    //微信注册
    [self.wxPlugIn WXRegister];
    //微博注册
    [self.wbPlugIn WBRegister:YES];
}

- (BOOL)thirdPlatformApplicationHandleOpenURL:(NSURL *)url {
    
    if ([LFTencentURLScheme isEqualToString:[url scheme]]) {
        //QQ
        if (YES == [TencentOAuth CanHandleOpenURL:url])
        {
            return [TencentOAuth HandleOpenURL:url];
        }
        return [QQApiInterface handleOpenURL:url delegate:self.qqPlugIn];
    }else if ([LFWXURLScheme isEqualToString:[url scheme]]) {
        //微信
        return [WXApi handleOpenURL:url delegate:self.wxPlugIn];
    }else if ([LFSinaURLScheme isEqualToString:[url scheme]]){
        //微博
        return [WeiboSDK handleOpenURL:url delegate:self.wbPlugIn];
    }
    return NO;
}

-(void)logIn:(LFSharePlatFormType)platFormType{
    switch (platFormType) {
        case LFSharePlatFormQQ:
            [[LFShareAndLogInManager sharedInstance].qqPlugIn QQOauthLogin];
            break;
        case LFSharePlatFormWX:
            [[LFShareAndLogInManager sharedInstance].wxPlugIn WXOauthLogin];
            break;
        case LFSharePlatFormWeiBo:
            [[LFShareAndLogInManager sharedInstance].wbPlugIn WBOauthLogin];
            break;
        default:
            break;
    }
}

- (void)logOut{
    [self.qqPlugIn QQLogout];
//    [self.wbPlugIn WBOauthLogin];
}

- (void) shareToThirdPlatformWithModel:(LFShareModel *)model{
    switch (model.platformType) {
        case LFSharePlatFormQQ:
            
            break;
        case LFSharePlatFormQQZone:
            
            break;
        case LFSharePlatFormWX:
            
            break;
        case LFSharePlatFormWXFriends:
            
            break;
        case LFSharePlatFormWeiBo:
            
            break;
        default:
            break;
    }
}
#pragma mark- 显示提示语
-(void)showToastMessage:(NSString *)message{
    if (self.delegate && [self.delegate respondsToSelector:@selector(shareAndLogInToShowToastMessage:)]) {
        [self.delegate shareAndLogInToShowToastMessage:message];
    }
}
-(void)loginSuccess:(NSDictionary *)responseObject{
    if (self.delegate && [self.delegate respondsToSelector:@selector(thirdPlatformDidLoginSuccess:)]) {
        [self.delegate thirdPlatformDidLoginSuccess:responseObject];
    }
}
#pragma mark- QQApiPlugInDelegate  QQ代理
/**
 * 登录成功后的回调
 */
- (void)QQApiPlugInTencentDidLogin:(NSDictionary *)dic{
    //授权成功正在登录中
    [self showToastMessage:LFQQToastLoginSuccessed];
    if (self.delegate && [self.delegate respondsToSelector:@selector(thirdPlatformDidLoginSuccess:)]) {
        [self.delegate thirdPlatformDidLoginSuccess:dic];
    }
}
/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)QQApiPlugInTencentDidNotLogin:(BOOL)cancelled{
    if(cancelled){
        [self showToastMessage:LFQQToastLoginCancelled];
    }else{
        [self showToastMessage:LFQQToastLoginFailed];
    }
}
/**
 * 登录时网络有问题的回调
 */
- (void)QQApiPlugInTencentDidNotNetWork{
    [self showToastMessage:LFQQToastNetworkError];
}
/**
 * 登录成功获取用户个人信息回调
 */
- (void)QQApiPlugInGetUserInfoResponse:(APIResponse*) response tencentOAuth:(TencentOAuth *)tencentOAut{
    //获取到QQ的用户信息
    NSLog(@"===%@",response.jsonResponse);
    NSInteger gender = 0;
    if ([response.jsonResponse[@"gender"] isEqualToString:@"男"]){
        gender = 1;
    }
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    [params setValue:tencentOAut.openId forKey:@"openid"];//openid【必须】
    [params setValue:[response.jsonResponse objectForKey:@"nickname"] forKey:@"nickName"];//QQ昵称【必须】
    [params setValue:[response.jsonResponse objectForKey:@"figureurl_qq_2"] forKey:@"avatar"];//头像【必须】
    [params setValue:gender == 1 ? @"男":@"女" forKey:@"sex"];//性别【必须】
    //登录成功回调
#warning 需要开发调用自己的登录接口
    [self loginSuccess:params];
}

- (void)QQApiPlugInDidRecvSendMessageResponse:(SendMessageToQQResp *)response{
    switch (response.type)
    {
        case ESENDMESSAGETOQQRESPTYPE:
        {
            if ([response.result isEqualToString:@"0"])
            {
                //QQ分享成功
                [self showToastMessage:LFQQToastShareSuccessed];
            }
            else
            {
                //QQ分享失败
                [self showToastMessage:LFQQToastShareFailed];
            }
            break;
        }
        default:
        {
            break;
        }
    }
}
#pragma mark- WXApiPlugInDelegate  微信代理
//第三方程序向微信终端发送SendMessageToWXReq后，微信发送回来的处理结果，该结果用SendMessageToWXResp表示。
- (void)WXApiPlugInDidRecvMessageResponse:(SendMessageToWXResp *)response{
    switch (response.errCode)
    {
        case WXErrCodeUserCancel:
            [self showToastMessage:LFWXToastShareCancelled];
            break;
        case WXErrCodeSentFail:
            [self showToastMessage:LFWXToastShareFailed];
            break;
        case WXSuccess:
            [self showToastMessage:LFWXToastShareSuccessed];
            break;
        default:
            break;
    }
}
//微信处理完第三方程序的认证和权限申请后向第三方程序回送的处理结果响应
- (void)WXApiPlugInDidRecvAuthResponse:(SendAuthResp *)response{
    //获取accessToken
    SendAuthResp *oauthResp = (SendAuthResp *)response;
    if (oauthResp.errCode == WXErrCodeAuthDeny)
    {
        [self showToastMessage:LFWXToastLoginRefused];
    }
    else if (oauthResp.errCode == WXErrCodeUserCancel)
    {
        [self showToastMessage:LFWXToastLoginCancelled];
    }
    else if (oauthResp.errCode == WXSuccess)
    {
        //TODO:获取到微信code 请求后台接口授权
        [self loginSuccess:@{@"code":oauthResp.code?oauthResp.code:@"",@"redirectUri":LFShareRedirectURL}];
        [self showToastMessage:LFWXToastLoginSuccessed];
    }
}

//获取微信用户信息
-(void)getWXUserInfo:(NSString *)access_token openid:(NSString *)openid{
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",access_token,openid];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSMutableDictionary * params = [NSMutableDictionary dictionary];
                [params setValue:openid forKey:@"openid"];//openid【必须】
                [params setValue:[dic objectForKey:@"nickname"] forKey:@"nickName"];//QQ昵称【必须】
                [params setValue:[dic objectForKey:@"headimgurl"] forKey:@"avatar"];//头像【必须】
                [params setValue:[[dic objectForKey:@"sex"] integerValue] == 1 ? @"男":@"女" forKey:@"sex"];//性别【必须】
                //微信登录
#warning 需要开发调用自己的登录接口
                [self loginSuccess:params];
            }
        });
    });
}
#pragma mark- WBApiPlugInDelegate  微博代理
- (void)WBApiPlugInDidRecvSendMessageResponse:(WBSendMessageToWeiboResponse *)response{
    //分享状态获取
    switch (response.statusCode)
    {
        case WeiboSDKResponseStatusCodeUserCancel:
            [self showToastMessage:LFWBToastShareCancelled];
            break;
        case WeiboSDKResponseStatusCodeSentFail:
            [self showToastMessage:LFWBToastShareFailed];
            break;
        case WeiboSDKResponseStatusCodeSuccess:
            [self showToastMessage:LFWBToastShareSuccessed];
            break;
        default:
            break;
    }
}
- (void)WBApiPlugInDidRecvAuthorizeResponse:(WBAuthorizeResponse *)response{
    if ((int)response.statusCode == 0) {
        WBAuthorizeResponse *authorize = (WBAuthorizeResponse *)response;
        [self showToastMessage:LFWBToastLoginSuccessed];
        [self loginSuccess:@{@"uid":authorize.userInfo[@"uid"]?authorize.userInfo[@"uid"]:@"",@"accessToken":authorize.accessToken?authorize.accessToken:@""}];
        //获取微博的用户信息
        [self getWeiBoUserInfo:authorize];
    }else if ((int)response.statusCode == -1){
        [self showToastMessage:LFWBToastLoginCancelled];
    }else if ((int)response.statusCode == -2){
        [self showToastMessage:LFWBToastLoginFailed];
    }
}
//获取微博信息
-(void)getWeiBoUserInfo:(WBAuthorizeResponse *)response{
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:response.accessToken forKey:@"access_token"];
    [params setValue:response.userID forKey:@"uid"];
    //TODO:发起网络请求
//    NSString * url = @"https://api.weibo.com/2/users/show.json";
//    typeof(self) __weak weakSelf = self;
//    [[NetWorkManager sharedInstance] GET:url parameters:params origin:YES success:^(NSInteger statusCode, NSString *message, id responseObject) {
//        STRONGSELFFor(weakSelf)
//        NSDictionary * dic = (NSDictionary *)responseObject;
//        [strongSelf weiboLogin:dic andUserID:response.userID];
//    } failure:^(id responseObject, NSError *error) {
//    }];
}
//微博登录
-(void)weiboLogin:(NSDictionary *)dic andUserID:(NSString *)userID{
    NSInteger gender = 0;
    if ([[dic objectForKey:@"gender"] isEqualToString:@"m"]){
        gender = 1;
    }
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    [params setValue:userID forKey:@"openid"];//openid【必须】
    [params setValue:[dic objectForKey:@"name"] forKey:@"nickName"];//QQ昵称【必须】
    [params setValue:[dic objectForKey:@"avatar_hd"] forKey:@"avatar"];//头像【必须】
    [params setValue:gender == 1 ? @"男":@"女" forKey:@"sex"];//性别【必须】
    //微博登录
#warning 需要开发调用自己的登录接口
    [self loginSuccess:params];
}
#pragma mark getter/setter
- (LFQQApiPlugIn *)qqPlugIn{
    if (!_qqPlugIn) {
        _qqPlugIn = [LFQQApiPlugIn sharedInstance];
        _qqPlugIn.qqDelegate = self;
    }
    return _qqPlugIn;
}

- (LFWXApiPlugIn *)wxPlugIn{
    if (!_wxPlugIn) {
        _wxPlugIn = [LFWXApiPlugIn sharedInstance];
        _wxPlugIn.wxDelegate = self;
    }
    return _wxPlugIn;
}

- (LFWBApiPlugIn *)wbPlugIn{
    if (!_wbPlugIn) {
        _wbPlugIn = [LFWBApiPlugIn sharedInstance];
        _wbPlugIn.wbDelegate = self;
    }
    return _wbPlugIn;
}
@end
