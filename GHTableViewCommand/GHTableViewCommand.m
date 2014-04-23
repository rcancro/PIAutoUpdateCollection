//
//  SDTableViewCommand.m
//
//  Created by ricky cancro on 2/6/14.
//

#import "GHTableViewCommand.h"
#import "UITableView+GHAutoUpdate.h"

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


#pragma mark - GHTableViewCommand()
@interface GHTableViewCommand()
@property (nonatomic, assign, readwrite) NSUInteger row;
@property (nonatomic, copy, readwrite) NSString * sectionIdentifier;
@property (nonatomic, assign, readwrite) GHTableCommandType commandType;

@property (nonatomic, strong,readwrite) NSIndexPath *resolvedIndexPath;

@end

@implementation GHTableViewCommand

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
            [description appendFormat:@"update row %tu %@", self.row, self.sectionIdentifier];
            break;
            
        case kGHTableCommandRemoveRow:
            [description appendFormat:@"remove row %tu %@", self.row, self.sectionIdentifier];
            break;
            
        case kGHTableCommandAddRow:
            [description appendFormat:@"add row at %tu %@", self.row, self.sectionIdentifier];
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




#pragma mark - GHTableCommandManager
@interface GHTableCommandManager()
@property (nonatomic, strong) NSMutableArray *updateRowCommands;
@property (nonatomic, strong) NSMutableArray *removeRowCommands;
@property (nonatomic, strong) NSMutableArray *insertRowCommands;
@property (nonatomic, strong) NSMutableArray *removeSectionCommands;
@property (nonatomic, strong) NSMutableArray *insertSectionCommands;

@property (nonatomic, strong) NSMutableDictionary *outdatedSectionLookup;
@property (nonatomic, strong) NSMutableDictionary *updatedSectionLookup;

@end

@implementation GHTableCommandManager

- (id)initWithOutdatedSections:(NSArray *)outdatedSections updatedSections:(NSArray *)updatedSections
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
        
        NSUInteger index = 0;
        for (id<GHTableSectionProtocol> section in outdatedSections)
        {
            _outdatedSectionLookup[section.identifier] = @(index);
            index++;
        }
        
        index = 0;
        for (id<GHTableSectionProtocol> section in updatedSections)
        {
            _updatedSectionLookup[section.identifier] = @(index);
            index++;
        }
        [self addCommandsForOutdatedSectionsObjects:outdatedSections newSectionObjects:updatedSections];
        
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
    
    NSComparator commandSortComparator = ^NSComparisonResult(GHTableViewCommand *obj1, GHTableViewCommand *obj2)
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

- (void)addCommands:(NSArray *)commands
{
    for (GHTableViewCommand *command in commands)
    {
        [self addCommand:command currentSectionLookup:self.outdatedSectionLookup updatedSectionLookup:self.updatedSectionLookup];
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


- (void)addCommandsForOutdatedSectionsObjects:(NSArray *)outdatedSections newSectionObjects:(NSArray *)newSections
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
        [desc appendFormat:@"-------- %@ Commands ----------", title];
    }
    
    for (GHTableViewCommand *command in commands)
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
