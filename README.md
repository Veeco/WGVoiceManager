# WGVoiceManager
iOS录音+播放处理


最近公司集成了一个语音聊天功能, 就是简单的录音发送和接收播放功能, 这里对声音处理的部分封装了一下, 分享给大家.

###1. 准备
由于工具类是单例设计, 大家集成工具类后直接用类方法获取工具类对象, 并设置对象的代理属性即可.
```objc
/**
 * 获取单例
 */
+ (nonnull __kindof WGVoiceManager *)manager;

/** 代理 */
@property (nonatomic, weak, nullable) id<WGVoiceManagerDelegate> delegate;
```

###2. 录音
工具类提供了4个关于录音最基本的方法.
```objc
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
 * 检查录音状态
 * 返回 是否正在录音
 */
- (BOOL)isRecording;
```

###3. 播放
工具类提供了2个关于播放最基本的方法.
```objc
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
```

###4. 监听
另外还提供了3个代理方法, 分别用来监听录音音量变化, 录音完成和播放完成.
```objc
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
```

另外如有其它属性需要设置(比如录音的比特率等等)的可以进 .m 文件内进行设置.

####时间有点仓促写得比较简单希望大家多多见谅, 如有意见或其它想法可以多多提出, 谢谢!
