//
//  OATableViewCustomHeaderView.h
//  OsmAnd
//
//  Created by Paul on 7/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OATableViewCustomHeaderView : UITableViewHeaderFooterView

@property (nonatomic, readonly) UITextView *label;

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width;

@end

