//
//  LFQQApiPlugIn.m
//  UmengSharePlugInDemo
//
//  Created by Xiao Xiao on 2018/8/29.
//  Copyright © 2018年 Xiao Xiao. All rights reserved.
//

#import "LFQQApiPlugIn.h"
#import "LFShareConst.h"
#import "UIImage+Tailoring.h"
@interface LFQQApiPlugIn()
@property (strong, nonatomic) TencentOAuth * tencentOauth;
@end
@implementation LFQQApiPlugIn
#pragma mark- init
+ (LFQQApiPlugIn *)sharedInstance
{
    static LFQQApiPlugIn * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LFQQApiPlugIn alloc] init];
    });
    return sharedInstance;
}
#pragma mark- QQ登录相关
/**
 QQ认证登录方法
 */
- (void)QQOauthLogin
{
    self.tencentOauth = [[TencentOAuth alloc]initWithAppId:LFQQAppkey andDelegate:self];
    NSArray *permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            kOPEN_PERMISSION_ADD_SHARE,
                            kOPEN_PERMISSION_GET_INFO, nil];
    [self.tencentOauth authorize:permissions];
}

/**
 * 退出登录(退出登录后，TecentOAuth失效，需要重新初始化)
 * param delegate 第三方应用用于接收请求返回结果的委托对象
 */
-(void)QQLogout{
    [self.tencentOauth logout:self];
}

- (BOOL)isQQInstalled
{
    return [TencentOAuth iphoneQQInstalled];
}
- (BOOL)isZoneInstalled
{
    return [TencentOAuth iphoneQZoneInstalled];
}
//移除代理
- (void)delegateDealloc{
    self.qqDelegate = nil;
}

#pragma mark- QQ分享相关
#pragma mark - 向QQ分享(空间和好友)
-(BOOL)sharedLinkToQQWithTitle:(NSString*)title
                       message:(NSString *) message
                     detailUrl:(NSString *)detailUrl
                         image:(UIImage *)image
                     shareType:(QQShareType) sharedType
{
    UIImage *compressedImage = [image imageWithFileSize:32*1024 scaledToSize:CGSizeMake(300, 300)];
    NSData *imageData = UIImageJPEGRepresentation(compressedImage,1.0);
    NSString *description = message;
    if(description.length > 20)
    {
        description = [message substringToIndex:20];
    }
    QQApiNewsObject *object = [QQApiNewsObject
                               objectWithURL:[NSURL URLWithString:detailUrl]
                               title:title?title:@""
                               description:description
                               previewImageData:imageData];
    
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:object];
    
    QQApiSendResultCode sent;
    if (sharedType == QQShareMessage)
    {
        //将内容分享到qq
        sent = [QQApiInterface sendReq:req];
    }else {
        //将内容分享到qzone
        sent = [QQApiInterface SendReqToQZone:req];
    }
    if (sent == EQQAPISENDSUCESS) {
        return YES;
    }else {
        return NO;
    }
    return NO;
}
//向QQ分享图片(空间和好友)
- (void)shareImgDataToQQ:(NSString *)titleStr
                 andInfo:(NSString *)messageStr
                andImage:(UIImage *)avatar{
    self.tencentOauth = [[TencentOAuth alloc]initWithAppId:LFQQAppkey andDelegate:self];
    NSData *previewImageData = UIImageJPEGRepresentation(avatar,1);
    
    //没有地址URL的,只分享图片出去
    
    //用于分享图片内容的对象
    
    QQApiImageObject *imgObj = [QQApiImageObject objectWithData:previewImageData
                                
                                               previewImageData:previewImageData
                                
                                                          title:titleStr
                                
                                                    description:messageStr];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imgObj];
    //将内容分享到qq
    [QQApiInterface sendReq:req];
}
#pragma mark- ---------------TencentSessionDelegate
/**
 * 退出登录的回调
 */
- (void)tencentDidLogout{
//    [[NSNotificationCenter defaultCenter] postNotificationName:TencentOAuthManagerDidLogout object:nil];
    if (self.qqDelegate && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInTencentDidLogout)]) {
        [self.qqDelegate QQApiPlugInTencentDidLogout];
    }
}
/**
 * 获取用户个人信息回调
 * \param response API返回结果，具体定义参见sdkdef.h文件中\ref APIResponse
 * \remarks 正确返回示例: \snippet example/getUserInfoResponse.exp success
 *          错误返回示例: \snippet example/getUserInfoResponse.exp fail
 */
- (void)getUserInfoResponse:(APIResponse*) response{
    
    if (URLREQUEST_SUCCEED == response.retCode
        && kOpenSDKErrorSuccess == response.detailRetCode)
    {
        //跳转QQ
        if (self.qqDelegate && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInGetUserInfoResponse:tencentOAuth:)]) {
            [self.qqDelegate QQApiPlugInGetUserInfoResponse:response tencentOAuth:self.tencentOauth];
        }
    }
}
- (BOOL)tencentNeedPerformIncrAuth:(TencentOAuth *)tencentOAuth withPermissions:(NSArray *)permissions{
    
    // incrAuthWithPermissions是增量授权时需要调用的登录接口
    // permissions是需要增量授权的权限列表
    [tencentOAuth incrAuthWithPermissions:permissions];
    return NO; // 返回NO表明不需要再回传未授权API接口的原始请求结果；
    // 否则可以返回YES
}

- (BOOL)tencentNeedPerformReAuth:(TencentOAuth *)tencentOAuth{
    return YES;
}
#pragma mark- ---------------TencentLoginDelegate
/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin{
//    [[NSNotificationCenter defaultCenter] postNotificationName:TencentOAuthManagerLoginSuccessed object:nil];
    [self.tencentOauth getUserInfo];
    if (self.qqDelegate && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInTencentDidLogin:)]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:self.tencentOauth.openId forKey:@"openId"];
        [dic setObject:self.tencentOauth.accessToken forKey:@"accessToken"];
        [self.qqDelegate QQApiPlugInTencentDidLogin:dic];
    }
}
/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled{
//    [[NSNotificationCenter defaultCenter] postNotificationName:TencentOAuthManagerLoginCancelled object:nil];
    if (self.qqDelegate && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInTencentDidNotLogin:)]) {
        [self.qqDelegate QQApiPlugInTencentDidNotLogin:cancelled];
    }
}
/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork{
//    [[NSNotificationCenter defaultCenter] postNotificationName:TencentOAuthManagerLoginFailed object:nil];
    if (self.qqDelegate && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInTencentDidNotNetWork)]) {
        [self.qqDelegate QQApiPlugInTencentDidNotNetWork];
    }
}
#pragma mark- ---------------QQApiInterfaceDelegate 分享相关的
/**
 处理来至QQ的请求
 */
- (void)onReq:(QQBaseReq *)req{
    NSLog(@"+++++++++++++++处理来至QQ的请求");
}
/**
 处理来至QQ的响应
 */
- (void)onResp:(QQBaseResp *)resp{
    NSLog(@"+++++++++++++++处理来至QQ的响应");
    if ([resp isKindOfClass:GetMessageFromQQResp.class])
    {
        //获取消息
        if (self.qqDelegate
            && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInDidRecvMessageResponse:)]) {
            GetMessageFromQQResp* getMessageFromQQResponse = (GetMessageFromQQResp*)resp;
            [self.qqDelegate QQApiPlugInDidRecvMessageResponse:getMessageFromQQResponse];
        }
    }
    else if ([resp isKindOfClass:SendMessageToQQResp.class])
    {
        //发送消息
        if (self.qqDelegate
            && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInDidRecvSendMessageResponse:)]) {
            SendMessageToQQResp *sendMessageToQQResponse = (SendMessageToQQResp *)resp;
            [self.qqDelegate QQApiPlugInDidRecvSendMessageResponse:sendMessageToQQResponse];
        }
    }
    else if ([resp isKindOfClass:ShowMessageFromQQResp.class])
    {
        //展示消息
        if (self.qqDelegate
            && [self.qqDelegate respondsToSelector:@selector(QQApiPlugInDidRecvShowMessageResponse:)]) {
            ShowMessageFromQQResp *sendMessageFromQQResponse = (ShowMessageFromQQResp *)resp;
            [self.qqDelegate QQApiPlugInDidRecvShowMessageResponse:sendMessageFromQQResponse];
        }
    }
}
/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response{
    
}
@end
