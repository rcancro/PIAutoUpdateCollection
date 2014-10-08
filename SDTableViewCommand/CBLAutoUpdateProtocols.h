//
//  CBLAutoUpdateProtocols.h
//  Pinterest
//
//  Created by Ricky Cancro on 9/28/14.
//  Copyright (c) 2014 Pinterest. All rights reserved.
//
@import Foundation;

//#import "CBLAutoUpdateCommand.h"

/**
 *  A protocol that all section objects return by SDTableViewAutoUpdateDataSource must conform to.
 *  A NSString category is included so that a section object could simply be a NSString
 */
@protocol CBLAutoUpdateSectionProtocol<NSObject>
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
@interface NSString(CBLAutoUpdateSectionProtocol)<CBLAutoUpdateSectionProtocol>
- (NSString *)identifier;
@end

/**
 *  Protocol that all rows returned from SDTableViewAutoUpdateDataSource must conform to.
 */
@protocol CBLAutoUpdateItemProtocol<NSObject>
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

+ (NSInteger)attributeHashWithModelObject:(id)object;

@end

/**
 *  The methods in SDTableViewAutoUpdateDataSource will be called twice.  Once before the underlying data has changed
 *  and once afterwards.  This is an enum so the implementer knows which pass the current call is.  This can be
 *  useful if the data needs to be reloaded after the update.
 */

/**
 *  Enum values for each pass that SDTableViewAutoUpdateDataSource methods will be called
 */
typedef NS_ENUM(NSUInteger, CBLAutoUpdatePass)
{
    kCBLAutoUpdatePassBeforeUpdate,
    kCBLAutoUpdatePassAfterUpdate,
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
@protocol CBLAutoUpdateDataSource<NSObject>

/**
 *  Returns an array of id<SDTableSectionProtocol> that represent the sections in the table
 *
 *  @param pass Used to tell the implementer whether this pass if before or after the table update
 *
 *  @return an array of id<SDTableSectionProtocol> that represent the sections in the table
 */
- (NSArray *)sectionsForPass:(CBLAutoUpdatePass)pass;

/**
 *  Returns an array of id<SDTableRowProtocol> for the given section and pass
 *
 *  @param section The section of row data to return
 *  @param pass Used to tell the implementer whether this pass if before or after the table update
 *
 *  @return and array of id<SDTableRowProtocol> for the given section/pass
 */
- (NSArray *)itemsForSection:(id<CBLAutoUpdateSectionProtocol>)section pass:(CBLAutoUpdatePass)pass;
@end

