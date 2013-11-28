// DynamicImagePlacerSampleTests.m
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

#import <XCTest/XCTest.h>
#import "NSString+ImageStringResolver.h"

@interface DynamicImagePlacerSampleTests : XCTestCase

@end

@implementation DynamicImagePlacerSampleTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImageNameConvertionForNoExtesion
{
    NSString* imageName = @"Test";
    BOOL isRetina =  ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00);
    XCTAssertEqualObjects([imageName realNameForImage], isRetina ? @"Test@2x.png" : @"Test.png", @"expect: %@\n"
                          "result: %@",[imageName realNameForImage], isRetina ? @"Test@2x.png" : @"Test.png");
}

- (void)testImageNameConvertionForExtesion
{
    NSString* imageName = @"Test.png";
    BOOL isRetina =  ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00);
    XCTAssertEqualObjects([imageName realNameForImage], isRetina ? @"Test@2x.png" : @"Test.png", @"expect: %@\n"
                          "result: %@",[imageName realNameForImage], isRetina ? @"Test@2x.png" : @"Test.png");
}

- (void)testImageNameConvertionForFullName
{
    NSString* imageName = @"Test@2x.png";
\
    XCTAssertEqualObjects([imageName realNameForImage],  @"Test@2x.png", @"expect: %@\n"
                          "result: %@",[imageName realNameForImage],  @"Test@2x.png" );
}

@end
