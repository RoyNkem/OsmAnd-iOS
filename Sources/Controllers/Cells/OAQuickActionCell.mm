//
//  OAQuickActionCell.m
//  OsmAnd
//
//  Created by Paul on 03/08/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionCell.h"
#import "OAUtilities.h"

@implementation OAQuickActionCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    self.layer.cornerRadius = 9.0;
    self.actionTitleView.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

@end
