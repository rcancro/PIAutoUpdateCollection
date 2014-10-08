//
//  UICollectionView+CBLAutoUpdate.h
//  SDTableViewCommand
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "CBLAutoUpdateCommand.h"
#import "CBLAutoUpdateProtocols.h"

typedef void (^CBLUpdateCollectionViewDataBlock)();

@interface UICollectionView(CBLAutoUpdate)<CBLAutoUpdateableCollectionView>

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateCollectionViewDataBlock)updateBlock;
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateCollectionViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock;

@end
