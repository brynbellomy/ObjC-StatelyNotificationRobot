//
//  SEStatelyNotificationHandler.h
//  SEStatelyNotificationRobot
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//


@interface SEStatelyNotificationHandler : NSObject

@property (nonatomic, strong, readwrite) NSString *handlerID;
@property (nonatomic, strong, readwrite) NSString *stativeThingName;
@property (nonatomic, strong, readwrite) id notificationHandle;

@end



