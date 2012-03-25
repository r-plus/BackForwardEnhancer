#import <UIKit/UIKit.h>

#define MAX_LIMIT 20
#define CANCEL_STRING NSLocalizedStringFromTableInBundle(@"Cancel (action sheet)", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")

@interface BrowserController : NSObject <UIActionSheetDelegate>
+ (id)sharedBrowserController;
- (id)transitionView;
- (void)showHistorySheet:(UILongPressGestureRecognizer *)sender backOrForward:(BOOL)isBackSheet;
- (id)webView;
- (id)backForwardList;
- (BOOL)goToBackForwardItem:(id)arg1;
- (id)activeWebView;
@end

@interface WebBackForwardList : NSObject
- (id)backListWithLimit:(int)arg1;
- (id)forwardListWithLimit:(int)arg1;
@end

@interface UIToolbarButton : UIControl
@end

@interface UIBarButtonItem (BackForwardEnhancer)
- (id)view;
@end

static BOOL isShowingActionSheet = NO;

// iOS 5x
%hook BrowserToolbar
- (void)_installGestureRecognizers
{
  %orig;
  
  // SpacedBarButtonItem : UIBarButtonItem : UIBarItem : NSObject  
  id back = MSHookIvar<id>(self, "_backItem");
  id forward = MSHookIvar<id>(self, "_forwardItem");
  
  UILongPressGestureRecognizer *backHoldGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showBackHistorySheet:)];
  [[back view] addGestureRecognizer:backHoldGesture];
  [backHoldGesture release];
  
  UILongPressGestureRecognizer *forwardHoldGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showForwardHistorySheet:)];
  [[forward view] addGestureRecognizer:forwardHoldGesture];
  [forwardHoldGesture release];
}

%new(v@:@)
- (void)showBackHistorySheet:(UILongPressGestureRecognizer *)sender
{
  if (!isShowingActionSheet){
    isShowingActionSheet = YES;
    [[%c(BrowserController) sharedBrowserController] showHistorySheet:sender backOrForward:YES];
  }
}

%new(v@:@)
- (void)showForwardHistorySheet:(UILongPressGestureRecognizer *)sender
{
  if (!isShowingActionSheet){
    isShowingActionSheet = YES;
    [[%c(BrowserController) sharedBrowserController] showHistorySheet:sender backOrForward:NO];
  }
}

%end

// iOS4x
%hook BrowserButtonBar

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
  if (!isShowingActionSheet){
    isShowingActionSheet = YES;
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

%group iOS5
%new(@@:)
- (id)transitionView {
  return MSHookIvar<id>(self, "_transitionView");
}
%end

%new(v@:@)
- (void)showHistorySheet:(UILongPressGestureRecognizer *)sender backOrForward:(BOOL)isBackSheet
{
  UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  [sheet setAlertSheetStyle:2];
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
    isShowingActionSheet = NO;
    return;
  }
  
  %orig;
}

%end

%ctor
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL isFirmware5x = [[[UIDevice currentDevice] systemVersion] hasPrefix:@"5"];
  %init;
  if (isFirmware5x)
    %init(iOS5);
  [pool drain];
}
