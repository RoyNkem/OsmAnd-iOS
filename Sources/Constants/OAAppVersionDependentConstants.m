//
//  OAAppVersionDependentConstants.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAppVersionDependentConstants.h"

@implementation OAAppVersionDependentConstants

+ (NSString *) getShortAppVersionWithSeparator:(NSString *)separator
{
    NSString *fullVersion = self.getVersion;
    NSArray *subversions = [fullVersion componentsSeparatedByString:@"."];
    
    if (subversions && subversions.count > 1)
    {
        return [NSString stringWithFormat:@"%@%@%@", subversions[0], separator, subversions[1]];
    }
    return fullVersion;
}

+ (NSString *) getVersion
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return version;
}

//4_2
+ (NSString *) getShortAppVersion
{
    return [self getShortAppVersionWithSeparator:@"_"];
}

+ (NSString *)getAppVersionWithBundle
{
    NSString *appVersion = self.getVersion;
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"OsmAnd Maps %@ (%@)", appVersion, bundleVersion];
}

+ (NSString *) getAppVersionForUrl
{
    return [[NSString stringWithFormat:@"OsmAndIOS_%@", self.getVersion] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
