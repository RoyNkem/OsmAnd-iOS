//
//  OAFavoriteListDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OADestinationItemsListViewController.h"

@class OAFavoriteItem;

@interface OAFavoriteListDialogView : UIView

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<OADestinationPointListDelegate> delegate;

@property (nonatomic) NSUInteger sortingType;

- (instancetype) initWithFrame:(CGRect)frame sortingType:(int)sortingType;

- (void) switchSorting;

@end
