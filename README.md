SDAutoUpdatingTableView
==================

SDAutoUpdatingTableView aims to make it so you never have to worry about this again:

````
Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid update: invalid number of rows in section 0. The number of rows contained in an existing section after the update (10) must be equal to the number of rows contained in that section before the update (10), plus or minus the number of rows inserted or deleted from that section (0 inserted, 1 deleted).'
````

By looking at the state of the table's data before and after a model change, a UITableView will automatically issue all of the required update/insert/delete commands needed to keep the table in a consistent state.

##How does it work?

#SDTableViewAutoUpdateDataSource
To make the comparisons work, we need a way for the tableview to know if its sections and rows have changed.  To provide this there is a protocol that will provide a "snapshot" of the data:

````
typedef NS_ENUM(NSUInteger, SDTableViewAutoUpdatePass)
{
    kSDTableViewAutoUpdatePassBeforeUpdate,
    kSDTableViewAutoUpdatePassAfterUpdate,
};

@protocol SDTableViewAutoUpdateDataSource<NSObject>
- (NSArray *)sectionsForPass:(SDTableViewAutoUpdatePass)pass;
- (NSArray *)rowsForSection:(id<SDTableSectionProtocol>)section pass:(SDTableViewAutoUpdatePass)pass;
@end
````
The two methods in the signature provide the snapshot for the given "pass".  Once pass is pre model refresh and one is post model refresh.

#SDTableSectionProtocol and SDTableRowProtocol
The arrays that are returned must contain objects that conform to this protocol for sections:

````
@protocol SDTableSectionProtocol<NSObject>
- (NSString *)identifier;
@end
````

And this protocol for rows:

````
@protocol SDTableRowProtocol<NSObject>
- (NSUInteger)hash;
@optional
- (NSInteger)attributeHash;
@end
````

The row protocol has two methods to identify itself.  For example, two rows that are both for the same product, say a Klondike bar, would return the same hash.  You can implement the hash to include whatever attributes make the Klondike bar unique by combinbing them in a string and returning that string's hash.

The attribute hash helps signal a refresh of a row.  In the case of a Klondike bar, perhaps the user upped the quantity desired from 1 to 2.  The attributeHash method could return the quantity (as a string) so that the cell will know it needs to be updated.

#UITableView+SDAutoUpdate
To make this happen you call a category method on UITableView:

````
- (void)updateWithAutoUpdateDataSource:(id<SDTableViewAutoUpdateDataSource>)updateDataSource updateBlock:(SDUpdateTableDataBlock)updateBlock;
````

You pass in the auto update data source and a block that actually updates the underlying data of the table.  The category will get a snapshot of the table, run the update block, and then take another snapshot (giving it a before and after snapshot).

In code it will look something like:
````
- (void)newDataFromSomeService:(NSArray *)newData
{
    @weakify(self);
    [self.tableView updateWithAutoUpdateDataSource:self updateBlock:^{
        @strongify(self);
        self.tableViewData = newData;
    }];
}
````

Ta-da!

##How to use it
To use it, simply add the following files to your project:
* SDTableViewCommand.h
* SDTableViewCommand.m
* UITableView+SDAutoUpdate.h
* UITableView+SDAutoUpdate.m
* SDMacros.h

Please let me know if you have any additions/comments/etc.

This class is part of SetDirection's ios-shared repository. https://github.com/setdirection/ios-shared

