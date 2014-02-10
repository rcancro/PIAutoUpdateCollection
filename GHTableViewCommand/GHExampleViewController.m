//
//  GHFirstViewController.m
//  GHTableViewCommand
//
//  Created by ricky cancro on 2/9/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "GHExampleViewController.h"
#import "GHTableViewCommand.h"

static const NSString *kSectionTitleKey = @"section title";
static const NSString *kRowDataKey = @"data";
static NSString *kDefaultCellIdentifier = @"cell";

typedef void (^TableModelChangeBlock)();

@interface GHExampleViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionBarButton;
@property (nonatomic, strong) NSMutableSet *selectedRows;
@end

@implementation GHExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    NSMutableArray *section1 = [NSMutableArray arrayWithArray:@[[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle]]];
    NSMutableArray *section2 = [NSMutableArray arrayWithArray:@[[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle]]];
    NSMutableArray *section3 = [NSMutableArray arrayWithArray:@[[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle]]];
    NSMutableArray *section4 = [NSMutableArray arrayWithArray:@[[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle]]];
    NSMutableArray *section5 = [NSMutableArray arrayWithArray:@[[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle],[self randomCellTitle]]];
    self.tableData = [NSMutableArray arrayWithArray:@[@{kSectionTitleKey:@"section1", kRowDataKey:section1},
                                                      @{kSectionTitleKey:@"section2", kRowDataKey:section2},
                                                      @{kSectionTitleKey:@"section3", kRowDataKey:section3},
                                                      @{kSectionTitleKey:@"section4", kRowDataKey:section4},
                                                      @{kSectionTitleKey:@"section5", kRowDataKey:section5}
                                                      ]];
    self.selectedRows = [NSMutableSet set];
    [self setupActionButton];
}
                                                      
- (NSString *)randomCellTitle
{
	NSString*	uuidString = nil;
	
	CFUUIDRef	uuidRef = CFUUIDCreate(kCFAllocatorDefault);
	if (uuidRef)
	{
		uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		
		CFRelease(uuidRef);
	}
	
	return uuidString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupActionButton
{
    self.actionBarButton.target = self;
    if ([self.selectedRows count] > 0)
    {
        [self.actionBarButton setAction:@selector(deleteSelectedRowsAction:)];
        [self.actionBarButton setTitle:@"Delete Rows"];
    }
    else
    {
        [self.actionBarButton setAction:@selector(addRowAction:)];
        [self.actionBarButton setTitle:@"Add Row"];
    }
}

#pragma mark - actions

- (IBAction)clearSelection:(id)sender
{
    self.selectedRows = [NSMutableSet set];
    [self.tableView reloadData];
}

- (void)tableUpdateAction:(TableModelChangeBlock)modelChangeBlock
{
    // Create the sectionDataObject needed to update the table
    GHTableCommandSectionIndexData *sectionIndexData = [[GHTableCommandSectionIndexData alloc] init];
    
    // set the current sections as the "oldSections"
    sectionIndexData.outdatedSections = [self nonEmptySections];
    
    GHTableCommandAllSectionData *allSectionData = [[GHTableCommandAllSectionData alloc] init];
    for (NSDictionary *sectionData in self.tableData)
    {
        [allSectionData addOutdatedData:sectionData[kRowDataKey] forSection:sectionData[kSectionTitleKey]];
    }
    
    modelChangeBlock();
    
    // now get the updated non empty sections and set them in the updatedSections
    sectionIndexData.updatedSections = [self nonEmptySections];
    
    for (NSDictionary *sectionData in self.tableData)
    {
        NSArray *rowData = sectionData[kRowDataKey];
        if ([rowData count] > 0)
        {
            [allSectionData addUpdatedData:rowData forSection:sectionData[kSectionTitleKey]];
        }
    }
    
    [self.tableView updateWithSectionIndexData:sectionIndexData sectionData:allSectionData withRowAnimation:UITableViewRowAnimationAutomatic callback:nil];
}

- (NSArray *)nonEmptySections
{
    NSMutableArray *sections = [NSMutableArray array];
    for (NSDictionary *sectionData in self.tableData)
    {
        if ([sectionData[kRowDataKey] count] > 0)
        {
            [sections addObject:sectionData[kSectionTitleKey]];
        }
    }
    return sections;
}

- (void)deleteSelectedRowsAction:(id)sender
{
    TableModelChangeBlock deleteSelectedBlock = ^{
        NSMutableArray *sortedIndexPaths = [NSMutableArray arrayWithArray:[self.selectedRows allObjects]];
        
        // we want to remove higher indexes first so we don't have to try to update indexes after a delete
        [sortedIndexPaths sortUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2)
         {
             NSComparisonResult result = NSOrderedSame;
             if (obj1.section > obj2.section)
             {
                 result = NSOrderedAscending;
             }
             else if (obj1.section < obj2.section)
             {
                 result = NSOrderedDescending;
             }
             else
             {
                 // ok we have the same section
                 if (obj1.row > obj2.row)
                 {
                     result =  NSOrderedAscending;
                 }
                 else if (obj1.row < obj2.row)
                 {
                     result = NSOrderedDescending;
                 }
             }
             return result;
         }];
        
        for (NSIndexPath *indexPath in sortedIndexPaths)
        {
            NSDictionary *sectionData = [self.tableData objectAtIndex:indexPath.section];
            NSMutableArray *rowData = sectionData[kRowDataKey];
            [rowData removeObjectAtIndex:indexPath.row];
        }
        self.selectedRows = [NSMutableSet set];
    };
    [self tableUpdateAction:deleteSelectedBlock];
}


- (void)addRowAction:(id)sender
{
    TableModelChangeBlock addRowBlock = ^{
        // insert the new row
        NSUInteger sectionIndex = rand() % [self numberOfSectionsInTableView:self.tableView];
        NSUInteger rowIndex = rand() % [self tableView:self.tableView numberOfRowsInSection:sectionIndex];
        
        NSDictionary *sectionData = [self.tableData objectAtIndex:sectionIndex];
        NSMutableArray *rowData = [sectionData objectForKey:kRowDataKey];
        
        NSString *title = [self randomCellTitle];
        [rowData insertObject:title atIndex:rowIndex];
    };
    [self tableUpdateAction:addRowBlock];
}

- (NSDictionary *)tableDataForSectionName:(NSString *)sectionName
{
    NSDictionary *sectionData = nil;
    for (NSDictionary *data in self.tableData)
    {
        if ([data[kSectionTitleKey] isEqualToString:sectionName])
        {
            sectionData = data;
            break;
        }
    }
    return sectionData;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self nonEmptySections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionTitle = [[self nonEmptySections] objectAtIndex:section];
    NSDictionary *sectionData = [self tableDataForSectionName:sectionTitle];
    return [sectionData[kRowDataKey] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDefaultCellIdentifier];
    }
    
    NSString *sectionTitle = [[self nonEmptySections] objectAtIndex:indexPath.section];
    NSDictionary *sectionData = [self tableDataForSectionName:sectionTitle];
    NSArray *rowData = sectionData[kRowDataKey];
    cell.textLabel.text = [rowData objectAtIndex:indexPath.row];
    cell.selected = [self.selectedRows containsObject:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self nonEmptySections] objectAtIndex:section];
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
