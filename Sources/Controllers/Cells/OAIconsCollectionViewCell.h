//
//  OAIconsCollectionViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCollectionCell.h"

@interface OAIconsCollectionViewCell : OABaseCollectionCell

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconView;

@end
