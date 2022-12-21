//
//  OARoutingHelperUtils.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <routingConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

struct RoutingParameter;

@interface OARoutingHelperUtils : NSObject

+ (NSString *) formatStreetName:(NSString *)name
                            ref:(NSString *)ref
                    destination:(NSString *)destination
                        towards:(NSString *)towards;

+ (RoutingParameter)getParameterForDerivedProfile:(NSString *)key appMode:(OAApplicationMode *)appMode router:(std::shared_ptr<GeneralRouter>)router;

@end

NS_ASSUME_NONNULL_END
