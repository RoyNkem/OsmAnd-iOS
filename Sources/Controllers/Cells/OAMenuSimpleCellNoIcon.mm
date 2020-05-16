//
//  OAMenuSimpleCellNoIcon.m
//  OsmAnd
//
//  Created by Paul on 19/09/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMenuSimpleCellNoIcon.h"
#import "OAUtilities.h"

#define defaultCellHeight 50.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OAMenuSimpleCellNoIcon

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
    if (!desc || desc.length == 0)
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    }
    else
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text] + [self.class getDescViewHeightWithWidth:textWidth text:desc]);
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    CGFloat textX = 16.0;
    CGFloat textWidth = w - titleTextWidthDelta;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.textView.text];
    
    if (self.descriptionView.hidden)
    {
        self.textView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    }
    else
    {
        CGFloat descHeight = [self.class getDescViewHeightWithWidth:textWidth text:self.descriptionView.text];
        self.textView.frame = CGRectMake(textX, 0.0, textWidth, MAX(minTextHeight, titleHeight));
        self.descriptionView.frame = CGRectMake(textX, h - descHeight - 3.0, textWidth, descHeight);
    }
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

+ (CGFloat) getDescViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_descFont)
        _descFont = [UIFont systemFontOfSize:13.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_descFont].height + textMarginVertical;
}

@end
