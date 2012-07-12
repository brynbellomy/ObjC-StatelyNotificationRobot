//
//  SEStatelyNotificationRobot.h
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SEStatelyNotificationRobotBlock)(NSInteger notificationState);

@interface SEStatelyNotificationRobot : NSObject

+ (SEStatelyNotificationRobot *) sharedInstance;

- (void) respondToState:(NSString *)notificationName withIdentifier:(NSString *)identifier onQueue:(NSOperationQueue *)queue withBlock:(SEStatelyNotificationRobotBlock)block;
- (void) removeObserverWithIdentifier: (NSString *)identifier;
- (void) postNotificationWithoutSettingState: (NSString *)notificationName;
- (void) postNotification: (NSString *)notificationName withState: (NSInteger)notificationState;

@end
