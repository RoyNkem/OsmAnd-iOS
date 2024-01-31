//
//  OAImageTextViewCell.m
//  OsmAnd
//
//  Created by igor on 24.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImageTextViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAImageTextViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    _descView.textContainerInset = UIEdgeInsetsZero;
    _descView.textContainer.lineFragmentPadding = 0;
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorActive],
                                     NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]};
    _descView.linkTextAttributes = linkAttributes;

    _extraDescView.textContainerInset = UIEdgeInsetsZero;
    _extraDescView.textContainer.lineFragmentPadding = 0;

    if ([self isDirectionRTL])
    {
        self.descView.textAlignment = NSTextAlignmentRight;
        self.extraDescView.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
    CGFloat newIconHeight = (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;
    BOOL hasExtraDesc = !self.extraDescView.hidden;
    BOOL hasDesc = !self.descView.hidden;

    self.iconViewHeight.constant = newIconHeight;
    self.extraDescLeadingConstraint.active = !hasDesc;
    self.descExtraTrailingConstraint.active = hasExtraDesc;
    self.descNoExtraTrailingConstraint.active = !hasExtraDesc;
    self.extraDescEqualDescWidth.active = hasExtraDesc;
    self.iconNoDescBottomConstraint.active = !hasDesc && !hasExtraDesc;
    self.iconDescBottomConstraint.active = hasDesc;
    self.iconExtraDescBottomConstraint.active = hasExtraDesc;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
        CGFloat newIconHeight = (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;
        BOOL hasExtraDesc = !self.extraDescView.hidden;
        BOOL hasDesc = !self.descView.hidden;

        res |= self.iconViewHeight.constant != newIconHeight;
        res |= self.extraDescLeadingConstraint.active != !hasDesc;
        res |= self.descExtraTrailingConstraint.active != hasExtraDesc;
        res |= self.descNoExtraTrailingConstraint.active != !hasExtraDesc;
        res |= self.extraDescEqualDescWidth.active != hasExtraDesc;
        res |= self.iconNoDescBottomConstraint.active != (!hasDesc && !hasExtraDesc);
        res |= self.iconDescBottomConstraint.active != hasDesc;
        res |= self.iconExtraDescBottomConstraint.active != hasExtraDesc;
    }
    return res;
}

- (void)showDesc:(BOOL)show
{
    self.descView.hidden = !show;
}

- (void)showExtraDesc:(BOOL)show
{
    self.extraDescView.hidden = !show;
}

@end
