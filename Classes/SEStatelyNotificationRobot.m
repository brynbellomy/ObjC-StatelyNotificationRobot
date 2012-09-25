//
// SEStatelyNotificationRobot.m  
// SEStatelyNotificationRobot  
//
// Created by bryn austin bellomy on 7/8/12.  
// Copyright (c) 2012 robot bubble bath LLC. All rights reserved.  
//

#import <BrynKit/Bryn.h>
#import <ConciseKit/ConciseKit.h>
#import "SEStatelyNotificationRobot.h"
#import "SEStatelyNotificationHandler.h"
#import "SEStativeThing.h"


Key(SEStatelyNotificationKey_State);
Key(SEStatelyNotificationKey_StateInfo);


/**!
 * # Private interface
 */

@interface SEStatelyNotificationRobot ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *handlerIDsToHandlers;
@property (nonatomic, strong, readwrite) NSMutableDictionary *stativeThingNamesToStativeThings;

@end





/**!
 * # Implementation
 */

@implementation SEStatelyNotificationRobot

@synthesize handlerIDsToHandlers = _handlerIDsToHandlers;
@synthesize stativeThingNamesToStativeThings = _stativeThingNamesToStativeThings;


/**!
 * ## Class methods
 */

#pragma mark- Class methods
#pragma mark-

/**!
 * #### sharedRobot
 * 
 * @return {SEStatelyNotificationRobot*}
 */

+ (SEStatelyNotificationRobot *) sharedRobot {
  static SEStatelyNotificationRobot *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = $new(SEStatelyNotificationRobot);
  });
  return shared;
}



/**!
 * ## Lifecycle
 */

#pragma mark- Lifecycle
#pragma mark-

/**!
 * #### init
 * 
 * @return {id}
 */

- (id) init {
  self = [super init];
  if (self) {
    self.handlerIDsToHandlers = $mdictnew;
    self.stativeThingNamesToStativeThings = $mdictnew;
  }
  return self;
}



/**!
 * ## State tracking and changing
 */

#pragma mark- State tracking and changing
#pragma mark-

/**!
 * #### handleStateOf:handlerID:onQueue:withBlock:
 * 
 * @param {NSString*} stativeThingName
 * @param {NSString*} handlerID
 * @param {NSOperationQueue*} queue
 * @param {SEStateHandlerBlock} block
 * 
 * @return {void}
 */

- (void) handleStateOf: (NSString *)stativeThingName
             handlerID: (NSString *)handlerID
               onQueue: (NSOperationQueue *)queue
             withBlock: (SEStateHandlerBlock)block {
  
  NSAssert(stativeThingName != nil, @"stativeThingName argument is nil.");
  NSAssert(handlerID != nil, @"handlerID argument is nil.");
  NSAssert(queue != nil, @"queue argument is nil.");
  
  // add a regular block-based NSNotification observer
  
  id notificationHandle = 
    [NSNotificationCenter.defaultCenter addObserverForName: stativeThingName 
                                                    object: nil queue: queue
                                                usingBlock: ^(NSNotification *note) {
                                                    
                                                    NSNumber *numState = note.userInfo[SEStatelyNotificationKey_State];
                                                    NSAssert(numState != nil, @"numState is nil.");
                                                  
                                                    SEState state = numState.integerValue;
                                                  
                                                    NSDictionary *stateInfo = note.userInfo[SEStatelyNotificationKey_StateInfo];
                                                    NSAssert(stateInfo != nil, @"stateInfo is nil.");
                                                  
                                                    block(state, stateInfo);
                                                }];
  
  
  // record the handle and stativeThingName under the handlerID so the caller
  // doesn't have to worry about storing the handle or doing anything complicated
  // when removing the handler
  
  SEStatelyNotificationHandler *handler = $new(SEStatelyNotificationHandler);
  handler.handlerID = handlerID;
  handler.stativeThingName = stativeThingName;
  handler.notificationHandle = notificationHandle;
  
  NSAssert(handler != nil, @"SEStatelyNotificationHandler is nil.");
  self.handlerIDsToHandlers[handlerID] = handler;
  
  
  // add an SEStativeThing object for this stativeThingName if it doesn't already exist
  
  if (self.stativeThingNamesToStativeThings[stativeThingName] == nil) {
    SEStativeThing *newStativeThing = $new(SEStativeThing);
    newStativeThing.name = stativeThingName;
    newStativeThing.state = b(SEStateUndefined);
    newStativeThing.stateInfo = @{};
    
    NSAssert(newStativeThing != nil, @"SEStativeThing is nil.");
    self.stativeThingNamesToStativeThings[stativeThingName] = newStativeThing;
  }
  
  // call the state handler block for the newly-registered observer immediately so it can sync with the current state
  
  __bryn_weak SEStatelyNotificationRobot *weakSelf = self;
  [queue addOperationWithBlock: ^{
      __strong SEStatelyNotificationRobot *strongSelf = weakSelf;
      SEStativeThing *stativeThing = strongSelf.stativeThingNamesToStativeThings[stativeThingName];
      SEState state = (stativeThing.state != nil ? stativeThing.state.integerValue : SEStateUndefined);
      block(state, stativeThing.stateInfo);
  }];
}



/**!
 * #### changeStateOf:to:
 * 
 * @param {NSString*} stativeThingName
 * @param {SEState} newState
 * 
 * @return {void}
 */

- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState {
  [self changeStateOf:stativeThingName to:newState stateInfo:nil];
}



/**!
 * #### changeStateOf:to:stateInfo:
 * 
 * @param {NSString*} stativeThingName
 * @param {SEState} newState
 * @param {NSDictionary*} stateInfo
 * 
 * @return {void}
 */

- (void) changeStateOf:(NSString *)stativeThingName to:(SEState)newState stateInfo:(NSDictionary *)stateInfo {
  NSAssert(stativeThingName != nil, @"stativeThingName argument is nil.");

  // update the SEStativeThing object we have on file
  SEStativeThing *stativeThing = self.stativeThingNamesToStativeThings[stativeThingName];
  
  if (stativeThing == nil) {
    stativeThing = $new(SEStativeThing);
    stativeThing.name = stativeThingName;
    
    NSAssert(stativeThing != nil, @"SEStativeThing object is nil.");
    self.stativeThingNamesToStativeThings[stativeThingName] = stativeThing;
  }
  
  if (stateInfo == nil) {
    stateInfo = @{};
  }
  
  stativeThing.state = b(newState);
  stativeThing.stateInfo = stateInfo;
  
    

  // trigger all of our handlers' blocks that we've registered with NSNotificationCenter.defaultCenter
  [NSNotificationCenter.defaultCenter postNotificationName: stativeThing.name
                                                    object: nil
                                                  userInfo: @{ SEStatelyNotificationKey_State : stativeThing.state,
                                                               SEStatelyNotificationKey_StateInfo : stativeThing.stateInfo }];
}



/**!
 * ## Stop tracking state
 */

#pragma mark- Stop tracking state
#pragma mark-

/**!
 * #### removeHandlerWithID:
 * 
 * @param {NSString*} handlerID
 * 
 * @return {void}
 */

- (void) removeHandlerWithID:(NSString *)handlerID {
  NSAssert(handlerID != nil, @"handlerID argument is nil.");
  
  // remove the handler from the identifiers-to-handles dictionary.  when the
  // handler deallocs, it will remove its observer from the default NSNotificationCenter.
  
  [self.handlerIDsToHandlers removeObjectForKey:handlerID];
}



/**!
 * #### stopTrackingStateOf:
 * 
 * @param {NSString*} stativeThingName
 * 
 * @return {void}
 */

- (void) stopTrackingStateOf: (NSString *)stativeThingName {
  NSAssert(stativeThingName != nil, @"stativeThingName argument is nil.");
  
  [self.stativeThingNamesToStativeThings removeObjectForKey: stativeThingName];
  
  
  NSMutableArray *handlerIDsToRemove = $marrnew;
  for (NSString *handlerID in self.handlerIDsToHandlers) {
    SEStatelyNotificationHandler *handler = self.handlerIDsToHandlers[handlerID];
    
    if ([stativeThingName isEqualToString:handler.stativeThingName]) {
      [handlerIDsToRemove addObject:handlerID];
    }
  }
  
  // this should dealloc all of the handler objects, which will cause each of those
  // objects to unregister with NSNotificationCenter.defaultCenter
  
  [self.handlerIDsToHandlers removeObjectsForKeys:handlerIDsToRemove];
}



/**!
 * #### stopTrackingAllStates
 * 
 * @return {void}
 */

- (void) stopTrackingAllStates {
  [self.stativeThingNamesToStativeThings removeAllObjects];
  [self.handlerIDsToHandlers removeAllObjects];
}



/**!
 * ## Public accessors for SEStativeThing objects
 */

#pragma mark- Public accessors for SEStativeThing objects
#pragma mark-

/**!
 * #### stateOf:
 * 
 * @param {NSString*} stativeThingName
 * 
 * @return {SEState}
 */

- (SEState) stateOf:(NSString *)stativeThingName {
  NSAssert(stativeThingName != nil, @"stativeThingName argument is nil.");
  
  SEStativeThing *stativeThing = self.stativeThingNamesToStativeThings[stativeThingName];
  if (stativeThing == nil)
    return SEStateUndefined;
  else
    return stativeThing.state.integerValue;
}



/**!
 * #### stateInfoForStateOf:
 * 
 * @param {NSString*} stativeThingName
 * 
 * @return {NSDictionary*}
 */

- (NSDictionary *) stateInfoForStateOf:(NSString *)stativeThingName {
  NSAssert(stativeThingName != nil, @"stativeThingName argument is nil.");
  
  SEStativeThing *stativeThing = self.stativeThingNamesToStativeThings[stativeThingName];
  return stativeThing.stateInfo;
}




@end





