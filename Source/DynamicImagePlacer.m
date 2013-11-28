// DynamicImagePlacer.m
//
// Copyright (c) 2013 Yangyang Zhao (https://github.com/Angelbear/DynamicImagePlacer)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DynamicImagePlacer.h"
#import "RoutingHTTPServer.h"
#import "MF_Base64Additions.h"
#import "ImageUploadConnection.h"
#import "CCTemplate.h"
#import "UIImage+LocalReplacement.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

@interface DynamicImagePlacer()
@property (nonatomic, strong) RoutingHTTPServer* http;
- (void) killServer:(RouteRequest *)request withResponse:(RouteResponse *)response;
- (void) listAllIcons:(RouteRequest *)request withResponse:(RouteResponse *)response;
@end

@implementation DynamicImagePlacer


+ (id) sharedPlacer
{
    static DynamicImagePlacer* sharedSingleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[DynamicImagePlacer alloc] init];
    });
    return sharedSingleton;
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

- (void) notifyUserForAddress:(NSString*) message
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message; ;
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.alertAction = @"OPEN";
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void) startServer
{
#ifdef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIImage swizzle_method];

        self.http = [[RoutingHTTPServer alloc] init];
        [self.http setPort:8080];
        [self.http setDefaultHeader:@"Server" value:@"DynamicImagePlacer/1.0"];
        [self setupRoutes];
        [self.http setConnectionClass:[ImageUploadConnection class]];
        
        NSError *error;
        if (![self.http start:&error]) {
            [self notifyUserForAddress:error.localizedDescription];
        }
        [self notifyUserForAddress:[NSString stringWithFormat:@"http://%@:%d", [self getIPAddress], 8080]];
    });
#endif
}


- (void)setupRoutes {
    [self.http handleMethod:@"GET" withPath:@"/" target:self selector:@selector(listAllIcons:withResponse:)];
    [self.http handleMethod:@"GET" withPath:@"/kill" target:self selector:@selector(killServer:withResponse:)];
    [self.http handleMethod:@"GET" withPath:@"/delete/:name" target:self selector:@selector(deleteFile:withResponse:)];
}

- (NSString*) localPNGFileBase64String:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [[[NSFileManager defaultManager] contentsAtPath:filePath] base64String];
    }

    return nil;
}

- (BOOL) deleteLocalPNGFile:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    return NO;
}


- (void) killServer:(RouteRequest *)request withResponse:(RouteResponse *)response
{
    exit(0);
}

- (void) deleteFile:(RouteRequest *)request withResponse:(RouteResponse *)response
{
    [response setHeader:@"Content-Type" value:@"application/json"];
    [response respondWithString:[NSString stringWithFormat:@"{success:%d}", [self deleteLocalPNGFile:[request param:@"name"]]]];
}

- (void) listAllIcons:(RouteRequest *)request withResponse:(RouteResponse *)response
{
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"DynamicImagePlacer" withExtension:@"bundle"]];
    
    NSString* rowHtmlTemplate = [bundle pathForResource:@"image_row_template" ofType:@"html"];
    NSString* rowHtmlTemplateString = [[NSString alloc] initWithContentsOfFile:rowHtmlTemplate encoding:NSUTF8StringEncoding error:nil];
    
    NSString* listHtmlTemplate = [bundle pathForResource:@"list" ofType:@"html"];
    NSString* listHtmlTemplateString = [[NSString alloc] initWithContentsOfFile:listHtmlTemplate encoding:NSUTF8StringEncoding error:nil];
    
    NSArray* imagePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil];
    NSString* imageTagList = @"";

    for(int i = 0; i < [imagePaths count]; i++) {
        NSString* image = [imagePaths objectAtIndex:i];
        NSString* pngName = [image lastPathComponent];
        if ([pngName hasPrefix:@"AppIcon"] || [pngName hasPrefix:@"LaunchImage"]) {
            continue;
        }
        
        UIImage* imageInstance = [UIImage imageNamed_reserve:pngName];
    
        NSString* localFileContent = [self localPNGFileBase64String:pngName];
        
        NSString* imgTag = @"";
        if (localFileContent) {
            imgTag = [NSString stringWithFormat:@"<img src=\"data:image/png;base64,%@\" width=\"%d\" height=\"%d\">", localFileContent, (int)(imageInstance.size.width), (int)(imageInstance.size.height)];
        }
        
        NSDictionary* params = @{
                                 @"file_id" : [NSString stringWithFormat:@"%d", i],
                                 @"file_name" : pngName,
                                 @"image_width" : [NSString stringWithFormat:@"%d", (int)imageInstance.size.width],
                                 @"image_height" : [NSString stringWithFormat:@"%d", (int)imageInstance.size.height],
                                 @"local_image" : imgTag,
                                 @"image_data" : [[[NSFileManager defaultManager] contentsAtPath:image] base64String]
                                 };
  
        imageTagList = [imageTagList stringByAppendingString:[rowHtmlTemplateString templateFromDict:params]];
    }
    [response setHeader:@"Content-Type" value:@"text/html"];
    
    NSDictionary* params = @{
                             @"app_name" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                             @"app_id" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"],
                             @"app_version" : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                             @"list_content" : imageTagList
                             };
    [response respondWithString:[listHtmlTemplateString templateFromDict:params]];
}
@end
