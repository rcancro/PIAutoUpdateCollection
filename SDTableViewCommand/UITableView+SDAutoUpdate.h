//
//  UITableView+SDAutoUpdate.h
//
//  Created by ricky cancro on 4/22/14.
//

#import "SDTableViewCommand.h"

/**
 *  A protocol that all section objects return by SDTableViewAutoUpdateDataSource must conform to.
 *  A NSString category is included so that a section object could simply be a NSString
 */
@protocol SDTableSectionProtocol<NSObject>
/**
 *  required method for SDTableSectionProtocol.
 *
 *  @return returns a unique (to the tableView) identifier of a section (usually just the section's title)
 */
- (NSString *)identifier;
@end

/**
 *  Simple category so that NSString will conform to SDTableSectionProtocol
 */
@interface NSString(SDTableSectionProtocol)<SDTableSectionProtocol>
- (NSString *)identifier;
@end

/**
 *  Protocol that all rows returned from SDTableViewAutoUpdateDataSource must conform to.
 */
@protocol SDTableRowProtocol<NSObject>
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

/**
 *  The methods in SDTableViewAutoUpdateDataSource will be called twice.  Once before the underlying data has changed
 *  and once afterwards.  This is an enum so the implementer knows which pass the current call is.  This can be
 *  useful if the data needs to be reloaded after the update.
 */

/**
 *  Enum values for each pass that SDTableViewAutoUpdateDataSource methods will be called
 */
typedef NS_ENUM(NSUInteger, SDTableViewAutoUpdatePass)
{
    kSDTableViewAutoUpdatePassBeforeUpdate,
    kSDTableViewAutoUpdatePassAfterUpdate,
};

/**
 *  Protocol that must be implemented in order to use the auto-updating tableview method.  
 *  These methods act as a data source to give a "snapshot" of the table data.  
 *  The autoUpdate methods on UITableView require a SDUpdateTableDataBlock.  This block will perform the
 *  actual changing of the tableview's underlying data.
 *
 *  To create the snapshot of the table, the SDTableViewAutoUpdateDataSource methods will be called once
 *  before the updateBlock is called (with the value kSDTableViewAutoUpdatePassBeforeUpdate for the pass parameter)
 *  and once after the updateBlock is called (with the value kSDTableViewAutoUpdatePassAfterUpdate for the pass parameter)
 *
 *  In each case the implementer should send back the current state of the tableView.
 */
@protocol SDTableViewAutoUpdateDataSource<NSObject>

/**
 *  Returns an array of id<SDTableSectionProtocol> that represent the sections in the table
 *
 *  @param pass Used to tell the implementer whether this pass if before or after the table update
 *
 *  @return an array of id<SDTableSectionProtocol> that represent the sections in the table
 */
- (NSArray *)sectionsForPass:(SDTableViewAutoUpdatePass)pass;

/**
 *  Returns an array of id<SDTableRowProtocol> for the given section and pass
 *
 *  @param section The section of row data to return
 *  @param pass Used to tell the implementer whether this pass if before or after the table update
 *
 *  @return and array of id<SDTableRowProtocol> for the given section/pass
 */
- (NSArray *)rowsForSection:(id<SDTableSectionProtocol>)section pass:(SDTableViewAutoUpdatePass)pass;
@end

/**
 *  A block passed into the update method of the tableview. This block is where the implementer will 
 *  update the underlying data in the tableView.
 *
 *  This could be as simple as:
 *    SDUpdateTableDataBlock updateBlock = ^{
 *       self.tableData = someNewDataArray;
 *    };
 *
 *  Once the block is run the methods in SDTableViewAutoUpdateDataSource will be called a second time to 
 *  get an updated snapshot of the table.
 */
typedef void (^SDUpdateTableDataBlock)();



/**
 *  Category on UITableView to call the appropriate update commands based data returned from SDTableViewAutoUpdateDataSource.
 */
@interface UITableView(SDAutoUpdate)

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 */
- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource updateBlock:(SDUpdateTableDataBlock)updateBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationType        The type of animation to perform when issuing update commands.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 */
- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(SDUpdateTableDataBlock)updateBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationType        The type of animation to perform when issuing update commands.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 *  @param commandCallbackBlock This block is called right after each SDTableViewCommand is run.  It is a chance for the client to react to the call.
 */
- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(SDUpdateTableDataBlock)updateBlock commandCallbackblock:(SDTableCommandCallbackBlock)commandCallbackBlock;

@end
