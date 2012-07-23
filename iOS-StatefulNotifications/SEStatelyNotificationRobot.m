//
//  SEStatelyNotificationRobot.m
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "SEStatelyNotificationRobot.h"
#import "SEStatelyNotificationHandler.h"
#import "SEStativeThing.h"


static NSString *const SEStatelyNotificationKey_State = @"SEStatelyNotificationKey_State";
static NSString *const SEStatelyNotificationKey_StateInfo = @"SEStatelyNotificationKey_StateInfo";



/**
 * private interface
 */

@interface SEStatelyNotificationRobot ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *handlerIDsToHandlers;
@property (nonatomic, strong, readwrite) NSMutableDictionary *stativeThingNamesToStativeThings;

@end





/**
 * implementation
 */

@implementation SEStatelyNotificationRobot

@synthesize handlerIDsToHandlers = _handlerIDsToHandlers;
@synthesize stativeThingNamesToStativeThings = _stativeThingNamesToStativeThings;


#pragma mark- Class methods
#pragma mark-

+ (SEStatelyNotificationRobot *) sharedRobot {
  static SEStatelyNotificationRobot *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[SEStatelyNotificationRobot alloc] init];
  });
  return shared;
}



#pragma mark- Lifecycle
#pragma mark-

- (id) init {
  self = [super init];
  if (self) {
    self.handlerIDsToHandlers = [NSMutableDictionary dictionary];
    self.stativeThingNamesToStativeThings = [NSMutableDictionary dictionary];
  }
  return self;
}



#pragma mark- State tracking and changing
#pragma mark-

- (void) handleStateOf: (NSString *)stativeThingName
             handlerID: (NSString *)handlerID
               onQueue: (NSOperationQueue *)queue
             withBlock: (SEStateHandlerBlock)block {

  // add a regular block-based NSNotification observer
  
  id notificationHandle = 
    [[NSNotificationCenter defaultCenter] addObserverForName: stativeThingName 
                                                      object: nil queue: queue
                                                  usingBlock: ^(NSNotification *note) {
                                                    
                                                      NSNumber *numState = [note.userInfo objectForKey: SEStatelyNotificationKey_State];
                                                      SEState state = (numState != nil ? numState.integerValue : SEStateUndefined);
                                                      NSDictionary *stateInfo = [note.userInfo objectForKey: SEStatelyNotificationKey_StateInfo];
                                                    
                                                      block(state, stateInfo);
                                                  }];
  
  
  // record the handle and stativeThingName under the handlerID so the caller
  // doesn't have to worry about storing the handle or doing anything complicated
  // when removing the handler
  
  SEStatelyNotificationHandler *handler = [[SEStatelyNotificationHandler alloc] init];
  handler.handlerID = handlerID;
  handler.stativeThingName = stativeThingName;
  handler.notificationHandle = notificationHandle;
  
  [self.handlerIDsToHandlers setObject:handler forKey:handlerID];
  
  
  // add a SEStativeThing object for this stativeThingName if it doesn't already exist
  
  if ([self.stativeThingNamesToStativeThings objectForKey:stativeThingName] == nil) {
    SEStativeThing *newStativeThing = [[SEStativeThing alloc] init];
    newStativeThing.name = stativeThingName;
    newStativeThing.state = [NSNumber numberWithInteger:SEStateUndefined];
    newStativeThing.stateInfo = [NSDictionary dictionary];
    [self.stativeThingNamesToStativeThings setObject:newStativeThing forKey:stativeThingName];
  }
  
  // call the state handler block for the newly-registered observer immediately so it can sync with the current state
  
  __weak SEStatelyNotificationRobot *weakSelf = self;
  [queue addOperationWithBlock: ^{
      __strong SEStatelyNotificationRobot *strongSelf = weakSelf;
      SEStativeThing *stativeThing = [strongSelf.stativeThingNamesToStativeThings objectForKey:stativeThingName];
      SEState state = (stativeThing.state != nil ? stativeThing.state.integerValue : SEStateUndefined);
      block(state, stativeThing.stateInfo);
  }];
}



- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState {
  [self changeStateOf:stativeThingName to:newState stateInfo:nil];
}



- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState stateInfo:(NSDictionary *)stateInfo {
  NSAssert(stativeThingName != nil, @"stativeThingName == nil");

  // update the SEStativeThing object we have on file
  SEStativeThing *stativeThing = [self.stativeThingNamesToStativeThings objectForKey:stativeThingName];
  
  if (stativeThing == nil) {
    stativeThing = [[SEStativeThing alloc] init];
    stativeThing.name = stativeThingName;
    
    [self.stativeThingNamesToStativeThings setObject:stativeThing forKey:stativeThingName];
  }
  
  if (stateInfo == nil) {
    stateInfo = [NSDictionary dictionary];
  }
  
  stativeThing.state = [NSNumber numberWithInteger:newState];
  stativeThing.stateInfo = stateInfo;
  
    

  // trigger all of our handlers' blocks that we've registered with [NSNotificationCenter defaultCenter]
  
  id keys[2], objects[2];
  keys[0] = SEStatelyNotificationKey_State;     objects[0] = stativeThing.state;
  keys[1] = SEStatelyNotificationKey_StateInfo; objects[1] = stativeThing.stateInfo;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: stativeThing.name
                                                      object: nil
                                                    userInfo: [NSDictionary dictionaryWithObjects:objects forKeys:keys count:2]];
}



#pragma mark- Stop tracking state
#pragma mark-

- (void) removeHandlerWithID:(NSString *)handlerID {
  
  // remove the handler from the identifiers-to-handles dictionary.  when the
  // handler deallocs, it will remove its observer from the default NSNotificationCenter.
  
  [self.handlerIDsToHandlers removeObjectForKey:handlerID];
}



- (void) stopTrackingStateOf: (NSString *)stativeThingName {
  if (stativeThingName == nil)
    return;
  
  [self.stativeThingNamesToStativeThings removeObjectForKey: stativeThingName];
  
  
  NSMutableArray *handlerIDsToRemove = [NSMutableArray array];
  for (NSString *handlerID in self.handlerIDsToHandlers) {
    SEStatelyNotificationHandler *handler = [self.handlerIDsToHandlers objectForKey:handlerID];
    
    if ([stativeThingName isEqualToString:handler.stativeThingName]) {
      [handlerIDsToRemove addObject:handlerID];
    }
  }
  
  // this should dealloc all of the handler objects, which will cause each of those
  // objects to unregister with [NSNotificationCenter defaultCenter]
  
  [self.handlerIDsToHandlers removeObjectsForKeys:handlerIDsToRemove];
}



- (void) stopTrackingAllStates {
  [self.stativeThingNamesToStativeThings removeAllObjects];
  [self.handlerIDsToHandlers removeAllObjects];
}



#pragma mark- Public accessors for SEStativeThing objects
#pragma mark-

- (SEState) stateOf:(NSString *)stativeThingName {
  SEStativeThing *stativeThing = [self.stativeThingNamesToStativeThings objectForKey:stativeThingName];
  if (stativeThing == nil)
    return SEStateUndefined;
  else
    return stativeThing.state.integerValue;
}



- (NSDictionary *) stateInfoForStateOf:(NSString *)stativeThingName {
  SEStativeThing *stativeThing = [self.stativeThingNamesToStativeThings objectForKey:stativeThingName];
  return stativeThing.stateInfo;
}




@end




