//
//  EncodedWordDecoder.h
//  Network News
//
//  Created by David Schweinsberg on 2/05/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncodedWordDecoder : NSObject {
}

//- (NSString *)decodeData:(NSData *)data;

- (NSString *)decodeString:(NSString *)string;

@end
