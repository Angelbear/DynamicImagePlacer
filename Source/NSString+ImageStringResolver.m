// NSString+ImageStringResolver.m
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

#import "NSString+ImageStringResolver.h"

@implementation NSString (ImageStringResolver)
- (NSString*) realNameForImage
{
    BOOL isRetina =  ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00);

    // Use [UIImage imageNamed:] internal logic to judge which image to use
    if ([self hasSuffix:@"@2x.png"]) {
        return self;
    }
    
    if ([self hasSuffix:@".png"]) {
        if (isRetina && ![self hasSuffix:@"@2x"]) {
            return [[self stringByDeletingPathExtension] stringByAppendingString:@"@2x.png"];
        }
        return self;
    }
    
    if (![self hasSuffix:@".png"]) {
        if (isRetina && ![self hasSuffix:@"@2x"]) {
            return [self stringByAppendingString:@"@2x.png"];
        }
        return [self stringByAppendingPathExtension:@"png"];
    }
    
    return self;
}
@end
