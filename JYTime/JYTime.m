//
//  NVTimeManagement.m
//  NewVoice
//
//  Created by NV on 2023/5/11.
//

#import "JYTime.h"

@implementation JYTimeItemModel

///初始化 时间默认设为毫秒 保证精准
+ (instancetype)timeInterval:(NSInteger)timeInterval {
    JYTimeItemModel *object = [JYTimeItemModel new];
    object.time = timeInterval * 1000;
    object.oriTime = timeInterval * 1000;
    return object;
}

///中途更改时间 单位:秒
- (void)setChangeTime:(NSTimeInterval)changeTime{
    
    _changeTime = changeTime;
    
    _time = changeTime * 1000;
    
}

@end

@interface JYTime ()

/** 定时器 */
@property (nonatomic,weak) NSTimer *timer;

/** 储存多个计时器数据源 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, JYTimeItemModel *> *timerData;


@end

@implementation JYTime

/**获取网络请求单例*/
+ (instancetype)sharedInstance{
    
    static JYTime *timeManagement = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        timeManagement = [[JYTime alloc] init];
        
    });
    
    return timeManagement;
}

/**
 *  添加计时任务 回调频率 1秒
 *
 *  @param time 时间长度
 *  @param identifier  计时任务标识
 *  @param handle 进行中Block
 *  @param finish 完成Block
 *  @param pause 暂停Block
 */
- (JYTimeItemModel *)addMinuteTimerForTime:(NSTimeInterval)time
                              identifier:(NSString *)identifier
                                  handle:(TimerChangeBlock)handleBlock finish:(TimerFinishBlock)finishBlock pause:(TimerPauseBlock)pauseBlock{
    //初始化定时任务
    return [self startTimerForForTime:time identifier:identifier unit:1000 handle:handleBlock finish:finishBlock pause:pauseBlock];
    
}


/**
 *  总初始化定时任务入口
 *
 *  @param time 时间长度
 *  @param identifier  计时任务标识
 *  @param unit  进度单位
 *  @param handle 进行中Block
 *  @param finish 完成Block
 *  @param pause 暂停Block
 */
- (JYTimeItemModel *)startTimerForForTime:(NSTimeInterval)time
                 identifier:(NSString *)identifier
                       unit:(NSTimeInterval)unit
                     handle:(TimerChangeBlock)handleBlock finish:(TimerFinishBlock)finishBlock pause:(TimerPauseBlock)pauseBlock{
    
    if (!identifier.length) {
        NSLog(@"无效定时任务,标识为空");
        return nil;
    }
    
    //添加定时任务新任务
    JYTimeItemModel *timeItemModel = [JYTimeItemModel timeInterval:time];
    timeItemModel.identifier = identifier;
    timeItemModel.unit = unit;
    timeItemModel.handleBlock = handleBlock;
    timeItemModel.finishBlock = finishBlock;
    timeItemModel.pauseBlock = pauseBlock;
    [self.timerData setObject:timeItemModel forKey:identifier];
    
    NSLog(@"定时管理器:当前定时任务 %ld 个",self.timerData.count);
    
    if (timeItemModel.handleBlock) {
        
        NSInteger totalSeconds = timeItemModel.time/1000.0;
        
        timeItemModel.handleBlock(totalSeconds);
        
    }
    
    [self initTimer];
    
    return timeItemModel;
}

/** 创建定定时器 */
- (void)initTimer{
    
    if (self.timer) {
        //定时器已存在
        return;
    }
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(timerChange) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
    
}

/** 时间差处理 */
- (void)timerChange{
    
    __weak typeof(self)weakSelf = self;
    
    [self.timerData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, JYTimeItemModel * _Nonnull obj, BOOL * _Nonnull stop) {
        
        if (!obj.isPause) {
         
            obj.time = obj.time - 100.0;
            
            if (obj.unit > -1) {
                obj.unit = obj.unit-100.0;
//                NSLog(@"%f",obj.unit);
            }
            
            if (obj.time < 0) {//计时结束
                obj.time = 0;
                obj.isPause = YES;
            }
            
            if (obj.unit <= 0) {
                
                NSInteger totalSeconds = obj.time/1000.0;
                
                if (obj.handleBlock) {
                    obj.handleBlock(totalSeconds);
                }
                
                obj.unit = 1000;
            }
            
           
            
            if (obj.time <= 0) {//计时器计时完毕自动移除计时任务
                if (obj.finishBlock) {
                    obj.finishBlock(obj.identifier);
                }
   
                [weakSelf.timerData removeObjectForKey:obj.identifier];
                
                NSLog(@"定时管理器:当前剩余定时任务 %ld 个",weakSelf.timerData.count);
                
                if (!weakSelf.timerData.count) {
                    //停止定时器
                    [weakSelf removeAllTimer];
                }
            }
        }
        
    }];
    
}


#pragma mark - ***** 暂停计时任务 *****
/// 通过标识暂停计时任务
/// @param identifier 计时任务标识
- (BOOL)pauseTimerForIdentifier:(NSString *)identifier{
    
    if (!identifier.length) {
        NSLog(@"定时管理器:计时器标识不能为空");
        return NO;
    }
    
    JYTimeItemModel *timeItemModel = self.timerData[identifier];
    
    if (timeItemModel) {
       
        timeItemModel.isPause = YES;
        
        if (timeItemModel.pauseBlock) {
            timeItemModel.pauseBlock(timeItemModel.identifier);
        }
        return YES;
    }else {
        NSLog(@"定时管理器:找不到计时器任务");
        return NO;
    }
    
}
/// 暂停所有计时任务
- (void)pauseAllTimer{
    
    if (!self.timerData.count) {
        return;
    }
   
    [self.timerData enumerateKeysAndObjectsUsingBlock:^(NSString *key, JYTimeItemModel *obj, BOOL *stop) {
        
        obj.isPause = YES;
        
        if (obj.pauseBlock) {
            obj.pauseBlock(obj.identifier);
        }
    }];
    
}

#pragma mark - ***** 重启计时任务 *****
/// 通过标识重启 计时任务
/// @param identifier 计时任务标识
- (BOOL)restartTimerForIdentifier:(NSString *)identifier{
    
    if (!identifier.length) {
        NSLog(@"定时管理器:计时器标识不能为空");
        return NO;
    }
    
    JYTimeItemModel *timeItemModel = self.timerData[identifier];
    
    if (timeItemModel) {
        
        timeItemModel.isPause = NO;
        return YES;
        
    }else {
        NSLog(@"定时管理器:找不到计时器任务");
        return NO;
    }
    
}
/// 重启所有计时任务
- (void)restartAllTimer{
    
    if (!self.timerData.count) {
        return;
    }
    
    [self.timerData enumerateKeysAndObjectsUsingBlock:^(NSString *key, JYTimeItemModel *obj, BOOL *stop) {
        
        obj.isPause = NO;
    
    }];
}

#pragma mark - ***** 重置计时任务(恢复初始状态) *****
/// 通过标识重置 计时任务
/// @param identifier 计时任务标识
- (BOOL)resetTimerForIdentifier:(NSString *)identifier{
    
    if (!identifier.length) {
        NSLog(@"定时管理器:计时器标识不能为空");
        return NO;
    }
    
    JYTimeItemModel *timeItemModel = self.timerData[identifier];
    
    if (timeItemModel) {
        
        timeItemModel.isPause = NO;
        timeItemModel.time = timeItemModel.oriTime;
        
        if (timeItemModel.handleBlock) {
            NSInteger totalSeconds = timeItemModel.time/1000.0;
            timeItemModel.handleBlock(totalSeconds);
        }
        
        return YES;
        
    }else {
        NSLog(@"定时管理器:定时任务停止");
        return NO;
    }
}
/// 重置所有计时任务
- (void)resetAllTimer{
    
    if (!self.timerData.count) {
        return;
    }
    
    [self.timerData enumerateKeysAndObjectsUsingBlock:^(NSString *key, JYTimeItemModel *obj, BOOL *stop) {
        
        obj.isPause = NO;
        obj.time = obj.oriTime;
        
        if (obj.handleBlock) {
            NSInteger totalSeconds = obj.time/1000.0;
            obj.handleBlock(totalSeconds);
        }
    
    }];
}

#pragma mark - ***** 移除计时任务 *****
/// 通过标识移除计时任务
/// @param identifier 计时任务标识
- (BOOL)removeTimerForIdentifier:(NSString *)identifier{
    
    if (!identifier.length) {
        NSLog(@"定时管理器:计时器标识不能为空");
        return NO;
    }
    
    [self.timerData removeObjectForKey:identifier];
    
    NSLog(@"定时管理器:当前剩余定时任务 %ld 个",self.timerData.count);
    
    if (!self.timerData.count) {//如果没有计时任务了 就销毁计时器
        [self.timer invalidate];
        self.timer = nil;
        NSLog(@"定时管理器:定时任务停止");
    }
    
    return YES;
    
}
/// 移除所有计时任务
- (void)removeAllTimer{
    
    [self.timerData removeAllObjects];
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"定时管理器:定时任务停止");
}


/** 懒加载 */
- (NSMutableDictionary<NSString *,JYTimeItemModel *> *)timerData{
    
    if (!_timerData) {
        _timerData = [NSMutableDictionary dictionary];
    }
    return _timerData;
}

@end


