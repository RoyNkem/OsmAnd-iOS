//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleIconRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

@end
