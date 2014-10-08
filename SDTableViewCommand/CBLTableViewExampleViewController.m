//
//  SDFirstViewController.m
//  SDTableViewCommand
//
//  Created by ricky cancro on 2/9/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "CBLTableViewExampleViewController.h"
#import "CBLAutoUpdateCommand.h"
#import "UITableView+CBLAutoUpdate.h"
#import "CBLAutoUpdateProtocols.h"
#import "UIColor+CBLAdditions.h"

typedef void (^TableModelChangeBlock)();
static NSString * const kDefaultCellIdentifier = @"CBLTableCell";
static CGFloat const kOverlayViewTag = 1234;

@interface CBLTableViewExampleViewController ()<UITableViewDataSource, UITableViewDelegate, CBLAutoUpdateDataSource>
@end

@implementation CBLTableViewExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
}
                                                      
#pragma mark - actions

- (IBAction)clearSelection:(id)sender
{
    self.selectedRows = [NSMutableSet set];
    [self.tableView reloadData];
}

- (void)deleteSelectedRowsAction:(id)sender
{
    __weak CBLTableViewExampleViewController *weakSelf = self;
    [self.tableView updateWithAutoUpdateDataSource:self updateBlock:^{
        CBLTableViewExampleViewController *strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf.selectedRows allObjects];
        for (NSIndexPath *indexPath in [selectedRows deleteFriendlySortedArray])
        {
            NSDictionary *sectionData = [strongSelf.data objectAtIndex:indexPath.section];
            NSMutableArray *rowData = sectionData[kDataKey];
            [rowData removeObjectAtIndex:indexPath.row];
            
            // if this is the last row, remove the section
            if ([rowData count] == 0)
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
    __weak CBLTableViewExampleViewController *weakSelf = self;
    [self.tableView updateWithAutoUpdateDataSource:self updateBlock:^{
        CBLTableViewExampleViewController *strongSelf = weakSelf;
        // insert the new row
        NSUInteger sectionIndex = rand() % [strongSelf numberOfSectionsInTableView:strongSelf.tableView];
        NSUInteger rowIndex = rand() % [strongSelf tableView:strongSelf.tableView numberOfRowsInSection:sectionIndex];
        
        NSDictionary *sectionData = [strongSelf.data objectAtIndex:sectionIndex];
        NSMutableArray *rowData = [sectionData objectForKey:kDataKey];
        
        UIColor *color = [UIColor randomColor];
        [rowData insertObject:color atIndex:rowIndex];
        [self setupActionButton];
    }];
}

#pragma mark - CBLAutoUpdateDataSource
- (NSArray *)sectionsForPass:(CBLAutoUpdatePass)pass
{
    return [self.data valueForKey:kSectionTitleKey];
}

- (NSArray *)itemsForSection:(id<CBLAutoUpdateSectionProtocol>)section pass:(CBLAutoUpdatePass)pass
{
    NSDictionary *sectionData = nil;
    for (NSDictionary *tableSection in self.data)
    {
        if ([tableSection[kSectionTitleKey] isEqualToString:[section identifier]])
        {
            sectionData = tableSection;
            break;
        }
    }
    return sectionData[kDataKey];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.data count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionData = [self.data objectAtIndex:section];
    return [sectionData[kDataKey] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
    NSDictionary *sectionData = [self.data objectAtIndex:indexPath.section];
    NSArray *rowData = sectionData[kDataKey];
    cell.contentView.backgroundColor = [rowData objectAtIndex:indexPath.row];
    cell.selected = [self.selectedRows containsObject:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionData = [self.data objectAtIndex:section];
    return sectionData[kSectionTitleKey];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedRows addObject:indexPath];
    [self setupActionButton];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedRows removeObject:indexPath];
    [self setupActionButton];
}

@end
