//
//  WGVoiceManager.h
//
//  Created by Veeco on 2017/3/2.
//

#import <Foundation/Foundation.h>
@class WGVoiceManager;

@protocol WGVoiceManagerDelegate <NSObject>

@optional

/**
 * 代理方法1 监听录音音量改变
 * 参数 manager 本单例
 * 参数 volumn 音量值
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager gotVolume:(float)volume;

/**
 * 代理方法2 监听录音完成
 * 参数 manager 本单例
 * 返回 base64String 录音文件base64字符串
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager didRecordByBase64String:(nonnull NSString *)base64String;

/**
 * 代理方法3 监听播放完成
 * 参数 manager 本单例
 */
- (void)didPlayWithManager:(nonnull __kindof WGVoiceManager *)manager;

@end

@interface WGVoiceManager : NSObject

/** 代理 */
@property (nonatomic, weak, nullable) id<WGVoiceManagerDelegate> delegate;

/**
 * 获取单例
 */
+ (nonnull __kindof WGVoiceManager *)manager;

/**
 *  开始录音
 */
- (void)recordStart;

/**
 *  停止录音
 */
- (void)recordStop;

/**
 *  取消录音
 */
- (void)recordCancel;

/**
 * 播放语音
 * 参数 base64String 要播放的声音文件的base64字符串
 */
- (void)playWithBase64String:(nonnull NSString *)base64String;

/**
 * 检查播放状态
 * 返回 是否正在播放
 */
- (BOOL)isPlaying;

/**
 * 检查录音状态
 * 返回 是否正在录音
 */
- (BOOL)isRecording;

@end
