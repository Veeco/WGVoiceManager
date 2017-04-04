//
//  WGVoiceManager.m
//
//  Created by vs on 2017/3/2.
//

#import "WGVoiceManager.h"
#import <AVFoundation/AVFoundation.h>

// 录音文件url
#define kRecordFileURL [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.aac"]]
// 播放文件url
#define kPlayFileURL [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"play.aac"]]

@interface WGVoiceManager ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

/** 录音器 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 定时器 */
@property (nonatomic, strong) CADisplayLink *displayLink;
/** 播放器 */
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation WGVoiceManager

#pragma mark - <懒加载>

/**
 * 懒加载 定时器
 */
- (CADisplayLink *)displayLink {
    
    if (_displayLink == nil) {
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(meteringRecorder)];
    }
    return _displayLink;
}

/**
 * 懒加载 录音器
 */
- (AVAudioRecorder *)recorder {
    
    if (!_recorder) {
        
        // 设置录音格式信息
        NSMutableDictionary *setting = [NSMutableDictionary dictionary];

        /*
         * settings 参数
         1. AVFormatIDKey
         2. AVNumberOfChannelsKey 通道数 通常为双声道 值2
         3. AVSampleRateKey 采样率 单位HZ 通常设置成44100 也就是44.1k,采样率必须要设为11025才能使转化成mp3格式后不会失真
         4. AVLinearPCMBitDepthKey 比特率 8 16 24 32
         5. AVEncoderAudioQualityKey 声音质量
            ① AVAudioQualityMin  = 0, 最小的质量
            ② AVAudioQualityLow  = 0x20, 比较低的质量
            ③ AVAudioQualityMedium = 0x40, 中间的质量
            ④ AVAudioQualityHigh  = 0x60,高的质量
            ⑤ AVAudioQualityMax  = 0x7F 最好的质量
         6. AVEncoderBitRateKey 音频编码的比特率 单位Kbps 传输的速率 一般设置128000 也就是128kbps
         */
        
        setting[@"AVFormatIDKey"] = @(kAudioFormatMPEG4AAC);
        setting[@"AVSampleRateKey"] = @11025.0;
        
        // 初始化录音器
        _recorder = [[AVAudioRecorder alloc] initWithURL:kRecordFileURL settings:setting error:nil];
        
        // 设置代理
        _recorder.delegate = self;
        
        // 允许监听录音分贝
        _recorder.meteringEnabled = YES;
    }
    return _recorder;
}

#pragma mark - <常规逻辑>

// 单例
static id _manager;

/**
 * 获取单例
 */
+ (nonnull __kindof WGVoiceManager *)manager {

    return [self allocWithZone:nil];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manager = [[super allocWithZone:zone] init];
    });
    return _manager;
}

/**
 * 定时器调用
 */
- (void)meteringRecorder {

    // 刷新录音接收分贝
    [self.recorder updateMeters];
    
    // 平均分贝
    float volume = [self.recorder averagePowerForChannel:0];
    
    if ([self.delegate respondsToSelector:@selector(manager:gotVolume:)]) {

        // 调用 代理方法1 监听录音音量改变
        [self.delegate manager:self gotVolume:volume];
    }
}

/**
 *  开始录音
 */
- (void)recordStart {
    
    // 准备录音
    if ([self.recorder prepareToRecord]) {
        
        // 设置声音处理方式为录音+听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        // 开始录音
        [self.recorder record];
        
        // 启动计时器
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

/**
 *  停止录音
 */
- (void)recordStop {
    
    // 停止录音
    [self.recorder stop];
    
    // 停止计时器
    [self displayStop];
}

/**
 *  取消录音
 */
- (void)recordCancel {
    
    // 停止并删除录音
    [self.recorder stop];
    [self.recorder deleteRecording];
    
    // 停止计时器
    [self displayStop];
}

/**
 * 停止计时器
 */
- (void)displayStop {
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

/**
 * 检查录音状态
 * 返回 是否正在录音
 */
- (BOOL)isRecording {

    return self.recorder.isRecording;
}

/**
 * 播放语音
 * 参数 base64String 要播放的声音文件的base64字符串
 */
- (void)playWithBase64String:(nonnull NSString *)base64String {

    // 过滤
    if (base64String.length == 0) return;
    
    // 获取播放声音文件数据
    NSData *fileData = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    // 创建播放声音文件
    if ([[NSFileManager defaultManager] createFileAtPath:kPlayFileURL.path contents:fileData attributes:nil]) {
        
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:kPlayFileURL error:nil];
        self.player.delegate = self;
        self.player.volume = 1.0;
        
        if ([self.player prepareToPlay]) {
        
            // 设置声音处理方式为喇叭播放
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            
            [self.player play];
        }
    }
}

/**
 * 检查播放状态
 * 返回 是否正在播放
 */
- (BOOL)isPlaying {

    return self.player.isPlaying;
}

#pragma mark - <AVAudioRecorderDelegdte>

/**
 * 监听录音完成
 * 参数 recorder 录音器
 * 返回 flag 成功与否
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    if (flag && [self.delegate respondsToSelector:@selector(manager:didRecordByBase64String:)] && [[NSFileManager defaultManager] fileExistsAtPath:kRecordFileURL.path]) {
        
        // 获取录音文件base64字符串
        NSString *base64Str = [[NSData dataWithContentsOfURL:kRecordFileURL] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        
        // 过滤
        if (base64Str.length == 0) return;
        
        // 调用 代理方法2 监听录音完成
        [self.delegate manager:self didRecordByBase64String:base64Str];
    }
}

#pragma mark - <AVAudioPlayerDelegdte>

/**
 * 监听播放完成
 * 参数 player 播放器
 * 返回 flag 成功与否
 */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    if (!flag) return;
    
    // 删除文件
    [[NSFileManager defaultManager] removeItemAtURL:kPlayFileURL error:nil];
    
    if ([self.delegate respondsToSelector:@selector(didPlayWithManager:)]) {
        
        // 调用 代理方法3 监听播放完成
        [self.delegate didPlayWithManager:self];
    }
}

@end
