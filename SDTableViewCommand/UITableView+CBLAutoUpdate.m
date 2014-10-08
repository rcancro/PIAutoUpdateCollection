//
//  UITableView+SDAutoUpdate.m
//
//  Created by ricky cancro on 4/22/14.
//
#import <objc/runtime.h>
#import "UITableView+CBLAutoUpdate.h"

NSString * const CBLTableViewUpdateRowAnimationKey = @"CBLCommandUpdateItemAnimationKey";
NSString * const CBLTableViewRemoveRowAnimationKey = @"CBLCommandRemoveItemAnimationKey";
NSString * const CBLTableViewAddRowAnimationKey = @"CBLCommandAddItemAnimationKey";
NSString * const CBLTableViewRemoveSectionAnimationKey = @"CBLCommandRemoveSectionAnimationKey";
NSString * const CBLTableViewAddSectionAnimationKey = @"CBLCommandAddSectionAnimationKey";

static char kAssociatedObjectKey;

#pragma mark - NSString(SDTableSectionObject)
@implementation NSString(SDTableSectionProtocol)

- (NSString *)identifier
{
    return self;
}

@end

#pragma mark - UITableView(SDAutoUpdate)
@implementation UITableView(SDAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateTableViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:UITableViewRowAnimationAutomatic updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(CBLUpdateTableViewDataBlock)updateBlock;
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:animationType updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(CBLUpdateTableViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationTypes:animationTypes updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(CBLUpdateTableViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    NSDictionary *animationTypes = @{CBLTableViewAddRowAnimationKey : @(animationType),
                                     CBLTableViewAddSectionAnimationKey : @(animationType),
                                     CBLTableViewRemoveRowAnimationKey : @(animationType),
                                     CBLTableViewRemoveSectionAnimationKey : @(animationType),
                                     CBLTableViewUpdateRowAnimationKey : @(animationType)};
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationTypes:animationTypes updateBlock:updateBlock commandCallbackblock:commandCallbackBlock];
}

- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(CBLUpdateTableViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    objc_setAssociatedObject(self, &kAssociatedObjectKey, animationTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [CBLAutoUpdateCommandManager runCommandsWithAutoUpdateDataSource:updateDataSource
                                                autoUpdateableObject:self
                                                         updateBlock:updateBlock
                                                commandCallbackblock:commandCallbackBlock];
    objc_setAssociatedObject(self, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - CBLAutoUpdateableObject

- (void)removeSections:(NSIndexSet *)sections
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[CBLTableViewRemoveSectionAnimationKey];
    [self deleteSections:sections withRowAnimation:[animationType integerValue]];
}

- (void)insertSections:(NSIndexSet *)sections
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[CBLTableViewAddSectionAnimationKey];
    [self insertSections:sections withRowAnimation:[animationType integerValue]];
}

- (void)removeItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[CBLTableViewRemoveRowAnimationKey];
    [self deleteRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)insertItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[CBLTableViewAddRowAnimationKey];
    [self insertRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)refreshItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[CBLTableViewUpdateRowAnimationKey];
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)runAutoUpdateCommandBlock:(CBLAutoUpdateRunCommandsBlock)block
{
    [self beginUpdates];
    block();
    [self endUpdates];
}

@end
