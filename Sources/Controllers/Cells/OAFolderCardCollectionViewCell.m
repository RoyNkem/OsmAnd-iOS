//
//  OAFolderCardCollectionViewCell.m
//  OsmAnd
//
//  Created by nnngrach on 08.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFolderCardCollectionViewCell.h"

@implementation OAFolderCardCollectionViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

@end
