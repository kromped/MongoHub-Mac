//
//  JsonWindowController.h
//  MongoHub
//
//  Created by Syd on 10-12-27.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKSyntaxColoredTextViewController.h"
#import "MODQuery.h"

@class DatabasesArrayController;
@class MODServer;
@class MODCollection;

#ifndef UKSCTD_DEFAULT_TEXTENCODING
#define UKSCTD_DEFAULT_TEXTENCODING     NSUTF8StringEncoding
#endif

@interface JsonWindowController : NSWindowController <UKSyntaxColoredTextViewDelegate, MODQueryCallbackTarget>
{
    DatabasesArrayController *databasesArrayController;
    MODServer *mongoServer;
    MODCollection *mongoCollection;
    NSString *dbname;
    NSString *collectionname;
    NSDictionary *jsonDict;
    IBOutlet NSTextView *myTextView;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextField *status;
    UKSyntaxColoredTextViewController *syntaxColoringController;
}

@property (nonatomic, retain) DatabasesArrayController *databasesArrayController;
@property (nonatomic, retain) MODServer *mongoServer;
@property (nonatomic, retain) NSString *dbname;
@property (nonatomic, retain) NSString *collectionname;
@property (nonatomic, retain) NSDictionary *jsonDict;
@property (nonatomic, retain) NSTextView *myTextView;
@property (nonatomic, readwrite, retain) MODCollection *mongoCollection;

- (IBAction)save:(id)sender;
- (IBAction)recolorCompleteFile: (id)sender;

@end
