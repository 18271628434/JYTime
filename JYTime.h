//
//  NVTimeManagement.h
//  NewVoice
//
//  Created by NV on 2023/5/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JYTimeItemModel;

/** 进行中回调 只返回剩余时间*/
typedef void(^TimerChangeBlock)(NSInteger countdown);
/** 时间结束回调 identifier:定时器标识*/
typedef void(^TimerFinishBlock)(NSString *identifier);
/** 时间暂停回调 identifier:定时器标识*/
typedef void(^TimerPauseBlock)(NSString *identifier);


@interface JYTime : NSObject



/**获取定时器单例*/
+ (instancetype)sharedInstance;


/**
 *  添加计时任务 回调频率 1秒
 *
 *  返回NVTimeItemModel必须弱引用
 *  返回的NVTimeItemModel对象可以动态更改剩余的时间
 *
 *  @param time 时间长度
 *  @param identifier  计时任务标识
 *  @param handle 进行中Block
 *  @param finish 完成Block
 *  @param pause 暂停Block
 */
- (JYTimeItemModel *)addMinuteTimerForTime:(NSTimeInterval)time
                   identifier:(NSString *)identifier
                       handle:(TimerChangeBlock)handleBlock finish:(TimerFinishBlock)finishBlock pause:(TimerPauseBlock)pauseBlock;


#pragma mark - ***** 暂停计时任务 *****
/// 通过标识暂停计时任务
/// @param identifier 计时任务标识
- (BOOL)pauseTimerForIdentifier:(NSString *)identifier;
/// 暂停所有计时任务
- (void)pauseAllTimer;

#pragma mark - ***** 重启计时任务 *****
/// 通过标识重启 计时任务
/// @param identifier 计时任务标识
- (BOOL)restartTimerForIdentifier:(NSString *)identifier;
/// 重启所有计时任务
- (void)restartAllTimer;

#pragma mark - ***** 重置计时任务(恢复初始状态) *****
/// 通过标识重置 计时任务
/// @param identifier 计时任务标识
- (BOOL)resetTimerForIdentifier:(NSString *)identifier;
/// 重置所有计时任务
- (void)resetAllTimer;

#pragma mark - ***** 移除计时任务 *****
/// 通过标识移除计时任务
/// @param identifier 计时任务标识
- (BOOL)removeTimerForIdentifier:(NSString *)identifier;
/// 移除所有计时任务
- (void)removeAllTimer;

@end


@interface JYTimeItemModel : NSObject

/** 毫秒为单位计算 */
@property (nonatomic, assign) NSTimeInterval time;
/** 原始开始时间 毫秒 */
@property (nonatomic, assign) NSTimeInterval oriTime;
/** 中途更改时间 单位:秒*/
@property (nonatomic, assign) NSTimeInterval changeTime;
/** 进度单位 */
@property (nonatomic, assign) NSTimeInterval unit;
/** 是否暂停 */
@property (nonatomic,assign) BOOL isPause;
/** 标识 */
@property (nonatomic, copy) NSString *identifier;
/** 进行中回调Block */
@property (nonatomic, copy) TimerChangeBlock handleBlock;
/** 结束回调Block */
@property (nonatomic, copy) TimerFinishBlock finishBlock;
/** 暂停回调Block */
@property (nonatomic, copy) TimerPauseBlock pauseBlock;

@end

NS_ASSUME_NONNULL_END
