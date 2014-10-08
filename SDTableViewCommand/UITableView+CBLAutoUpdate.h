//
//  UITableView+SDAutoUpdate.h
//
//  Created by ricky cancro on 4/22/14.
//

#import "CBLAutoUpdateCommand.h"
#import "CBLAutoUpdateProtocols.h"

extern NSString * const CBLTableViewUpdateRowAnimationKey;
extern NSString * const CBLTableViewRemoveRowAnimationKey;
extern NSString * const CBLTableViewAddRowAnimationKey;
extern NSString * const CBLTableViewRemoveSectionAnimationKey;
extern NSString * const CBLTableViewAddSectionAnimationKey;

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
typedef void (^CBLUpdateTableViewDataBlock)();

/**
 *  Category on UITableView to call the appropriate update commands based data returned from SDTableViewAutoUpdateDataSource.
 */
@interface UITableView(CBLAutoUpdate)<CBLAutoUpdateableCollectionView>

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 */
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource updateBlock:(CBLUpdateTableViewDataBlock)updateBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationType        The type of animation to perform when issuing update commands.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 */
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(CBLUpdateTableViewDataBlock)updateBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationTypes       A dictionary that defines the animation type for each update type (row refresh/removal/addition, section removal/addition)
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 */
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(CBLUpdateTableViewDataBlock)updateBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationType        The type of animation to perform when issuing update commands.
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 *  @param commandCallbackBlock This block is called right after each SDTableViewCommand is run.  It is a chance for the client to react to the call.
 */
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationType:(UITableViewRowAnimation)animationType updateBlock:(CBLUpdateTableViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock;

/**
 *  A method to compare snapshots of a table's data and issue the proper update commands (insert/remove sections and insert/remove/update rows) to the tableView.
 *
 *  @param updateDataSource     The data source that will supply the before and after snapshots of the table's data.
 *  @param animationTypes       A dictionary that defines the animation type for each update type (row refresh/removal/addition, section removal/addition)
 *  @param updateBlock          The block that actually performs the update of the table's data.  The methods of SDTableViewAutoUpdateDataSource will be called once before this block
 *                              is run to get the "before" snapshot.  After the block is run the methods will be called again to get the "after" snapshot
 *  @param commandCallbackBlock This block is called right after each SDTableViewCommand is run.  It is a chance for the client to react to the call.
 */
- (void)updateWithAutoUpdateDataSource:(id<CBLAutoUpdateDataSource>)updateDataSource withRowAnimationTypes:(NSDictionary *)animationTypes updateBlock:(CBLUpdateTableViewDataBlock)updateBlock commandCallbackblock:(CBLAutoUpdateCommandCallbackBlock)commandCallbackBlock;

@end
