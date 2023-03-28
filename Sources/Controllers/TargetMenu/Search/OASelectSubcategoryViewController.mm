//
//  OASelectSubcategoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASelectSubcategoryViewController.h"
#import "Localization.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAButtonTableViewCell.h"
#import "OAMenuSimpleCell.h"
#import "OAColors.h"
#import "OAPOIUIFilter.h"
#import "OASearchResult.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OAQuickSearchHelper.h"
#import "OATableViewCustomHeaderView.h"
#import "OACustomPOIViewController.h"

@interface OASelectSubcategoryViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightPrimaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightSecondaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *applyButtonHeightPrimaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *applyButtonHeightSecondaryConstraint;

@end

@implementation OASelectSubcategoryViewController
{
    OASearchUICore *_core;
    OAPOICategory *_category;
    OAPOIUIFilter *_filter;
    NSArray<OAPOIType *> *_items;
    NSMutableArray<OAPOIType *> *_selectedItems;
    NSMutableArray<OAPOIType *> *_searchResult;
    BOOL _searchMode;
}

- (instancetype)initWithCategory:(OAPOICategory *)category filter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _core = [[OAQuickSearchHelper instance] getCore];
        _category = category;
        _filter = filter;
        [self initData];
    }
    return self;
}

- (void)initData
{
    if (_category)
    {
        NSSet<NSString *> *acceptedTypes = [[_filter getAcceptedTypes] objectForKey:_category];
        NSSet<NSString *> *acceptedSubtypes = [_filter getAcceptedSubtypes:_category];
        NSArray<OAPOIType *> *types = _category.poiTypes;

        _selectedItems = [NSMutableArray new];
        _items = [NSArray arrayWithArray:[types sortedArrayUsingComparator:^NSComparisonResult(OAPOIType * _Nonnull t1, OAPOIType * _Nonnull t2) {
            return [t1.nameLocalized localizedCaseInsensitiveCompare:t2.nameLocalized];
        }]];

        if (acceptedSubtypes == [OAPOIBaseType nullSet] || acceptedTypes.count == types.count)
        {
            _selectedItems = [NSMutableArray arrayWithArray:_items];
        }
        else
        {
            for (OAPOIType *poiType in _items)
            {
                if ([acceptedTypes containsObject:poiType.name])
                    [_selectedItems addObject:poiType];
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self.tableView beginUpdates];
    for (NSInteger i = 0; i < _items.count; i++)
        if ([_selectedItems containsObject:_items[i]])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView endUpdates];

    _searchMode = NO;
    self.searchBar.delegate = self;

    [self updateApplyButton:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)applyLocalization
{
    [self updateScreenTitle];

    self.applyButton.titleLabel.text = OALocalizedString(@"shared_string_apply");
    self.searchBar.placeholder = _searchMode ? @"" : OALocalizedString(@"shared_string_search");
}

- (void)updateScreenTitle
{
    if (_searchMode)
        self.titleLabel.text = OALocalizedString(@"shared_string_search");
    else if (_category)
        self.titleLabel.text = _category.nameLocalized;
    else
        self.titleLabel.text = @"";
}

- (void)updateApplyButton:(BOOL)hasSelection
{
    self.applyButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_button_gray_background);
    [self.applyButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.applyButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.applyButton setUserInteractionEnabled:hasSelection];
}

- (BOOL)willUpdateApplyButton
{
    NSSet<NSString *> *acceptedSubtypes = [_filter getAcceptedSubtypes:_category];
    NSArray<OAPOIType *> *types = _category.poiTypes;
    if ((![[self getSelectedKeys] isEqualToSet:acceptedSubtypes] && acceptedSubtypes != [OAPOIBaseType nullSet]) || (acceptedSubtypes == [OAPOIBaseType nullSet] && _selectedItems.count != types.count))
        return YES;
    return NO;
}

- (NSMutableSet<NSString *> *)getSelectedKeys
{
    NSMutableSet<NSString *> *selectedKeys = [NSMutableSet set];
    for (OAPOIType *poiType in _selectedItems)
        [selectedKeys addObject:poiType.name];
    return selectedKeys;
}

- (NSString *)getTitleForSection
{
    return [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, (int)_items.count] upperCase];
}

- (void)selectDeselectGroup:(id)sender
{
    BOOL shouldSelect = _selectedItems.count == 0;
    if (!shouldSelect)
        [_selectedItems removeAllObjects];
    else
        [_selectedItems addObjectsFromArray:_items];

    for (NSInteger i = 0; i < _items.count; i++)
    {
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    }
    [self.tableView beginUpdates];
    [self.tableView headerViewForSection:0].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count] upperCase];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

    [self updateApplyButton:[self willUpdateApplyButton]];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode && indexPath.row > 0))
    {
        [self.tableView beginUpdates];
        OAPOIType *type = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
        if ([_selectedItems containsObject:type])
            [_selectedItems removeObject:type];
        else
            [_selectedItems addObject:type];
        [self.tableView headerViewForSection:indexPath.section].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int) _selectedItems.count, _items.count] upperCase];
        [self.tableView endUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

        [self updateApplyButton:[self willUpdateApplyButton]];
    }
}

- (void)resetSearchTypes
{
    [_core updateSettings:[[_core getSearchSettings] resetSearchTypes]];
}

- (IBAction)onBackButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate selectSubcategoryCancel];

    [self resetSearchTypes];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onApplyButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate selectSubcategoryDone:_category keys:[self getSelectedKeys] allSelected:_selectedItems.count == _items.count];

    [self resetSearchTypes];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    _searchMode = NO;
    _searchResult = [NSMutableArray new];
    self.searchBar.placeholder = OALocalizedString(@"shared_string_search");
    [self updateScreenTitle];
    [self.tableView setEditing:NO];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchBar.text.length == 0)
    {
        _searchMode = NO;
        [_core updateSettings:_core.getSearchSettings.resetSearchTypes];
        [self resetSearchTypes];
    }
    else
    {
        _searchMode = YES;
        _searchResult = [NSMutableArray new];
        OASearchSettings *searchSettings = [[_core getSearchSettings] setSearchTypes:@[[OAObjectType withType:POI_TYPE]]];
        [_core updateSettings:searchSettings];
        [_core search:searchBar.text delayedExecution:YES matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
            OASearchResult *obj = *object;
            if (obj.objectType == SEARCH_FINISHED)
            {
                OASearchResultCollection *currentSearchResult = [_core getCurrentSearchResult];
                NSMutableArray<OAPOIType *> *results = [NSMutableArray new];
                for (OASearchResult *result in currentSearchResult.getCurrentSearchResults)
                {
                    NSObject *poiObject = result.object;
                    if ([poiObject isKindOfClass:[OAPOIType class]])
                    {
                        OAPOIType *poiType = (OAPOIType *) poiObject;
                        if (!poiType.isAdditional)
                        {
                            if (poiType.category == _category || [_items containsObject:poiType])
                            {
                                [results addObject:poiType];
                            }
                            else
                            {
                                for (OAPOIType *item in _items)
                                {
                                    if ([item.name isEqualToString:poiType.name])
                                        [results addObject:item];
                                }
                            }
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    _searchResult = [NSMutableArray arrayWithArray:results];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self updateApplyButton:[self willUpdateApplyButton]];
                });
            }
            return YES;
        } cancelledFunc:^BOOL {
            return !_searchMode;
        }]];
    }
    self.searchBar.placeholder = _searchMode ? @"" : OALocalizedString(@"shared_string_search");
    [self updateScreenTitle];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateApplyButton:[self willUpdateApplyButton]];
}

#pragma mark - UITableViewDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && !_searchMode)
    {
        OAButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:YES];
            [cell.button.titleLabel setTextAlignment:NSTextAlignmentNatural];
            cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
        }
        if (cell)
        {
            NSUInteger selectedAmount = _selectedItems.count;

            NSString *selectionText = selectedAmount > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");
            [cell.button setTitle:selectionText forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];

            UIImage *selectionImage = nil;
            if (selectedAmount > 0)
                selectionImage = [UIImage imageNamed:selectedAmount < _items.count ? @"ic_system_checkbox_indeterminate" : @"ic_system_checkbox_selected"];
            else
                selectionImage = [UIImage imageNamed:@"ic_custom_checkbox_unselected"];
            [cell.leftEditButton setImage:selectionImage forState:UIControlStateNormal];
            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.leftEditButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else
    {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 65.0, 0.0, 0.0);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIType *poiType = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
            BOOL selected = [_selectedItems containsObject:poiType];

            UIColor *selectedColor = selected ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
            cell.imgView.image = self.delegate ? [self.delegate getPoiIcon:poiType] : [UIImage templateImageNamed:@"ic_custom_search_categories"];
            cell.imgView.tintColor = selectedColor;
            if (cell.imgView.image.size.width < cell.imgView.frame.size.width && cell.imgView.image.size.height < cell.imgView.frame.size.height)
                cell.imgView.contentMode = UIViewContentModeCenter;
            else
                cell.imgView.contentMode = UIViewContentModeScaleAspectFit;

            cell.textView.text = poiType.nameLocalized ? poiType.nameLocalized : @"";
            cell.descriptionView.hidden = YES;

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode &&  indexPath.row > 0))
    {
        OAPOIType *item = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
        BOOL selected = [_selectedItems containsObject:item];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode &&  indexPath.row > 0))
        [self selectDeselectItem:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode &&  indexPath.row > 0))
        [self selectDeselectItem:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        [customHeader setYOffset:32];
        customHeader.label.text = [self getTitleForSection];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [OATableViewCustomHeaderView getHeight:[self getTitleForSection] width:tableView.bounds.size.width] + 18;
    }
    return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchMode ? _searchResult.count : _items.count + 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _searchMode || (!_searchMode && indexPath.row != 0);
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = DeviceScreenHeight - keyboardHeight;

    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = viewFrame;
        self.bottomViewHeightPrimaryConstraint.active = NO;
        self.bottomViewHeightSecondaryConstraint.active = YES;
        self.applyButtonHeightPrimaryConstraint.active = NO;
        self.applyButtonHeightSecondaryConstraint.active = YES;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = DeviceScreenHeight;

    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = viewFrame;

        self.bottomViewHeightPrimaryConstraint.active = YES;
        self.bottomViewHeightSecondaryConstraint.active = NO;

        self.applyButtonHeightPrimaryConstraint.active = YES;
        self.applyButtonHeightSecondaryConstraint.active = NO;
    } completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

@end
