//
//  MHQueryWindowController.m
//  MongoHub
//
//  Created by Syd on 10-4-28.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import "Configure.h"
#import "NSProgressIndicator+Extras.h"
#import "MHQueryWindowController.h"
#import "DatabasesArrayController.h"
#import "ResultsOutlineViewController.h"
#import "NSString+Extras.h"
#import "JsonWindowController.h"
#import "MODServer.h"
#import "MODCollection.h"
#import "MODDatabase.h"
#import "MODHelper.h"
#import "MODJsonParser.h"
#import "MHConnectionStore.h"

@implementation MHQueryWindowController

@synthesize databasesArrayController;
@synthesize findResultsViewController;
@synthesize mongoCollection = _mongoCollection;
@synthesize connectionStore = _connectionStore;

@synthesize fieldsTextField = _fieldsTextField;
@synthesize skipTextField = _skipTextField;
@synthesize limitTextField = _limitTextField;
@synthesize totalResultsTextField;
@synthesize findQueryTextField;
@synthesize findResultsOutlineView;
@synthesize findQueryLoaderIndicator;

@synthesize updateCriticalTextField;
@synthesize updateSetTextField;
@synthesize upsetCheckBox;
@synthesize updateResultsTextField;
@synthesize updateQueryTextField;
@synthesize updateQueryLoaderIndicator;

@synthesize removeCriticalTextField;
@synthesize removeResultsTextField;
@synthesize removeQueryTextField;
@synthesize removeQueryLoaderIndicator;

@synthesize insertDataTextView;
@synthesize insertResultsTextField;
@synthesize insertLoaderIndicator;

@synthesize indexTextField;
@synthesize indexesOutlineViewController;
@synthesize indexLoaderIndicator;

@synthesize mapFunctionTextView;
@synthesize reduceFunctionTextView;
@synthesize mrcriticalTextField;
@synthesize mroutputTextField;
@synthesize mrOutlineViewController;
@synthesize mrLoaderIndicator;

@synthesize expCriticalTextField;
@synthesize expFieldsTextField;
@synthesize expSkipTextField;
@synthesize expLimitTextField;
@synthesize expSortTextField;
@synthesize expResultsTextField;
@synthesize expPathTextField;
@synthesize expTypePopUpButton;
@synthesize expQueryTextField;
@synthesize expJsonArrayCheckBox;
@synthesize expProgressIndicator;

@synthesize impIgnoreBlanksCheckBox;
@synthesize impDropCheckBox;
@synthesize impHeaderlineCheckBox;
@synthesize impFieldsTextField;
@synthesize impResultsTextField;
@synthesize impPathTextField;
@synthesize impTypePopUpButton;
@synthesize impJsonArrayCheckBox;
@synthesize impStopOnErrorCheckBox;
@synthesize impProgressIndicator;


- (id)init
{
    if (self = [super initWithWindowNibName:@"QueryWindow"]) {
        
    }
    return self;
}

- (void)dealloc
{
    [databasesArrayController release];
    [findResultsViewController release];
    [_mongoCollection release];
    [_connectionStore release];
    
    [totalResultsTextField release];
    [findQueryTextField release];
    [findResultsOutlineView release];
    [findQueryLoaderIndicator release];
    
    [updateCriticalTextField release];
    [updateSetTextField release];
    [upsetCheckBox release];
    [updateResultsTextField release];
    [updateQueryTextField release];
    [updateQueryLoaderIndicator release];
    
    [removeCriticalTextField release];
    [removeResultsTextField release];
    [removeQueryTextField release];
    [removeQueryLoaderIndicator release];
    
    [insertDataTextView release];
    [insertResultsTextField release];
    [insertLoaderIndicator release];
    
    [indexTextField release];
    [indexesOutlineViewController release];
    [indexLoaderIndicator release];
    
    [mapFunctionTextView release];
    [reduceFunctionTextView release];
    [mrcriticalTextField release];
    [mroutputTextField release];
    [mrOutlineViewController release];
    [mrLoaderIndicator release];
    
    [expCriticalTextField release];
    [expFieldsTextField release];
    [expSkipTextField release];
    [expLimitTextField release];
    [expSortTextField release];
    [expResultsTextField release];
    [expPathTextField release];
    [expTypePopUpButton release];
    [expQueryTextField release];
    [expJsonArrayCheckBox release];
    [expProgressIndicator release];
    
    [impIgnoreBlanksCheckBox release];
    [impDropCheckBox release];
    [impHeaderlineCheckBox release];
    [impFieldsTextField release];
    [impResultsTextField release];
    [impPathTextField release];
    [impTypePopUpButton release];
    [impJsonArrayCheckBox release];
    [impStopOnErrorCheckBox release];
    [impProgressIndicator release];
    
    [super dealloc];
}

- (NSString *)formatedQuerySort
{
    NSString *result;
    
    result = [[_sortTextField stringValue] stringByTrimmingWhitespace];
    if ([result length] == 0) {
        result = @"{ \"_id\": 1}";
    }
    return result;
}

- (NSString *)formatedQueryWithReplace:(BOOL)replace
{
    NSString *query = @"";
    NSString *value;
    
    value = [[_criteriaComboBox stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([value length] == 24 && [[value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"1234567890abcdefABCDEF"]] length] == 0) {
        // 24 char length and only hex char... it must be an objectid
        query = [NSString stringWithFormat:@"{\"_id\": { \"$oid\": \"%@\" }}",value];
    } else if ([value length] > 0) {
        if ([value hasPrefix:@"{"]) {
            NSString *innerValue;
            
            innerValue = [[value substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([innerValue hasPrefix:@"\"$oid\""] || [innerValue hasPrefix:@"'$iod'"]) {
                query = [NSString stringWithFormat:@"{\"_id\": %@ }",value];
            } else {
                query = value;
            }
        } else if ([value hasPrefix:@"\"$oid\""] || [value hasPrefix:@"'$iod'"]) {
            query = [NSString stringWithFormat:@"{\"_id\": {%@}}",value];
        } else {
            query = [NSString stringWithFormat:@"{\"_id\": %@}",value];
        }
    }
    if (replace) {
        [_criteriaComboBox setStringValue:query];
    }
    return query;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *title = [[NSString alloc] initWithFormat:@"Query in %@", _mongoCollection.absoluteCollectionName];
    [self.window setTitle:title];
    [title release];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self release];
}

- (IBAction)findQuery:(id)sender
{
    int limit = [_limitTextField intValue];
    NSMutableArray *fields;
    NSString *criteria;
    NSString *sort = [self formatedQuerySort];
    NSString *queryTitle = [[_criteriaComboBox stringValue] retain];
    
    [self findQueryComposer:nil];
    if (limit <= 0) {
        limit = 30;
    }
    criteria = [self formatedQueryWithReplace:YES];
    fields = [[NSMutableArray alloc] init];
    for (NSString *field in [[_fieldsTextField stringValue] componentsSeparatedByString:@","]) {
        field = [field stringByTrimmingWhitespace];
        if ([field length] > 0) {
            [fields addObject:field];
        }
    }
    [findQueryLoaderIndicator start];
    [_mongoCollection findWithCriteria:criteria fields:fields skip:[_skipTextField intValue] limit:limit sort:sort callback:^(NSArray *documents, MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            [findQueryLoaderIndicator stop];
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            if ([queryTitle length] > 0) {
                [_connectionStore addNewQuery:[NSDictionary dictionaryWithObjectsAndKeys:queryTitle, @"title", [_sortTextField stringValue], @"sort", [_fieldsTextField stringValue], @"fields", [_limitTextField stringValue], @"limit", [_skipTextField stringValue], @"skip", nil] withDatabaseName:_mongoCollection.databaseName collectionName:_mongoCollection.collectionName];
            }
            [findResultsViewController.results removeAllObjects];
            [findResultsViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObjects:documents]];
            [findResultsViewController.myOutlineView reloadData];
            [_mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
                [findQueryLoaderIndicator stop];
                [totalResultsTextField setStringValue:[NSString stringWithFormat:@"Total Results: %lld (%0.2fs)", count, [[mongoQuery.userInfo objectForKey:@"timequery"] duration]]];
            }];
        }
    }];
    [fields release];
    [queryTitle release];
}

- (IBAction)expandFindResults:(id)sender
{
    [findResultsOutlineView expandItem:nil expandChildren:YES];
}

- (IBAction)collapseFindResults:(id)sender
{
    [findResultsOutlineView collapseItem:nil collapseChildren:YES];
}

- (IBAction)updateQuery:(id)sender
{
    NSString *criteria = [updateCriticalTextField stringValue];
    
    [updateQueryLoaderIndicator start];
    [_mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
        [updateResultsTextField setStringValue:[NSString stringWithFormat:@"Affected Rows: %lld", count]];
    }];
    [_mongoCollection updateWithCriteria:criteria update:[updateSetTextField stringValue] upsert:[upsetCheckBox state] multiUpdate:YES callback:^(MODQuery *mongoQuery) {
        [updateQueryLoaderIndicator stop];
    }];
}

- (IBAction)removeQuery:(id)sender
{
    [removeQueryLoaderIndicator start];
    NSString *criteria = [removeCriticalTextField stringValue];
    
    [_mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
        [updateResultsTextField setStringValue:[NSString stringWithFormat:@"Affected Rows: %lld", count]];
    }];
    [_mongoCollection removeWithCriteria:criteria callback:^(MODQuery *mongoQuery) {
        [removeQueryLoaderIndicator stop];
    }];
}

- (IBAction) insertQuery:(id)sender
{
    id objects;
    NSError *error;
    
    [insertLoaderIndicator start];
    objects = [MODJsonToObjectParser objectsFromJson:[insertDataTextView string] error:&error];
    if (error) {
        NSRunAlertPanel(@"Error", [error localizedDescription], @"OK", nil, nil);
    } else {
        if ([objects isKindOfClass:[NSDictionary class]]) {
            objects = [NSArray arrayWithObject:objects];
        }
        [_mongoCollection insertWithDocuments:objects callback:^(MODQuery *mongoQuery) {
            [insertLoaderIndicator stop];
            if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
                [insertResultsTextField setStringValue:@"Error!"];
            } else {
                [insertResultsTextField setStringValue:@"Completed!"];
            }
        }];
    }
}

- (IBAction) indexQuery:(id)sender
{
    [_mongoCollection indexListWithcallback:^(NSArray *indexes, MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [indexesOutlineViewController.results removeAllObjects];
        [indexesOutlineViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObjects:indexes]];
        [indexesOutlineViewController.myOutlineView reloadData];
    }];
}

- (IBAction) ensureIndex:(id)sender
{
    [indexLoaderIndicator start];
    [_mongoCollection createIndex:[indexTextField stringValue] name:nil options:0 callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [indexTextField setStringValue:@""];
        }
        [indexLoaderIndicator stop];
        [self indexQuery:nil];
    }];
}


- (IBAction) reIndex:(id)sender
{
    [indexLoaderIndicator start];
    [_mongoCollection reIndexWithCallback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [indexTextField setStringValue:@""];
        }
        [indexLoaderIndicator stop];
    }];
}

- (IBAction) dropIndex:(id)sender
{
    [indexLoaderIndicator start];
    [_mongoCollection dropIndex:[[indexesOutlineViewController.selectedDocument objectForKey:@"objectvalue"] objectForKey:@"key"] callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [indexLoaderIndicator stop];
        [self indexQuery:nil];
    }];
}

- (IBAction) mapReduce:(id)sender
{
    [_mongoCollection mapReduceWithMapFunction:[mapFunctionTextView string] reduceFunction:[reduceFunctionTextView string] query:[mrcriticalTextField stringValue] sort:nil limit:-1 output:[mroutputTextField stringValue] keepTemp:NO finalizeFunction:nil scope:nil jsmode:NO verbose:NO callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
    }];
}

- (IBAction)removeRecord:(id)sender
{
    if ([findResultsViewController.myOutlineView selectedRow] != -1)
    {
        NSDictionary *criteria;
        id currentItem = [findResultsViewController.myOutlineView itemAtRow:[findResultsViewController.myOutlineView selectedRow]];
        //NSLog(@"%@", [findResultsViewController rootForItem:currentItem]);
        [removeQueryLoaderIndicator start];
        
        criteria = [[NSDictionary alloc] initWithObjectsAndKeys:[currentItem objectForKey:@"objectvalueid"], @"_id", nil];
        [_mongoCollection removeWithCriteria:criteria callback:^(MODQuery *mongoQuery) {
            if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
            }
            [removeQueryLoaderIndicator stop];
            [self findQuery:nil];
        }];
        [criteria release];
    }
}

- (void)controlTextDidChange:(NSNotification *)nd
{
	NSTextField *ed = [nd object];
    
	if (ed == _criteriaComboBox || ed == _fieldsTextField || ed == _sortTextField || ed == _skipTextField || ed == _limitTextField) {
        [self findQueryComposer:nil];
    } else if (ed == updateCriticalTextField || ed == updateSetTextField) {
        [self updateQueryComposer:nil];
    } else if (ed == removeCriticalTextField) {
        [self removeQueryComposer:nil];
    } else if (ed == expCriticalTextField || ed == expFieldsTextField || ed == expSortTextField || ed == expSkipTextField || ed == expLimitTextField) {
        [self exportQueryComposer:nil];
    }

}

- (IBAction) findQueryComposer:(id)sender
{
    NSString *criteria = [self formatedQueryWithReplace:NO];
    NSString *jsFields;
    NSString *sortValue = [self formatedQuerySort];
    NSString *sort;
    
    if ([[_fieldsTextField stringValue] length] > 0) {
        NSArray *keys = [[NSArray alloc] initWithArray:[[_fieldsTextField stringValue] componentsSeparatedByString:@","]];
        NSMutableArray *tmpstr = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (NSString *str in keys) {
            [tmpstr addObject:[NSString stringWithFormat:@"%@:1", str]];
        }
        jsFields = [[NSString alloc] initWithFormat:@", {%@}", [tmpstr componentsJoinedByString:@","] ];
        [keys release];
        [tmpstr release];
    }else {
        jsFields = [[NSString alloc] initWithString:@""];
    }
    
    if ([sortValue length] > 0) {
        sort = [[NSString alloc] initWithFormat:@".sort(%@)", sortValue];
    }else {
        sort = [[NSString alloc] initWithString:@""];
    }
    
    NSString *skip = [[NSString alloc] initWithFormat:@".skip(%d)", [_skipTextField intValue]];
    NSString *limit = [[NSString alloc] initWithFormat:@".limit(%d)", [_limitTextField intValue]];
    NSString *col = [NSString stringWithFormat:@"%@.%@", _mongoCollection.databaseName, _mongoCollection.collectionName];
    
    NSString *query = [NSString stringWithFormat:@"db.%@.find(%@%@)%@%@%@", col, criteria, jsFields, sort, skip, limit];
    [jsFields release];
    [sort release];
    [skip release];
    [limit release];
    [findQueryTextField setStringValue:query];
}

- (IBAction)updateQueryComposer:(id)sender
{
    NSString *col = [NSString stringWithFormat:@"%@.%@", _mongoCollection.databaseName, _mongoCollection.collectionName];
    NSString *critical;
    if ([[updateCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[updateCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    NSString *sets;
    if ([[updateSetTextField stringValue] length] > 0) {
        //sets = [[NSString alloc] initWithFormat:@", {$set:%@}", [updateSetTextField stringValue]];
        sets = [[NSString alloc] initWithFormat:@", %@", [updateSetTextField stringValue]];
    }else {
        sets = [[NSString alloc] initWithString:@""];
    }
    NSString *upset;
    if ([upsetCheckBox state] == 1) {
        upset = [[NSString alloc] initWithString:@", true"];
    }else {
        upset = [[NSString alloc] initWithString:@", false"];
    }

    NSString *query = [NSString stringWithFormat:@"db.%@.update(%@%@%@)", col, critical, sets, upset];
    [critical release];
    [sets release];
    [upset release];
    [updateQueryTextField setStringValue:query];
}

- (IBAction)removeQueryComposer:(id)sender
{
    NSString *col = [NSString stringWithFormat:@"%@.%@", _mongoCollection.databaseName, _mongoCollection.collectionName];
    NSString *critical;
    if ([[removeCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[removeCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    NSString *query = [NSString stringWithFormat:@"db.%@.remove(%@)", col, critical];
    [critical release];
    [removeQueryTextField setStringValue:query];
}

- (IBAction) exportQueryComposer:(id)sender
{
    NSString *critical;
    if ([[expCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[expCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    
    NSString *jsFields;
    if ([[expFieldsTextField stringValue] length] > 0) {
        NSArray *keys = [[NSArray alloc] initWithArray:[[expFieldsTextField stringValue] componentsSeparatedByString:@","]];
        NSMutableArray *tmpstr = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (NSString *str in keys) {
            [tmpstr addObject:[NSString stringWithFormat:@"%@:1", str]];
        }
        jsFields = [[NSString alloc] initWithFormat:@", {%@}", [tmpstr componentsJoinedByString:@","] ];
        [keys release];
        [tmpstr release];
    }else {
        jsFields = [[NSString alloc] initWithString:@""];
    }
    
    NSString *sort;
    if ([[expSortTextField stringValue] length] > 0) {
        sort = [[NSString alloc] initWithFormat:@".sort(%@)"];
    }else {
        sort = [[NSString alloc] initWithString:@""];
    }
    
    NSString *skip = [[NSString alloc] initWithFormat:@".skip(%d)", [expSkipTextField intValue]];
    NSString *limit = [[NSString alloc] initWithFormat:@".limit(%d)", [expLimitTextField intValue]];
    NSString *col = [NSString stringWithFormat:@"%@.%@", _mongoCollection.databaseName, _mongoCollection.collectionName];
    
    NSString *query = [NSString stringWithFormat:@"db.%@.find(%@%@)%@%@%@", col, critical, jsFields, sort, skip, limit];
    [critical release];
    [jsFields release];
    [sort release];
    [skip release];
    [limit release];
    [expQueryTextField setStringValue:query];
}

- (void)showEditWindow:(id)sender
{
    switch([findResultsViewController.myOutlineView selectedRow])
	{
		case -1:
			break;
		default:{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findQuery:) name:kJsonWindowSaved object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jsonWindowWillClose:) name:kJsonWindowWillClose object:nil];
            id currentItem = [findResultsViewController.myOutlineView itemAtRow:[findResultsViewController.myOutlineView selectedRow]];
            //NSLog(@"%@", [findResultsViewController rootForItem:currentItem]);
            JsonWindowController *jsonWindowController = [[JsonWindowController alloc] init];
            jsonWindowController.mongoCollection = _mongoCollection;
            jsonWindowController.jsonDict = [findResultsViewController rootForItem:currentItem];
            [jsonWindowController showWindow:sender];
			break;
        }
	}
}

- (void)jsonWindowWillClose:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)chooseExportPath:(id)sender
{
    NSSavePanel *tvarNSSavePanelObj	= [NSSavePanel savePanel];
    int tvarInt	= [tvarNSSavePanelObj runModal];
    if(tvarInt == NSOKButton){
     	NSLog(@"doSaveAs we have an OK button");
        //NSString * tvarDirectory = [tvarNSSavePanelObj directory];
        //NSLog(@"doSaveAs directory = %@",tvarDirectory);
        NSString * tvarFilename = [[tvarNSSavePanelObj URL] path];
        NSLog(@"doSaveAs filename = %@",tvarFilename);
        [expPathTextField setStringValue:tvarFilename];
    } else if(tvarInt == NSCancelButton) {
     	NSLog(@"doSaveAs we have a Cancel button");
     	return;
    } else {
     	NSLog(@"doSaveAs tvarInt not equal 1 or zero = %3d",tvarInt);
     	return;
    } // end if
}

- (IBAction)chooseImportPath:(id)sender
{
    NSOpenPanel *tvarNSOpenPanelObj	= [NSOpenPanel openPanel];
    NSInteger tvarNSInteger	= [tvarNSOpenPanelObj runModal];
    if(tvarNSInteger == NSOKButton){
     	NSLog(@"doOpen we have an OK button");
        //NSString * tvarDirectory = [tvarNSOpenPanelObj directory];
        //NSLog(@"doOpen directory = %@",tvarDirectory);
        NSString * tvarFilename = [[tvarNSOpenPanelObj URL] path];
        NSLog(@"doOpen filename = %@",tvarFilename);
        [impPathTextField setStringValue:tvarFilename];
    } else if(tvarNSInteger == NSCancelButton) {
     	NSLog(@"doOpen we have a Cancel button");
     	return;
    } else {
     	NSLog(@"doOpen tvarInt not equal 1 or zero = %ld",(long int)tvarNSInteger);
     	return;
    } // end if
}

- (IBAction)segmentedControlAction:(id)sender
{
    NSString *identifier;
    
    identifier = [[NSString alloc] initWithFormat:@"%ld", [segmentedControl selectedSegment]];
    [tabView selectTabViewItemWithIdentifier:identifier];
    [identifier release];
}

@end

@implementation MHQueryWindowController(MODCollectionDelegate)

- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [findQueryLoaderIndicator stop];
    if (collection == _mongoCollection) {
        if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        } else {
            [findResultsViewController.results removeAllObjects];
            [findResultsViewController.results addObjectsFromArray:result];
            [findResultsViewController.myOutlineView reloadData];
        }
    }
}

- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    if (collection == _mongoCollection) {
        if ([mongoQuery.userInfo objectForKey:@"title"]) {
            if ([mongoQuery.userInfo objectForKey:@"timequery"]) {
                [[mongoQuery.userInfo objectForKey:@"textfield"] setStringValue:[NSString stringWithFormat:[mongoQuery.userInfo objectForKey:@"title"], value, [[mongoQuery.userInfo objectForKey:@"timequery"] duration]]];
            } else {
                [[mongoQuery.userInfo objectForKey:@"textfield"] setStringValue:[NSString stringWithFormat:[mongoQuery.userInfo objectForKey:@"title"], value]];
            }
        }
    }
}

- (void)mongoCollection:(MODCollection *)collection updateDonwWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    if (collection == _mongoCollection) {
        [findQueryLoaderIndicator stop];
        if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        }
    }
}

@end

@implementation MHQueryWindowController(NSComboBox)

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [[_connectionStore queryHistoryWithDatabaseName:_mongoCollection.databaseName collectionName:_mongoCollection.collectionName] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [[[_connectionStore queryHistoryWithDatabaseName:_mongoCollection.databaseName collectionName:_mongoCollection.collectionName] objectAtIndex:index] objectForKey:@"title"];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSArray *queries;
    NSUInteger index;
    
    index = [_criteriaComboBox indexOfSelectedItem];
    queries = [_connectionStore queryHistoryWithDatabaseName:_mongoCollection.databaseName collectionName:_mongoCollection.collectionName];
    if (index < [queries count]) {
        NSDictionary *query;
        
        query = [queries objectAtIndex:[_criteriaComboBox indexOfSelectedItem]];
        if ([query objectForKey:@"fields"]) {
            [_fieldsTextField setStringValue:[query objectForKey:@"fields"]];
        } else {
            [_fieldsTextField setStringValue:@""];
        }
        if ([query objectForKey:@"sort"]) {
            [_sortTextField setStringValue:[query objectForKey:@"sort"]];
        } else {
            [_sortTextField setStringValue:@""];
        }
        if ([query objectForKey:@"skip"]) {
            [_skipTextField setStringValue:[query objectForKey:@"skip"]];
        } else {
            [_skipTextField setStringValue:@""];
        }
        if ([query objectForKey:@"limit"]) {
            [_limitTextField setStringValue:[query objectForKey:@"limit"]];
        } else {
            [_limitTextField setStringValue:@""];
        }
    }
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string
{
    NSUInteger result = NSNotFound;
    NSUInteger index = 0;
    
    for (NSDictionary *history in [_connectionStore queryHistoryWithDatabaseName:_mongoCollection.databaseName collectionName:_mongoCollection.collectionName]) {
        if ([[history objectForKey:@"title"] isEqualToString:string]) {
            result = index;
            [self comboBoxSelectionDidChange:nil];
            break;
        }
        index++;
    }
    return result;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string
{
    return @"";
}

@end