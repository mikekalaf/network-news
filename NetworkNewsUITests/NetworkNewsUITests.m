//
//  NetworkNewsUITests.m
//  NetworkNewsUITests
//
//  Created by David Schweinsberg on 4/26/18.
//  Copyright © 2018 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface NetworkNewsUITests : XCTestCase

@end

@implementation NetworkNewsUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTest {

//    XCUIApplication *app = [[XCUIApplication alloc] init];
//    [app.tables/*@START_MENU_TOKEN@*/.staticTexts[@"misc.test"]/*[[".cells.staticTexts[@\"misc.test\"]",".staticTexts[@\"misc.test\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
//    [app.activityIndicators[@"In progress"] tap];

}

- (void)testPostArticle {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery.staticTexts[@"misc.test"] tap];

    XCUIElement *composeButton = app.toolbars[@"Toolbar"].buttons[@"Compose"];

//    while (!composeButton.enabled)
//    {
//        sleep(1);
//    }

    [composeButton tap];

//    XCUIElementQuery *query = app.textFields;
//    NSUInteger count = query.count;
//    for (NSUInteger i = 0; i < count; ++i)
//    {
//        XCUIElement *element = [query elementBoundByIndex:i];
//        NSLog(@"%@", element);
//    }

    XCUIElement *toTextField = app.textFields.element;
    [toTextField typeText:@"Testing"];

//    [app.keys[@"T"] tap];
//    [app.keys[@"e"] tap];
//    [app.keys[@"s"] tap];
//    [app.keys[@"t"] tap];

//    XCUIElement *textView = [app.textViews containingType:XCUIElementTypeTextView identifier:@"To:"].element;
    XCUIElement *textView = app.textViews.element;
    [textView tap];

    NSString *text = [NSString stringWithFormat:@"Testing at %@\n\n", [[NSDate date] description]];
    [textView typeText:text];

    text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
    [textView typeText:text];

//    for (int i = 0; i < text.length; ++i)
//    {
//        unichar c = [text characterAtIndex:i];
//        if (c == ' ')
//            [app.keys[@"space"] tap];
//        else if (c == '.')
//        {
//            [app.keys[@"more"] tap];
//            [app.keys[@"."] tap];
//        }
//        else if (c == ',')
//        {
//            [app.keys[@"more"] tap];
//            [app.keys[@","] tap];
//        }
//        else
//            [app.keys[[NSString stringWithCharacters:&c length:1]] tap];
//    }

//    [app.buttons[@"Return"] tap];

//    XCUIElement *moreKey = app/*@START_MENU_TOKEN@*/.keys[@"more"]/*[[".keyboards",".keys[@\"more, numbers\"]",".keys[@\"more\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/;
//    [moreKey tap];
//    [moreKey tap];
//    [app/*@START_MENU_TOKEN@*/.keys[@"1"]/*[[".keyboards.keys[@\"1\"]",".keys[@\"1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
//    [app/*@START_MENU_TOKEN@*/.keys[@"2"]/*[[".keyboards.keys[@\"2\"]",".keys[@\"2\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
//
//    XCUIElement *key = app/*@START_MENU_TOKEN@*/.keys[@"3"]/*[[".keyboards.keys[@\"3\"]",".keys[@\"3\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/;
//    [key tap];
//    [key tap];
    [app.navigationBars[@"New Article"].buttons[@"Send"] tap];
}

@end
