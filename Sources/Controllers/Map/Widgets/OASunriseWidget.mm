//
//  OASunriseWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseWidget.h"
#import "OAMapLayers.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "SunriseSunset.h"

@implementation OASunriseWidget
{
    CLLocation *_location;
    BOOL _isTimeLeft;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _location = OsmAndApp.instance.locationServices.lastKnownLocation;
        _isTimeLeft = NO;
        
        __weak OASunriseWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        
        [self setText:@"-" subtext:@""];
        [self setIcons:@"widget_sunrise_day" widgetNightIcon:@"widget_sunrise_night"];
    }
    return self;
}

- (BOOL) updateInfo
{
    if (_isTimeLeft)
        [self timeLeftUntilSunriseCalculate];
    else
        [self nextSunriseCalculate];
    return YES;
}

- (void) onWidgetClicked
{
    if (!_isTimeLeft)
        _isTimeLeft = YES;
    else
        _isTimeLeft = NO;
    [self updateInfo];
}

- (void) nextSunriseCalculate
{
    NSDate *actualTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    SunriseSunset *sunriseSunset = [self createSunriseSunset:actualTime forNextDay:NO];
    SunriseSunset *nextSunriseSunset = [self createSunriseSunset:actualTime forNextDay:YES];
    
    NSDate *sunrise = [sunriseSunset getSunrise];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *time = [dateFormatter stringFromDate:sunrise];
    [dateFormatter setDateFormat:@"EE"];
    NSString *day = [dateFormatter stringFromDate:sunrise];
    
    NSDate *nextSunrise = [nextSunriseSunset getSunrise];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *nextTime = [dateFormatter stringFromDate:nextSunrise];
    [dateFormatter setDateFormat:@"EE"];
    NSString *nextDay = [dateFormatter stringFromDate:nextSunrise];
    
    if ([actualTime compare:sunrise] == NSOrderedDescending)
        [self setText:nextTime subtext:nextDay];
    else
        [self setText:time subtext:day];
}

- (void) timeLeftUntilSunriseCalculate
{
    NSDate *actualTime = [NSDate date];
    
    SunriseSunset *sunriseSunset = [self createSunriseSunset:actualTime forNextDay:NO];
    SunriseSunset *nextSunriseSunset = [self createSunriseSunset:actualTime forNextDay:YES];
    
    NSDate *sunrise = [sunriseSunset getSunrise];
    NSDate *nextSunrise = [nextSunriseSunset getSunrise];

    if ([actualTime compare:sunrise] == NSOrderedDescending)
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:nextSunrise options:0];
        [self setText:[NSString stringWithFormat:@"%ld:%ld", [components hour], [components minute]] subtext:[components hour] > 0 ? OALocalizedString(@"int_hour") : OALocalizedString(@"int_min")];
    }
    else
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:actualTime toDate:sunrise options:0];
        [self setText:[NSString stringWithFormat:@"%ld:%ld", [components hour], [components minute]] subtext:[components hour] > 0 ? OALocalizedString(@"int_hour") : OALocalizedString(@"int_min")];
    }
}

- (SunriseSunset *) createSunriseSunset:(NSDate *)date forNextDay:(BOOL)nextDay
{
    double longitude = _location.coordinate.longitude;
    SunriseSunset *sunriseSunset = [[SunriseSunset alloc] initWithLatitude:_location.coordinate.latitude longitude:longitude < 0 ? 360 + longitude : longitude dateInputIn:date tzIn:[NSTimeZone localTimeZone] forNextDay:nextDay];
    return sunriseSunset;
}

@end
