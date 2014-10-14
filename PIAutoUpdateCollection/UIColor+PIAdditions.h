//
//  UIColor+PIAdditions.h
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

@import UIKit;
#import "PIAutoUpdateProtocols.h"

@interface UIColor(PIAdditions)<PIAutoUpdateItemProtocol>
+ (UIColor *)randomColor;
- (NSString *)identifier;
@end
