//
//  OAIconTitleValueCell.m
//  OsmAnd
//
//  Created by Paul on 01.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleValueCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 48.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;

@implementation OAIconTitleValueCell

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title value:value] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont systemFontOfSize:17.0];
    
    CGFloat w = cellWidth / titleTextWidthKoef;
    CGFloat titleHeight = 0;
    if (title)
        titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    
    w = cellWidth / valueTextWidthKoef;
    CGFloat valueHeight = 0;
    if (value && value.length > 0)
        valueHeight = [OAUtilities calculateTextBounds:value width:w font:_titleTextFont].height + textMarginVertical * 2;
    
    return MAX(titleHeight, valueHeight);
}

-(void)showImage:(BOOL)show
{
    if (show)
    {
        CGRect frame = CGRectMake(51.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
    }
    else
    {
        CGRect frame = CGRectMake(16.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
    }
}

@end
