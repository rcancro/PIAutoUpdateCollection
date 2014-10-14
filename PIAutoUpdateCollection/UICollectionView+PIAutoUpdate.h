//
//  UICollectionView+PIAutoUpdate.h
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

@import UIKit;

#import "PIAutoUpdateCommand.h"
#import "PIAutoUpdateProtocols.h"

typedef void (^PIUpdateCollectionViewDataBlock)();

@interface UICollectionView(PIAutoUpdate)<PIAutoUpdateableCollectionView>

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource updateBlock:(PIUpdateCollectionViewDataBlock)updateBlock;
- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource updateBlock:(PIUpdateCollectionViewDataBlock)updateBlock commandCallbackblock:(PIAutoUpdateCommandCallbackBlock)commandCallbackBlock;

@end
