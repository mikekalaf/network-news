//
//  Base64Decoder.m
//  Network News
//
//  Created by David Schweinsberg on 5/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "NNBase64Decoder.h"


static char base64LUT[256] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 1x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, // 2x
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, 64, -1, -1, // 3x
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, // 4x
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, // 5x
    -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, // 6x
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1, // 7x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 8x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 9x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Ax
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Bx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Cx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Dx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Ex
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1  // Fx
};
//  x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF

@interface NNBase64Decoder ()
{
    NSData *_data;
}

@end

@implementation NNBase64Decoder

- (id)initWithData:(NSData *)encodedData
{
    self = [super init];
    if (self)
    {
        _data = encodedData;
    }
    return self;
}

- (NSData *)decode
{
    NSMutableData *decodedData = nil;
    char inputGroup[4];
    char outputGroup[3];
    for (NSUInteger i = 0; i < [_data length]; i += 4)
    {
        NSRange range = NSMakeRange(i, 4);
        [_data getBytes:inputGroup range:range];

        if (inputGroup[0] == 13 || inputGroup[0] == 10)
        {
            // We've reached the end of a line, so rewind three characters
            // and try again (this will probably happen twice: CR + LF
            i -= 3;
            continue;
        }

        char in0 = base64LUT[inputGroup[0]];
        char in1 = base64LUT[inputGroup[1]];
        char in2 = base64LUT[inputGroup[2]];
        char in3 = base64LUT[inputGroup[3]];

        // Are all the encoding inputs legal?
        if (in0 == -1 || in1 == -1 || in2 == -1 || in3 == -1)
            return nil;

        outputGroup[0] = ((in0 << 2) & 0xfc) | ((in1 >> 4) & 0x03);
        outputGroup[1] = ((in1 << 4) & 0xf0) | ((in2 >> 2) & 0x0f);
        outputGroup[2] = ((in2 << 6) & 0xc0) | (in3 & 0x3f);

        if (decodedData == nil)
            decodedData = [[NSMutableData alloc] initWithCapacity:[_data length] / 4 * 3];

        [decodedData appendBytes:outputGroup length:3];

        // It it only a CRLF that remains?
        if (i + 6 >= [_data length] - 2)
        {
            char b[2];
            [_data getBytes:b range:NSMakeRange(i + 4, 1)];
            break;
        }
    }
    return decodedData;
}

- (NSString *)decodeString:(NSString *)string
          toStringEncoding:(CFStringEncoding)encoding
{
    // The string length must be a multiple of 4
    if (string.length % 4 != 0)
        return nil;
    
    NSMutableData *decodedData = nil;
    unichar inputGroup[4];
    char outputGroup[3];
    for (NSUInteger i = 0; i < string.length; i += 4)
    {
        NSRange range = NSMakeRange(i, 4);
        [string getCharacters:inputGroup range:range];
        
        char in0 = base64LUT[inputGroup[0]];
        char in1 = base64LUT[inputGroup[1]];
        char in2 = base64LUT[inputGroup[2]];
        char in3 = base64LUT[inputGroup[3]];
        
        // Are all the encoding inputs legal?
        if (in0 == -1 || in1 == -1 || in2 == -1 || in3 == -1)
        {
            return nil;
        }
        
        outputGroup[0] = ((in0 << 2) & 0xfc) | ((in1 >> 4) & 0x03);
        outputGroup[1] = ((in1 << 4) & 0xf0) | ((in2 >> 2) & 0x0f);
        outputGroup[2] = ((in2 << 6) & 0xc0) | (in3 & 0x3f);
        
        if (decodedData == nil)
            decodedData = [[NSMutableData alloc] initWithCapacity:string.length / 4 * 3];
        
        [decodedData appendBytes:outputGroup length:3];
    }

    CFStringRef strRef = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                 decodedData.bytes,
                                                 decodedData.length,
                                                 encoding,
                                                 false);
    NSLog(@"BASE64 decoded string: %@", (__bridge NSString *)strRef);

    return (NSString *)CFBridgingRelease(strRef);
}

@end
