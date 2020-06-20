//
//  OAViewsCollectionViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAViewsCollectionViewCell.h"

@implementation OAViewsCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconView.layer.cornerRadius = 6;
    self.backView.layer.cornerRadius = 9;
}

@end
