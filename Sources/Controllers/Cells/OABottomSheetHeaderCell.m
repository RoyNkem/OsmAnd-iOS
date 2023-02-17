//
//  OAWaypointHeader.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetHeaderCell.h"

@implementation OABottomSheetHeaderCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.titleView.font = [UIFont scaledSystemFontOfSize:18. weight:UIFontWeightMedium];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
