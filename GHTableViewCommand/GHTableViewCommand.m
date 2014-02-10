//
//  GHTableCommand.h
//  GHTableViewCommand
//
//  Created by ricky cancro on 2/9/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//


#import "GHTableViewCommand.h"

#pragma mark - SDTableCommandSectionData
@implementation GHTableCommandSectionData
+ (instancetype)sectionDataWithOldSections:(NSArray *)oldSections updatedSections:(NSArray *)updatedSections
{
    GHTableCommandSectionData *data = [[GHTableCommandSectionData alloc] init];
    data.oldSections = oldSections;
    data.updatedSections = updatedSections;
    return data;
}
@end

#pragma mark - NSString(SDTableSectionObject)
@implementation NSString(GHTableSectionObject)

- (NSString *)identifier
{
    return self;
}

@end

#pragma mark - SDTableCommandRowData
@implementation GHTableCommandRowData
@end

@interface GHTableCommandTableRowData()
@property (nonatomic, strong, readwrite) NSMutableDictionary *tableRows;
@end

@implementation GHTableCommandTableRowData

- (id)init
{
    self = [super init];
    if (self)
    {
        self.tableRows = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addOldData:(NSArray *)data forSection:(NSString *)sectionIdentifier
{
    GHTableCommandRowData *rowObject = self.tableRows[sectionIdentifier];
    if (!rowObject)
    {
        rowObject = [[GHTableCommandRowData alloc] init];
        rowObject.sectionIdentifier = sectionIdentifier;
    }
    rowObject.oldSectionRows = data;
    [self.tableRows setObject:rowObject forKey:sectionIdentifier];
}

- (void)addUpdatedData:(NSArray *)data forSection:(NSString *)sectionIdentifier
{
    GHTableCommandRowData *rowObject = self.tableRows[sectionIdentifier];
    if (!rowObject)
    {
        rowObject = [[GHTableCommandRowData alloc] init];
        rowObject.sectionIdentifier = sectionIdentifier;
    }
    rowObject.updatedSectionRows = data;
    [self.tableRows setObject:rowObject forKey:sectionIdentifier];
}

@end

#pragma mark - SDTableViewCommand()
@interface GHTableViewCommand()
@property (nonatomic, assign, readwrite) NSUInteger row;
@property (nonatomic, copy, readwrite) NSString * sectionIdentifier;
@property (nonatomic, assign, readwrite) GHTableCommandType commandType;

@property (nonatomic, strong,readwrite) NSIndexPath *resolvedIndexPath;

@end

#pragma mark - SDTableCommandManager
@interface SDTableCommandManager : NSObject
@property (nonatomic, strong) NSMutableIndexSet *insertSectionIndexes;
@property (nonatomic, strong) NSMutableArray *insertRowIndexPaths;
@property (nonatomic, strong) NSMutableIndexSet *removeSectionIndexes;
@property (nonatomic, strong) NSMutableArray *removeRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *updateRowIndexPaths;
@end

@implementation SDTableCommandManager

+ (SDTableCommandManager *)sharedInstance
{
    static SDTableCommandManager *gCommandManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        gCommandManager = [[SDTableCommandManager alloc] init];
        // Do any other initialisation stuff here
    });
    return gCommandManager;
}

- (void)beginUpdates
{
    self.insertSectionIndexes = [NSMutableIndexSet indexSet];
    self.insertRowIndexPaths = [NSMutableArray array];
    self.removeSectionIndexes = [NSMutableIndexSet indexSet];
    self.removeRowIndexPaths = [NSMutableArray array];
    self.updateRowIndexPaths = [NSMutableArray array];
}

- (void)endUpdates:(UITableView *)tableView withRowAnimation:(UITableViewRowAnimation)animationType
{
    
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
    if ([self.removeSectionIndexes count])
    {
        [tableView deleteSections:self.removeSectionIndexes withRowAnimation:animationType];
    }
    
    // remove rows
    if ([self.removeRowIndexPaths count])
    {
        [tableView deleteRowsAtIndexPaths:self.removeRowIndexPaths withRowAnimation:animationType];
    }
    
    // Update command use the old indexes just like delete
    // update rows
    if ([self.updateRowIndexPaths count])
    {
        [tableView reloadRowsAtIndexPaths:self.updateRowIndexPaths withRowAnimation:animationType];
    }
    
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
    if ([self.insertSectionIndexes count])
    {
        [tableView insertSections:self.insertSectionIndexes withRowAnimation:animationType];
    }
    
    // insert rows
    if ([self.insertRowIndexPaths count])
    {
        [tableView insertRowsAtIndexPaths:self.insertRowIndexPaths withRowAnimation:animationType];
    }
    
    self.insertSectionIndexes = [NSMutableIndexSet indexSet];
    self.insertRowIndexPaths = [NSMutableArray array];
    self.removeSectionIndexes = [NSMutableIndexSet indexSet];
    self.removeRowIndexPaths = [NSMutableArray array];
    self.updateRowIndexPaths = [NSMutableArray array];
}

- (void)addCommands:(NSArray *)commands currentSectionLookup:(NSDictionary *)currentSectionLookup updatedSectionLookup:(NSDictionary *)updatedSectionLookup callback:(GHTableCommandCallbackBlock)block;
{
    for (GHTableViewCommand *command in commands)
    {
        [self addCommand:command currentSectionLookup:currentSectionLookup updatedSectionLookup:updatedSectionLookup];
        if (block)
        {
            block(command);
        }
    }
}

- (void)addCommand:(GHTableViewCommand *)command currentSectionLookup:(NSDictionary *)currentSectionLookup updatedSectionLookup:(NSDictionary *)updatedSectionLookup
{
    switch (command.commandType)
    {
        case kASDATableCommandUpdateRow:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.updateRowIndexPaths addObject:[NSIndexPath indexPathForRow:command.row inSection:section]];
            break;
        }
            
        case kASDATableCommandRemoveRow:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.removeRowIndexPaths addObject:[NSIndexPath indexPathForRow:command.row inSection:section]];
            break;
        }
            
        case kASDATableCommandAddRow:
        {
            NSUInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:command.row inSection:section];
            [self.insertRowIndexPaths addObject:[NSIndexPath indexPathForRow:command.row inSection:section]];
            break;
        }
            
        case kASDATableCommandAddSection:
        {
            NSUInteger section = [[updatedSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.insertSectionIndexes addIndex:section];
            break;
        }
            
        case kASDATableCommandRemoveSection:
        {
            NSUInteger section = [[currentSectionLookup objectForKey:command.sectionIdentifier] integerValue];
            command.resolvedIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
            [self.removeSectionIndexes addIndex:section];
            break;
        }
    }
}

@end


@implementation GHTableViewCommand

+ (NSArray *)commandsForOldData:(NSArray *)oldData newData:(NSArray *)newData forSectionIdentifier:(NSString *)identifier
{
    NSMutableArray *commands = [NSMutableArray array];
    
    // get the removed Items
    NSMutableArray *removedItems = [NSMutableArray arrayWithArray:oldData];
    [removedItems removeObjectsInArray:newData];
    
    // added Items
    NSMutableArray *addedItems = [NSMutableArray arrayWithArray:newData];
    [addedItems removeObjectsInArray:oldData];
    
    for (id<GHTableRowObject> removedItem in removedItems)
    {
        NSUInteger index = [oldData indexOfObject:removedItem];
        [commands addObject:[GHTableViewCommand removeRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<GHTableRowObject> addedItem in addedItems)
    {
        NSUInteger index = [newData indexOfObject:addedItem];
        [commands addObject:[GHTableViewCommand addRowCommandForRow:index sectionIdentifier:identifier]];
    }
    
    for (id<GHTableRowObject> updatedItem in newData)
    {
        NSUInteger index = [oldData indexOfObject:updatedItem];
        if (index != NSNotFound)
        {
            id<GHTableRowObject> oldItem = [oldData objectAtIndex:index];
            if ([oldItem respondsToSelector:@selector(attributeHash)] && [updatedItem respondsToSelector:@selector(attributeHash)])
            {
                if ([oldItem attributeHash] != [updatedItem attributeHash])
                {
                    [commands addObject:[GHTableViewCommand updateRowCommandForRow:index sectionIdentifier:identifier]];
                }
            }
        }
    }
    return commands;
}


+ (NSArray *)commandsForOldSectionsObjects:(NSArray *)oldSections newSectionObjects:(NSArray *)newSections inTableView:(UITableView *)tableView
{
    NSMutableArray *commands = [NSMutableArray array];
    
    // get the removed Sections
    NSMutableArray *removedSections = [NSMutableArray arrayWithArray:oldSections];
    [removedSections removeObjectsInArray:newSections];
    
    // added Sections
    NSMutableArray *addedSections = [NSMutableArray arrayWithArray:newSections];
    [addedSections removeObjectsInArray:oldSections];
    
    for (id<GHTableSectionObject> section in removedSections)
    {
        [commands addObject:[GHTableViewCommand removeSectionCommandWithSectionIdentifier:section.identifier]];
    }
    
    for (id<GHTableSectionObject> section in addedSections)
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
    command.commandType = kASDATableCommandRemoveRow;
    return command;
}

+ (instancetype)addRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kASDATableCommandAddRow;
    return command;
}

+ (instancetype)updateRowCommandForRow:(NSUInteger)row sectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.row = row;
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kASDATableCommandUpdateRow;
    return command;
}

+ (instancetype)removeSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kASDATableCommandRemoveSection;
    return command;
}

+ (instancetype)addSectionCommandWithSectionIdentifier:(NSString *)sectionIdentifier
{
    GHTableViewCommand *command = [[GHTableViewCommand alloc] init];
    command.sectionIdentifier = sectionIdentifier;
    command.commandType = kASDATableCommandAddSection;
    return command;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithString:@"Table Command: "];
    switch (self.commandType)
    {
        case kASDATableCommandUpdateRow:
            [description appendFormat:@"update row %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kASDATableCommandRemoveRow:
            [description appendFormat:@"remove row %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kASDATableCommandAddRow:
            [description appendFormat:@"add row at %d %@", self.row, self.sectionIdentifier];
            break;
            
        case kASDATableCommandAddSection:
            [description appendFormat:@"add section at %@", self.sectionIdentifier];
            break;
            
        case kASDATableCommandRemoveSection:
            [description appendFormat:@"remove section at %@", self.sectionIdentifier];
            break;
    }
    return description;
}

@end

@implementation UITableView(GHTableViewCommand)


- (void)updateWithSectionData:(GHTableCommandSectionData *)sectionData rowData:(GHTableCommandTableRowData *)rowData withRowAnimation:(UITableViewRowAnimation)animationType callback:(GHTableCommandCallbackBlock)block
{
    [self beginUpdates];
    [[SDTableCommandManager sharedInstance] beginUpdates];
    
    NSMutableDictionary *oldSectionLookup = [NSMutableDictionary dictionary];
    NSMutableDictionary *newSectionLookup = [NSMutableDictionary dictionary];
    
    NSUInteger index = 0;
    for (id<GHTableSectionObject> section in sectionData.oldSections)
    {
        [oldSectionLookup setObject:@(index) forKey:section.identifier];
        index++;
    }
    
    index = 0;
    for (id<GHTableSectionObject> section in sectionData.updatedSections)
    {
        [newSectionLookup setObject:@(index) forKey:section.identifier];
        index++;
    }
    
    NSArray *sectionCommands = [GHTableViewCommand commandsForOldSectionsObjects:sectionData.oldSections newSectionObjects:sectionData.updatedSections inTableView:self];
    [[SDTableCommandManager sharedInstance] addCommands:sectionCommands currentSectionLookup:oldSectionLookup updatedSectionLookup:newSectionLookup callback:block];
    
    for (GHTableCommandRowData *data in [rowData.tableRows allValues])
    {
        NSArray *rowCommands = [GHTableViewCommand commandsForOldData:data.oldSectionRows newData:data.updatedSectionRows forSectionIdentifier:data.sectionIdentifier];
        [[SDTableCommandManager sharedInstance] addCommands:rowCommands currentSectionLookup:oldSectionLookup updatedSectionLookup:newSectionLookup callback:block];
    }

    [[SDTableCommandManager sharedInstance] endUpdates:self withRowAnimation:animationType];
    [self endUpdates];
}


@end
