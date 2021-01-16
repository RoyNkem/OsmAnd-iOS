//
//  OABaseTableViewViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@interface OABaseTableViewViewController : OACompoundViewController

@property (strong, nonatomic) IBOutlet UIView *navbarView;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end
