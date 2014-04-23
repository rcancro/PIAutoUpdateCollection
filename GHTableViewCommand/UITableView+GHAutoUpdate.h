//
//  UITableView+GHAutoUpdate.h
//
//  Created by ricky cancro on 4/22/14.
//

#import "GHTableViewCommand.h"

/**
 *  A protocol that all section objects used in GHTableCommandSectionIndexData must conform to.
 *  A NSString category is included so that a section object could simply be a NSString
 */
@protocol GHTableSectionProtocol<NSObject>
/**
 *  required method for GHTableSectionProtocol.
 *
 *  @return returns a unique (to the tableView) identifier of a section (usually just the section's title)
 */
- (NSString *)identifier;
@end

/**
 *  Simple category so that NSString will conform to GHTableSectionProtocol
 */
@interface NSString(GHTableSectionProtocol)<GHTableSectionProtocol>
- (NSString *)identifier;
@end

/**
 *  Protocol that all rows used in GHTableCommandSectionData must conform to.
 */
@protocol GHTableRowProtocol<NSObject>
/**
 *  Returns a hash to determine if two rows are equal.  For example, two rows that are both for
 *  the same product, say a Klondike bar, would return the same hash.  You can implement the hash to
 *  include whatever attributes make the Klondike bar unique by combinbing them in a string and returning
 *  that string's hash.
 *
 *  @return unique hash for this row object
 */
- (NSUInteger)hash;
@optional

/**
 *  It is possible that some rows may have attributes that change that would require a cell refresh, but
 *  not a complete removal of the cell.  In the case of a Klondike bar, perhaps the user upped the quantity
 *  desired from 1 to 2.  This function is used to signal that a cell just needs to reload itself instead
 *  of needing to completely remove and re-add itself.
 *
 *  @return hash based on attributes of the row item.
 */
- (NSInteger)attributeHash;
@end

typedef NS_ENUM(NSUInteger, GHTableViewAutoUpdatePass)
{
    kGHTableViewAutoUpdatePassBeforeUpdate,
    kGHTableViewAutoUpdatePassAfterUpdate,
};

@protocol GHTableViewAutoUpdateDataSource<NSObject>
- (NSArray *)sectionsForPass:(GHTableViewAutoUpdatePass)pass;
- (NSArray *)rowsForSection:(id<GHTableSectionProtocol>)section pass:(GHTableViewAutoUpdatePass)pass;
@end

typedef void (^GHUpdateTableDataBlock)();

/**
 *  Category on UITableView to call the appropriate update commands based on the section and row data passed in.
 */
@interface UITableView(GHAutoUpdate)

/**
 *  sectionData and rowData are compared and the appropriate table update commands to updaet the table from the old state to the new state are
 *  called against the tableView.
 *
 *  @param sectionData   the sectionData that contains the outdatedSections and updatedSections
 *  @param rowData       an array of GHTableCommandRowData objects for each section in the table.  Note that the order of the GHTableCommandRowData does not matter since indexes are determined by sectionData and the sectionIdentifier
 *  @param animationType type of animation to use when running the table update commands
 *  @param block         callBack block that is called right before any table update method.
 */
//- (void)updateWithSectionIndexData:(GHTableCommandSectionIndexData *)sectionData sectionData:(GHTableCommandAllSectionData *)rowData withRowAnimation:(UITableViewRowAnimation)animationType callback:(GHTableCommandCallbackBlock)block;

- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource updateBlock:(GHUpdateTableDataBlock)updateBlock;
- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(GHUpdateTableDataBlock)updateBlock;
- (void)updateWithAutoUpdateDataSource:(id<GHTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(GHUpdateTableDataBlock)updateBlock commandCallbackblock:(GHTableCommandCallbackBlock)commandCallbackBlock;

@end
