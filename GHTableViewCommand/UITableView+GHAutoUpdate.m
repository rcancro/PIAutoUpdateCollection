//
//  UITableView+GHAutoUpdate.m
//
//  Created by ricky cancro on 4/22/14.
//

#import "UITableView+GHAutoUpdate.h"

#pragma mark - NSString(GHTableSectionObject)
@implementation NSString(GHTableSectionProtocol)

- (NSString *)identifier
{
    return self;
}

@end


#pragma mark - UITableView(GHAutoUpdate)
@implementation UITableView(GHAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource updateBlock:(GHUpdateTableDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:UITableViewRowAnimationAutomatic updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(GHUpdateTableDataBlock)updateBlock;
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:animationType updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(GHUpdateTableDataBlock)updateBlock commandCallbackblock:(GHTableCommandCallbackBlock)commandCallbackBlock
{
    // get the data that is about to be updated
    NSArray *outdatedSections = [[updateDataSource sectionsForPass:kGHTableViewAutoUpdatePassBeforeUpdate] copy];
    NSMutableDictionary *outdatedRowData = [NSMutableDictionary dictionary];
    
    for (id<GHTableSectionProtocol> section in outdatedSections)
    {
        outdatedRowData[section.identifier] = [[updateDataSource rowsForSection:section pass:kGHTableViewAutoUpdatePassBeforeUpdate] copy];
    }
    
    // call the block to update the table's underlying data
    if (updateBlock)
    {
        updateBlock();
    }
    
    // get the new state of the table
    NSArray *updatedSections = [[updateDataSource sectionsForPass:kGHTableViewAutoUpdatePassAfterUpdate] copy];
    NSMutableDictionary *updatedRowData = [NSMutableDictionary dictionary];
    
    for (id<GHTableSectionProtocol> section in updatedSections)
    {
        updatedRowData[section.identifier] = [[updateDataSource rowsForSection:section pass:kGHTableViewAutoUpdatePassAfterUpdate] copy];
    }
    
    
    GHTableCommandManager *manager = [[GHTableCommandManager alloc] initWithOutdatedSections:outdatedSections updatedSections:updatedSections];
    
    NSMutableSet *allSectionIdentifiers = [NSMutableSet setWithArray:[outdatedRowData allKeys]];
    [allSectionIdentifiers addObjectsFromArray:[updatedRowData allKeys]];
    
    for (NSString *sectionIdentifier in allSectionIdentifiers)
    {
        [manager addCommandsForOutdatedData:outdatedRowData[sectionIdentifier] newData:updatedRowData[sectionIdentifier] forSectionIdentifier:sectionIdentifier];
    }
    
    [self beginUpdates];
    [manager runCommands:self withRowAnimation:animationType callback:commandCallbackBlock];
    [self endUpdates];
}


@end
