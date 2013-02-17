//
//  NNBase64Decoder.h
//  Network News
//
//  Created by David Schweinsberg on 5/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNBase64Decoder : NSObject
{

}

- (NSString *)decodeString:(NSString *)string
          toStringEncoding:(CFStringEncoding)encoding;

@end
