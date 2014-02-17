//
//  GHTableCommand.h
//  GHTableViewCommand
//
//  Created by ricky cancro on 2/9/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//


#import "GHTableViewCommand.h"

#pragma mark - GHTableCommandSectionData
@implementation GHTableCommandSectionIndexData
+ (instancetype)sectionDataWithOutdatedSections:(NSArray *)outdatedSections updatedSections:(NSArray *)updatedSections
{
    GHTableCommandSectionIndexData *data = [[GHTableCommandSectionIndexData alloc] init];
    data.outdatedSections = outdatedSections;
    data.updatedSections = updatedSections;
    return data;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"outdated Indexes:\n%@\n\nupdated Indexes:\n%@\n\n", self.outdatedSections, self.updatedSections];
}

@end

#pragma mark - NSString(GHTableSectionObject)
@implementation NSString(GHTableSectionProtocol)

- (NSString *)identifier
{
    return self;
}

@end

@implementation NSArray(NSIndexPath)
- (NSArray *)deleteFriendlySortedArray
{
    NSComparator commandSortComparator = ^NSComparisonResult(id obj1, id obj2)
    {
        NSIndexPath *indexPath1 = obj1, *indexPath2 = obj2;
        if ([obj1 isKindOfClass:[GHTableViewCommand class]])
        {
            indexPath1 = [(GHTableViewCommand *)obj1 resolvedIndexPath];
        }
        if ([obj2 isKindOfClass:[GHTableViewCommand class]])
        {
            indexPath2 = [(GHTableViewCommand *)obj2 resolvedIndexPath];
        }
        
        NSComparisonResult result = NSOrderedSame;
        if (indexPath1.section > indexPath2.section)
        {
            result = NSOrderedAscending;
        }
        else if (indexPath1.section < indexPath2.section)
        {
            result = NSOrderedDescending;
        }
        else
        {
            // ok we have the same section
            if (indexPath1.row > indexPath2.row)
            {
                result =  NSOrderedAscending;
            }
            else if (indexPath1.row < indexPath2.row)
            {
                result = NSOrderedDescending;
            }
        }
        return result;
    };
    
    return [self sortedArrayUsingComparator:commandSortComparator];
}
@end


#pragma mark - GHTableCommandRowData
@implementation GHTableCommandSectionData
- (NSString *)description
{
    return [NSString stringWithFormat:@"Section: %@\noutdated Rows: %@\nupdated Rows: %@\n", self.sectionIdentifier, self.outdatedSectionRows, self.updatedSectionRows];
}
@end

@interface GHTableCommandTableViewData()
@property (nonatomic, strong, readwrite) NSMutableDictionary *tableRows;
@end

@implementation GHTableCommandTableViewData

- (id)init
{
    self = [super init];
    if (self)
    {
        self.tableRows = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addOutdatedData:(NSArray *)data forSection:(NSString *)sectionIdentifier
{
    GHTableCommandSectionData *rowObject = self.tableRows[sectionIdentifier];
    if (!rowObject)
    {
        rowObject = [[GHTableCommandSectionData alloc] init];
        rowObject.sectionIdentifier = sectionIdentifier;
    }
    rowObject.outdatedSectionRows = data;
    [self.tableRows setObject:rowObject forKey:sectionIdentifier];
}

- (void)addUpdatedData:(NSArray *)data forSection:(NSString *)sectionIdentifier
{
    GHTableCommandSectionData *rowObject = self.tableRows[sectionIdentifier];
    if (!rowObject)
    {
        rowObject = [[GHTableCommandSectionData alloc] init];
        rowObject.sectionIdentifier = sectionIdentifier;
    }
    rowObject.updatedSectionRows = data;
    [self.tableRows setObject:rowObject forKey:sectionIdentifier];
}

- (NSString *)description
{
    NSMutableString *tableData = [NSMutableString stringWithString:@""];
    for (GHTableCommandSectionData *sectionData in [self.tableRows allValues])
    {
        [tableData appendFormat:@"%@\n", sectionData];
    }
    return tableData;
}

@end

#pragma mark - GHTableViewCommand()
@interface GHTableViewCommand()
@property (nonatomic, assign, readwrite) NSUInteger row;
@property (nonatomic, copy, readwrite) NSString * sectionIdentifier;
@property (nonatomic, assign, readwrite) GHTableCommandType commandType;

@property (nonatomic, strong,readwrite) NSIndexPath *resolvedIndexPath;

@end

#pragma mark - GHTableCommandManager
@interface GHTableCommandManager : NSObject
@property (nonatomic, strong) NSMutableArray *updateRowCommands;
@property (nonatomic, strong) NSMutableArray *removeRowCommands;
@property (nonatomic, strong) NSMutableArray *insertRowCommands;
@property (nonatomic, strong) NSMutableArray *removeSectionCommands;
@property (nonatomic, strong) NSMutableArray *insertSectionCommands;
@end

@implementation GHTableCommandManager

+ (GHTableCommandManager *)sharedInstance
{
    static GHTableCommandManager *gCommandManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        gCommandManager = [[GHTableCommandManager alloc] init];
        // Do any other initialisation stuff here
    });
    return gCommandManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _updateRowCommands = [NSMutableArray array];
        _removeRowCommands = [NSMutableArray array];
        _insertRowCommands = [NSMutableArray array];
        _removeSectionCommands = [NSMutableArray array];
        _insertSectionCommands = [NSMutableArray array];
    }
    return self;
}

- (void)runCommands:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animationType callback:(GHTableCommandCallbackBlock)callbackBlock;
{
    
    NSMutableIndexSet *insertSectionIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *insertRowIndexPaths = [NSMutableArray array];
    NSMutableIndexSet *removeSectionIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *removeRowIndexPaths = [NSMutableArray array];
    NSMutableArray *updateRowIndexPaths = [NSMutableArray array];
    
    // Sort deletions so the highest indexes are removed first.  This isn't required for the tableView update calls,
    // but if helpful for the callback in case the user is also deleting something at the same index paths
    self.removeSectionCommands = [NSMutableArray arrayWithArray:[self.removeSectionCommands deleteFriendlySortedArray]];
    self.removeRowCommands = [NSMutableArray arrayWithArray:[self.removeRowCommands deleteFriendlySortedArray]];
    
    // NOTE: All removes use indexes as if no sections or rows have been removed.  In other words if we have an section with rows:
    // A
    // B
    // C
    // and you want to remove A and B you'd used:
    //     [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    //     [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    // even though after the first delete C is actually at index 1.  Granted this is a silly case (you could put both index paths in the first call)
    // but if just providing an example.
    //
    // In this case that means we'll use the old section controller array to get section indexes for delete
    
    // remove sections
    for (GHTableViewCommand *command in self.removeSectionCommands)
    {
        [removeSectionIndexes addIndex:command.resolvedIndexPath.section];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [tableView deleteSections:removeSectionIndexes withRowAnimation:animationType];
    
    // remove rows
    for (GHTableViewCommand *command in self.removeRowCommands)
    {
        [removeRowIndexPaths addObject:command.resolvedIndexPath];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [tableView deleteRowsAtIndexPaths:removeRowIndexPaths withRowAnimation:animationType];
    
    // Update command use the old indexes just like delete
    // update rows
    for (GHTableViewCommand *command in self.updateRowCommands)
    {
        [updateRowIndexPaths addObject:command.resolvedIndexPath];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [tableView reloadRowsAtIndexPaths:updateRowIndexPaths withRowAnimation:animationType];
    
    // Insert commands use the new indexes.  For example say that you had a table with 3 sections:
    // A
    // B
    // C
    // And you want to delete section B then insert into section C.  The index to delete section B would be 1.
    // To insert into section C you would then use a section index of 1 NOT 2.  Even more confusing, say you want
    // to delete section B, a row out of section C then insert into section C.  You would use the following indexes:
    // Section index to delete section B -> 1
    // Section index to delete a Row in section C -> 2
    // Section index to INSERT a row in section C -> 1
    //
    // In other words, all deletions are done with the old indexes and all insertions are done with the new indexes.
    // insert sections
    for (GHTableViewCommand *command in self.insertSectionCommands)
    {
        [insertSectionIndexes addIndex:command.resolvedIndexPath.section];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [tableView insertSections:insertSectionIndexes withRowAnimation:animationType];
    
    // insert rows
    for (GHTableViewCommand *command in self.insertRowCommands)
    {
        [insertRowIndexPaths addObject:command.resolvedIndexPath];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [tableView insertRowsAtIndexPaths:insertRowIndexPaths withRowAnimation:animationType];
    
    self.insertRowCommands = self.insertSectionCommands = self.updateRowCommands = self.removeRowCommands = self.removeSectionCommands = nil;
}

- (void)addCommands:(NSArray *)commands outdatedSectionLookup:(NSDictionary *)currentSectionLookup updatedSectionLookup:(NSDictionary *)updatedSectionLookup
{
    for (GHTableViewCommand *command in commands)
    {
        [self addCommand:command currentSectionLookup:currentSectionLookup updatedSectionLookup:updatedSectionLookup];
    }
}

- (void)addCommand:(GHTableViewCommand *)command currentSectionLookup:(NSDictionary *)currentSectionLookup updatedSectionLookup:(NSDictionary *)updatedSectionLookup
{
    switch (command.commandType)
    {
        case kGHTableCommandUpdateRow:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.updateRowCommands addObject:command];
            break;
        }
            
        case kGHTableCommandRemoveRow:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.removeRowCommands addObject:command];
            break;
        }
            
        case kGHTableCommandAddRow:
        {
            NSUInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.insertRowCommands addObject:command];
            break;
        }
            
        case kGHTableCommandAddSection:
        {
            NSUInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.insertSectionCommands addObject:command];
            break;
        }
            
        case kGHTableCommandRemoveSection:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.removeSectionCommands addObject:command];
            break;
        }
    }
}

@end


@implementation GHTableViewCommand

+ (NSArray *)commandsForOutdatedData:(NSArray *)outdatedData newData:(NSArray *)newData forSectionIdentifier:(NSString *)identifier
{
    NSMutableArray *commands = [NSMutableArray array];
    
    // get the removed Items
    NSMutableArray *removedItems = [NSMutableArray arrayWithArray:outdatedData];
    [removedItems removeObjectsInArray:newData];
    
    // added Items
    NSMutableArray *addedItems = [NSMutableArray arrayWithArray:newData];
    [addedItems removeObjectsInArray:outdatedData];
    
    for (id<GHTableRowProtocol> removedItem in removedItems)
    {
        NSUInteger index = [outdatedData indexOfObject:removedItem];
        [commands addObject:[GHTableViewCommand removeRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<GHTableRowProtocol> addedItem in addedItems)
    {
        NSUInteger index = [newData indexOfObject:addedItem];
        [commands addObject:[GHTableViewCommand addRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<GHTableRowProtocol> updatedItem in newData)
    {
        NSUInteger index = [outdatedData indexOfObject:updatedItem];
        if (index != NSNotFound)
        {
            id<GHTableRowProtocol> outdatedItem = [outdatedData objectAtIndex:index];
            if ([outdatedItem respondsToSelector:@selector(attributeHash)] && [updatedItem respondsToSelector:@selector(attributeHash)])
            {
                if ([outdatedItem attributeHash] != [updatedItem attributeHash])
                {
                    [commands addObject:[GHTableViewCommand updateRowCommandForRow:index sectionIdentifier:identifier]];
                }
            }
        }
    }
    return commands;
}


+ (NSArray *)commandsForOutdatedSectionsObjects:(NSArray *)outdatedSections newSectionObjects:(NSArray *)newSections inTableView:(UITableView *)tableView
{
    NSMutableArray *commands = [NSMutableArray array];
    
    // get the removed Sections
    NSMutableArray *removedSections = [NSMutableArray arrayWithArray:outdatedSections];
    [removedSections removeObjectsInArray:newSections];
    
    // added Sections
    NSMutableArray *addedSections = [NSMutableArray arrayWithArray:newSections];
    [addedSections removeObjectsInArray:outdatedSections];
    
    for (id<GHTableSectionProtocol> section in removedSections)
    {
        [commands addObject:[GHTableViewCommand removeSectionCommandWithSectionIdentifier:section.identifier]];
    }
    
    for (id<GHTableSectionProtocol> section in addedSections)
    {
        [commands addObject:[GHTableViewCommand addSectionCommandWithSectionIdentifier:section.identifier]];
        
        NSUInteger sectionIndex = [newSections indexOfObject:section];
        NSInteger newRowCount = [tableView.dataSource tableView:tableView numberOfRowsInSection:sectionIndex];
        for (NSInteger row =0;newRowCount < 0; row++)
        {
            [commands addObject:[GHTableViewCommand addRowCommandForRow:row sectionIdentifier:section.identifier]];
        }
    }
    
    return commands;
}

+ (instancetype)removeRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kGHTableCommandRemoveRow;
    return command;
}

+ (instancetype)addRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kGHTableCommandAddRow;
    return command;
}

+ (instancetype)updateRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kGHTableCommandUpdateRow;
    return command;
}

+ (instancetype)removeSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kGHTableCommandRemoveSection;
    return command;
}

+ (instancetype)addSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kGHTableCommandAddSection;
    return command;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:@"Table Command: "];
    switch (self.commandType)
    {
        case kGHTableCommandUpdateRow:
            [description appendFormat:@"update row %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kGHTableCommandRemoveRow:
            [description appendFormat:@"remove row %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kGHTableCommandAddRow:
            [description appendFormat:@"add row at %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kGHTableCommandAddSection:
            [description appendFormat:@"add section at %@", self.sectionIdentifier];
            break;
            
        case kGHTableCommandRemoveSection:
            [description appendFormat:@"remove section at %@", self.sectionIdentifier];
            break;
    }
    return description;
}

@end

@implementation UITableView(GHTableViewCommand)


- (void)updateWithSectionIndexData:(GHTableCommandSectionIndexData *)sectionIndexData sectionData:(GHTableCommandTableViewData *)tableData withRowAnimation:(UITableViewRowAnimation)animationType callback:(GHTableCommandCallbackBlock)block
{
    [self beginUpdates];
    GHTableCommandManager *commandManager = [[GHTableCommandManager alloc] init];
    
    NSMutableDictionary *outdatedSectionLookup = [NSMutableDictionary dictionary];
    NSMutableDictionary *newSectionLookup = [NSMutableDictionary dictionary];
    
    NSUInteger index = 0;
    for (id<GHTableSectionProtocol> section in sectionIndexData.outdatedSections)
    {
        [outdatedSectionLookup setObject:@(index) forKey:section.identifier];
        index++;
    }
    
    index = 0;
    for (id<GHTableSectionProtocol> section in sectionIndexData.updatedSections)
    {
        [newSectionLookup setObject:@(index) forKey:section.identifier];
        index++;
    }
    
    NSArray *sectionCommands = [GHTableViewCommand commandsForOutdatedSectionsObjects:sectionIndexData.outdatedSections newSectionObjects:sectionIndexData.updatedSections inTableView:self];
    [commandManager addCommands:sectionCommands outdatedSectionLookup:outdatedSectionLookup updatedSectionLookup:newSectionLookup];
    
    for (GHTableCommandSectionData *data in [tableData.tableRows allValues])
    {
        NSArray *rowCommands = [GHTableViewCommand commandsForOutdatedData:data.outdatedSectionRows newData:data.updatedSectionRows forSectionIdentifier:data.sectionIdentifier];
        [commandManager addCommands:rowCommands outdatedSectionLookup:outdatedSectionLookup updatedSectionLookup:newSectionLookup];
    }

    [commandManager runCommands:self withRowAnimation:animationType  callback:block];
    [self endUpdates];
}


@end
