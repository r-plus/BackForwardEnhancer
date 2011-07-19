#import <UIKit/UIKit.h>
#import "SA_ActionSheet.h"

@interface BrowserController : NSObject
+ (id)sharedBrowserController;
- (id)activeWebView;
- (id)backForwardListDictionary;
- (void)backFromButtonBar;
- (void)forwardFromButtonBar;
@end

@interface WebBackForwardList : NSObject
- (id)dictionaryRepresentation;
- (id)forwardListWithLimit:(int)arg1;
@end

@interface BrowserButtonBar : UIToolbar
@end

@interface UIToolbarButton : UIControl
@end

static NSMutableArray *forwardLists = [NSMutableArray array];
static NSMutableArray *backLists = [NSMutableArray array];
static BOOL isActionSheetShowing = NO;

%hook WebBackForwardList

//returnClass=WebHistoryItem
//WebHistoryItem canPerform -(NSURL*)URL; -(NSString*)title;

- (id)backItem
{
	NSDictionary *dict = [self dictionaryRepresentation];
	NSInteger current = [[dict objectForKey:@"current"] intValue];
	NSArray *entries = [dict objectForKey:@"entries"];

	//back
	if ([backLists count] != 0)
			[backLists removeAllObjects];
	if (current > 0)
		for (NSInteger i = 0; i < current; i++)
			[backLists addObject:[entries objectAtIndex:i]];
	
	return %orig;
}

- (id)forwardItem
{
	NSDictionary *dict = [self dictionaryRepresentation];
	NSUInteger current = [[dict objectForKey:@"current"] intValue];
	NSArray *entries = [dict objectForKey:@"entries"];

	//forward
	if ([forwardLists count] != 0)
		[forwardLists removeAllObjects];
	if (current + 1 < [entries count])
		for (NSUInteger i = current + 1; i < [entries count]; i++)
		[forwardLists addObject:[entries objectAtIndex:i]];

	return %orig;
}

%end

%hook BrowserButtonBar

//return class=UIToolbarButton arg class=__NSCFDictionary
//arg detail http://pastie.org/2236489
- (id)createButtonWithDescription:(id)description
{
	id navButton = %orig;
	NSString *buttonAction = [description objectForKey:@"UIButtonBarButtonAction"];
	
	if ([buttonAction isEqualToString:@"backFromButtonBar"])
	{
		UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backButtonHeld:)];
		[navButton addGestureRecognizer:holdGesture];
		[holdGesture release];
	}
	else if ([buttonAction isEqualToString:@"forwardFromButtonBar"])
	{
		UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(forwardButtonHeld:)];
		[navButton addGestureRecognizer:holdGesture];
		[holdGesture release];
	}
	
	return navButton;
}

%new(v@:@)
- (void)backButtonHeld:(UILongPressGestureRecognizer *)sender
{
	if (!isActionSheetShowing)
	{
		isActionSheetShowing = YES;
		
		SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

		for (id item in [backLists reverseObjectEnumerator])
			[sheet addButtonWithTitle:[item objectForKey:@"title"]];
		[sheet setCancelButtonIndex:[sheet addButtonWithTitle:@"Cancel"]];
		
		UIToolbarButton *button = (UIToolbarButton *)sender.view;
		[sheet showFromRect:button.frame inView:self animated:YES buttonBlock:^(int buttonIndex){
			
			if (buttonIndex + 1 != [sheet numberOfButtons])
			{
				// goBack loop type action.
				for (NSInteger i = 0; i < buttonIndex + 1; i++)
					[[%c(BrowserController) sharedBrowserController] backFromButtonBar];
				
				/* goto page type action.
				 NSString *stringURL = [[backLists objectAtIndex:buttonIndex] objectForKey:@""""];
				 NSURL *urlURL = [NSURL URLWithString:stringURL];
				 NSURLRequest *request = [NSURLRequest requestWithURL:urlURL];
				 [[[%c(BrowserController) sharedBrowserController] activeWebView] loadRequest:request];
				*/
			}
			isActionSheetShowing = NO;
		}];
		
		[sheet release];
	}
}

%new(v@:@)
- (void)forwardButtonHeld:(UILongPressGestureRecognizer *)sender
{
	if (!isActionSheetShowing)
	{
		isActionSheetShowing = YES;
		
		SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		for (id item in forwardLists)
			[sheet addButtonWithTitle:[item objectForKey:@"title"]];
		[sheet setCancelButtonIndex:[sheet addButtonWithTitle:@"Cancel"]];
		
		UIToolbarButton *button = (UIToolbarButton *)sender.view;
		[sheet showFromRect:button.frame inView:self animated:YES buttonBlock:^(int buttonIndex){
			
			if (buttonIndex + 1 != [sheet numberOfButtons])
			{
				// goForward loop type action.
				for (NSInteger i = 0; i < buttonIndex + 1; i++)
					[[%c(BrowserController) sharedBrowserController] forwardFromButtonBar];
				
				/* goto page type action
				 NSString *stringURL = [[forwardLists objectAtIndex:buttonIndex] objectForKey:@""""];
				 NSURL *urlURL = [NSURL URLWithString:stringURL];
				 NSURLRequest *request = [NSURLRequest requestWithURL:urlURL];
				 [[[%c(BrowserController) sharedBrowserController] activeWebView] loadRequest:request];
				*/
			}
			isActionSheetShowing = NO;
		}];
		
		[sheet release];
	}
}

%end

%hook BrowserController

-(void)switchFromTabDocument:(id)tabDocument toTabDocument:(id)tabDocument2 inBackground:(BOOL)background
{
	if (!background)
	{
		NSDictionary *dict = [tabDocument2 backForwardListDictionary];
		NSUInteger current = [[dict objectForKey:@"current"] intValue];
		NSArray *entries = [dict objectForKey:@"entries"];
		
		//back
		if ([backLists count] != 0)
			[backLists removeAllObjects];
		if (current > 0 && [tabDocument2 canGoBack])
			for (NSUInteger i = 0; i < current; i++)
				[backLists addObject:[entries objectAtIndex:i]];

		//forward
		if ([forwardLists count] != 0)
			[forwardLists removeAllObjects];
		if (current + 1 < [entries count] && [tabDocument2 canGoForward])
			for (NSUInteger i = current + 1; i < [entries count]; i++)
				[forwardLists addObject:[entries objectAtIndex:i]];
	}
	%orig;
}

%end
