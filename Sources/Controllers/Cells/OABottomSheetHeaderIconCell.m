//
//  OABottomSheetHeaderIconCell.m
//  OsmAnd
//
//  Created by Paul on 29/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetHeaderIconCell.h"

@implementation OABottomSheetHeaderIconCell

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
