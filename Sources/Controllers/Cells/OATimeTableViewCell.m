//
//  OATimeTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATimeTableViewCell.h"
#import "OAColors.h"

#define leftTextMargin 62.0

@implementation OATimeTableViewCell
{
    UIView *_separator;
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    _imageLeftConstrraint.constant = 0.;
    _imageWidthConstraint.constant = 0.;
    _lbTime.textAlignment = [self.contentView isDirectionRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)showLeftImageView:(BOOL)show
{
    _leftImageView.hidden = !show;
    _imageWidthConstraint.constant = show ? 30. : 0.;
    _imageLeftConstrraint.constant = show ? 16. : 0.;
    [self setNeedsLayout];
}

@end
