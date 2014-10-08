//
//  UICollectionView+CBLAutoUpdate.m
//  SDTableViewCommand
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "UICollectionView+CBLAutoUpdate.h"

@implementation UICollectionView(CBLAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateCollectionViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateCollectionViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    [CBLAutoUpdateCommandManager runCommandsWithAutoUpdateDataSource:updateDataSource
                                                autoUpdateableObject:self
                                                         updateBlock:updateBlock
                                                commandCallbackblock:commandCallbackBlock];
}

#pragma mark - CBLAutoUpdateableObject

- (void)runAutoUpdateCommandBlock:(CBLAutoUpdateRunCommandsBlock)block
{
    [self performBatchUpdates:^{
        block();
    } completion:nil];
}

- (void)removeSections:(NSIndexSet *)sections
{
    [self deleteSections:sections];
}

// insertSections is already implemented by UICollectionView

- (void)removeItems:(NSArray *)indexPaths
{
    [self deleteItemsAtIndexPaths:indexPaths];
}

- (void)insertItems:(NSArray *)indexPaths
{
    [self insertItemsAtIndexPaths:indexPaths];
}

- (void)refreshItems:(NSArray *)indexPaths
{
    [self reloadItemsAtIndexPaths:indexPaths];
}

@end
