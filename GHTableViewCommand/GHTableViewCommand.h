//
//  GHTableCommand.h
//  GHTableViewCommand
//
//  Created by ricky cancro on 2/9/14.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM (NSUInteger, GHTableCommandType)
{
    kASDATableCommandUpdateRow,
    kASDATableCommandAddRow,
    kASDATableCommandRemoveRow,
    
    kASDATableCommandRemoveSection,
    kASDATableCommandAddSection,
};

/**
 *  A protocol that all section objects used in SDTableViewCommand must conform to.
 *  A NSString category is included so that a section object could simply be a NSString
 */
@protocol GHTableSectionObject<NSObject>
/**
 *  required method for SDTableSectionObject.
 *
 *  @return returns a unique (to the tableView) identifier of a section (usually just the section's title)
 */
- (NSString *)identifier;
@end

/**
 *  Simple category so that NSString will conform to SDTableSectionObject
 */
@interface NSString(GHTableSectionObject)<GHTableSectionObject>
- (NSString *)identifier;
@end

/**
 *  Protocol that all rows used in SDTableViewCommand must conform to.
 */
@protocol GHTableRowObject<NSObject>
/**
 *  Returns a hash to determine if two rows are equal.  For example, two rows that are both for
 *  the same product, say a Klondike bar, would return the same hash.  You can implement the hash to 
 *  include whatever attributes make the Klondike bar unique by combinbing them in a string and returning
 *  that string's hash.
 *
 *  @return unique hash for this row object
 */
- (NSInteger)hash;
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
 *  Simple object used to pass data to the SDTableViewCommand function that performs table update methods.
 */
@interface GHTableCommandSectionData : NSObject
/**
 *  An array of the old sections in their proper order.  All items in the array should conform to SDTableSectionObject
 */
@property (nonatomic, copy) NSArray *oldSections;

/**
 *  An array of the new sections in their proper order.  All items in the array should conform to SDTableSectionObject
 */
@property (nonatomic, copy) NSArray *updatedSections;

/**
 *  Convenience method to create GHTableCommandSectionDatax
 *
 *  @param oldSections     an array of id<SDTableSectionObject> represnting the sections in the table before the update
 *  @param updatedSections an array of id<SDTableSectionObject> represnting the sections in the table after the update
 *
 */
+ (instancetype)sectionDataWithOldSections:(NSArray *)oldSections updatedSections:(NSArray *)updatedSections;
@end

/**
 *  Simple object used to hold rowData needed by SDTableViewCommand
 */
@interface GHTableCommandRowData : NSObject

/**
 *  The identifier of the section that these rows belong to
 */
@property (nonatomic, copy) NSString *sectionIdentifier;

/**
 *  An array of objects that conform to SDTableRowObject that were contained in this section before the model changed
 */
@property (nonatomic, copy) NSArray *oldSectionRows;

/**
 *  An array of objects that conform to SDTableRowObject that are contained in this section after the model changed
 */
@property (nonatomic, copy) NSArray *updatedSectionRows;

@end


/**
 *  Object to hold all of the table row data
 */
@interface GHTableCommandTableRowData : NSObject

/**
 *  Add the outdated data for a given section
 *
 *  @param data              an array of id<GHTableRowObject> for the outdated section data
 *  @param sectionIdentifier the section
 */
- (void)addOldData:(NSArray *)data forSection:(NSString *)sectionIdentifier;

/**
 *  Add the updated data for a given section
 *
 *  @param data              an array of id<GHTableRowObject> for the updated section data
 *  @param sectionIdentifier the section
 */
- (void)addUpdatedData:(NSArray *)data forSection:(NSString *)sectionIdentifier;

@end



@class GHTableViewCommand;
typedef void (^GHTableCommandCallbackBlock)(GHTableViewCommand *command);

/**
 *  A table command encapsulated in a class.  These commands are run automatically by the class method, but are sent along via the callback block
 *  so the client can see which command it is getting a call back about.
 */
@interface GHTableViewCommand : NSObject

/**
 *  The type of command that will be exectued.  See the ASDATableCommandType enum above.
 */
@property (nonatomic, assign, readonly) GHTableCommandType commandType;

/**
 *  The row that will be affected (id applicable)
 */
@property (nonatomic, assign, readonly) NSUInteger row;

/**
 *  The section Identifier that will be affected (if applicable)
 */
@property (nonatomic, copy, readonly) NSString * sectionIdentifier;

/**
 *  nil until the index path is resolved right before the actual table update is performed.
 *  this property will be valid when TableCommandCallbackBlock is called.
 */
@property (nonatomic, strong, readonly) NSIndexPath *resolvedIndexPath;

@end

/**
 *  Category on UITableView to call the appropriate update commands based on the section and row data passed in.
 */
@interface UITableView(GHTableViewCommand)

/**
 *  sectionData and rowData are looked at and the appropriate table update commands to go from the old state to the new state are
 *  against the tableView.
 *
 *  @param sectionData   the sectionData that contains the oldSections and newSections
 *  @param rowData       an array of SDTableCommandRowData objects for each section in the table.  Note that the order of the SDTableCommandRowData
                         does not matter since indexes are determined by the sectionIdentifier
 *  @param animationType type of animation to use when running the table update commands
 *  @param block         callBack block that is called right before any table update method.
 */
- (void)updateWithSectionData:(GHTableCommandSectionData *)sectionData rowData:(GHTableCommandTableRowData *)rowData withRowAnimation:(UITableViewRowAnimation)animationType callback:(GHTableCommandCallbackBlock)block;

@end

