//
//  SEStativeThing.h
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//


@interface SEStativeThing : NSObject

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSNumber *state;
@property (nonatomic, strong, readwrite) NSDictionary *stateInfo;

@end
