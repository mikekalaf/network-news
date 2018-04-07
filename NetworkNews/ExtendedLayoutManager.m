//
//  ExtendedLayoutManager.m
//  Network News
//
//  Created by David Schweinsberg on 4/01/10.
//  Copyright 2010 David Schweinsberg. All rights reserved.
//

#import "ExtendedLayoutManager.h"
#import "Preferences.h"

@implementation ExtendedLayoutManager

- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin
{
    NSRange glyphRange = glyphsToShow;
    while (glyphRange.length > 0)
    {
        NSRange charRange = [self characterRangeForGlyphRange:glyphRange
                                             actualGlyphRange:NULL];
        NSRange attributeCharRange;
        id attribute = [self.textStorage attribute:NSParagraphStyleAttributeName
                                           atIndex:charRange.location
                             longestEffectiveRange:&attributeCharRange
                                           inRange:charRange];
        NSRange attributeGlyphRange = [self glyphRangeForCharacterRange:attributeCharRange
                                                   actualCharacterRange:NULL];
        attributeGlyphRange = NSIntersectionRange(attributeGlyphRange,
                                                  glyphRange);

        // Draw quotes marks for each quote level >0
        if (attribute)
        {
            CGContextRef context = UIGraphicsGetCurrentContext();
            NSTextContainer *container = [self textContainerForGlyphAtIndex:attributeGlyphRange.location
                                                             effectiveRange:NULL];
            CGRect paraRect = [self boundingRectForGlyphRange:attributeGlyphRange
                                              inTextContainer:container];
            NSParagraphStyle *paragraphStyle = attribute;
            CGFloat indent = paragraphStyle.headIndent;
            if (indent > 0)
            {

                NSUInteger level = indent / LEVEL_INDENT;
                for (NSUInteger i = 0; i < level; ++i)
                {

                    UIColor *color = [Preferences colorForQuoteLevel:i + 1];
                    CGFloat redComponent;
                    CGFloat greenComponent;
                    CGFloat blueComponent;
                    CGFloat alphaComponent;
                    [color getRed:&redComponent green:&greenComponent blue:&blueComponent alpha:&alphaComponent];
                    CGContextSetRGBFillColor(context,
                                             redComponent,
                                             greenComponent,
                                             blueComponent,
                                             alphaComponent);
                    CGRect rect = {
                        {LEVEL_INDENT * i + 5, paraRect.origin.y + 8},
                        {2, paraRect.size.height}
                    };
                    CGContextFillRect(context, rect);
                }
            }

            // Draw a divider between the header and the body
            CGFloat spacing = paragraphStyle.paragraphSpacingBefore;
            if (spacing > 0)
            {
                CGContextSetRGBFillColor(context, 0.75, 0.75, 0.75, 1.0);
                CGRect rect = {
                    {5, paraRect.origin.y - 5},
                    {paraRect.size.width, 1}
                };
                CGContextFillRect(context, rect);
            }
        }

        // Draw the glyphs
        [super drawGlyphsForGlyphRange:attributeGlyphRange
                               atPoint:origin];

        glyphRange.length = NSMaxRange(glyphRange) - NSMaxRange(attributeGlyphRange);
        glyphRange.location = NSMaxRange(attributeGlyphRange);
    }
}

- (void)showCGGlyphs:(const CGGlyph *)glyphs positions:(const CGPoint *)positions count:(NSUInteger)glyphCount font:(UIFont *)font matrix:(CGAffineTransform)textMatrix attributes:(NSDictionary *)attributes inContext:(CGContextRef)graphicsContext
{
    [super showCGGlyphs:glyphs positions:positions count:glyphCount font:font matrix:textMatrix attributes:attributes inContext:graphicsContext];
}

@end
