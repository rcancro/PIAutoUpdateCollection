//
//  PITableViewCommand.m
//
//  Created by ricky cancro on 2/6/14.
//

#import "PIAutoUpdateCommand.h"
#import "PIAutoUpdateProtocols.h"

@implementation NSArray(NSIndexPath)
- (NSArray *)deleteFriendlySortedArray
{
    NSComparator commandSortComparator = ^NSComparisonResult(id obj1, id obj2)
    {
        NSIndexPath *indexPath1 = obj1, *indexPath2 = obj2;
        if ([obj1 isKindOfClass:[PIAutoUpdateCommand class]])
        {
            indexPath1 = [(PIAutoUpdateCommand *)obj1 resolvedIndexPath];
        }
        if ([obj2 isKindOfClass:[PIAutoUpdateCommand class]])
        {
            indexPath2 = [(PIAutoUpdateCommand *)obj2 resolvedIndexPath];
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


#pragma mark - PICommand()
@interface PIAutoUpdateCommand()
@property (nonatomic, assign, readwrite) NSUInteger row;
@property (nonatomic, copy, readwrite) NSString * sectionIdentifier;
@property (nonatomic, assign, readwrite) PICommandType commandType;

@property (nonatomic, strong,readwrite) NSIndexPath *resolvedIndexPath;

@end

@implementation PIAutoUpdateCommand

+ (instancetype)removeRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    PIAutoUpdateCommand *command = [[PIAutoUpdateCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kPICommandRemoveRow;
    return command;
}

+ (instancetype)addRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    PIAutoUpdateCommand *command = [[PIAutoUpdateCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kPICommandAddRow;
    return command;
}

+ (instancetype)updateRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    PIAutoUpdateCommand *command = [[PIAutoUpdateCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kPICommandUpdateRow;
    return command;
}

+ (instancetype)removeSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    PIAutoUpdateCommand *command = [[PIAutoUpdateCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kPICommandRemoveSection;
    return command;
}

+ (instancetype)addSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    PIAutoUpdateCommand *command = [[PIAutoUpdateCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kPICommandAddSection;
    return command;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:@"Table Command: "];
    switch (self.commandType)
    {
        case kPICommandUpdateRow:
            [description appendFormat:@"update row %tu %@", self.row, self.sectionIdentifier];
            break;
            
        case kPICommandRemoveRow:
            [description appendFormat:@"remove row %tu %@", self.row, self.sectionIdentifier];
            break;
            
        case kPICommandAddRow:
            [description appendFormat:@"add row at %tu %@", self.row, self.sectionIdentifier];
            break;
            
        case kPICommandAddSection:
            [description appendFormat:@"add section at %@", self.sectionIdentifier];
            break;
            
        case kPICommandRemoveSection:
            [description appendFormat:@"remove section at %@", self.sectionIdentifier];
            break;
    }
    return description;
}

@end




#pragma mark - PITableCommandManager
@interface PIAutoUpdateCommandManager()
@property (nonatomic, strong) NSMutableArray *updateRowCommands;
@property (nonatomic, strong) NSMutableArray *removeRowCommands;
@property (nonatomic, strong) NSMutableArray *insertRowCommands;
@property (nonatomic, strong) NSMutableArray *removeSectionCommands;
@property (nonatomic, strong) NSMutableArray *insertSectionCommands;

@property (nonatomic, strong) NSMutableDictionary *outdatedSectionLookup;
@property (nonatomic, strong) NSMutableDictionary *updatedSectionLookup;

@end

@implementation PIAutoUpdateCommandManager

+ (void)runCommandsWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource
                       autoUpdateableObject:(id<PIAutoUpdateableCollectionView>)updateableObject
                                updateBlock:(PIUpdateCollectionViewDataBlock)updateBlock
                       commandCallbackblock:(PIAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    PIAutoUpdateCommandManager *manager = [[PIAutoUpdateCommandManager alloc] init];
        NSArray *outdatedSections = [[updateDataSource sectionsForPass:kPIAutoUpdatePassBeforeUpdate] copy];
        NSMutableDictionary *outdatedRowData = [NSMutableDictionary dictionary];
        
        for (id<PIAutoUpdateSectionProtocol> section in outdatedSections)
        {
            outdatedRowData[section.identifier] = [[updateDataSource itemsForSection:section pass:kPIAutoUpdatePassBeforeUpdate] copy];
        }
        
        // call the block to update the table's underlying data
        if (updateBlock)
        {
            updateBlock();
        }
        
        // get the new state of the table
        NSArray *updatedSections = [[updateDataSource sectionsForPass:kPIAutoUpdatePassAfterUpdate] copy];
        NSMutableDictionary *updatedRowData = [NSMutableDictionary dictionary];
        
        for (id<PIAutoUpdateSectionProtocol> section in updatedSections)
        {
            updatedRowData[section.identifier] = [[updateDataSource itemsForSection:section pass:kPIAutoUpdatePassAfterUpdate] copy];
        }
        
        NSUInteger index = 0;
        for (id<PIAutoUpdateSectionProtocol> section in outdatedSections)
        {
            manager.outdatedSectionLookup[section.identifier] = @(index);
            index++;
        }
        
        index = 0;
        for (id<PIAutoUpdateSectionProtocol> section in updatedSections)
        {
            manager.updatedSectionLookup[section.identifier] = @(index);
            index++;
        }
        [manager addCommandsForOutdatedSectionsObjects:outdatedSections newSectionObjects:updatedSections];
        
        NSMutableSet *allSectionIdentifiers = [NSMutableSet setWithArray:[outdatedRowData allKeys]];
        [allSectionIdentifiers addObjectsFromArray:[updatedRowData allKeys]];
        
        for (NSString *sectionIdentifier in allSectionIdentifiers)
        {
            [manager addCommandsForOutdatedData:outdatedRowData[sectionIdentifier] newData:updatedRowData[sectionIdentifier] forSectionIdentifier:sectionIdentifier];
        }
        
        [updateableObject runAutoUpdateCommandBlock:^{
            [manager runCommands:updateableObject withAnimationTypes:nil callback:commandCallbackBlock];
        }];
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _updateRowCommands = [NSMutableArray array];
        _removeRowCommands = [NSMutableArray array];
        _insertRowCommands = [NSMutableArray array];
        _removeSectionCommands = [NSMutableArray array];
        _insertSectionCommands = [NSMutableArray array];
        
        _outdatedSectionLookup = [NSMutableDictionary dictionary];
        _updatedSectionLookup = [NSMutableDictionary dictionary];
        
        
    }
    return self;
}

- (UITableViewRowAnimation)animationForKey:(NSString *)key inDictionary:(NSDictionary *)animationTypes
{
    UITableViewRowAnimation animationType = UITableViewRowAnimationAutomatic;
    if ([animationTypes objectForKey:key])
    {
        animationType = [[animationTypes objectForKey:key] intValue];
    }
    return animationType;
}

- (void)runCommands:(id<PIAutoUpdateableCollectionView>)updateableObject withAnimationTypes:(NSDictionary *)animationTypes callback:(PIAutoUpdateCommandCallbackBlock)callbackBlock;
{
    
    NSMutableIndexSet *insertSectionIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *insertRowIndexPaths = [NSMutableArray array];
    NSMutableIndexSet *removeSectionIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *removeRowIndexPaths = [NSMutableArray array];
    NSMutableArray *updateRowIndexPaths = [NSMutableArray array];
    
    // Sort deletions so the highest indexes are removed first.  This isn't required for the tableView update calls,
    // but if helpful for the callback in case the user is also deleting something at the same index paths
    
    NSComparator commandSortComparator = ^NSComparisonResult(PIAutoUpdateCommand *obj1, PIAutoUpdateCommand *obj2)
    {
        NSComparisonResult result = NSOrderedSame;
        if (obj1.resolvedIndexPath.section > obj2.resolvedIndexPath.section)
        {
            result = NSOrderedAscending;
        }
        else if (obj1.resolvedIndexPath.section < obj2.resolvedIndexPath.section)
        {
            result = NSOrderedDescending;
        }
        else
        {
            // ok we have the same section
            if (obj1.resolvedIndexPath.row > obj2.resolvedIndexPath.row)
            {
                result =  NSOrderedAscending;
            }
            else if (obj1.resolvedIndexPath.row < obj2.resolvedIndexPath.row)
            {
                result = NSOrderedDescending;
            }
        }
        return result;
    };
    
    [self.removeSectionCommands sortUsingComparator:commandSortComparator];
    [self.removeRowCommands sortUsingComparator:commandSortComparator];
    
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
    
    // Update command use the old indexes just like delete
    // update rows
    for (PIAutoUpdateCommand *command in self.updateRowCommands)
    {
        [updateRowIndexPaths addObject:command.resolvedIndexPath];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [updateableObject refreshItems:updateRowIndexPaths];
    
    // remove sections
    for (PIAutoUpdateCommand *command in self.removeSectionCommands)
    {
        [removeSectionIndexes addIndex:(NSUInteger)command.resolvedIndexPath.section];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [updateableObject removeSections:removeSectionIndexes];
    
    // remove rows
    for (PIAutoUpdateCommand *command in self.removeRowCommands)
    {
        if (![removeSectionIndexes containsIndex:command.resolvedIndexPath.section]) {
            [removeRowIndexPaths addObject:command.resolvedIndexPath];
        }
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [updateableObject removeItems:removeRowIndexPaths];

    
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
    for (PIAutoUpdateCommand *command in self.insertSectionCommands)
    {
        [insertSectionIndexes addIndex:(NSUInteger)command.resolvedIndexPath.section];
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [updateableObject insertSections:insertSectionIndexes];
    
    // insert rows
    for (PIAutoUpdateCommand *command in self.insertRowCommands)
    {
        // If we've insert the entire section, don't bother with the individual
        //  rows because the TableView will deal with that
        if (![insertSectionIndexes containsIndex:command.resolvedIndexPath.section]) {
            [insertRowIndexPaths addObject:command.resolvedIndexPath];
        }
        
        if (callbackBlock)
        {
            callbackBlock(command);
        }
    }
    [updateableObject insertItems:insertRowIndexPaths];
    
    self.insertRowCommands = self.insertSectionCommands = self.updateRowCommands = self.removeRowCommands = self.removeSectionCommands = nil;
}

- (void)addCommands:(NSArray *)commands
{
    for (PIAutoUpdateCommand *command in commands)
    {
        [self addCommand:command currentSectionLookup:self.outdatedSectionLookup updatedSectionLookup:self.updatedSectionLookup];
    }
}

- (void)addCommand:(PIAutoUpdateCommand *)command currentSectionLookup:(NSDictionary *)currentSectionLookup updatedSectionLookup:(NSDictionary *)updatedSectionLookup
{
    switch (command.commandType)
    {
        case kPICommandUpdateRow:
        {
            NSInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:(NSInteger)command.row inSection:section];
            [self.updateRowCommands addObject:command];
            break;
        }
            
        case kPICommandRemoveRow:
        {
            NSInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:(NSInteger)command.row inSection:section];
            [self.removeRowCommands addObject:command];
            break;
        }
            
        case kPICommandAddRow:
        {
            NSInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:(NSInteger)command.row inSection:section];
            [self.insertRowCommands addObject:command];
            break;
        }
            
        case kPICommandAddSection:
        {
            NSInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.insertSectionCommands addObject:command];
            break;
        }
            
        case kPICommandRemoveSection:
        {
            NSInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.removeSectionCommands addObject:command];
            break;
        }
    }
}


- (void)addCommandsForOutdatedSectionsObjects:(NSArray *)outdatedSections newSectionObjects:(NSArray *)newSections
{
    NSMutableArray *commands = [NSMutableArray array];
    
    NSString *identifierKeyPath = @"identifier";
    
    // get the removed Sections
    NSMutableArray *removedSections = [NSMutableArray arrayWithArray:[outdatedSections valueForKeyPath:identifierKeyPath]];
    [removedSections removeObjectsInArray:[newSections valueForKeyPath:identifierKeyPath]];
    
    // added Sections
    NSMutableArray *addedSections = [NSMutableArray arrayWithArray:[newSections valueForKeyPath:identifierKeyPath]];
    [addedSections removeObjectsInArray:[outdatedSections valueForKeyPath:identifierKeyPath]];
    
    for (id<PIAutoUpdateSectionProtocol> section in removedSections)
    {
        [commands addObject:[PIAutoUpdateCommand removeSectionCommandWithSectionIdentifier:section.identifier]];
    }
    
    for (id<PIAutoUpdateSectionProtocol> section in addedSections)
    {
        [commands addObject:[PIAutoUpdateCommand addSectionCommandWithSectionIdentifier:section.identifier]];
    }
    [self addCommands:commands];
}


- (void)addCommandsForOutdatedData:(NSArray *)outdatedData newData:(NSArray *)newData forSectionIdentifier:(NSString *)identifier
{
    NSMutableArray *commands = [NSMutableArray array];
    
    // get the removed Items
    NSMutableArray *removedItems = [NSMutableArray arrayWithArray:outdatedData];
    [removedItems removeObjectsInArray:newData];
    
    // added Items
    NSMutableArray *addedItems = [NSMutableArray arrayWithArray:newData];
    [addedItems removeObjectsInArray:outdatedData];
    
    for (id<PIAutoUpdateItemProtocol> removedItem in removedItems)
    {
        NSUInteger index = [outdatedData indexOfObject:removedItem];
        [commands addObject:[PIAutoUpdateCommand removeRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<PIAutoUpdateItemProtocol> addedItem in addedItems)
    {
        NSUInteger index = [newData indexOfObject:addedItem];
        [commands addObject:[PIAutoUpdateCommand addRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<PIAutoUpdateItemProtocol> updatedItem in newData)
    {
        NSUInteger index = [outdatedData indexOfObject:updatedItem];
        if (index != NSNotFound)
        {
            id<PIAutoUpdateItemProtocol> outdatedItem = [outdatedData objectAtIndex:index];
            if ([outdatedItem respondsToSelector:@selector(itemAttributesHash)] && [updatedItem respondsToSelector:@selector(itemAttributesHash)])
            {
                if ([outdatedItem itemAttributesHash] != [updatedItem itemAttributesHash])
                {
                    [commands addObject:[PIAutoUpdateCommand updateRowCommandForRow:index sectionIdentifier:identifier]];
                }
            }
        }
    }
    [self addCommands:commands];
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendString:[self descriptionForCommands:self.removeSectionCommands commandsTitle:@"Remove Section"]];
    [desc appendString:[self descriptionForCommands:self.insertSectionCommands commandsTitle:@"Insert Section"]];
    
    [desc appendString:[self descriptionForCommands:self.removeRowCommands commandsTitle:@"Remove Row"]];
    [desc appendString:[self descriptionForCommands:self.insertRowCommands commandsTitle:@"Insert Row"]];
    [desc appendString:[self descriptionForCommands:self.updateRowCommands commandsTitle:@"Update Row"]];
    return desc;
}

- (NSString *)descriptionForCommands:(NSArray *)commands commandsTitle:(NSString *)title
{
    NSMutableString *desc = [NSMutableString stringWithString:@""];
    
    if (0 < [commands count])
    {
        [desc appendFormat:@"-------- %@ Commands ----------\n", title];
    }
    
    for (PIAutoUpdateCommand *command in commands)
    {
        [desc appendFormat:@"%@\n", [command description]];
    }
    
    if (0 < [commands count])
    {
        [desc appendString:@"\n\n"];
    }
    
    return desc;
}

@end
