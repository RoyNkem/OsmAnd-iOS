//
//  OADefaultFavorite.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaultFavoriteZoom 15.0f
#define kDefaultFavoriteZoomOnShow 16.0f

#define kFavoriteDefaultColorKey @"FavoriteDefaultColorKey"
#define kFavoriteDefaultGroupKey @"FavoriteDefaultGroupKey"

#define kWptDefaultColorKey @"WptDefaultColorKey"
#define kWptDefaultGroupKey @"WptDefaultGroupKey"

@interface OAFavoriteColor : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) UIColor *color;
@property (nonatomic) UIImage *icon;
@property (nonatomic) UIImage *cellIcon;
@property (nonatomic) NSString *iconName;

-(instancetype)initWithName:(NSString *)name color:(UIColor *)color iconName:(NSString *)iconName;

@end

@interface OADefaultFavorite : NSObject

+ (OAFavoriteColor *)nearestFavColor:(UIColor *)sourceColor;

+ (NSArray *)builtinColors;

@end
