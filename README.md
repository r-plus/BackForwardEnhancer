#BackForwardEnhancer

![](http://moreinfo.thebigboss.org/moreinfo/backforwardenhancer1.png)  
this tweak is fork of [WillFour20's BookmarksBarTweak](https://github.com/WillFour20/BookmarksBarTweak).

##Usage for developer

MobileSafari or global tweak developer can call BackForwardEnhancer's sheet and function.  

(1) insert interface of BrowserController.

    @interface BrowserController : NSObject
    + (id)sharedBrowserController;
    - (void)showHistorySheet:(id)sender backOrForward:(BOOL)isBackSheet;
    @end

(2) call two lines.

    if ([[%c(BrowserController) sharedBrowserController] respondsToSelector:@selector(showHistorySheet:backOrForward:)])
      [[%c(BrowserController) sharedBrowserController] showHistorySheet:nil backOrForward:YES];

or forwardList is below

    if ([[%c(BrowserController) sharedBrowserController] respondsToSelector:@selector(showHistorySheet:backOrForward:)])
      [[%c(BrowserController) sharedBrowserController] showHistorySheet:nil backOrForward:NO];      

##License (MIT)

BackForwardEnhancer - Copyright (C) 2011 by r_plus  
  
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:  
  
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.  
  
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
