#import <UIKit/UIKit.h>

#define MAX_LIMIT 100
#define CANCEL_STRING NSLocalizedStringFromTableInBundle(@"Cancel (action sheet)", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")

@interface BrowserController : NSObject <UIActionSheetDelegate>
+ (id)sharedBrowserController;
- (id)tabController;
- (id)transitionView;
- (void)showHistorySheet:(UILongPressGestureRecognizer *)sender backOrForward:(BOOL)isBackSheet;
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
/* v0.4 regist type. But not compatible iOS5?
 - (void)positionButtons:(id)buttons tags:(int*)tags count:(int)count group:(int)group
 {
 id bc = [%c(BrowserController) sharedBrowserController];
 
 for (UIToolbarButton *item in buttons) {
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
 */

//return class=UIToolbarButton arg class=__NSCFDictionary
//arg detail http://pastie.org/2236489
- (id)createButtonWithDescription:(id)description
{
  id navButton = %orig;
  NSString *buttonAction = [description objectForKey:@"UIButtonBarButtonAction"];
  
  if ([buttonAction isEqualToString:@"backFromButtonBar"] || [buttonAction isEqualToString:@"forwardFromButtonBar"])
  {
    UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showHistorySheet:)];
    [navButton addGestureRecognizer:holdGesture];
    [holdGesture release];
  }
  
  return navButton;
}

%new(v@:@)
- (void)showHistorySheet:(UILongPressGestureRecognizer *)sender
{
  if (!isActionSheetShowing){
    isActionSheetShowing = YES;
    switch (sender.view.tag) {
      case 5:
      case 6:
        [[%c(BrowserController) sharedBrowserController] showHistorySheet:sender backOrForward:YES];
        break;
      case 7:
      case 8:
        [[%c(BrowserController) sharedBrowserController] showHistorySheet:sender backOrForward:NO];
        break;
      default:
        break;
    }
  }
}
%end

%hook BrowserController

%new(v@:@)
- (void)showHistorySheet:(UILongPressGestureRecognizer *)sender backOrForward:(BOOL)isBackSheet
{
  UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  NSDictionary *dict = [[[[[%c(BrowserController) sharedBrowserController] activeWebView] webView] backForwardList] dictionaryRepresentation];
  NSUInteger current = [[dict objectForKey:@"current"] intValue];
  NSArray *entries = [dict objectForKey:@"entries"];
  NSMutableArray *historyLists = [NSMutableArray array];
  
  if (isBackSheet){
    sheet.tag = 24;    
    if (current > 0)// make backHistory list
      for (NSUInteger i = 0; i < current; i++)
        [historyLists addObject:[entries objectAtIndex:i]];
    for (id item in [historyLists reverseObjectEnumerator])// add buttons
      [sheet addButtonWithTitle:[item objectForKey:@"title"]];
  } else {
    sheet.tag = 25;
    if (current + 1 < [entries count])// make forwardHistory list
      for (NSUInteger i = current + 1; i < [entries count]; i++)
        [historyLists addObject:[entries objectAtIndex:i]];
    for (id item in historyLists)// add buttons
      [sheet addButtonWithTitle:[item objectForKey:@"title"]];
  }
  [sheet setCancelButtonIndex:[sheet addButtonWithTitle:CANCEL_STRING]];
  
  id tv = [[%c(BrowserController) sharedBrowserController] transitionView];
  
  if (sender != nil ) {// from LongPress
    UIToolbarButton *button = (UIToolbarButton *)sender.view;
    [sheet showFromRect:button.frame inView:tv animated:YES];
  } else { // from other
    [sheet showInView:tv];
  }
  [sheet release];
}

- (void)actionSheet:(UIActionSheet*)sheet clickedButtonAtIndex:(int)buttonIndex
{
  if (sheet.tag == 24 || sheet.tag == 25) {
    if (buttonIndex + 1 != [sheet numberOfButtons]) { // If cancel clicked, only return.
      id wv = [[[%c(BrowserController) sharedBrowserController] activeWebView] webView];
      
      if (sheet.tag == 24) { // back
        NSArray *bl = [[wv backForwardList] backListWithLimit:MAX_LIMIT];
        [wv goToBackForwardItem:[bl objectAtIndex:[bl count] - 1 - buttonIndex]];
      } else { // forward
        NSArray *fl = [[wv backForwardList] forwardListWithLimit:MAX_LIMIT];
        [wv goToBackForwardItem:[fl objectAtIndex:buttonIndex]];
      }
    }
    isActionSheetShowing = NO;
    return;
  }
  
  %orig;
}

%end
