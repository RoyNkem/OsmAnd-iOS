//
//  OAPOIFilterViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPOIFilterViewController.h"
#import "OAPOISearchHelper.h"
#import "OAPOIUIFilter.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OACustomPOIViewController.h"
#import "OAPOIHelper.h"
#import "OAPOIBaseType.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIFilter.h"
#import "OAUtilities.h"
#import "OAIconTextCollapseCell.h"
#import "OAIconTextSwitchCell.h"
#import "OAIconButtonCell.h"
#import "OAIconTextFieldCell.h"
#import "OASizes.h"

typedef enum
{
    EMenuStandard = 0,
    EMenuCustom,
    EMenuDelete,
    
} EMenuType;

typedef enum
{
    GROUP_HEADER,
    SWITCH_ITEM,
    BUTTON_ITEM,
    
} OAPOIFilterListItemType;

@interface OAPOIFilterListItem : NSObject

@property (nonatomic) OAPOIFilterListItemType type;
@property (nonatomic) UIImage *icon;
@property (nonatomic) NSString *text;
@property (nonatomic) int groupIndex;
@property (nonatomic) BOOL expandable;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL checked;
@property (nonatomic) NSString *category;
@property (nonatomic) NSString *keyName;

- (instancetype)initWithType:(OAPOIFilterListItemType)type icon:(UIImage *)icon text:(NSString *)text groupIndex:(int)groupIndex expandable:(BOOL)expandable expanded:(BOOL)expanded checked:(BOOL)checked category:(NSString *)category keyName:(NSString *)keyName;

@end
    
@implementation OAPOIFilterListItem

- (instancetype)initWithType:(OAPOIFilterListItemType)type icon:(UIImage *)icon text:(NSString *)text groupIndex:(int)groupIndex expandable:(BOOL)expandable expanded:(BOOL)expanded checked:(BOOL)checked category:(NSString *)category keyName:(NSString *)keyName
{
    self = [super init];
    if (self)
    {
        self.type = type;
        self.icon = icon;
        self.text = text;
        self.groupIndex = groupIndex;
        self.expandable = expandable;
        self.expanded = expanded;
        self.checked = checked;
        self.category = category;
        self.keyName = keyName;
    }
    return self;
}

@end


@interface OAPOIFilterViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;

@property (weak, nonatomic) IBOutlet UIView *applyView;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;

@end

@implementation OAPOIFilterViewController
{
    OAPOIUIFilter *_filter;
    
    NSString *_nameFilterText;
    NSString *_nameFilterTextOrig;

    NSMutableSet<NSString *> *_selectedPoiAdditionals;
    NSMutableSet<NSString *> *_selectedPoiAdditionalsOrig;
    NSMutableArray<NSString *> *_collapsedCategories;
    NSMutableArray<NSString *> *_showAllCategories;

    OAPOIFiltersHelper *_helper;
    
    NSDictionary<NSNumber *, NSMutableArray<OAPOIFilterListItem *> *> *_groups;
    
    UIView *_textFieldHeaderView;
    OAIconTextFieldCell *_textFieldCell;
    BOOL _applyViewVisible;

    UIPanGestureRecognizer *_tblMove;
}

- (instancetype)initWithFilter:(OAPOIUIFilter * _Nonnull)filter filterByName:(NSString * _Nullable)filterByName
{
    self = [super init];
    if (self)
    {
        _helper = [OAPOIFiltersHelper sharedInstance];
        
        if (!filterByName)
            filterByName = @"";
        
        _nameFilterText = filterByName;
        _nameFilterTextOrig = filterByName;
        
        if( filter)
        {
            _filter = filter;
        }
        else
        {
            _filter = [_helper getCustomPOIFilter];
            [_filter clearFilter];
        }
        
        _selectedPoiAdditionals = [NSMutableSet set];
        _selectedPoiAdditionalsOrig = [NSMutableSet set];
        _collapsedCategories = [NSMutableArray array];
        _showAllCategories = [NSMutableArray array];
        
        [self processFilterFields];
        [self initListItems];

        _selectedPoiAdditionalsOrig = [NSMutableSet setWithSet:_selectedPoiAdditionals];
        
        [self updateGroups];
    }
    return self;
}

-(void)applyLocalization
{
    _textView.text = OALocalizedString(@"shared_string_filters");
    [_applyButton setTitle:[OALocalizedString(@"apply_filters") upperCase] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tblMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(moveGestureDetected:)];
    _tblMove.delegate = self;

    _descView.text = _filter.name;
    
    // drop shadow
    [_applyView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_applyView.layer setShadowOpacity:0.3];
    [_applyView.layer setShadowRadius:3.0];
    [_applyView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _applyView.hidden = YES;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextFieldCell" owner:self options:nil];
    _textFieldCell = (OAIconTextFieldCell *)[nib objectAtIndex:0];
    _textFieldCell.backgroundColor = [UIColor whiteColor];
    _textFieldCell.iconView.image = [OAUtilities getTintableImageNamed:@"search_icon"];
    _textFieldCell.textField.placeholder = OALocalizedString(@"filter_poi_hint");
    _textFieldCell.textField.text = _nameFilterText;
    [_textFieldCell.textField addTarget:self action:@selector(filterTextChanged:) forControlEvents:UIControlEventEditingChanged];
    
    _textFieldHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _tableView.bounds.size.width, 51.0)];
    _textFieldHeaderView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _textFieldHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_textFieldHeaderView addSubview:_textFieldCell];
    
    UIView *topSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _textFieldHeaderView.bounds.size.width, 0.5)];
    topSeparatorView.backgroundColor = _tableView.separatorColor;
    topSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_textFieldHeaderView addSubview:topSeparatorView];

    UIView *bottomSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 51.5, _textFieldHeaderView.bounds.size.width, 0.5)];
    bottomSeparatorView.backgroundColor = _tableView.separatorColor;
    bottomSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_textFieldHeaderView addSubview:bottomSeparatorView];
    [self applySafeAreaMargins];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unregisterKeyboardNotifications];
}

-(UIView *) getTopView
{
    return _topView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(UIView *) getBottomView
{
    return _applyViewVisible ? _applyView : nil;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

- (void)filterTextChanged:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    _nameFilterText = textField.text;
    [self updateApplyButton];
}

-(void)moveGestureDetected:(id)sender
{
    [_textFieldCell.textField resignFirstResponder];
}

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addGestureRecognizer:_tblMove];
    });
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view removeGestureRecognizer:_tblMove];
    });
}

- (IBAction)closePress:(id)sender
{
    if (_delegate)
    {
        if (![_filter isStandardFilter])
            [_delegate updateFilter:_filter nameFilter:@""];
        else
            [_delegate updateFilter:_filter nameFilter:_nameFilterTextOrig];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)morePress:(id)sender
{
    if (![_filter isStandardFilter])
    {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:_filter.name delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") destructiveButtonTitle:OALocalizedString(@"delete_filter") otherButtonTitles:OALocalizedString(@"edit_filter"), OALocalizedString(@"shared_string_save_as"), nil];
        menu.tag = EMenuCustom;
        [menu showInView:self.btnMore];
    }
    else
    {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:_filter.name delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") destructiveButtonTitle:nil otherButtonTitles:OALocalizedString(@"save_filter"), nil];
        menu.tag = EMenuStandard;
        [menu showInView:self.btnMore];
    }
}

- (void) deleteFilter
{
    UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:OALocalizedString(@"edit_filter_delete_dialog_title") delegate:self cancelButtonTitle:nil destructiveButtonTitle:OALocalizedString(@"shared_string_yes") otherButtonTitles:OALocalizedString(@"shared_string_no"), nil];
    menu.tag = EMenuDelete;
    [menu showInView:self.view];
}

- (void) editCategories
{
    OACustomPOIViewController *customPOI = [[OACustomPOIViewController alloc] initWithFilter:_filter];
    [self.navigationController pushViewController:customPOI animated:YES];
}

- (void) applyFilterFields
{
    NSMutableString *sb = [NSMutableString string];
    if (_nameFilterText.length > 0)
        [sb appendString:_nameFilterText];
    
    for (NSString *param in _selectedPoiAdditionals)
    {
        if (sb.length > 0)
            [sb appendString:@" "];
        
        [sb appendString:param];
    }
    [_filter setFilterByName:sb];
}

- (void) processFilterFields
{
    NSString __block *filterByName = _filter.filterByName;
    if (filterByName.length > 0)
    {
        int __block index;
        OAPOIHelper *poiTypes = [OAPOIHelper sharedInstance];
        NSDictionary<NSString *, OAPOIType *> *poiAdditionals = [_filter getPoiAdditionals];
        NSSet<NSString *> *excludedPoiAdditionalCategories = [self getExcludedPoiAdditionalCategories];
        NSArray<OAPOIType *> *otherAdditionalCategories = poiTypes.otherMapCategory.poiAdditionalsCategorized;
        
        if (![excludedPoiAdditionalCategories containsObject:@"opening_hours"])
        {
            NSString *keyNameOpen = [[OALocalizedString(@"shared_string_is_open") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];
            NSString *keyNameOpen24 = [[OALocalizedString(@"shared_string_is_open_24_7") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];
            index = [filterByName indexOf:keyNameOpen24];
            if (index != -1)
            {
                [_selectedPoiAdditionals addObject:keyNameOpen24];
                filterByName = [filterByName stringByReplacingOccurrencesOfString:keyNameOpen24 withString:@""];
            }
            index = [filterByName indexOf:keyNameOpen];
            if (index != -1)
            {
                [_selectedPoiAdditionals addObject:keyNameOpen];
                filterByName = [filterByName stringByReplacingOccurrencesOfString:keyNameOpen withString:@""];
            }
        }
        if (poiAdditionals)
        {
            NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *additionalsMap = [NSMutableDictionary dictionary];
            [self extractPoiAdditionals:[poiAdditionals allValues] additionalsMap:additionalsMap excludedPoiAdditionalCategories:excludedPoiAdditionalCategories extractAll:YES];
            [self extractPoiAdditionals:otherAdditionalCategories additionalsMap:additionalsMap excludedPoiAdditionalCategories:excludedPoiAdditionalCategories extractAll:YES];
            
            if (additionalsMap.count > 0)
            {
                [additionalsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<OAPOIType *> * _Nonnull value, BOOL * _Nonnull stop) {
                   
                    for (OAPOIType *poiType in value)
                    {
                        NSString *keyName = [[poiType.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] lowerCase];
                        index = [filterByName indexOf:keyName];
                        if (index != -1)
                        {
                            [_selectedPoiAdditionals addObject:keyName];
                            filterByName = [filterByName stringByReplacingOccurrencesOfString:keyName withString:@""];
                        }
                    }
                }];
            }
        }
        if ([filterByName trim].length > 0 && _nameFilterText.length == 0)
        {
            _nameFilterText = [filterByName trim];
            _nameFilterTextOrig = [NSString stringWithString:_nameFilterText];
        }
    }
}

- (void) extractPoiAdditionals:(NSArray<OAPOIType *> *)poiAdditionals additionalsMap:(NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *)additionalsMap excludedPoiAdditionalCategories:(NSSet<NSString *> *)excludedPoiAdditionalCategories extractAll:(BOOL)extractAll
{
    for (OAPOIType *poiType in poiAdditionals)
    {
        NSString *category = poiType.poiAdditionalCategory;
        if (!category)
            category = @"";

        if (excludedPoiAdditionalCategories && [excludedPoiAdditionalCategories containsObject:category])
            continue;
        
        if ([_collapsedCategories containsObject:category] && !extractAll)
        {
            if (![additionalsMap objectForKey:category])
                [additionalsMap setObject:[NSMutableArray array] forKey:category];
            
            continue;
        }
        BOOL showAll = [_showAllCategories containsObject:category] || extractAll;
        NSString *keyName = [[poiType.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] lowerCase];
        if (showAll || poiType.top || [_selectedPoiAdditionals containsObject:[keyName stringByReplacingOccurrencesOfString:@" " withString:@":"]])
        {
            NSMutableArray<OAPOIType *> *adds = [additionalsMap objectForKey:category];
            if (!adds)
            {
                adds = [NSMutableArray array];
                [additionalsMap setObject:adds forKey:category];
            }
            if (![adds containsObject:poiType])
                [adds addObject:poiType];
        }
    }
}
             
- (NSSet<NSString *> *) getExcludedPoiAdditionalCategories
{
    NSMutableSet<NSString *> *excludedPoiAdditionalCategories = [NSMutableSet set];
    if ([_filter getAcceptedTypes].count == 0)
        return excludedPoiAdditionalCategories;
    
    OAPOIHelper *poiTypes = [OAPOIHelper sharedInstance];
    OAPOICategory *topCategory = nil;
    if ([_filter.baseType isKindOfClass:[OAPOICategory class]])
        topCategory = (OAPOICategory *) _filter.baseType;
    else if ([_filter.baseType isKindOfClass:[OAPOIFilter class]])
        topCategory = ((OAPOIFilter *) _filter.baseType).category;
    else if ([_filter.baseType isKindOfClass:[OAPOIType class]])
        topCategory = ((OAPOIType *) _filter.baseType).category;
    
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *accTypes = [_filter getAcceptedTypes];
    for (OAPOICategory *key in accTypes.keyEnumerator)
    {
        NSSet<NSString *> *value = [accTypes objectForKey:key];
        
        if (value != [OAPOIBaseType nullSet])
        {
            NSMutableSet<NSString *> *excluded = [NSMutableSet set];
            for (NSString *keyName in value) {
                OAPOIType *poiType = [poiTypes getPoiTypeByKeyInCategory:topCategory name:keyName];
                if (poiType)
                {
                    [self collectExcludedPoiAdditionalCategories:poiType excludedPoiAdditionalCategories:excluded];
                    if (!poiType.reference)
                    {
                        OAPOIFilter *poiFilter = poiType.filter;
                        if (poiFilter)
                            [self collectExcludedPoiAdditionalCategories:poiFilter excludedPoiAdditionalCategories:excluded];
                        
                        OAPOICategory *poiCategory = poiType.category;
                        if (poiCategory)
                            [self collectExcludedPoiAdditionalCategories:poiCategory excludedPoiAdditionalCategories:excluded];
                    }
                }
                if (excludedPoiAdditionalCategories.count == 0)
                    [excludedPoiAdditionalCategories addObjectsFromArray:[excluded allObjects]];
                else
                    [excludedPoiAdditionalCategories intersectSet:excluded];
                
                [excluded removeAllObjects];
            }
        }
    }
    
    if (topCategory && topCategory.excludedPoiAdditionalCategories)
        [excludedPoiAdditionalCategories addObjectsFromArray:topCategory.excludedPoiAdditionalCategories];
    
    return excludedPoiAdditionalCategories;
}

- (void) collectExcludedPoiAdditionalCategories:(OAPOIBaseType *)abstractPoiType excludedPoiAdditionalCategories:(NSMutableSet<NSString *> *)excludedPoiAdditionalCategories
{
    NSArray<NSString *> *categories = abstractPoiType.excludedPoiAdditionalCategories;
    if (categories)
        [excludedPoiAdditionalCategories addObjectsFromArray:categories];
}

- (void) initListItems
{
    NSDictionary<NSString *, OAPOIType *> *poiAdditionals = [_filter getPoiAdditionals];
    NSSet<NSString *> *excludedPoiAdditionalCategories = [self getExcludedPoiAdditionalCategories];
    NSArray<OAPOIType *> *otherAdditionalCategories = [OAPOIHelper sharedInstance].otherMapCategory.poiAdditionalsCategorized;
    if (poiAdditionals)
    {
        [self initPoiAdditionals:poiAdditionals.allValues excludedPoiAdditionalCategories:excludedPoiAdditionalCategories];
        [self initPoiAdditionals:otherAdditionalCategories excludedPoiAdditionalCategories:excludedPoiAdditionalCategories];
    }
}

- (void) initPoiAdditionals:(NSArray<OAPOIType *> *)poiAdditionals excludedPoiAdditionalCategories:(NSSet<NSString *> *)excludedPoiAdditionalCategories
{
    NSMutableSet<NSString *> *selectedCategories = [NSMutableSet set];
    NSMutableSet<NSString *> *topTrueOnlyCategories = [NSMutableSet set];
    NSMutableSet<NSString *> *topFalseOnlyCategories = [NSMutableSet set];
    for (OAPOIType *poiType in poiAdditionals)
    {
        NSString *category = poiType.poiAdditionalCategory;
        if (category)
        {
            [topTrueOnlyCategories addObject:category];
            [topFalseOnlyCategories addObject:category];
        }
    }
    for (OAPOIType *poiType in poiAdditionals)
    {
        NSString *category = poiType.poiAdditionalCategory;
        if (!category)
            category = @"";
        
        if (excludedPoiAdditionalCategories && [excludedPoiAdditionalCategories containsObject:category])
        {
            [topTrueOnlyCategories removeObject:category];
            [topFalseOnlyCategories removeObject:category];
            continue;
        }
        if (!poiType.top)
            [topTrueOnlyCategories removeObject:category];
        else
            [topFalseOnlyCategories removeObject:category];
        
        NSString *keyName = [[[poiType.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] stringByReplacingOccurrencesOfString:@" " withString:@":"] lowerCase];
        if ([_selectedPoiAdditionals containsObject:keyName])
            [selectedCategories addObject:category];
        
    }
    for (NSString *category in topTrueOnlyCategories)
    {
        if (![_showAllCategories containsObject:category])
            [_showAllCategories addObject:category];
    }
    for (NSString *category in topFalseOnlyCategories)
    {
        if (![_collapsedCategories containsObject:category] && ![_showAllCategories containsObject:category])
        {
            if (![selectedCategories containsObject:category])
                [_collapsedCategories addObject:category];
            
            [_showAllCategories addObject:category];
        }
    }
}

- (void) updateGroups
{
    OAPOIHelper *poiTypes = [OAPOIHelper sharedInstance];
    
    int __block groupId = -1;
    NSMutableDictionary<NSNumber *, NSMutableArray<OAPOIFilterListItem *> *> *groups = [NSMutableDictionary dictionary];
    
    NSDictionary<NSString *, OAPOIType *> *poiAdditionals = [_filter getPoiAdditionals];
    NSSet<NSString *> *excludedPoiAdditionalCategories = [self getExcludedPoiAdditionalCategories];
    NSArray<OAPOIType *> *otherAdditionalCategories = poiTypes.otherMapCategory.poiAdditionalsCategorized;
    
    if (![excludedPoiAdditionalCategories containsObject:@"opening_hours"])
    {
        groupId++;

        NSString *keyNameOpen = [[OALocalizedString(@"shared_string_is_open") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];

        NSMutableArray<OAPOIFilterListItem *> *items = [NSMutableArray array];
        
        [items addObject:[[OAPOIFilterListItem alloc] initWithType:SWITCH_ITEM icon:[UIImage imageNamed:@"ic_working_time.png"] text:OALocalizedString(@"shared_string_is_open") groupIndex:groupId expandable:NO expanded:NO checked:[_selectedPoiAdditionals containsObject:keyNameOpen] category:nil keyName:keyNameOpen]];
        NSString *keyNameOpen24 = [[OALocalizedString(@"shared_string_is_open_24_7") stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowerCase];
        
        [items addObject:[[OAPOIFilterListItem alloc] initWithType:SWITCH_ITEM icon:nil text:OALocalizedString(@"shared_string_is_open_24_7") groupIndex:groupId expandable:NO expanded:NO checked:[_selectedPoiAdditionals containsObject:keyNameOpen24] category:nil keyName:keyNameOpen24]];
        
        [groups setObject:items forKey:[NSNumber numberWithInt:groupId]];
    }
    if (poiAdditionals)
    {
        NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *additionalsMap = [NSMutableDictionary dictionary];
        [self extractPoiAdditionals:[poiAdditionals allValues] additionalsMap:additionalsMap excludedPoiAdditionalCategories:excludedPoiAdditionalCategories extractAll:NO];
        [self extractPoiAdditionals:otherAdditionalCategories additionalsMap:additionalsMap excludedPoiAdditionalCategories:excludedPoiAdditionalCategories extractAll:NO];
        
        if (additionalsMap.count > 0)
        {
            NSArray<NSString *> *keys = [additionalsMap.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull s1, NSString * _Nonnull s2) {
                return [s1 localizedCaseInsensitiveCompare:s2];
            }];
            
            for (NSString *category in keys)
            {
                NSMutableArray<OAPOIType *> *value = [additionalsMap objectForKey:category];
               
                NSString *categoryLocalizedName = [poiTypes getPhraseByName:category];
                BOOL expanded = ![_collapsedCategories containsObject:category];
                BOOL showAll = [_showAllCategories containsObject:category];
                
                NSString *categoryIconStr = [poiTypes getPoiAdditionalCategoryIcon:category];
                UIImage *categoryIcon = nil;
                if (categoryIconStr.length > 0)
                    categoryIcon = [OAUtilities getMxIcon:categoryIconStr];
                
                if (!categoryIcon)
                    categoryIcon = [OAUtilities getMxIcon:category];
                
                if (!categoryIcon) {
                    categoryIcon = [UIImage imageNamed:@"ic_search_filter"];
                }

                categoryIcon = [OAUtilities getTintableImage:categoryIcon];
                
                groupId++;
                NSMutableArray<OAPOIFilterListItem *> *items = [NSMutableArray array];

                [items addObject:[[OAPOIFilterListItem alloc] initWithType:GROUP_HEADER icon:categoryIcon text:categoryLocalizedName groupIndex:groupId expandable:YES expanded:expanded checked:NO category:category keyName:nil]];
                
                NSMutableArray<OAPOIType *> *categoryPoiAdditionals = value;
                [categoryPoiAdditionals sortUsingComparator:^NSComparisonResult(OAPOIType * _Nonnull p1, OAPOIType * _Nonnull p2) {
                    if (p1.nameLocalized && p2.nameLocalized)
                        return [p1.nameLocalized localizedCaseInsensitiveCompare:p2.nameLocalized];
                    else
                        return NSOrderedSame;
                }];
                for (OAPOIType *poiType in categoryPoiAdditionals)
                {
                    NSString *keyName = [[poiType.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] lowerCase];
                    
                    [items addObject:[[OAPOIFilterListItem alloc] initWithType:SWITCH_ITEM icon:nil text:poiType.nameLocalized groupIndex:groupId expandable:NO expanded:NO checked:[_selectedPoiAdditionals containsObject:keyName] category:category keyName:keyName]];
                }
                if (!showAll && categoryPoiAdditionals.count > 0)
                {
                    [items addObject:[[OAPOIFilterListItem alloc] initWithType:BUTTON_ITEM icon:nil text:[OALocalizedString(@"show_all") upperCase] groupIndex:groupId expandable:NO expanded:NO checked:NO category:category keyName:nil]];
                }

                [groups setObject:items forKey:[NSNumber numberWithInt:groupId]];
            }
        }
    }
    _groups = [NSDictionary dictionaryWithDictionary:groups];
}

- (void) toggleCheckbox:(OAPOIFilterListItem *)item checkBox:(UISwitch *)checkBox isChecked:(BOOL)isChecked
{
    if (checkBox)
        [checkBox setOn:isChecked animated:YES];
    
    item.checked = isChecked;
    if (item.checked)
        [_selectedPoiAdditionals addObject:item.keyName];
    else
        [_selectedPoiAdditionals removeObject:item.keyName];

    [self updateApplyButton];
}

- (void) toggleCheckbox:(UISwitch *)checkBox
{
    [self moveGestureDetected:nil];
    
    NSInteger section = checkBox.tag >> 10;
    NSInteger row = checkBox.tag & 0x3ff;
    OAPOIFilterListItem *item = [self getItem:[NSIndexPath indexPathForRow:row inSection:section]];
    if (item && item.type == SWITCH_ITEM)
    {
        item.checked = checkBox.on;
        if (item.checked)
            [_selectedPoiAdditionals addObject:item.keyName];
        else
            [_selectedPoiAdditionals removeObject:item.keyName];
    }
    
    [self updateApplyButton];
}

- (BOOL) hasChanges
{
    return ![_nameFilterText isEqualToString:_nameFilterTextOrig] || ![_selectedPoiAdditionals isEqualToSet:_selectedPoiAdditionalsOrig];
}

- (void) updateApplyButton
{
    [self setApplyViewVisible:[self hasChanges]];
}

- (IBAction)applyButtonPress:(id)sender
{
    [self applyFilterFields];
    
    if (![_filter isStandardFilter])
    {
        [_filter setSavedFilterByName:_filter.filterByName];
        if ([_helper editPoiFilter:_filter])
        {
            if (!_delegate || [_delegate updateFilter:_filter nameFilter:@""])
                [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        if (!_delegate || [_delegate updateFilter:_filter nameFilter:[_nameFilterText trim]])
            [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)setApplyViewVisible:(BOOL)visible
{
    if (visible)
    {
        if (!_applyViewVisible)
        {
            _applyView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _applyView.bounds.size.height);
            _applyView.hidden = NO;
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height -= _applyView.bounds.size.height;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _applyView.frame = CGRectMake(0, self.view.bounds.size.height - _applyView.bounds.size.height, self.view.bounds.size.width, _applyView.bounds.size.height);
            }];
        }
        _applyViewVisible = YES;
        [self applySafeAreaMargins];
    }
    else
    {
        if (_applyViewVisible)
        {
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height = self.view.bounds.size.height - tableFrame.origin.y;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _applyView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _applyView.bounds.size.height);
            } completion:^(BOOL finished) {
                _applyView.hidden = YES;
            }];
        }
        _applyViewVisible = NO;
    }
}

#pragma mark - UITableViewDataSource

-(OAPOIFilterListItem *) getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section < 0 || indexPath.section > _groups.count - 1)
        return nil;
    
    NSMutableArray<OAPOIFilterListItem *> *items = [_groups objectForKey:[NSNumber numberWithInteger:indexPath.section]];
    
    if (!items || indexPath.row < 0 || indexPath.row > items.count - 1)
        return nil;
    
    return items[indexPath.row];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == _groups.count - 1)
        return [OAPOISearchHelper getHeightForFooter];
    else
        return 0.01;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 51.0 + [OAPOISearchHelper getHeightForHeader];
    else
        return [OAPOISearchHelper getHeightForHeader];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return _textFieldHeaderView;
    else
        return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPOIFilterListItem *item = [self getItem:indexPath];
    if (!item || item.type != SWITCH_ITEM)
        return 51.0;
    else
        return [OAIconTextSwitchCell getHeight:item.text descHidden:YES detailsIconHidden:YES cellWidth:tableView.bounds.size.width];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MAX(1, _groups.count);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray<OAPOIFilterListItem *> *items = [_groups objectForKey:[NSNumber numberWithInteger:section]];
    if (items)
        return items.count;
    else
        return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPOIFilterListItem *item = [self getItem:indexPath];
    if (!item)
        return nil;
    
    switch (item.type)
    {
        case GROUP_HEADER:
        {
            OAIconTextCollapseCell* cell;
            cell = (OAIconTextCollapseCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextCollapseCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCollapseCell" owner:self options:nil];
                cell = (OAIconTextCollapseCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(0x727272);
            }
            
            if (cell)
            {
                if (item.icon)
                {
                    cell.iconView.image = item.icon;
                    cell.iconView.hidden = NO;
                }
                else
                {
                    cell.iconView.hidden = YES;
                }
                [cell.textView setText:item.text];
                if (item.expandable)
                    cell.collapsed = !item.expanded;
                else
                    cell.rightIconView.hidden = YES;
                
            }
            return cell;
        }
        case SWITCH_ITEM:
        {
            OAIconTextSwitchCell* cell;
            cell = (OAIconTextSwitchCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextSwitchCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextSwitchCell" owner:self options:nil];
                cell = (OAIconTextSwitchCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(0x727272);
                cell.descView.hidden = YES;
                cell.detailsIconView.hidden = YES;
            }
            
            if (cell)
            {
                [cell.switchView removeTarget:self action:@selector(toggleCheckbox:) forControlEvents:UIControlEventValueChanged];
                cell.switchView.tag = (indexPath.section << 10) + indexPath.row;
                [cell.switchView addTarget:self action:@selector(toggleCheckbox:) forControlEvents:UIControlEventValueChanged];
                if (item.icon)
                {
                    cell.iconView.image = item.icon;
                    cell.iconView.hidden = NO;
                }
                else
                {
                    cell.iconView.hidden = YES;
                }
                [cell.textView setText:item.text];
                cell.switchView.on = item.checked;
            }
            return cell;
        }
        case BUTTON_ITEM:
        {
            OAIconButtonCell* cell;
            cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconButtonCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconButtonCell" owner:self options:nil];
                cell = (OAIconButtonCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(0x727272);
                cell.arrowIconView.hidden = YES;
            }
            
            if (cell)
            {
                if (item.icon)
                {
                    cell.iconView.image = item.icon;
                    cell.iconView.hidden = NO;
                }
                else
                {
                    cell.iconView.hidden = YES;
                }
                [cell.textView setText:item.text];
            }
            return cell;
        }
        default:
            return nil;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self moveGestureDetected:nil];
    
    OAPOIFilterListItem *item = [self getItem:indexPath];
    if (!item)
        return;
    
    switch (item.type)
    {
        case GROUP_HEADER:
        {
            if (item.category)
            {
                if ([_collapsedCategories containsObject:item.category])
                    [_collapsedCategories removeObject:item.category];
                else
                    [_collapsedCategories addObject:item.category];
                
                [self updateGroups];
                [tableView reloadData];
            }
            break;
        }
        case SWITCH_ITEM:
        {
            OAIconTextSwitchCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                UISwitch *switchView = cell.switchView;
                [self toggleCheckbox:item checkBox:switchView isChecked:!switchView.on];
            }
            break;
        }
        case BUTTON_ITEM:
        {
            if (item.category)
            {
                [_showAllCategories addObject:item.category];
                [self updateGroups];
                [tableView reloadData];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    switch (actionSheet.tag)
    {
        case EMenuStandard:
            if ([self hasChanges])
                [self applyFilterFields];
            if (self.delegate && [self.delegate saveFilter:_filter])
                [self.navigationController popViewControllerAnimated:YES];
            
            break;
            
        case EMenuCustom:
            if (buttonIndex == actionSheet.destructiveButtonIndex)
            {
                [self deleteFilter];
            }
            else if (buttonIndex == 1)
            {
                [self editCategories];
            }
            else if (buttonIndex == 2)
            {
                if ([self hasChanges])
                    [self applyFilterFields];
                if (self.delegate && [self.delegate saveFilter:_filter])
                    [self.navigationController popViewControllerAnimated:YES];
            }
            break;
            
        case EMenuDelete:
            if (buttonIndex == actionSheet.destructiveButtonIndex)
            {
                if (self.delegate && [self.delegate removeFilter:_filter])
                    [self.navigationController popViewControllerAnimated:YES];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
