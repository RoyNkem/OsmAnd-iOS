//
//  OACloudBackupViewController.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseCloudBackupViewController.h"

typedef NS_ENUM(NSInteger, EOACloudScreenSourceType) {
    EOACloudScreenSourceTypeSignIn = 0,
    EOACloudScreenSourceTypeSignUp,
    EOACloudScreenSourceTypeDirect
};

@interface OACloudBackupViewController : OABaseCloudBackupViewController

- (instancetype) initWithSourceType:(EOACloudScreenSourceType)type;

@end

