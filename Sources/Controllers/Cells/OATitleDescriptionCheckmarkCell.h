//
//  OATitleDescriptionCheckmarkCell.h
//  OsmAnd
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleDescriptionCheckmarkCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet UIButton *openCloseGroupButton;

@end
