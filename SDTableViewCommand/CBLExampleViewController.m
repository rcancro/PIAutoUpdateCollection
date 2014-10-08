//
//  CBLExampleViewController.m
//  SDTableViewCommand
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

NSString * const kSectionTitleKey = @"section title";
NSString * const kDataKey = @"data";

#import "CBLExampleViewController.h"
#import "UIColor+CBLAdditions.h"

@interface CBLExampleViewController ()

@end

@implementation CBLExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *section1 = [NSMutableArray arrayWithArray:@[[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor]]];
    NSMutableArray *section2 = [NSMutableArray arrayWithArray:@[[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor]]];
    NSMutableArray *section3 = [NSMutableArray arrayWithArray:@[[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor]]];
    NSMutableArray *section4 = [NSMutableArray arrayWithArray:@[[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor]]];
    NSMutableArray *section5 = [NSMutableArray arrayWithArray:@[[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor],[UIColor randomColor]]];
    self.data = [NSMutableArray arrayWithArray:@[@{kSectionTitleKey:@"section1", kDataKey:section1},
                                                 @{kSectionTitleKey:@"section2", kDataKey:section2},
                                                 @{kSectionTitleKey:@"section3", kDataKey:section3},
                                                 @{kSectionTitleKey:@"section4", kDataKey:section4},
                                                 @{kSectionTitleKey:@"section5", kDataKey:section5}
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
        [self.actionBarButton setTitle:@"Delete Items"];
    }
    else
    {
        [self.actionBarButton setAction:@selector(addRowAction:)];
        [self.actionBarButton setTitle:@"Add Item"];
    }
}

- (IBAction)clearSelection:(id)sender
{
}

- (void)deleteSelectedRowsAction:(id)sender
{
}


- (void)addRowAction:(id)sender
{
}
@end
