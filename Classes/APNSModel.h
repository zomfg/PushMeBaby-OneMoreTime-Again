//
//  APNSModel.h
//  PushMeBaby
//
//  Created by Sergio Kunats on 11/9/12.
//
//

#import <Foundation/Foundation.h>

@interface APNSModel : NSObject {
    NSString* name;

    NSString* deviceToken;
    NSString* cerPath;
    NSString* applePushServer;

    NSString *alertText, *alertBody, *alertActionLocKey, *alertLocKey, *alertLocArgs, *alertLaunchImage;
    NSString *apsBadge, *apsSoundm, *apsCustomFields;
    NSNumber *apsContentAvailable;
}

@property (nonatomic, retain) NSString* name;

@property (nonatomic, retain) NSString* deviceToken;
@property (nonatomic, retain) NSString* cerPath;
@property (nonatomic, retain) NSString* applePushServer;

@property (nonatomic, retain) NSString *alertText, *alertBody, *alertActionLocKey, *alertLocKey, *alertLocArgs, *alertLaunchImage;
@property (nonatomic, retain) NSString *apsBadge, *apsSound, *apsCustomFields;
@property (nonatomic, retain) NSNumber *apsContentAvailable;

@property (nonatomic, retain, readonly) NSString *payload, *prettyPayload;
@property (nonatomic, retain, readonly) NSDictionary *apnsDictionary;

- (id) initWithDictionary:(NSDictionary*)apnsDico;

@end
