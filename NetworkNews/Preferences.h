//
//  Preferences.h
//  Network News
//
//  Created by David Schweinsberg on 16/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Preferences : NSObject {
}

+ (void)registerDefaults;

+ (UIColor *)colorForQuoteLevel:(NSUInteger)level;

@end
