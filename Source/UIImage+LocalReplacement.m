// UIImage+LocalReplacement.m
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

#import "UIImage+LocalReplacement.h"
#import "NSString+ImageStringResolver.h"
#import <objc/runtime.h>

@implementation UIImage (LocalReplacement)

void SwizzleClassMethod(Class class, SEL origin_Method, SEL new_Method) {
#ifdef DEBUG
    Method origMethod = class_getClassMethod(class, origin_Method);
    Method newMethod = class_getClassMethod(class, new_Method);
    
    class = object_getClass((id)class);
    
    if(class_addMethod(class, origin_Method, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(class, new_Method, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
#endif
}

+ (void) swizzle_method
{
    SwizzleClassMethod([UIImage class], @selector(imageNamed_reserve:), @selector(imageNamed:));
    SwizzleClassMethod([UIImage class], @selector(imageNamed:), @selector(imageNamed_local:));
}


+ (UIImage*) imageNamed_local:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[name realNameForImage]];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        return [[UIImage alloc] initWithContentsOfFile:filePath];
    }
    return [UIImage imageNamed_reserve:name];
}

+ (UIImage*) imageNamed_reserve:(NSString *)name
{
    // DO Nothing
    return nil;
}
@end
