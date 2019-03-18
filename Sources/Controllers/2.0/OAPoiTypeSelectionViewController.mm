//
//  OAPoiTypeSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 2/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAPoiTypeSelectionViewController.h"
#import "OAEditPOIData.h"
#import "OAPOIHelper.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIBaseType.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"
#import "MaterialTextFields.h"

@interface OAPoiTypeSelectionViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@end

@implementation OAPoiTypeSelectionViewController
{
    EOASelectionType _screenType;
    OAEditPOIData *_poiData;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
    
    NSMutableArray *_filteredData;
    BOOL _isFiltered;
}

-(id)initWithType:(EOASelectionType)type
{
    self = [super init];
    if (self) {
        _screenType = type;
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

-(void) applyLocalization
{
    _titleView.text = _screenType == CATEGORY_SCREEN ? OALocalizedString(@"poi_select_category") : OALocalizedString(@"poi_select_type");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    _searchField.placeholder = OALocalizedString(@"shared_string_search");
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat)getNavBarHeight
{
    return navBarWithSearchFieldHeight;
}

-(void)setupView
{
    _isFiltered = NO;
    [self setupSearchView];
    [self applySafeAreaMargins];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _poiData = self.dataProvider.getData;
    if (_screenType == CATEGORY_SCREEN)
        _data = _poiHelper.poiCategories;
    else
        [self generateTypesList];
    _data = [_data sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [((OAPOIBaseType *)obj1).nameLocalized caseInsensitiveCompare:((OAPOIBaseType *)obj2).nameLocalized];
    }];
}

-(void) setupSearchView
{
    _searchField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.44];
    _searchField.layer.cornerRadius = 10.0;
    _searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_searchField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    _searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(4.0, 0.0, 34.0, _searchField.bounds.size.height)];
    _searchField.leftViewMode = UITextFieldViewModeAlways;
    _searchField.textColor = [UIColor whiteColor];
    _searchField.delegate = self;
    [_searchField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    leftImageView.contentMode = UIViewContentModeCenter;
    leftImageView.frame = _searchField.leftView.frame;
    leftImageView.tintColor = [UIColor whiteColor];
    
    [_searchField.leftView addSubview:leftImageView];
}

-(void)generateTypesList
{
    NSMutableArray *dataArr = [NSMutableArray new];
    OAPOICategory *filter = _poiData.getPoiCategory;
    NSString *categoryName = filter ? filter.name : nil;
    
    for (OAPOIType *type in _poiHelper.poiTypes)
    {
        if (((categoryName && [type.category.name isEqualToString:categoryName]) || !categoryName) && !type.nonEditableOsm)
            [dataArr addObject:type];
    }
    _data = [NSArray arrayWithArray:dataArr];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _isFiltered ? _filteredData.count : _data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
    OASettingsTitleTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAPOIBaseType *item = _isFiltered ? (OAPOIBaseType *)_filteredData[indexPath.row] : (OAPOIBaseType *)_data[indexPath.row];
        [cell.textView setText:item.nameLocalized];
        if (_screenType == CATEGORY_SCREEN)
            [cell.iconView setImage:[UIImage imageNamed:[item isEqual:_poiData.getPoiCategory] ? @"menu_cell_selected.png" : @""]];
        else
            [cell.iconView setImage:[UIImage imageNamed:[item isEqual:_poiData.getCurrentPoiType] ? @"menu_cell_selected.png" : @""]];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_screenType == CATEGORY_SCREEN)
        [_poiData updateType:_isFiltered ? _filteredData[indexPath.row] : _data[indexPath.row]];
    else
        [_poiData updateTypeTag:_isFiltered ? ((OAPOIBaseType *)_filteredData[indexPath.row]).nameLocalized : ((OAPOIBaseType *)_data[indexPath.row]).nameLocalized userChanges:YES];
        
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0)
    {
        _isFiltered = NO;
    }
    else
    {
        _isFiltered = YES;
        _filteredData = [NSMutableArray new];
        for (OAPOIBaseType *type in _data)
        {
            NSRange nameRange = [type.nameLocalized rangeOfString:textView.text options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                [_filteredData addObject:type];
        }
    }
    [_tableView reloadData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
