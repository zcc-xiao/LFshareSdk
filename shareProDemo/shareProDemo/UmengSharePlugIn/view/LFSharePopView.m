//
//  LFSharePopView.m
//  UmengSharePlugInDemo
//
//  Created by Xiao Xiao on 2018/8/29.
//  Copyright © 2018年 Xiao Xiao. All rights reserved.
//

#import "LFSharePopView.h"
#import "LFShareConst.h"
#import "LFShareAndLogInManager.h"
typedef void(^hiddenShareblock)(void);
@interface LFSharePopView()
@property(nonatomic ,strong)UIImageView *shareTopImgView;
@property(nonatomic ,strong)UIView *shareBottomView;
@property(nonatomic ,strong)UIButton *shareQQbtn;
@property(nonatomic ,strong)UIButton *shareWXbtn;
@property(nonatomic ,strong)UIButton *shareWXFriendBtn;
@property(nonatomic ,strong)UIButton *shareWeiBoBtn;
@property(nonatomic ,assign)BOOL isHidden;
@end
@implementation LFSharePopView
- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [self addSubview:self.shareTopImgView];
        _shareTopImgView.userInteractionEnabled = YES;
        [self addSubview:self.shareBottomView];
        _shareBottomView.userInteractionEnabled = YES;
        [_shareBottomView addSubview:self.shareWXFriendBtn];
        [_shareBottomView addSubview:self.shareWeiBoBtn];
        [_shareBottomView addSubview:self.shareQQbtn];
        [_shareBottomView addSubview:self.shareWXbtn];
    }
    return self;
}


- (void) initUI{
    _shareTopImgView.frame = CGRectMake(0, CGRectGetMaxY(self.bounds), CGRectGetWidth(self.bounds), 80);
    _shareBottomView.frame = CGRectMake(0,CGRectGetMaxY(_shareTopImgView.frame), CGRectGetWidth(self.frame), iPhoneX()?IPhoneXSafeAreaPotraitBottom + 132:132 );
    
    CGFloat btnSpace = (CGRectGetWidth(self.frame) - 45*4- AspectScale(30)*2)/3.0;
    _shareWXFriendBtn.frame = CGRectMake(AspectScale(30), 32, 45, 45+8+16.5);
    _shareWeiBoBtn.frame = CGRectMake(CGRectGetMaxX(_shareWXFriendBtn.frame)+btnSpace, 32, 45, 45+8+16.5);
    _shareQQbtn.frame = CGRectMake(CGRectGetMaxX(_shareWeiBoBtn.frame)+btnSpace, 32, 45, 45+8+16.5);
    _shareWXbtn.frame = CGRectMake(CGRectGetMaxX(_shareQQbtn.frame)+btnSpace, 32, 45, 45+8+16.5);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (CGRectContainsPoint(_shareBottomView.frame, point) || CGRectContainsPoint(_shareTopImgView.frame, point)){
        return [super hitTest:point withEvent:event];
    }
    [self hideShareView:nil];
    return self;
}

-(void)showShareView{
    _isHidden = NO;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    [self initUI];
    typeof(self) __weak weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        typeof(weakSelf) __strong strongSelf = weakSelf;

        strongSelf.shareTopImgView.transform = CGAffineTransformMakeTranslation(0, -(CGRectGetHeight(strongSelf.shareBottomView.frame) +CGRectGetHeight(strongSelf.shareTopImgView.bounds)));

        strongSelf.shareBottomView.transform =CGAffineTransformMakeTranslation(0, -(CGRectGetHeight(strongSelf.shareBottomView.frame) +CGRectGetHeight(strongSelf.shareTopImgView.bounds)));
    }];
}

-(void)hideShareView:(hiddenShareblock)compelteBlck{
    if (_isHidden == YES)return;
    _isHidden = YES;
    typeof(self) __weak weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        typeof(weakSelf) __strong strongSelf = weakSelf;
        strongSelf.shareBottomView.transform = CGAffineTransformIdentity;
        strongSelf.shareTopImgView.transform = CGAffineTransformIdentity;

    } completion:^(BOOL finished) {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        if (finished == YES) {
            [strongSelf removeFromSuperview];
            if (compelteBlck) {
                compelteBlck();
            }
        }
    }];
}

- (void) setUpBtnSpaceImgAndTitle:(UIButton *)btn andSpace:(CGFloat)space{
    CGFloat imageWith = btn.imageView.frame.size.width;
    CGFloat imageHeight = btn.imageView.frame.size.height;
    CGFloat labelWidth = btn.titleLabel.intrinsicContentSize.width;
    CGFloat labelHeight = btn.titleLabel.intrinsicContentSize.height;
   UIEdgeInsets imageEdgeInsets = UIEdgeInsetsMake(-labelHeight-space/2.0, 0, 0, -labelWidth);
  UIEdgeInsets  labelEdgeInsets = UIEdgeInsetsMake(0, -imageWith, -imageHeight-space/2.0, 0);
    btn.titleEdgeInsets = labelEdgeInsets;
    btn.imageEdgeInsets = imageEdgeInsets;
}

#pragma mark --Actions--
- (void) shareQQbtnAction{
    _model.platformType = LFSharePlatFormQQ;
    [self shareAction];
}

- (void) shareWXbtnAction{
    _model.platformType = LFSharePlatFormWX;
    [self shareAction];
}

- (void) shareWXFriendbtnAction{
    _model.platformType = LFSharePlatFormWXFriends;
    [self shareAction];
}

- (void) shareWBAction{
    _model.platformType = LFSharePlatFormWeiBo;
    [self shareAction];
}

- (void) shareAction{
     typeof(self) __weak weakSelf = self;
    [self hideShareView:^{
        typeof(weakSelf) __strong strongSelf = weakSelf;
        [[LFShareAndLogInManager sharedInstance] shareToThirdPlatformWithModel:strongSelf.model];
    }];
}
#pragma mark  --getter/setter--
- (UIImageView *)shareTopImgView{
    if (!_shareTopImgView) {
        _shareTopImgView = [[UIImageView alloc] initWithImage:LFBundle_Image(@"popup_share")];
        _shareTopImgView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _shareTopImgView;
}
- (UIView *)shareBottomView{
    if (!_shareBottomView) {
        _shareBottomView = [[UIView alloc] init];
        _shareBottomView.backgroundColor = [UIColor whiteColor];
    }
    return _shareBottomView;
}

- (UIButton *)shareQQbtn{
    if (!_shareQQbtn) {
        _shareQQbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareQQbtn setTitle:@"QQ" forState:UIControlStateNormal];
        [_shareQQbtn setImage:LFBundle_Image(@"login_qq") forState:UIControlStateNormal];
        _shareQQbtn.highlighted = NO;
        _shareQQbtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_shareQQbtn setTitleColor: [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1/1.0] forState:UIControlStateNormal];
        [_shareQQbtn setFrame:CGRectMake(0, 0, 45, 45+8+16.5)];
        [_shareQQbtn addTarget:self action:@selector(shareQQbtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self setUpBtnSpaceImgAndTitle:_shareQQbtn andSpace:10];
    }
    return _shareQQbtn;
}

- (UIButton *)shareWXbtn{
    if (!_shareWXbtn) {
        _shareWXbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareWXbtn setTitle:@"微信" forState:UIControlStateNormal];
        [_shareWXbtn setImage: LFBundle_Image(@"login_weixin") forState:UIControlStateNormal];
        _shareWXbtn.highlighted = NO;
        _shareWXbtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_shareWXbtn setTitleColor: [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1/1.0] forState:UIControlStateNormal];
        [_shareWXbtn setFrame:CGRectMake(0, 0, 45, 45+8+16.5)];
        [_shareWXbtn addTarget:self action:@selector(shareWXbtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self setUpBtnSpaceImgAndTitle:_shareWXbtn andSpace:10];
    }
    return _shareWXbtn;
}

- (UIButton *)shareWXFriendBtn{
    if (!_shareWXFriendBtn) {
        _shareWXFriendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareWXFriendBtn setTitle:@"朋友圈" forState:UIControlStateNormal];
        [_shareWXFriendBtn setImage:LFBundle_Image(@"login_pengyouquan") forState:UIControlStateNormal];
        _shareWXFriendBtn.highlighted = NO;
        _shareWXFriendBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_shareWXFriendBtn setTitleColor: [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1/1.0]
                                forState:UIControlStateNormal];
        [_shareWXFriendBtn setFrame:CGRectMake(0, 0, 45, 45+8+16.5)];
        [_shareWXFriendBtn addTarget:self
                              action:@selector(shareWXFriendbtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self setUpBtnSpaceImgAndTitle:_shareWXFriendBtn andSpace:10];
    }
    return _shareWXFriendBtn;
}

- (UIButton *)shareWeiBoBtn{
    if (!_shareWeiBoBtn) {
        _shareWeiBoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareWeiBoBtn setTitle:@"微博" forState:UIControlStateNormal];
        [_shareWeiBoBtn setImage:LFBundle_Image(@"login_weibo") forState:UIControlStateNormal];
        _shareWeiBoBtn.highlighted = NO;
        _shareWeiBoBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_shareWeiBoBtn setTitleColor: [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1/1.0] forState:UIControlStateNormal];
        [_shareWeiBoBtn setFrame:CGRectMake(0, 0, 45, 45+8+16.5)];
        [_shareWeiBoBtn addTarget:self action:@selector(shareWBAction) forControlEvents:UIControlEventTouchUpInside];
        [self setUpBtnSpaceImgAndTitle:_shareWeiBoBtn andSpace:10];
    }
    return _shareWeiBoBtn;
}
@end
