//
//  UICollectionView+PIAutoUpdate.m
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "UICollectionView+PIAutoUpdate.h"

@implementation UICollectionView(PIAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource updateBlock:(PIUpdateCollectionViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource updateBlock:(PIUpdateCollectionViewDataBlock)updateBlock commandCallbackblock:(PIAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    [PIAutoUpdateCommandManager runCommandsWithAutoUpdateDataSource:updateDataSource
                                                autoUpdateableObject:self
                                                         updateBlock:updateBlock
                                                commandCallbackblock:commandCallbackBlock];
}

#pragma mark - PIAutoUpdateableObject

- (void)runAutoUpdateCommandBlock:(PIAutoUpdateRunCommandsBlock)block
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
