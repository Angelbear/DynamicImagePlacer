// ImageUploadConnection.m
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

#import "ImageUploadConnection.h"
#import "HTTPMessage.h"
#import "HTTPDynamicFileResponse.h"
#import "MultipartMessageHeader.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPAsyncFileResponse.h"
#import "HTTPFileResponse.h"

@interface ImageUploadConnection()
@property(nonatomic, strong) MultipartFormDataParser* parser;
@property(nonatomic, strong) NSFileHandle* storeFile;
@property(nonatomic, strong) NSString* fileName;
@end

@implementation ImageUploadConnection
@synthesize storeFile=_storeFile;
@synthesize parser=_parser;
@synthesize fileName=_fileName;

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    if ([method isEqualToString:@"POST"])
    {
        if ([path hasPrefix:@"/upload"])
        {
            return YES;
        }
    }
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    // Inform HTTP server that we expect a body to accompany a POST request
    if([method isEqualToString:@"POST"] && [path hasPrefix:@"/upload"]) {
        self.fileName = [path lastPathComponent];
        
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }
        
        // enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
    return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    // set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    self.parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    self.parser.delegate = self;
}

- (void)processBodyData:(NSData *)postDataChunk
{
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [self.parser appendData:postDataChunk];
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.fileName];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header
{
    // here we just write the output from parser to the file.
    if( self.storeFile ) {
        [self.storeFile writeData:data];
    }
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
    // as the file part is over, we close the file.
    [self.storeFile closeFile];
    self.storeFile = nil;
}

- (void) processPreambleData:(NSData*) data
{
    // if we are interested in preamble data, we could process it here.
    
}

- (void) processEpilogueData:(NSData*) data
{
    // if we are interested in epilogue data, we could process it here.
    
}
@end
