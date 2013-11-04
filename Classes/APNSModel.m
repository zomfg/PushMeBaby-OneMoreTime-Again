//
//  APNSModel.m
//  PushMeBaby
//
//  Created by Sergio Kunats on 11/9/12.
//
//

#import "APNSModel.h"

NSString* const kPayloadKeyAPS                  = @"aps";
NSString* const kPayloadKeyBadge                = @"badge";
NSString* const kPayloadKeySound                = @"sound";
NSString* const kPayloadKeyContentAvailable     = @"content-available";
NSString* const kPayloadKeyAlert                = @"alert";
NSString* const kPayloadKeyAlertBody            = @"body";
NSString* const kPayloadKeyAlertActionLocKey    = @"action-loc-key";
NSString* const kPayloadKeyAlertLocKey          = @"loc-key";
NSString* const kPayloadKeyAlertLocArgs         = @"loc-args";
NSString* const kPayloadKeyAlertLaunchImage     = @"launch-image";

@implementation APNSModel

@synthesize name;
@synthesize deviceToken, cerPath, applePushServer;
@synthesize alertText, alertBody, alertActionLocKey, alertLocKey, alertLocArgs, alertLaunchImage, apsContentAvailable, apsBadge, apsSound, apsCustomFields;
@synthesize payload, prettyPayload, apnsDictionary;


- (id) initWithDictionary:(NSDictionary*)apnsDico {
    if ((self = [super init]))
        [self setValuesForKeysWithDictionary:apnsDico];
    return self;
}

- (NSDictionary *) apnsDictionary {
    NSArray* propList = @[@"name", @"deviceToken", @"cerPath", @"applePushServer", @"alertText", @"alertBody", @"alertActionLocKey", @"alertLocKey", @"alertLocArgs", @"alertLaunchImage", @"apsContentAvailable", @"apsBadge", @"apsSound", @"apsCustomFields"];
    NSMutableDictionary* dico = [NSMutableDictionary new];
    for (NSString* p in propList) {
        NSString* value = [self valueForKey:p];
        if (value)
            [dico setObject:value forKey:p];
    }
    return [dico autorelease];
}

- (void) dealloc {
    [name release];
    [deviceToken release];
    [cerPath release];
    [applePushServer release];
    [alertText release];
    [alertBody release];
    [alertActionLocKey release];
    [alertLocKey release];
    [alertLocArgs release];
    [alertLaunchImage release];
    [apsContentAvailable release];
    [apsBadge release];
    [apsSound release];
    [apsCustomFields release];
    [super dealloc];
}

- (NSString*) generatePayload:(BOOL)prettyJSON {
    id alert = nil;
    if (self.alertText && ![self.alertText isEqualToString:@""])
        alert = self.alertText;
    else {
        alert = [NSMutableDictionary dictionary];
        if (self.alertBody && ![self.alertBody isEqualToString:@""])
            [alert setObject:self.alertBody forKey:kPayloadKeyAlertBody];
        if (self.alertActionLocKey && ![self.alertActionLocKey isEqualToString:@""])
            [alert setObject:self.alertActionLocKey forKey:kPayloadKeyAlertActionLocKey];
        if (self.alertLocKey && ![self.alertLocKey isEqualToString:@""])
            [alert setObject:self.alertLocKey forKey:kPayloadKeyAlertLocKey];
        if (self.alertLocArgs && ![self.alertLocArgs isEqualToString:@""])
            [alert setObject:self.alertLocArgs forKey:kPayloadKeyAlertLocArgs];
        if (self.alertLaunchImage && ![self.alertLaunchImage isEqualToString:@""])
            [alert setObject:self.alertLaunchImage forKey:kPayloadKeyAlertLaunchImage];
    }
    NSMutableDictionary* apsDico = [NSMutableDictionary new];
    if (alert)
        [apsDico setObject:alert forKey:kPayloadKeyAlert];
    if (self.apsSound && ![self.apsSound isEqualToString:@""])
        [apsDico setObject:self.apsSound forKey:kPayloadKeySound];
    if (self.apsBadge && ![self.apsBadge isEqualToString:@""]) {
        NSNumber* badgeNumber = [NSNumber numberWithInteger:[self.apsBadge integerValue]];
        [apsDico setObject:badgeNumber forKey:kPayloadKeyBadge];
    }
    if (self.apsContentAvailable && self.apsContentAvailable.boolValue)
        [apsDico setObject:@"1" forKey:kPayloadKeyContentAvailable];

    NSError *error = nil;
    NSDictionary* customDico = nil;
    if (self.apsCustomFields) {
        const char * bytes = [self.apsCustomFields UTF8String];
        NSData *customData = [[NSData alloc] initWithBytes:bytes length:strlen(bytes)];
        if (customData)
            customDico = [NSJSONSerialization JSONObjectWithData:customData options:NSJSONReadingAllowFragments error:&error];
        [customData release];
    }
    NSMutableDictionary* payloadDico = [[NSMutableDictionary alloc] initWithObjectsAndKeys:apsDico, kPayloadKeyAPS, nil];
    [apsDico release];
    [payloadDico addEntriesFromDictionary:customDico];
//    if (customDico)
//        for (NSString* k in customDico)
//            [payloadDico setObject:[customDico objectForKey:k] forKey:k];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payloadDico
                                                       options:(prettyJSON ? NSJSONWritingPrettyPrinted : 0) // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    [payloadDico release];
    NSString *jsonString = nil;
    if (!jsonData)
        NSLog(@"Got an error: %@", error);
    else
        jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    return jsonString;
}

- (NSString *) payload {
    return [self generatePayload:NO];
}

- (NSString *) prettyPayload {
    return [self generatePayload:YES];
}

@end
