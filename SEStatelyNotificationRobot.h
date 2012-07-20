//
//  SEStatelyNotificationRobot.h
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// except for SEStateUndefined, these are just for users' convenience -- feel
// free to ignore/extend/redefine.
typedef enum {
  SEStateUnstarted = (1 << 1),
  SEStateInProgress = (1 << 2),
  SEStateFinished = (1 << 3),
  SEStateNotActive = (1 << 4),
  SEStateUndefined = INT_MAX
} SEState;

typedef void (^SEStateHandlerBlock)(SEState newState, NSDictionary *stateInfo);



@interface SEStatelyNotificationRobot : NSObject

/* class methods */
+ (SEStatelyNotificationRobot *) sharedRobot;


/* instance methods */
+ (SEStatelyNotificationRobot *) sharedRobot;
- (void) handleStateOf:(NSString *)stativeThingName handlerID:(NSString *)identifier onQueue:(NSOperationQueue *)queue withBlock:(SEStateHandlerBlock)block;
- (void) removeHandlerWithID:(NSString *)handlerID;
- (void) stopTrackingStateOf: (NSString *)stativeThingName;

- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState;
- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState stateInfo:(NSDictionary *)stateInfo;

- (SEState) stateOf:(NSString *)stativeThingName;
- (NSDictionary *) stateInfoForStateOf:(NSString *)stativeThingName;


@end



