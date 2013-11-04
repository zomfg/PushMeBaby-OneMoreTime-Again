//
//  ApplicationDelegate.h
//  PushMeBaby
//
//  Created by Stefan Hafeneger on 07.04.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ioSock.h"

#import "APNSModel.h"

@interface ApplicationDelegate : NSObject<NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    NSMutableArray* apnsList;

    APNSModel* currentNotification;

	otSocket socket;
	SSLContextRef context;
	SecKeychainRef keychain;
	SecCertificateRef certificate;
	SecIdentityRef identity;

    NSWindow* window;
    NSPanel* previewWindow;
    NSTextField* previewText;
    NSTextField* payloadCountText;

    NSTableView* apnsTableView;
}

@property (nonatomic, retain) IBOutlet NSWindow* window;
@property (nonatomic, retain) IBOutlet NSPanel* previewWindow;
@property (nonatomic, retain) IBOutlet NSTextField* previewText;
@property (nonatomic, retain) IBOutlet NSTextField* payloadCountText;
@property (nonatomic, retain) IBOutlet NSTableView* apnsTableView;

@property(nonatomic, retain) APNSModel* currentNotification;
@property(nonatomic, retain) NSMutableArray* apnsList;

#pragma mark IBAction
- (IBAction)push:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)save:(id)sender;

@end
