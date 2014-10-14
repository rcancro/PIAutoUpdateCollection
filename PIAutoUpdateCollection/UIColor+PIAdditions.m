//
//  UIColor+PIAdditions.m
//  PIAutoUpdateCollection
//
//  Created by Ricky Cancro on 10/5/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "UIColor+PIAdditions.h"

@implementation UIColor(PIAdditions)

+ (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

- (NSUInteger)hash
{
    return [super hash];
}

- (NSString *)identifier
{
    CGFloat red, blue, green, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"%f-%f-%f-%f", red, green, blue, alpha];
}

@end
