//
//  SEStatelyNotificationRobot.m
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "SEStatelyNotificationRobot.h"

@interface SEStatelyNotificationRobot ()
  @property (nonatomic, strong, readwrite) NSMutableDictionary *notificationStates;
  @property (nonatomic, strong, readwrite) NSMutableDictionary *identifiersToNSNotificationHandles;
@end



@implementation SEStatelyNotificationRobot

@synthesize notificationStates = _notificationStates;
@synthesize identifiersToNSNotificationHandles = _identifiersToNSNotificationHandles;



+ (SEStatelyNotificationRobot *) sharedInstance {
  static SEStatelyNotificationRobot *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[SEStatelyNotificationRobot alloc] init];
  });
  return shared;
}



- (id) init {
  self = [super init];
  if (self) {
    self.notificationStates = [NSMutableDictionary dictionary];
    self.identifiersToNSNotificationHandles = [NSMutableDictionary dictionary];
  }
  return self;
}



- (void) respondToState: (NSString *)notificationName
         withIdentifier: (NSString *)identifier
                onQueue: (NSOperationQueue *)queue
              withBlock: (SEStatelyNotificationRobotBlock)block {
  
  // add a regular block-based NSNotification observer
  
  id handle = 
    [[NSNotificationCenter defaultCenter] addObserverForName: notificationName 
                                                      object: nil queue: queue
                                                  usingBlock: ^(NSNotification *note) {
                                                      NSNumber *numState = [note.userInfo objectForKey: @"notificationState"];
                                                      NSInteger state = numState.integerValue;
                                                      block(state);
                                                  }];
  
  
  // record the handle under the identifier so the caller doesn't have to mess with it
  
  [self.identifiersToNSNotificationHandles setObject:handle forKey:identifier];
  
  
  // call the state handler block for the newly-registered observer immediately so it can sync with the current state
  
  __weak SEStatelyNotificationRobot *weakSelf = self;
  [queue addOperationWithBlock: ^{
      __strong SEStatelyNotificationRobot *strongSelf = weakSelf;
      NSNumber *numState = [strongSelf.notificationStates objectForKey:notificationName];
      NSInteger state = numState.integerValue;
      block(state);
  }];
}



- (void) removeObserverWithIdentifier:(NSString *)identifier {
  
  // remove the observer we added to the default NSNotificationCenter
  
  id handle = [self.identifiersToNSNotificationHandles objectForKey:identifier];
  if (handle != nil)
    [[NSNotificationCenter defaultCenter] removeObserver:handle];
  
  
  // remove the handle from the identifiers-to-handles dictionary
  
  [self.identifiersToNSNotificationHandles removeObjectForKey:identifier];
}



- (NSDictionary *)makeUserInfoDictionaryForNotification:(NSString *)notificationName {
  NSNumber *notificationState = [self.notificationStates objectForKey:notificationName];
  return [NSDictionary dictionaryWithObject:notificationState forKey:@"notificationState"];
}



- (void) postNotificationToAllRegisteredBlocks:(NSString *)notificationName {
  [[NSNotificationCenter defaultCenter] postNotificationName: notificationName
                                                      object: nil
                                                    userInfo: [self makeUserInfoDictionaryForNotification:notificationName]];
}



- (void) postNotificationWithoutSettingState:(NSString *)notificationName {
  [self postNotificationToAllRegisteredBlocks:notificationName];
}



- (void) postNotification:(NSString *)notificationName withState:(NSInteger)notificationState {
  
  // set the new notification state
  
  NSNumber *numNotificationState = [NSNumber numberWithInteger:notificationState];
  [self.notificationStates setObject:numNotificationState forKey:notificationName];
  
  
  // trigger all observer blocks
  
  [self postNotificationToAllRegisteredBlocks:notificationName];
}





@end




