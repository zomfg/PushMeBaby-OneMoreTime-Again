//
//  ApplicationDelegate.m
//  PushMeBaby
//
//  Created by Stefan Hafeneger on 07.04.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//  Modified by jlott on 01.01.2012
//

#import "ApplicationDelegate.h"

// apple gateway must be production if using a production certificate, else if using a developer certificate, then use sandbox
#define kApplePushGateway "gateway.push.apple.com" //"gateway.sandbox.push.apple.com"

// Device token should be 32 bytes
// The push text box requires there to be spaces in the token between every 8 characters.  There is code to check and fix this at runtime.
#define kDeviceToken @"1111111122222222aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff"

// name the cert to whatever you want.  Make sure the cert is bundled with app (check the Copy Bundle Resources build phase)
// cert should be of extension ".cer"  and should NOT contain the private key, just the cert by itself.
#define kPushCertificate @"Push_Notification_Certificate_Production.cer"

@interface ApplicationDelegate ()
#pragma mark Properties
@property(nonatomic, retain) NSString *deviceToken, *payload, *certificate;
#pragma mark Private
- (void)connect;
- (void)disconnect;
@end

@implementation ApplicationDelegate
@synthesize window;

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
		self.deviceToken = kDeviceToken;
		self.payload = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":1,\"sound\" : \"bingbong.aiff\"}}";
        NSString* certificateName = kPushCertificate;
		self.certificate = [[NSBundle mainBundle] pathForResource:[certificateName stringByDeletingPathExtension] ofType:[certificateName pathExtension]];
	}
	return self;
}

- (void)dealloc {
	
	// Release objects.
	self.deviceToken = nil;
	self.payload = nil;
	self.certificate = nil;
	
	// Call super.
	[super dealloc];
	
}


#pragma mark Properties

@synthesize deviceToken = _deviceToken;
@synthesize payload = _payload;
@synthesize certificate = _certificate;

#pragma mark Inherent

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[self connect];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self disconnect];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
	return YES;
}

#pragma mark Private

- (void)connect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Establish connection to server.
	PeerSpec peer;
	result = MakeServerConnection(kApplePushGateway, 2195, &socket, &peer); NSLog(@"MakeServerConnection(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Create new SSL context.
	result = SSLNewContext(false, &context); NSLog(@"SSLNewContext(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Set callback functions for SSL context.
	result = SSLSetIOFuncs(context, SocketRead, SocketWrite); NSLog(@"SSLSetIOFuncs(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Set SSL context connection.
	result = SSLSetConnection(context, socket); NSLog(@"SSLSetConnection(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Set server domain name.
	result = SSLSetPeerDomainName(context, kApplePushGateway, [[NSString stringWithUTF8String:kApplePushGateway] length]); NSLog(@"SSLSetPeerDomainName(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );

	// Open keychain.
	result = SecKeychainCopyDefault(&keychain); NSLog(@"SecKeychainOpen(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Create certificate.
	NSData *certificateData = [NSData dataWithContentsOfFile:self.certificate];
	CSSM_DATA data;
	data.Data = (uint8 *)[certificateData bytes];
	data.Length = [certificateData length];
	result = SecCertificateCreateFromData(&data, CSSM_CERT_X_509v3, CSSM_CERT_ENCODING_BER, &certificate); NSLog(@"SecCertificateCreateFromData(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Create identity.
	result = SecIdentityCreateWithCertificate(keychain, certificate, &identity); NSLog(@"SecIdentityCreateWithCertificate(): %d [%s]- %@", result, (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Set client certificate.
	CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
	result = SSLSetCertificate(context, certificates); NSLog(@"SSLSetCertificate(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	CFRelease(certificates);
	
	// Perform SSL handshake.
	do {
		result = SSLHandshake(context); NSLog(@"SSLHandshake(): %d", result);NSLog(@"SSLHandshake(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	} while(result == errSSLWouldBlock);
	
}

- (void)disconnect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Close SSL session.
	result = SSLClose(context);// NSLog(@"SSLClose(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
	// Release identity.
	CFRelease(identity);
	
	// Release certificate.
	CFRelease(certificate);
	
	// Release keychain.
	CFRelease(keychain);
	
	// Close connection to server.
	close((int)socket);
	
	// Delete SSL context.
	result = SSLDisposeContext(context);// NSLog(@"SSLDisposeContext(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
	
}

#pragma mark IBAction

- (IBAction)push:(id)sender {
	
	if(! self.certificate) {
        NSString* message = @"you need the APNS Certificate for the app to work";
		NSLog(@"%@", message);
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:message];
        [alert beginSheetModalForWindow:window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
		return;
	}
	
	// Validate input.
	if(self.deviceToken == nil || self.payload == nil) {
		return;
	}
    else if(![self.deviceToken rangeOfString:@" "].length)
    {
        //put in spaces in device token
        NSMutableString* tempString =  [NSMutableString stringWithString:self.deviceToken];
        int offset = 0;
        for(int i = 0; i < tempString.length; i++)
        {
            if(i%8 == 0 && i != 0 && i+offset < tempString.length-1)
            {
                //NSLog(@"i = %d + offset[%d] = %d", i, offset, i+offset);
                [tempString insertString:@" " atIndex:i+offset];
                offset++;
            }
        }
        NSLog(@" device token string after adding spaces = '%@'", tempString);
        self.deviceToken = tempString;
    }
	
	// Convert string into device token data.
	NSMutableData *deviceToken = [NSMutableData data];
	unsigned value;
	NSScanner *scanner = [NSScanner scannerWithString:self.deviceToken];
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
        //NSLog(@"scanned value %x", value);
		value = htonl(value);
		[deviceToken appendBytes:&value length:sizeof(value)];
	}
	NSLog(@"device token data %@, length = %ld", deviceToken, deviceToken.length);
	// Create C input variables.
	char *deviceTokenBinary = (char *)[deviceToken bytes];
	char *payloadBinary = (char *)[self.payload UTF8String];
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
	NSLog(@"SSLWrite(): [%s]- %@", (char *)GetMacOSStatusErrorString(result),[NSString stringWithUTF8String:(char *) GetMacOSStatusCommentString(result)] );
    NSLog(@"SSLWrite(): %d %ld", result, processed);
}

@end
