//
//  OASunriseSunsetWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
#import "OAAppSettings.h"
#import "OASunriseSunsetWidgetState.h"

@interface OASunriseSunsetWidget : OATextInfoWidget

- (instancetype) initWithState:(OASunriseSunsetWidgetState *)state;
+ (NSString *) getTitle:(EOASunriseSunsetMode)ssm isSunrise:(BOOL)isSunrise;
+ (NSString *) getDescription:(EOASunriseSunsetMode)ssm isSunrise:(BOOL)isSunrise;
- (OACommonInteger *) getPreference;

@end
