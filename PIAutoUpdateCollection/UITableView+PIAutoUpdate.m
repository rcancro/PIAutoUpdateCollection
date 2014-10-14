//
//  UITableView+PIAutoUpdate.m
//
//  Created by ricky cancro on 4/22/14.
//
#import <objc/runtime.h>
#import "UITableView+PIAutoUpdate.h"

NSString * const PITableViewUpdateRowAnimationKey = @"PICommandUpdateItemAnimationKey";
NSString * const PITableViewRemoveRowAnimationKey = @"PICommandRemoveItemAnimationKey";
NSString * const PITableViewAddRowAnimationKey = @"PICommandAddItemAnimationKey";
NSString * const PITableViewRemoveSectionAnimationKey = @"PICommandRemoveSectionAnimationKey";
NSString * const PITableViewAddSectionAnimationKey = @"PICommandAddSectionAnimationKey";

static char kAssociatedObjectKey;

#pragma mark - NSString(PITableSectionObject)
@implementation NSString(PITableSectionProtocol)

- (NSString *)identifier
{
    return self;
}

@end

#pragma mark - UITableView(PIAutoUpdate)
@implementation UITableView(PIAutoUpdate)

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource updateBlock:(PIUpdateTableViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:UITableViewRowAnimationAutomatic updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(PIUpdateTableViewDataBlock)updateBlock;
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationType:animationType updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(PIUpdateTableViewDataBlock)updateBlock
{
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationTypes:animationTypes updateBlock:updateBlock commandCallbackblock:nil];
}

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(PIUpdateTableViewDataBlock)updateBlock commandCallbackblock:(PIAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    NSDictionary *animationTypes = @{PITableViewAddRowAnimationKey : @(animationType),
                                     PITableViewAddSectionAnimationKey : @(animationType),
                                     PITableViewRemoveRowAnimationKey : @(animationType),
                                     PITableViewRemoveSectionAnimationKey : @(animationType),
                                     PITableViewUpdateRowAnimationKey : @(animationType)};
    [self updateWithAutoUpdateDataSource:updateDataSource withRowAnimationTypes:animationTypes updateBlock:updateBlock commandCallbackblock:commandCallbackBlock];
}

- (void)updateWithAutoUpdateDataSource:(id<PIAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(PIUpdateTableViewDataBlock)updateBlock commandCallbackblock:(PIAutoUpdateCommandCallbackBlock)commandCallbackBlock
{
    objc_setAssociatedObject(self, &kAssociatedObjectKey, animationTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [PIAutoUpdateCommandManager runCommandsWithAutoUpdateDataSource:updateDataSource
                                                autoUpdateableObject:self
                                                         updateBlock:updateBlock
                                                commandCallbackblock:commandCallbackBlock];
    objc_setAssociatedObject(self, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - PIAutoUpdateableObject

- (void)removeSections:(NSIndexSet *)sections
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[PITableViewRemoveSectionAnimationKey];
    [self deleteSections:sections withRowAnimation:[animationType integerValue]];
}

- (void)insertSections:(NSIndexSet *)sections
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[PITableViewAddSectionAnimationKey];
    [self insertSections:sections withRowAnimation:[animationType integerValue]];
}

- (void)removeItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[PITableViewRemoveRowAnimationKey];
    [self deleteRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)insertItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[PITableViewAddRowAnimationKey];
    [self insertRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)refreshItems:(NSArray *)indexPaths
{
    NSDictionary *animationTypes = objc_getAssociatedObject(self, &kAssociatedObjectKey);
    NSNumber *animationType = animationTypes[PITableViewUpdateRowAnimationKey];
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:[animationType integerValue]];
}

- (void)runAutoUpdateCommandBlock:(PIAutoUpdateRunCommandsBlock)block
{
    [self beginUpdates];
    block();
    [self endUpdates];
}

@end
