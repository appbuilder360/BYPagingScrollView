#import "PagingViewController.h"
#import "ColorView.h"

@implementation PagingViewController

#pragma mark - How to use paging scroll in the view controller

- (void)loadView
{
    // Calculate scroll view frame as window frame minus status and navigation bars
    CGRect scrollFrame = [UIApplication sharedApplication].keyWindow.frame;
    scrollFrame.size.height -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    scrollFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    // Create scroll view
    BYPagingScrollView *pagingScrollView = [[BYPagingScrollView alloc] initWithFrame:scrollFrame];
    pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    pagingScrollView.opaque = YES;
    pagingScrollView.backgroundColor = [UIColor blackColor];
    self.view = pagingScrollView;
    [pagingScrollView release];
    
    // Configure scroll view in one line
    pagingScrollView.pageSource = self;
}

#pragma mark - Data source protocol for paging scroll view

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView
{
    return 2;
}

- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex
{
    UIView *view = [scrollView dequePageViewWithClassName:NSStringFromClass([UIView class])];
    if (view == nil)
    {
        view = [[[ColorView alloc] initWithFrame:CGRectZero] autorelease];
        view.backgroundColor = [UIColor colorWithWhite:.15 alpha:1];
    }
    view.tag = pageIndex;
    return view;
}

#pragma mark -

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex
{
    self.title = [NSString stringWithFormat:@"Page %d", newPageIndex + 1];
}

#pragma mark - How to handle rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    // Deny portrait upside down on iPhone
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? orientation != UIInterfaceOrientationPortraitUpsideDown : YES);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    // Notify scroll view that it is being rotated
    [(BYPagingScrollView *)self.view beginRotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Notify scroll view that rotation is completed
    [(BYPagingScrollView *)self.view endRotation];
}

@end
