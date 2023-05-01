//
//  OABaseCollectionHandler.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol OACollectionCellDelegate <NSObject>

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath;
- (void)reloadCollectionData;

@end

@interface OABaseCollectionHandler : NSObject

- (instancetype)initWithData:(NSArray<NSArray *> *)data;

- (NSString *)getCellIdentifier;
- (CGSize)getItemSize;
- (UICollectionViewScrollDirection)getScrollDirection;
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection;
- (UIMenu *)getMenuForItem:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;

- (NSIndexPath *)getSelectedIndexPath;
- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath;
- (void)updateData:(NSArray<NSArray *> *)data collectionView:(UICollectionView *)collectionView;

- (NSInteger)itemsCount:(NSInteger)section;
- (UICollectionViewCell *)getCollectionViewCell:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;
- (NSInteger)sectionsCount;
- (void)onItemSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView;

@property (nonatomic, weak) id<OACollectionCellDelegate> delegate;

@end
