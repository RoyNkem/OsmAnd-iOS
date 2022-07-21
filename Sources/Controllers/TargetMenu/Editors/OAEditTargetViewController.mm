//
//  OAEditTargetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditTargetViewController.h"
#import "OsmAndApp.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OAEditDescriptionViewController.h"
#import "OADefaultFavorite.h"
#import "OATargetInfoCollapsableViewCell.h"
#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OACollapsableWaypointsView.h"
#import <UIAlertView+Blocks.h>
#import "OAColors.h"
#import "OAColorViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OATextViewTableViewCell.h"
#import "OATextMultiViewCell.h"
#import "OAGPXWptViewController.h"
#import "OAFavoriteViewController.h"
#import "OATargetInfoViewCell.h"
#import "OAGPXWptViewController.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OATargetInfoViewController.h"
#import "OrderedDictionary.h"

#include "Localization.h"

@interface OAEditTargetViewController () <OAEditColorViewControllerDelegate, OAEditGroupViewControllerDelegate, OAEditDescriptionViewControllerDelegate, UITextFieldDelegate>

@end

@implementation OAEditTargetViewController
{
    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;
    
    CGFloat _descHeight;
    BOOL _descSingleLine;
    CGFloat dy;
    
    BOOL _backButtonPressed;
    BOOL _editNameFirstTime;
    
    BOOL _askPreHide;
    
    NSMutableArray<NSDictionary *> *_data;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;
@synthesize keyboardSize = _keyboardSize;
@synthesize topToolbarType = _topToolbarType;

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL) needAddress
{
    return NO;
}

- (NSString *)getTypeStr
{
    NSString *group = [self getItemGroup];
    if (group.length > 0)
    {
        return group;
    }
    else
    {
        return [self getCommonTypeStr];
    }
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"gpx_point");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return [self getAttributedTypeStr:[self getTypeStr]];
}

- (NSAttributedString *) getAttributedCommonTypeStr
{
    return [self getAttributedTypeStr:[self getCommonTypeStr]];
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return self.newItem || self.editing ? ETopToolbarTypeFixed : _topToolbarType;
}

- (BOOL) supportFullScreen
{
    return YES;
}

- (BOOL) supportEditing
{
    return YES;
}

- (void) activateEditing
{
    if (self.editing)
        return;
    
    _editing = YES;
    _editNameFirstTime = YES;
    
    if (![self isViewLoaded])
        return;
    
    [self setupView];
    [self generateData];
    [self.tableView reloadData];
    
    if (self.delegate)
        [self.delegate contentHeightChanged:[self contentHeight]];
}

- (void) deleteItem
{
    // override
}

- (NSString *) getItemName
{
    return nil; // override
}

- (void) setItemName:(NSString *)name
{
    // override
}

- (BOOL) isItemExists:(NSString *)name
{
    return NO;
}

- (void) saveItemToStorage
{
    // override
}

- (void) removeExistingItemFromCollection
{
    // override
}

- (void) removeNewItemFromCollection
{
    // override
}

- (UIColor *) getItemColor
{
    return nil; // override
}

- (void) setItemColor:(UIColor *)color
{
    // override
}

- (NSString *) getItemGroup
{
    return nil; // override
}

- (void) setItemGroup:(NSString *)groupName
{
    // override
}

- (NSArray *) getItemGroups
{
    return nil; // override
}

- (NSString *) getItemDesc
{
    return nil; // override
}

- (void) setItemDesc:(NSString *)desc
{
    // override
}

- (void) cancelPressed
{
    _backButtonPressed = YES;
    
    // back / cancel
    if (self.newItem)
    {
        [self removeNewItemFromCollection];
    }
    else
    {
        if (_wasEdited)
        {
            [self doSave];
        }
        else if (self.delegate)
        {
            [self.delegate btnCancelPressed];
        }
    }
}

- (void) okPressed
{
    _backButtonPressed = NO;

    // save
    [self doSave];
}

- (void) processButtonPress
{
    if (!_askPreHide)
    {
        if (_backButtonPressed)
        {
            if (self.delegate)
                [self.delegate btnCancelPressed];
        }
        else
        {
            if (self.delegate)
                [self.delegate btnOkPressed];
        }
    }
    
    _backButtonPressed = NO;
}

- (CGFloat) contentHeight
{
    return ([self.tableView numberOfRowsInSection:0] - 1) * 44.0 + _descHeight + dy + (_collapsableGroupView.collapsed ? 0 : _collapsableGroupView.frame.size.height) + (_collapsableCoordinatesView.collapsed ? 0 : _collapsableCoordinatesView.frame.size.height);
}

- (IBAction) deletePressed:(id)sender
{
    if (self.editing || ![self supportEditing])
        [self deleteItem];
    else
        [self activateEditing];
}

- (id) initWithItem:(id)item
{
    self = [super init];
    if (self)
    {
        self.newItem = NO;
        self.savedColorIndex = -1;
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation
{
    self = [super init];
    if (self)
    {
        self.name = formattedLocation;
        self.desc = @"";
        self.savedColorIndex = -1;
        self.location = location;
        self.newItem = YES;        
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.buttonOK setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    dy = 0.0;
    
    [self setupView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;    
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0xffffff);
    self.tableView.backgroundView = view;
    self.tableView.scrollEnabled = NO;

    [self registerForKeyboardNotifications];
    [self generateData];
}

- (void) dealloc
{
    [self unregisterKeyboardNotifications];
}

- (void) setupColor
{
    if (self.newItem && _colorController)
    {
        self.savedColorIndex = _colorController.colorIndex;
    }
}

- (void) setupGroup
{
    if (self.newItem && _groupController)
    {
        self.savedGroupName = _groupController.groupName;
    }
}

- (void) setupDeleteButtonIcon
{
    if (self.editing)
        [self.deleteButton setImage:[UIImage imageNamed:@"icon_remove"] forState:UIControlStateNormal];
    else
        [self.deleteButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
}

- (void) setupView
{
    CGSize s = [OAUtilities calculateTextBounds:self.desc width:self.tableView.bounds.size.width - 38.0 font:[UIFont systemFontOfSize:14.0]];
    CGFloat h = MIN(188.0, s.height + 10.0);
    h = MAX(44.0, h);
    
    _descHeight = h;
    _descSingleLine = (s.height < 24.0);
    
    if (self.newItem)
    {
        [self.buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
        [self.buttonCancel setImage:nil forState:UIControlStateNormal];
        [self.buttonCancel setTintColor:[UIColor whiteColor]];
        self.buttonCancel.titleEdgeInsets = UIEdgeInsetsZero;
        self.buttonCancel.imageEdgeInsets = UIEdgeInsetsZero;
        self.buttonOK.hidden = NO;
        self.deleteButton.hidden = YES;
    }
    else
    {
        [self.buttonCancel setImage:[UIImage templateImageNamed:@"ic_navbar_chevron.png"] forState:UIControlStateNormal];
        [self.buttonCancel setTintColor:[UIColor whiteColor]];
        self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        self.buttonOK.hidden = YES;
        self.deleteButton.hidden = ![self supportEditing];
    }

    [self setupDeleteButtonIcon];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    NSArray<OAGpxExtension *> *extensions;
    
    if ([self hasDescription])
    {
        [_data addObject:@{
            @"type" : [OATextMultiViewCell getCellIdentifier],
            @"label" : self.desc,
            @"placeholder" : OALocalizedString(@"enter_description"),
        }];
    }

    if ([self isKindOfClass:OAFavoriteViewController.class])
    {
        extensions = [((OAFavoriteViewController *)self).favorite getExtensions];
        [_data addObject:@{
            @"type" : [OATargetInfoCollapsableViewCell getCellIdentifier],
            @"label" : self.groupTitle,
            @"description" : OALocalizedString(@"all_group_points"),
            @"iconName" : @"ic_custom_folder",
            @"iconColor" : self.groupColor ? self.groupColor : ((OAFavoriteColor *)OADefaultFavorite.builtinColors.firstObject).color
        }];
        
        NSDate *date = [((OAFavoriteViewController *)self) getTimestamp];
        NSString *dateText = [self dateToString:date];
        if (dateText)
        {
            [_data addObject:@{
                @"type" : [OATargetInfoViewCell getCellIdentifier],
                @"label" : dateText,
                @"iconName" : @"ic_custom_date",
            }];
        }
    }
    else if ([self isKindOfClass:OAGPXWptViewController.class])
    {
        extensions = ((OAGPXWptViewController *)self).wpt.point.extensions;
        NSString *groupName = self.groupTitle;
        if (!groupName)
            groupName = [((OAGPXWptViewController *)self) getGpxFileName];
        
        [_data addObject:@{
            @"type" : [OATargetInfoCollapsableViewCell getCellIdentifier],
            @"label" : groupName ? groupName : @"",
            @"description" : OALocalizedString(@"all_group_points"),
            @"iconName" : @"ic_custom_folder",
            @"iconColor" : [self getItemColor]
        }];
        
        NSDate *date = [((OAGPXWptViewController *)self) getTimestamp];
        NSString *dateText = [self dateToString:date];
        if (dateText)
        {
            [_data addObject:@{
                @"type" : [OATargetInfoViewCell getCellIdentifier],
                @"label" : dateText,
                @"iconName" : @"ic_custom_date",
            }];
        }
    }
    
    [_data addObject:@{
        @"type" : [OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier],
        @"lat" : [NSNumber numberWithFloat:self.location.latitude],
        @"lon" : [NSNumber numberWithFloat:self.location.longitude]
    }];
    
    if (extensions && extensions.count > 0)
    {
        //collect and merge POI extensions data
        NSArray<NSString *> *osmandTags = @[@"color", @"background", @"icon"];
        MutableOrderedDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *combinedExtensions = [MutableOrderedDictionary dictionary];
        for (OAGpxExtension *extension in extensions)
        {
            if (![osmandTags containsObject:extension.name] && extension.name.length > 0 && extension.value.length > 0)
            {
                if ([extension.name hasSuffix:@"_label"])
                {
                    NSString *key = [extension.name stringByReplacingOccurrencesOfString:@"_label" withString:@""];
                    if (!combinedExtensions[key])
                        combinedExtensions[key] = [NSMutableDictionary dictionary];
                    combinedExtensions[key][@"label"] = extension.value;
                }
                else if ([extension.name hasSuffix:@"_icon"])
                {
                    NSString *key = [extension.name stringByReplacingOccurrencesOfString:@"_icon" withString:@""];
                    if (!combinedExtensions[key])
                        combinedExtensions[key] = [NSMutableDictionary dictionary];
                    combinedExtensions[key][@"iconName"] = extension.value;
                }
            }
        }
        
        //check and add to tableView data
        for (NSString *key in combinedExtensions.allKeys)
        {
            NSString *label = combinedExtensions[key][@"label"];
            NSString *iconName = combinedExtensions[key][@"iconName"] ? combinedExtensions[key][@"iconName"] : @"ic_custom_poi";
            if (label && label.length > 0)
            {
                [_data addObject:@{
                    @"type" : [OATargetInfoViewCell getCellIdentifier],
                    @"key" : key,
                    @"label" : combinedExtensions[key][@"label"],
                    @"iconName" : combinedExtensions[key][@"iconName"] ? combinedExtensions[key][@"iconName"] : @"ic_custom_poi"
                }];
            }
        }
    }
}

- (NSString *)dateToString:(NSDate *)date
{
    if (date)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        return [dateFormatter stringFromDate:date];
    }
    return nil;
}

- (void) setupCollapableViewsWithData:(id)data lat:(double)lat lon:(double)lon
{
    OACollapsableWaypointsView *collapsableGroupView = [[OACollapsableWaypointsView alloc] init];
    [collapsableGroupView setData:data];
    collapsableGroupView.collapsed = YES;
    self.collapsableGroupView = collapsableGroupView;

    OACollapsableCoordinatesView *collapsableCoordinatesView = [[OACollapsableCoordinatesView alloc] initWithFrame:CGRectMake(0, 0, 320, 100) lat:lat lon:lon];
    collapsableCoordinatesView.collapsed = YES;
    self.collapsableCoordinatesView = collapsableCoordinatesView;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// keyboard notifications register+process
- (void) registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void) unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void) keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    _keyboardSize = kbSize;
    _showingKeyboard = YES;

    if (self.delegate)
        [self.delegate keyboardWasShown:kbSize.height];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void) keyboardWillBeHidden:(NSNotification*)aNotification
{
    _showingKeyboard = NO;
    _keyboardSize = CGSizeZero;

    if (self.delegate)
        [self.delegate keyboardWasHidden:self.keyboardSize.height];
}

-(BOOL) commitChangesAndExit
{
    if (_wasEdited)
    {
        return [self doSave];
    }
    else
    {
        [self doExit];
        return YES;
    }
}

- (BOOL) preHide
{
    _askPreHide = YES;
    
    if (self.wasEdited)
        return [self commitChangesAndExit];
    return YES;
}

- (NSString *) getNewItemName:(NSString *)name
{
    NSString *newName;
    for (int i = 2; i < 100000; i++) {
        newName = [NSString stringWithFormat:@"%@_%d", name, i];
        if (![self isItemExists:newName])
            break;
    }
    return newName;
}

- (BOOL) doSave
{
    if (self.name)
        [self setItemName:(self.name)];
    
    NSString *title = [self getItemName];
    
    if ([self isItemExists:title])
    {
        NSString *newName = [self getNewItemName:title];
        
        [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), title] cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems:
          [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"add_as"), newName] action:^{
            [self setItemName:newName];
            [self saveAndExit];
        }],
          [RIButtonItem itemWithLabel:OALocalizedString(@"fav_replace") action:^{
            [self removeExistingItemFromCollection];
            [self saveAndExit];
        }],
          nil] show];
        
        return NO;
    }
    
    [self saveAndExit];
    
    return YES;
}

- (void) saveAndExit
{
    [self saveItemToStorage];
    [self doExit];
}

- (void) doExit
{
    _editing = NO;
    _wasEdited = NO;
    
    [self processButtonPress];

    _askPreHide = NO;
}

- (void) changeColorClicked
{
    _colorController = [[OAEditColorViewController alloc] initWithColor:[self getItemColor]];
    _colorController.delegate = self;
    [self.navController pushViewController:_colorController animated:YES];
}

- (void) changeGroupClicked
{
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:[self getItemGroup] groups:[self getItemGroups]];
    _groupController.delegate = self;
    [self.navController pushViewController:_groupController animated:YES];
}

- (void) changeDescriptionClicked
{
    OAEditDescriptionViewController *editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:self.desc isNew:self.newItem isEditing:NO readOnly:YES];
    editDescController.delegate = self;
    [self.navController pushViewController:editDescController animated:YES];
}

- (void) editFavName:(id)sender
{
    _wasEdited = YES;
    self.name = [((UITextField*)sender) text];
}

- (BOOL) hasDescription
{
    return [self supportEditing] && self.desc.length > 0;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OATextViewTableViewCell getCellIdentifier]])
    {
        OATextViewTableViewCell* cell;
        cell = (OATextViewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATextViewTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:item[@"label"]];
            [cell.textView setPlaceholder:item[@"placeholder"]];
            [cell.textView removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.textView addTarget:self action:NSSelectorFromString(item[@"selector"]) forControlEvents:UIControlEventEditingChanged];
            [cell.textView setDelegate:self];
            
            cell.textView.backgroundColor = UIColorFromRGB(0xffffff);
            cell.backgroundColor = UIColorFromRGB(0xffffff);
            return cell;
        }
    }
    else if ([item[@"type"] isEqualToString:[OAColorViewCell getCellIdentifier]])
    {
        OAColorViewCell* cell;
        cell = (OAColorViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAColorViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAColorViewCell *)[nib objectAtIndex:0];
            cell.colorIconView.layer.cornerRadius = cell.colorIconView.frame.size.width / 2;
        }
        OAFavoriteColor *favCol = item[@"color"];
        [cell.textView setText: item[@"label"]];
        [cell.descriptionView setText:favCol.name];
        cell.backgroundColor = UIColorFromRGB(0xffffff);
        cell.colorIconView.backgroundColor = favCol.color;
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoViewCell getCellIdentifier]])
    {
        OATargetInfoViewCell* cell;
        cell = (OATargetInfoViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATargetInfoViewCell *)[nib objectAtIndex:0];
        }
        cell.backgroundColor = UIColorFromRGB(0xffffff);
        cell.iconView.image = [[OATargetInfoViewController getIcon:item[@"iconName"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        
        cell.textView.text = item[@"label"];
        if([item[@"key"] isEqualToString:@"website"] || [item[@"key"] isEqualToString:@"phone"] || [item[@"label"] hasPrefix:@"http"])
            cell.textView.textColor = UIColorFromRGB(color_primary_light_blue);
        else
            cell.textView.textColor = UIColor.blackColor;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell;
        cell = (OAIconTitleValueCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }

        [cell showLeftIcon:NO];
        [cell.textView setText: item[@"label"]];
        [cell.descriptionView setText: item[@"description"]];
        cell.backgroundColor = UIColorFromRGB(0xffffff);
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextMultiViewCell getCellIdentifier]])
    {
        OATextMultiViewCell* cell;
        cell = (OATextMultiViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATextMultiViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultiViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultiViewCell *)[nib objectAtIndex:0];
        }
        
        NSString *label = item[@"label"];
        if (label.length == 0)
        {
            cell.textView.font = [UIFont systemFontOfSize:16.0];
            cell.textView.textContainerInset = UIEdgeInsetsMake(11,11,0,0);
            cell.textView.text = item[@"placeholder"];
            cell.textView.textColor = [UIColor lightGrayColor];
            cell.iconView.hidden = NO;
        }
        else
        {
            cell.textView.font = [UIFont systemFontOfSize:14.0];
            
            if (_descSingleLine)
                cell.textView.textContainerInset = UIEdgeInsetsMake(12,11,0,35);
            else if (_descHeight > 44.0)
                cell.textView.textContainerInset = UIEdgeInsetsMake(5,11,0,35);
            else
                cell.textView.textContainerInset = UIEdgeInsetsMake(3,11,0,35);
            
            cell.textView.textColor = [UIColor blackColor];
            cell.textView.text = label;
            cell.iconView.hidden = NO;
        }
        cell.textView.backgroundColor = UIColorFromRGB(0xffffff);
        cell.backgroundColor = UIColorFromRGB(0xffffff);
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableViewCell getCellIdentifier]])
    {
        OATargetInfoCollapsableViewCell* cell;
        cell = (OATargetInfoCollapsableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATargetInfoCollapsableViewCell *)[nib objectAtIndex:0];
        }
        cell.iconView.contentMode = UIViewContentModeCenter;
        
        [cell setImage:[UIImage templateImageNamed:item[@"iconName"]]];
        cell.iconView.tintColor = item[@"iconColor"];
        cell.textView.text = item[@"label"];
        cell.descrLabel.hidden = NO;
        cell.descrLabel.text = item[@"description"];
        [cell setDescription:item[@"description"]];

        cell.collapsableView = self.collapsableGroupView;
        [cell setCollapsed:self.collapsableGroupView.collapsed rawHeight:64.];

        if ([cell needsUpdateConstraints])
            [cell updateConstraints];

        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]])
    {
        OATargetInfoCollapsableCoordinatesViewCell* cell;
        cell = (OATargetInfoCollapsableCoordinatesViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]];
        
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATargetInfoCollapsableCoordinatesViewCell *)[nib objectAtIndex:0];
        }
        
        [cell setupCellWithLat:[item[@"lat"] floatValue] lon:[item[@"lon"] floatValue]];
        cell.collapsableView = self.collapsableCoordinatesView;
        [cell setCollapsed:self.collapsableCoordinatesView.collapsed rawHeight:64.];
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextMultiViewCell getCellIdentifier]])
        return _descHeight;
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableViewCell getCellIdentifier]])
        return 64. + (self.collapsableGroupView.collapsed ? 0. : self.collapsableGroupView.frame.size.height);
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]])
        return 48. + (self.collapsableCoordinatesView.collapsed ? 0. : self.collapsableCoordinatesView.frame.size.height + 16.);
    else
        return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextViewTableViewCell getCellIdentifier]])
    {
    }
    else if ([item[@"type"] isEqualToString:[OAColorViewCell getCellIdentifier]])
    {
        if ([self supportEditing])
            [self changeColorClicked];
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        if ([self supportEditing])
            [self changeGroupClicked];
    }
    else if ([item[@"type"] isEqualToString:[OATextMultiViewCell getCellIdentifier]])
    {
        [self changeDescriptionClicked];
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableViewCell getCellIdentifier]])
    {
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:OATargetInfoCollapsableViewCell.class])
        {
            self.collapsableGroupView.collapsed = !self.collapsableGroupView.collapsed;
            [self.collapsableGroupView adjustHeightForWidth:tableView.frame.size.width];
            if (self.delegate)
                [self.delegate contentHeightChanged];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]])
    {
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:OATargetInfoCollapsableCoordinatesViewCell.class])
        {
            self.collapsableCoordinatesView.collapsed = !self.collapsableCoordinatesView.collapsed;
            [self.collapsableCoordinatesView adjustHeightForWidth:tableView.frame.size.width];
            if (self.delegate)
                [self.delegate contentHeightChanged];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else if ([item[@"type"] isEqualToString:[OATargetInfoViewCell getCellIdentifier]])
    {
        NSString *key = item[@"key"];
        NSString *value = item[@"label"];
        if (key && key.length > 0 && value && value.length > 0)
        {
            if([key isEqualToString:@"website"] || [value hasPrefix:@"http"])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:value] options:@{} completionHandler:nil];
            }
            else if ([key isEqualToString:@"phone"])
            {
                NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", value]];
                [[UIApplication sharedApplication] openURL:phoneURL options:@{} completionHandler:nil];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:))
        [[UIPasteboard generalPasteboard] setString:_data[indexPath.row][@"label"]];
}

#pragma mark - OAEditColorViewControllerDelegate

- (void) colorChanged
{
    OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][_colorController.colorIndex];
    [self setItemColor:favCol.color];
    
    _wasEdited = YES;
    [self setupColor];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAEditGroupViewControllerDelegate

- (void) groupChanged
{
    [self setItemGroup:_groupController.groupName];
    self.groupTitle = _groupController.groupName;
    
    _wasEdited = YES;
    [self setupGroup];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAEditDescriptionViewControllerDelegate

- (void) descriptionChanged:(NSString *)descr
{
    _wasEdited = YES;
    
    self.desc = descr;
    [self setItemDesc:self.desc];
    
    [self setupView];
    [self generateData];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate contentHeightChanged:[self contentHeight]];
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.newItem && _editNameFirstTime)
    {
        [textField selectAll:nil];
    }
    _editNameFirstTime = NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [self setItemName:self.name];
    [self saveItemToStorage];
    
    [sender resignFirstResponder];
    return YES;
}

@end
