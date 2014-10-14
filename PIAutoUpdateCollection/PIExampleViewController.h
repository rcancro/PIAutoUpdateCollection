//
//  PIExampleViewController.h
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

@import UIKit;

extern NSString * const kSectionTitleKey;
extern NSString * const kDataKey;

@interface PIExampleViewController : UIViewController
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionBarButton;
@property (nonatomic, strong) NSMutableSet *selectedRows;

- (void)setupActionButton;

@end
