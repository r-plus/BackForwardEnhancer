#import <UIKit/UIKit.h>
#import "SA_ActionSheet.h"

#define MAX_LIMIT 100
#define CANCEL_STRING NSLocalizedStringFromTableInBundle(@"Cancel (action sheet)", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")

@interface BrowserController : NSObject
+ (id)sharedBrowserController;
- (id)tabController;
- (id)transitionView;
- (id)webView;
- (id)backForwardList;
- (BOOL)goToBackForwardItem:(id)arg1;
- (id)activeWebView;
- (id)backForwardListDictionary;
- (void)backFromButtonBar;
- (void)forwardFromButtonBar;
@end

@interface WebBackForwardList : NSObject
- (id)dictionaryRepresentation;
- (id)backListWithLimit:(int)arg1;
- (id)forwardListWithLimit:(int)arg1;
@end

@interface BrowserButtonBar : UIToolbar
@end

@interface UIToolbarButton : UIControl
@end

static BOOL isActionSheetShowing = NO;

// regist LongPressGesture
%hook BrowserButtonBar
- (void)positionButtons:(id)buttons tags:(int*)tags count:(int)count group:(int)group
{
  id bc = [%c(BrowserController) sharedBrowserController];
  
  for (id item in buttons){
    if ([item tag] == 5 || [item tag] == 6 )
    {
      UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:bc action:@selector(showBackListSheet:)];
      [item addGestureRecognizer:holdGesture];
      [holdGesture release];
    }
    else if ([item tag] == 7 || [item tag] == 8)
    {
      UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:bc action:@selector(showForwardListSheet:)];
      [item addGestureRecognizer:holdGesture];
      [holdGesture release];
    }
  }
  %orig;
}
%end


static inline void Alert(NSString *message, NSString *title)
{
	// Helper function
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[av show];
	[av release];
}

/*
 usage for MobileSafari tweak:
  if ([[objc_getClass("BrowserController") sharedBrowserController] respondsToSelector:@selector(showBackListSheet:)])
    [[objc_getClass("BrowserController") sharedBrowserController] performSelector:@selector(showBackListSheet:) withObject:nil];
*/
%hook BrowserController

#define BACK_METHOD \
if (buttonIndex + 1 != [sheet numberOfButtons])\
{\
  id wv = [[[%c(BrowserController) sharedBrowserController] activeWebView] webView];\
  NSArray *bl = [[wv backForwardList] backListWithLimit:MAX_LIMIT];\
  [wv goToBackForwardItem:[bl objectAtIndex:[bl count] - 1 - buttonIndex]];\
}\
isActionSheetShowing = NO;

%new(v@:@)
-(void)showBackListSheet:(UILongPressGestureRecognizer *)sender
{
  Alert(@"msg_back",@"title");
	if (!isActionSheetShowing)
	{
		isActionSheetShowing = YES;
    
		SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSDictionary *dict = [[[[[%c(BrowserController) sharedBrowserController] activeWebView] webView] backForwardList] dictionaryRepresentation];
    NSUInteger current = [[dict objectForKey:@"current"] intValue];
    NSArray *entries = [dict objectForKey:@"entries"];
    NSMutableArray *backLists = [NSMutableArray array];
    
    if (current > 0)// make backHistory list
      for (NSUInteger i = 0; i < current; i++)
        [backLists addObject:[entries objectAtIndex:i]];
    
		for (id item in [backLists reverseObjectEnumerator])// add buttons
			[sheet addButtonWithTitle:[item objectForKey:@"title"]];
		[sheet setCancelButtonIndex:[sheet addButtonWithTitle:CANCEL_STRING]];
    
    id tv = [[%c(BrowserController) sharedBrowserController] transitionView];
    
    if (sender != nil )// from LongPress
    {
      UIToolbarButton *button = (UIToolbarButton *)sender.view;
      [sheet showFromRect:button.frame inView:tv animated:YES buttonBlock:^(int buttonIndex){
        BACK_METHOD
      }];
    } else {// from other
      [sheet showInView:tv buttonBlock:^(int buttonIndex){
        BACK_METHOD
      }];
    }
		[sheet release];
	}
}

#define FORWARD_METHOD \
if (buttonIndex + 1 != [sheet numberOfButtons])\
{\
  id wv = [[[%c(BrowserController) sharedBrowserController] activeWebView] webView];\
  NSArray *fl = [[wv backForwardList] forwardListWithLimit:MAX_LIMIT];\
  [wv goToBackForwardItem:[fl objectAtIndex:buttonIndex]];\
}\
isActionSheetShowing = NO;

%new(v@:)
-(void)showForwardListSheet:(UILongPressGestureRecognizer *)sender
{
  Alert(@"msg_forward",@"title");

  if (!isActionSheetShowing)
	{
		isActionSheetShowing = YES;
		
		SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSDictionary *dict = [[[[[%c(BrowserController) sharedBrowserController] activeWebView] webView] backForwardList] dictionaryRepresentation];
    NSUInteger current = [[dict objectForKey:@"current"] intValue];
    NSArray *entries = [dict objectForKey:@"entries"];
    NSMutableArray *forwardLists = [NSMutableArray array];

		if (current + 1 < [entries count])// make forwardHistory list
			for (NSUInteger i = current + 1; i < [entries count]; i++)
				[forwardLists addObject:[entries objectAtIndex:i]];
    
		for (id item in forwardLists)// add buttons
			[sheet addButtonWithTitle:[item objectForKey:@"title"]];
		[sheet setCancelButtonIndex:[sheet addButtonWithTitle:CANCEL_STRING]];
		
    id tv = [[%c(BrowserController) sharedBrowserController] transitionView];
    
    if (sender != nil)// from LongPress
    {
      UIToolbarButton *button = (UIToolbarButton *)sender.view;
      [sheet showFromRect:button.frame inView:tv animated:YES buttonBlock:^(int buttonIndex){
        FORWARD_METHOD
      }];
    } else {// from other
      [sheet showInView:tv buttonBlock:^(int buttonIndex){
        FORWARD_METHOD
      }];
    }
    [sheet release];
  }
}
%end
