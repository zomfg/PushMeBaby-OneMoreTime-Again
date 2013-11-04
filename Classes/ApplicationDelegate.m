//
//  ApplicationDelegate.m
//  PushMeBaby
//
//  Created by Stefan Hafeneger on 07.04.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//  Modified by jlott on 01.01.2012
//

#import "ApplicationDelegate.h"


NSString* const kAPNSListKey = @"apns_list";
const NSUInteger kPayloadSizeLimit = 256;

@implementation ApplicationDelegate
#pragma mark Properties

@synthesize window;
@synthesize previewText;
@synthesize previewWindow;
@synthesize payloadCountText;
@synthesize apnsTableView;

@synthesize apnsList;
@synthesize currentNotification;

#pragma mark Allocation

- (void) loadAPNSList {
    apnsList = [NSMutableArray new];
    NSArray* data = [[NSUserDefaults standardUserDefaults] objectForKey:kAPNSListKey];
    if (data == nil)
        return;
    for (NSDictionary* d in data) {
        APNSModel* m = [[APNSModel alloc] initWithDictionary:d];
        [apnsList addObject:m];
        [m release];
    }
}

- (id) init {
    if ((self = [super init])) {
        [self initNewNotification];
        [self loadAPNSList];
    }
    return self;
}

- (void)dealloc {
	// Release objects.
	self.currentNotification = nil;
    self.apnsList = nil;
	// Call super.
	[super dealloc];
}

#pragma mark Inherent

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
	return YES;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updatePayloadPreview) userInfo:nil repeats:YES];
}

#pragma mark Private

- (void) initNewNotification {
    self.currentNotification = [APNSModel new];
}

- (void) updatePayloadPreview {
    NSUInteger length = self.currentNotification.payload.length;
    if (length > kPayloadSizeLimit)
        self.payloadCountText.textColor = [NSColor redColor];
    else
        self.payloadCountText.textColor = [NSColor whiteColor];
    [self.payloadCountText setIntegerValue:length];
    [self.previewText setStringValue:self.currentNotification.prettyPayload];
}

- (void) displayMessage:(NSString*)message {
    NSLog(@"%@", message);
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:message];
    [alert beginSheetModalForWindow:window
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];
}

- (BOOL) checkFormData {
    NSString* message = nil;
    if (self.currentNotification.deviceToken == nil || [self.currentNotification.deviceToken isEqualToString:@""])
        message = @"Enter your device token";
    else if (![[NSFileManager defaultManager] fileExistsAtPath:self.currentNotification.cerPath])
        message = @"APNS Certificate not found";
    else if (self.currentNotification.cerPath == nil || [self.currentNotification.cerPath isEqualToString:@""])
        message = @"you need the APNS Certificate for the app to work";

    if (message == nil)
        return YES;

    [self displayMessage:message];
    return NO;
}

- (BOOL) connect {
	// Define result variable.
	OSStatus result;

	// Establish connection to server.
	PeerSpec peer;
	result = MakeServerConnection([self.currentNotification.applePushServer UTF8String], 2195, &socket, &peer);
    NSLog(@"MakeServerConnection(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Create new SSL context.
	result = SSLNewContext(false, &context);
    NSLog(@"SSLNewContext(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Set callback functions for SSL context.
	result = SSLSetIOFuncs(context, SocketRead, SocketWrite);
    NSLog(@"SSLSetIOFuncs(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Set SSL context connection.
	result = SSLSetConnection(context, socket);
    NSLog(@"SSLSetConnection(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Set server domain name.
	result = SSLSetPeerDomainName(context, [self.currentNotification.applePushServer UTF8String], [self.currentNotification.applePushServer length]);
    NSLog(@"SSLSetPeerDomainName(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Open keychain.
	result = SecKeychainCopyDefault(&keychain);
    NSLog(@"SecKeychainOpen(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));

	// Create certificate.
	NSData *certificateData = [NSData dataWithContentsOfFile:self.currentNotification.cerPath];
    certificate = SecCertificateCreateWithData(NULL, (CFDataRef)certificateData);
    NSLog(@"SecCertificateCreateFromData(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));
	
	// Create identity.
	result = SecIdentityCreateWithCertificate(keychain, certificate, &identity);
    NSLog(@"SecIdentityCreateWithCertificate(): %d [%s]- %s", result, (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));
	
	// Set client certificate.
	CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
	result = SSLSetCertificate(context, certificates);
    NSLog(@"SSLSetCertificate(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));
	CFRelease(certificates);
	
	// Perform SSL handshake.
	do {
		result = SSLHandshake(context);
        NSLog(@"SSLHandshake(): %d", result);
        NSLog(@"SSLHandshake(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));
	} while(result == errSSLWouldBlock);
	return result == errSecSuccess;
}

- (void) disconnect {

	// Define result variable.
	OSStatus result;
	
	// Close SSL session.
	result = SSLClose(context);// NSLog(@"SSLClose(): [%s]- %s", (char *)GetMacOSStatusErrorString(result),(char *)GetMacOSStatusCommentString(result));
	
	// Release identity.
	CFRelease(identity);
	
	// Release certificate.
	CFRelease(certificate);
	
	// Release keychain.
	CFRelease(keychain);
	
	// Close connection to server.
	close((int)socket);
	
	// Delete SSL context.
	result = SSLDisposeContext(context);// NSLog(@"SSLDisposeContext(): [%s]- %s", (char *)GetMacOSStatusErrorString(result),(char *)GetMacOSStatusCommentString(result));
	
}

#pragma mark IBAction


- (IBAction)reset:(id)sender {
    [self initNewNotification];
}

- (IBAction)add:(id)sender {
    if ([self.apnsList containsObject:self.currentNotification])
        return;
    [self.apnsList addObject:self.currentNotification];
    [self.apnsTableView reloadData];
}

- (IBAction)remove:(id)sender {
    [self.apnsList removeObject:self.currentNotification];
    [self.apnsTableView reloadData];
    if (self.apnsTableView.selectedRow > -1 && self.apnsTableView.selectedRow < [self.apnsList count])
        self.currentNotification = [self.apnsList objectAtIndex:self.apnsTableView.selectedRow];
    else
        [self initNewNotification];
}

- (IBAction)save:(id)sender {
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray* data = [[NSMutableArray alloc] initWithCapacity:[self.apnsList count]];
    for (APNSModel* m in self.apnsList)
        [data addObject:m.apnsDictionary];
    [ud setObject:data forKey:kAPNSListKey];
    [data release];
    [ud synchronize];
}

- (IBAction)preview:(id)sender {
    [self updatePayloadPreview];
}

- (IBAction)push:(id)sender {
    if (![self checkFormData])
        return;
	if (![self connect])
        return [self displayMessage:@"SSL Fail"];

    NSString* payload = self.currentNotification.payload;
	// Validate input.
	if (payload == nil)
		return;
    if (![self.currentNotification.deviceToken rangeOfString:@" "].length)
    {
        //put in spaces in device token
        NSMutableString* tempString =  [NSMutableString stringWithString:self.currentNotification.deviceToken];
        int offset = 0;
        for (int i = 0; i < tempString.length; i++)
        {
            if (i%8 == 0 && i != 0 && i+offset < tempString.length-1)
            {
                //NSLog(@"i = %d + offset[%d] = %d", i, offset, i+offset);
                [tempString insertString:@" " atIndex:i+offset];
                offset++;
            }
        }
        NSLog(@" device token string after adding spaces = '%@'", tempString);
        self.currentNotification.deviceToken = tempString;
    }
	
	// Convert string into device token data.
	NSMutableData *deviceTokenData = [NSMutableData data];
	unsigned value;
	NSScanner *scanner = [NSScanner scannerWithString:self.currentNotification.deviceToken];
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
        //NSLog(@"scanned value %x", value);
		value = htonl(value);
		[deviceTokenData appendBytes:&value length:sizeof(value)];
	}
	NSLog(@"device token data %@, length = %ld", deviceTokenData, deviceTokenData.length);
	// Create C input variables.
	char *deviceTokenBinary = (char *)[deviceTokenData bytes];
	char *payloadBinary = (char *)[payload UTF8String];
	size_t payloadLength = strlen(payloadBinary);
	
	// Define some variables.
	uint8_t command = 0;
	char message[293];
	char *pointer = message;
	uint16_t networkTokenLength = htons(32);
	uint16_t networkPayloadLength = htons(payloadLength);
	
	// Compose message.
	memcpy(pointer, &command, sizeof(uint8_t));
	pointer += sizeof(uint8_t);
	memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, deviceTokenBinary, 32);
	pointer += 32;
	memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, payloadBinary, payloadLength);
	pointer += payloadLength;
	
	NSLog(@"pointer - message- %ld", (pointer -message));
	// Send message over SSL.
	size_t processed = 0;
	OSStatus result = SSLWrite(context, &message, (pointer - message), &processed);// NSLog(@"SSLWrite(): %d %d", result, processed);
	NSLog(@"SSLWrite(): [%s]- %s", (char *)GetMacOSStatusErrorString(result), (char *)GetMacOSStatusCommentString(result));
    NSLog(@"SSLWrite(): %d %ld", result, processed);
    [self disconnect];
}


#pragma mark TableViewDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.apnsList count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= [self.apnsList count])
        return nil;
    APNSModel* notification = [self.apnsList objectAtIndex:row];
    return [notification valueForKey:[tableColumn identifier]];
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView* tableView = notification.object;
    if (tableView.selectedRow > -1 && tableView.selectedRow < [self.apnsList count])
        self.currentNotification = [self.apnsList objectAtIndex:tableView.selectedRow];
}

@end
