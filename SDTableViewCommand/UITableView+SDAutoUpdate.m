//
//  UITableView+SDAutoUpdate.m
//
//  Created by ricky cancro on 4/22/14.
//

#import "UITableView+SDAutoUpdate.h"

#pragma mark - NSString(SDTableSectionObject)
@implementation NSString(SDTableSectionProtocol)

- (NSString *)identifier
{
    return self;
}

@end


#pragma mark - UITableView(SDAutoUpdate)
@implementation UITableView(SDAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource updateBlock:(SDUpdateTableDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:UITableViewRowAnimationAutomatic updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(SDUpdateTableDataBlock)updateBlock;
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:animationType updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(SDUpdateTableDataBlock)updateBlock commandCallbackblock:(SDTableCommandCallbackBlock)commandCallbackBlock
{
    // get the data that is about to be updated
    NSArray *outdatedSections = [[updateDataSource sectionsForPass:kSDTableViewAutoUpdatePassBeforeUpdate] copy];
    NSMutableDictionary *outdatedRowData = [NSMutableDictionary dictionary];
    
    for (id<SDTableSectionProtocol> section in outdatedSections)
    {
        outdatedRowData[section.identifier] = [[updateDataSource rowsForSection:section pass:kSDTableViewAutoUpdatePassBeforeUpdate] copy];
    }
    
    // call the block to update the table's underlying data
    if (updateBlock)
    {
        updateBlock();
    }
    
    // get the new state of the table
    NSArray *updatedSections = [[updateDataSource sectionsForPass:kSDTableViewAutoUpdatePassAfterUpdate] copy];
    NSMutableDictionary *updatedRowData = [NSMutableDictionary dictionary];
    
    for (id<SDTableSectionProtocol> section in updatedSections)
    {
        updatedRowData[section.identifier] = [[updateDataSource rowsForSection:section pass:kSDTableViewAutoUpdatePassAfterUpdate] copy];
    }
    
    
    SDTableCommandManager *manager = [[SDTableCommandManager alloc] initWithOutdatedSections:outdatedSections updatedSections:updatedSections];
    
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
