//
//  OABaseNavbarViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OAColors.h"

@interface OABaseNavbarViewController ()

@property (weak, nonatomic) IBOutlet UIView *navbarBackgroundView;
@property (weak, nonatomic) IBOutlet UIStackView *navbarStackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navbarStackViewEstimatedHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *leftNavbarMarginView;
@property (weak, nonatomic) IBOutlet UIView *rightNavbarMarginView;

@property (weak, nonatomic) IBOutlet UIStackView *leftNavbarButtonStackView;
@property (weak, nonatomic) IBOutlet UIView *leftNavbarButtonMarginView;

@property (weak, nonatomic) IBOutlet UIStackView *rightNavbarButtonStackView;
@property (weak, nonatomic) IBOutlet UIView *rightNavbarButtonMarginView;

@end

@implementation OABaseNavbarViewController
{
    BOOL _isHeaderBlurred;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseNavbarViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
}

// use in overridden init method if class properties have complex dependencies
- (void)postInit
{
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self setupNavbarButtons];
    [self setupNavbarFonts];
    [self updateNavbarStackViewEstimatedHeight];
    self.titleLabel.textColor = [self getTitleColor];

    NSString *title = [self getTitle];
    self.titleLabel.hidden = !title || title.length == 0;
    NSString *subtitle = [self getSubtitle];
    self.subtitleLabel.hidden = !subtitle || subtitle.length == 0;
    self.separatorNavbarView.hidden = ![self isNavbarSeparatorVisible];
    self.navbarBackgroundView.backgroundColor = [self getNavbarColor];

    [self generateData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateNavbarStackViewEstimatedHeight];
        [self updateNavbarEstimatedHeight];
        [self onRotation];
        [self.tableView reloadData];
    } completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange)
        return UIStatusBarStyleLightContent;

    return UIStatusBarStyleDarkContent;
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    self.titleLabel.text = [self getTitle];
    self.subtitleLabel.text = [self getSubtitle];
    [self.leftNavbarButton setTitle:[self getLeftNavbarButtonTitle] forState:UIControlStateNormal];
    [self.rightNavbarButton setTitle:[self getRightNavbarButtonTitle] forState:UIControlStateNormal];
}

- (void)setupNavbarButtons
{
    UIColor *buttonsTintColor = [self getNavbarButtonsTintColor];
    [self.leftNavbarButton setTitleColor:buttonsTintColor forState:UIControlStateNormal];
    self.leftNavbarButton.tintColor = buttonsTintColor;
    [self.rightNavbarButton setTitleColor:buttonsTintColor forState:UIControlStateNormal];
    self.rightNavbarButton.tintColor = buttonsTintColor;

    BOOL isChevronIconVisible = [self isChevronIconVisible];
    [self.leftNavbarButton setImage:isChevronIconVisible ? [UIImage templateImageNamed:@"ic_navbar_chevron"] : nil
                           forState:UIControlStateNormal];
    self.leftNavbarButton.titleEdgeInsets = UIEdgeInsetsMake(0., isChevronIconVisible ? -10. : 0., 0., 0.);

    NSString *leftNavbarButtonTitle = [self getLeftNavbarButtonTitle];
    BOOL hasLeftButton = (leftNavbarButtonTitle && leftNavbarButtonTitle.length > 0) || isChevronIconVisible;
    self.leftNavbarButton.hidden = !hasLeftButton;
    self.leftNavbarButtonMarginView.hidden = !hasLeftButton || isChevronIconVisible;

    NSString *rightNavbarButtonTitle = [self getRightNavbarButtonTitle];
    BOOL hasRightButton = rightNavbarButtonTitle && rightNavbarButtonTitle.length > 0;
    self.rightNavbarButton.hidden = !hasRightButton;
    self.rightNavbarButtonMarginView.hidden = !hasRightButton;

    self.leftNavbarButtonStackView.hidden = !hasLeftButton && !hasRightButton;
    self.rightNavbarButtonStackView.hidden = !hasLeftButton && !hasRightButton;
}

- (void)setupNavbarFonts
{
    self.leftNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.rightNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightSemibold maximumSize:18.];
}

- (CGFloat)getNavbarHeight
{
    return self.navbarBackgroundView.frame.size.height;
}

- (CGFloat)getNavbarEstimatedHeight
{
    return self.navbarStackViewEstimatedHeightConstraint.constant;
}

- (void)updateNavbarEstimatedHeight
{
    self.navbarStackViewEstimatedHeightConstraint.constant = [self getNavbarHeight] - ([self isModal] ? 0. : [OAUtilities getTopMargin]);
    self.tableView.contentInset = UIEdgeInsetsMake(self.navbarStackViewEstimatedHeightConstraint.constant, 0, 0, 0);
}

- (void)updateNavbarStackViewEstimatedHeight
{
    CGFloat height = [self isNavbarSeparatorVisible] ? separatorNavBarHeight : 0.;
    height += [self isModal] && ![OAUtilities isLandscape] ? modalNavBarHeight : defaultNavBarHeight;
    self.navbarStackViewEstimatedHeightConstraint.constant = height;
}

- (void)resetNavbarEstimatedHeight
{
    self.navbarStackViewEstimatedHeightConstraint.constant = 0;
}

- (void)adjustScrollStartPosition
{
    self.tableView.contentOffset = CGPointMake(0., -[self getNavbarHeight]);
}

- (UIColor *)getNavbarColor
{
    EOABaseNavbarColorScheme colorScheme = [self getNavbarColorScheme];
    switch (colorScheme)
    {
        case EOABaseNavbarColorSchemeOrange:
        {
            return UIColorFromRGB(color_primary_orange_navbar_background);
            break;
        }
        case EOABaseNavbarColorSchemeWhite:
        {
            return UIColor.whiteColor;
            break;
        }
        default:
        {
            return UIColorFromRGB(color_primary_gray_navbar_background);
            break;
        }
    }
}

- (UIColor *)getNavbarButtonsTintColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? UIColor.whiteColor : UIColorFromRGB(color_primary_purple);
}

- (UIColor *)getTitleColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? UIColor.whiteColor : UIColor.blackColor;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return @"";
}

- (NSString *)getSubtitle
{
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return @"";
}

- (NSString *)getRightNavbarButtonTitle
{
    return @"";
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeGray;
}

- (BOOL)isNavbarSeparatorVisible
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

- (BOOL)isChevronIconVisible
{
    return YES;
}

- (BOOL)isNavbarBlurring
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
}

- (BOOL)hideFirstHeader
{
    return NO;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return @"";
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger)sectionsCount
{
    return 0;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    return nil;
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    return nil;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
}

#pragma mark - Selectors

- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

- (IBAction)onRightNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)onRotation
{
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self isScreenLoaded])
    {
        if ([self isNavbarBlurring])
        {
            CGFloat y = scrollView.contentOffset.y + [self getNavbarHeight];
            if (!_isHeaderBlurred && y > 0)
            {
                [UIView animateWithDuration:.2 animations:^{
                    [self.navbarBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
                    _isHeaderBlurred = YES;
                }];
            }
            else if (_isHeaderBlurred && y <= 0)
            {
                [UIView animateWithDuration:.2 animations:^{
                    [self.navbarBackgroundView removeBlurEffect:[self getNavbarColor]];
                    _isHeaderBlurred = NO;
                }];
            }
        }

        [self onScrollViewDidScroll:scrollView];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [self hideFirstHeader])
        return 0.001;

    return [self getCustomHeightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getCustomHeightForFooter:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getCustomViewForHeader:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [self getCustomViewForFooter:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onRowPressed:indexPath];

    UITableViewCell *row = [self getRow:indexPath];
    if (row && row.selectionStyle != UITableViewCellSelectionStyleNone)
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getRow:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self sectionsCount];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self getTitleForHeader:section];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self getTitleForFooter:section];
}

@end

// !!!
// remove from project:
//
//tableView.separatorInset =
//- (CGFloat)heightForRow:(NSIndexPath *)indexPath
//- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath