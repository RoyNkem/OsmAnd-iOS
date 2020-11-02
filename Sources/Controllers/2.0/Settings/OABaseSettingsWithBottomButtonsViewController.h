//
//  OABaseSettingsWithBottomButtonsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

@class OAApplicationMode;

@interface OABaseSettingsWithBottomButtonsViewController : OABaseBigTitleSettingsViewController

@property (strong, nonatomic) IBOutlet UIButton *additionalNavBarButton;
@property (strong, nonatomic) IBOutlet UIView *bottomBarView;
@property (strong, nonatomic) IBOutlet UIButton *primaryBottomButton;
@property (strong, nonatomic) IBOutlet UIButton *secondaryBottomButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonLeftMarginWithIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonLeftMarginNoIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *primaryButtonTopMarginNoSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *primaryButtonTopMarginYesSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *secondaryButtonBottomMarginYesPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeigh;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *primaryButtonHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *secondaryButtonHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomMarginYesView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomMarginNoView;


- (void) setToButton:(UIButton *)button firstLabelText:(NSString *)firstLabelText firstLabelFont:(UIFont *)firstLabelFont firstLabelColor:(UIColor *)firstLabelColor secondLabelText:(NSString *)secondLabelText secondLabelFont:(UIFont *)secondLabelFont secondLabelColor:(UIColor *)secondLabelColor;
- (UIView *) getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment forSection:(NSInteger)section;
- (CGFloat) getHeightForHeaderWithFirstHeaderText:(NSString *)text boldFragment:(NSString *)boldFragment inSection:(NSInteger)section;

@end
