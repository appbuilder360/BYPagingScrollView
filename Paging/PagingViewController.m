#import "PagingViewController.h"

@implementation PagingViewController

#pragma mark - How to embed paging scroll view into the view hierarchy

- (void)loadView
{
    // Calculate a scroll view frame as window frame minus status and navigation bars
    CGRect scrollFrame = [UIApplication sharedApplication].keyWindow.frame;
    scrollFrame.size.height -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    scrollFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    // Create the scroll view like a standard control
    BYPagingScrollView *pagingScrollView = [[BYPagingScrollView alloc] initWithFrame:scrollFrame];
    pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    pagingScrollView.opaque = YES;
    pagingScrollView.backgroundColor = [UIColor redColor];
    self.view = pagingScrollView;
    [pagingScrollView release];
    
    // Configure the scroll view
//    pagingScrollView.vertical = YES;
    pagingScrollView.pageSource = self;
}

#pragma mark - Data source protocol for paging scroll view

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView
{
    return 5;
}

- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex
{
    UILabel *label = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([UILabel class])];
    if (label == nil)
    {
        label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        label.contentMode = UIViewContentModeCenter;
        label.backgroundColor = [UIColor colorWithWhite:.4 alpha:1];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:150];
        label.textColor = [UIColor colorWithWhite:.2 alpha:1];
        label.shadowColor = [UIColor colorWithWhite:.6 alpha:1];
        label.shadowOffset = CGSizeMake(0, 1);
    }
    label.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
    return label;
}

#pragma mark -

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex
{
    self.title = [NSString stringWithFormat:@"%@", (newPageIndex + 1) % 2 == 0 ? @"Even" : @"Odd"];
}

#pragma mark - Help paging scroll view to handle rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    // Deny portrait upside down on iPhone
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? orientation != UIInterfaceOrientationPortraitUpsideDown : YES);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    // Notify scroll view that it is being rotated
    [(BYPagingScrollView *)self.view beginTwoPartRotationWithDuration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Notify scroll view that rotation is completed
    BYPagingScrollView *scrollView = (BYPagingScrollView *)self.view;
    [scrollView endTwoPartRotation];
    
    // If the rotated view has a Center content mode, it may need redrawing after rotation, but not this time
//    UILabel *label = [scrollView pageViewAtIndex:scrollView.currentPageIndex];
//    [label setNeedsDisplay];
}

@end
