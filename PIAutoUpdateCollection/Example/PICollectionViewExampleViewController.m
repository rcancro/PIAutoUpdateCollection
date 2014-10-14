//
//  PICollectionViewExampleViewController.m
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "PICollectionViewExampleViewController.h"
#import "UICollectionView+PIAutoUpdate.h"
#import "UIColor+PIAdditions.h"

static NSString * const kCollectionViewCellReuseIdentifier = @"PICell";

@interface PICollectionViewExampleViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, PIAutoUpdateDataSource>
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionBarButton;
@property (nonatomic, strong) NSMutableSet *selectedRows;
@end

@implementation PICollectionViewExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.allowsMultipleSelection = YES;
}

#pragma mark - actions

- (IBAction)clearSelection:(id)sender
{
    self.selectedRows = [NSMutableSet set];
    [self.collectionView reloadData];
}

- (void)deleteSelectedRowsAction:(id)sender
{
    __weak PICollectionViewExampleViewController *weakSelf = self;
    [self.collectionView updateWithAutoUpdateDataSource:self updateBlock:^{
        PICollectionViewExampleViewController *strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf.selectedRows allObjects];
        for (NSIndexPath *indexPath in [selectedRows deleteFriendlySortedArray])
        {
            NSDictionary *sectionData = [strongSelf.data objectAtIndex:indexPath.section];
            NSMutableArray *itemData = sectionData[kDataKey];
            [itemData removeObjectAtIndex:indexPath.item];
            
            // if this is the last row, remove the section
            if ([itemData count] == 0)
            {
                [strongSelf.data removeObjectAtIndex:indexPath.section];
            }
        }
        strongSelf.selectedRows = [NSMutableSet set];
        [strongSelf setupActionButton];
    }];
}


- (void)addRowAction:(id)sender
{
    __weak PICollectionViewExampleViewController *weakSelf = self;
    [self.collectionView updateWithAutoUpdateDataSource:self updateBlock:^{
        PICollectionViewExampleViewController *strongSelf = weakSelf;
        // insert the new row
        NSUInteger sectionIndex = rand() % [strongSelf numberOfSectionsInCollectionView:strongSelf.collectionView];
        NSUInteger rowIndex = rand() % [strongSelf collectionView:strongSelf.collectionView numberOfItemsInSection:sectionIndex];
        
        NSDictionary *sectionData = [strongSelf.data objectAtIndex:sectionIndex];
        NSMutableArray *itemData = [sectionData objectForKey:kDataKey];
        
        UIColor *color = [UIColor randomColor];
        [itemData insertObject:color atIndex:rowIndex];
        [self setupActionButton];
    }];
}

#pragma mark - PIAutoUpdateDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.data count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSDictionary *sectionData = [self.data objectAtIndex:section];
    NSArray *rowData = sectionData[kDataKey];
    return [rowData count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    NSDictionary *sectionData = [self.data objectAtIndex:indexPath.section];
    NSArray *rowData = sectionData[kDataKey];
    cell.backgroundColor = [rowData objectAtIndex:indexPath.item];
    cell.selected = [self.selectedRows containsObject:indexPath];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PISimpleHeader" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[reusableview viewWithTag:1234];
        
        NSDictionary *sectionData = [self.data objectAtIndex:indexPath.section];
        label.text = sectionData[kSectionTitleKey];
    }
    return reusableview;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedRows addObject:indexPath];
    [self setupActionButton];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedRows removeObject:indexPath];
    [self setupActionButton];
}

#pragma mark - PIAutoUpdateDataSource

- (NSArray *)sectionsForPass:(PIAutoUpdatePass)pass
{
    return [self.data valueForKey:kSectionTitleKey];
}

- (NSArray *)itemsForSection:(id<PIAutoUpdateSectionProtocol>)section pass:(PIAutoUpdatePass)pass
{
    NSDictionary *sectionData = nil;
    for (NSDictionary *collectionSection in self.data)
    {
        if ([collectionSection[kSectionTitleKey] isEqualToString:[section identifier]])
        {
            sectionData = collectionSection;
            break;
        }
    }
    return sectionData[kDataKey];
}

@end
