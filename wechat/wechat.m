//
//  wechat.m
//  wechat
//
//  Created by ZW on 16/3/2.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "wechat.h"
#import <objc/runtime.h>

#define CBHookInstanceMethod(classname, ori_sel, new_sel) \
\
{ \
Class class = objc_getClass(#classname); \
Method ori_method = class_getInstanceMethod(class, ori_sel); \
Method new_method = class_getInstanceMethod(class, new_sel); \
method_exchangeImplementations(ori_method, new_method); \
} \
\

@interface WCPayInfoItem: NSObject
@property(retain, nonatomic) NSString *m_c2cNativeUrl;
@end


@interface CMessageWrap : NSObject // 微信消息
@property (retain, nonatomic) WCPayInfoItem *m_oWCPayInfoItem;
@property (assign, nonatomic) NSUInteger m_uiMesLocalID;
@property (retain, nonatomic) NSString* m_nsFromUsr; // 发信人，可能是群或个人
@property (retain, nonatomic) NSString* m_nsToUsr; // 收信人
@property (assign, nonatomic) NSUInteger m_uiStatus;
@property (retain, nonatomic) NSString* m_nsContent; // 消息内容
@property (retain, nonatomic) NSString* m_nsRealChatUsr; // 群消息的发信人，具体是群里的哪个人
@property (nonatomic) NSUInteger m_uiMessageType;
@property (nonatomic) long long m_n64MesSvrID;
@property (nonatomic) NSUInteger m_uiCreateTime;
@property (retain, nonatomic) NSString *m_nsDesc;
@property (retain, nonatomic) NSString *m_nsAppExtInfo;
@property (nonatomic) NSUInteger m_uiAppDataSize;
@property (nonatomic) NSUInteger m_uiAppMsgInnerType;
@property (retain, nonatomic) NSString *m_nsShareOpenUrl;
@property (retain, nonatomic) NSString *m_nsShareOriginUrl;
@property (retain, nonatomic) NSString *m_nsJsAppId;
@property (retain, nonatomic) NSString *m_nsPrePublishId;
@property (retain, nonatomic) NSString *m_nsAppID;
@property (retain, nonatomic) NSString *m_nsAppName;
@property (retain, nonatomic) NSString *m_nsThumbUrl;
@property (retain, nonatomic) NSString *m_nsAppMediaUrl;
@property (retain, nonatomic) NSData *m_dtThumbnail;
@property (retain, nonatomic) NSString *m_nsTitle;
@property (retain, nonatomic) NSString *m_nsMsgSource;
- (instancetype)initWithMsgType:(int)msgType;
+ (UIImage *)getMsgImg:(CMessageWrap *)arg1;
+ (NSData *)getMsgImgData:(CMessageWrap *)arg1;
+ (NSString *)getPathOfMsgImg:(CMessageWrap *)arg1;
- (UIImage *)GetImg;
- (BOOL)IsImgMsg;
- (BOOL)IsAtMe;
+ (void)GetPathOfAppThumb:(NSString *)senderID LocalID:(NSUInteger)mesLocalID retStrPath:(NSString **)pathBuffer;
@end

@interface CMessageMgr : NSObject

- (void)AsyncOnAddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap;

@end



@interface WCRedEnvelopesControlData : NSObject
@property(retain, nonatomic) CMessageWrap *m_oSelectedMessageWrap;
@end



@interface MMServiceCenter : NSObject
+ (instancetype)defaultCenter;
- (id)getService:(Class)service;
@end
// @interface WCRedEnvelopesControlMgr : NSObject
// - (unsigned int)startLogic:(id)arg1;
// @end

// @interface WCRedEnvelopesReceiveControlLogic : NSObject

// - (id)initWithData:(id)arg1;

// - (void)startLogic;

// - (void)WCRedEnvelopesReceiveHomeViewOpenRedEnvelopes;

// @end

@interface WCRedEnvelopesLogicMgr: NSObject
- (void)OpenRedEnvelopesRequest:(id)params;
@end



@interface MMMsgLogicManager: NSObject
- (id)GetCurrentLogicController;
@end


@interface CContact: NSObject
@property(retain, nonatomic) NSString *m_nsUsrName;
@property(retain, nonatomic) NSString *m_nsHeadImgUrl;
@property(retain, nonatomic) NSString *m_nsNickName;


- (id)getContactDisplayName;
@end



@interface WCBizUtil : NSObject

+ (id)dictionaryWithDecodedComponets:(id)arg1 separator:(id)arg2;

@end



@interface CContactMgr : NSObject
- (id)getSelfContact;
@end


@interface NSMutableDictionary (SafeInsert)
- (void)safeSetObject:(id)arg1 forKey:(id)arg2;
@end


@implementation NSObject (MsgPreview)

- (void)cb_AsyncOnAddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap {
    [self cb_AsyncOnAddMsg:msg MsgWrap:wrap];
    
    switch(wrap.m_uiMessageType) {
        case 49: { // AppNode
            
            
            CContactMgr *contactMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("CContactMgr") class]];

            CContact *selfContact = [contactMgr getSelfContact];
            BOOL isMesasgeFromMe = NO;
            if ([wrap.m_nsFromUsr isEqualToString:selfContact.m_nsUsrName]) {
                isMesasgeFromMe = YES;
            }

            if ([wrap.m_nsContent rangeOfString:@"wxpay://"].location != NSNotFound) { // 红包
                if ([wrap.m_nsFromUsr rangeOfString:@"@chatroom"].location != NSNotFound ||
                    (isMesasgeFromMe && [wrap.m_nsToUsr rangeOfString:@"@chatroom"].location != NSNotFound)) { // 群组红包或群组里自己发的红包
                    
                    NSString *nativeUrl = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];
                    nativeUrl = [nativeUrl substringFromIndex:[@"wxpay://c2cbizmessagehandler/hongbao/receivehongbao?" length]];
//
                    NSDictionary *nativeUrlDict = [objc_getClass("WCBizUtil") dictionaryWithDecodedComponets:nativeUrl separator:@"&"];

                    /** 构造参数 */
                    NSMutableDictionary *params = [@{} mutableCopy];
                    [params safeSetObject:nativeUrlDict[@"msgtype"] forKey:@"msgType"];
                    [params safeSetObject:nativeUrlDict[@"sendid"] forKey:@"sendId"];
                    [params safeSetObject:nativeUrlDict[@"channelid"] forKey:@"channelId"];
                    [params safeSetObject:[selfContact getContactDisplayName] forKey:@"nickName"];
                    [params safeSetObject:[selfContact m_nsHeadImgUrl] forKey:@"headImg"];
                    [params safeSetObject:[[wrap m_oWCPayInfoItem] m_c2cNativeUrl] forKey:@"nativeUrl"];
                    [params safeSetObject:wrap.m_nsFromUsr forKey:@"sessionUserName"];
                    
                    WCRedEnvelopesLogicMgr *logicMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("WCRedEnvelopesLogicMgr") class]];
//
                    [logicMgr performSelector:@selector(OpenRedEnvelopesRequest:) withObject:params afterDelay:1];
//                    //                    [logicMgr OpenRedEnvelopesRequest:params];
                }
            }
            break;
        }
        default:
            break;
    }
}

@end

static void __attribute__((constructor)) initialize(void) {
    CBHookInstanceMethod(CMessageMgr, @selector(AsyncOnAddMsg:MsgWrap:), @selector(cb_AsyncOnAddMsg:MsgWrap:));
//    CBHookInstanceMethod(BaseMsgContentViewController, @selector(viewDidLoad), @selector(cb_msgContentViewControllerViewDidLoad));
//    CBHookInstanceMethod(MMWebViewController, @selector(viewDidLoad), @selector(cb_webViewControllerViewDidLoad));
}
