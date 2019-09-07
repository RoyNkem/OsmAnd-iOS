//
//  OATextInputIconCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputIconCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;

@implementation OATextInputIconCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat textX = 62.0;
    CGFloat w = self.bounds.size.width - textX - 16.0;
    
    CGFloat textWidth = w;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:[self.inputField.text length] == 0 ? self.inputField.placeholder : self.inputField.text];
    
    self.inputField.frame = CGRectMake(textX, 0.0, textWidth - textX, MAX(defaultCellHeight, titleHeight));
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:16.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}


@end
