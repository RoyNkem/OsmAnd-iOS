//
//  OADeviceScreenTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADeviceScreenTableViewCell.h"

@implementation OADeviceScreenTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OADeviceScreenTableViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
