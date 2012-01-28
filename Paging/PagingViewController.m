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
    pagingScrollView.backgroundColor = [UIColor redColor];
    self.view = pagingScrollView;
    [pagingScrollView release];
    
    // Configure the scroll view
//    pagingScrollView.vertical = YES;
    pagingScrollView.pageSource = self;
}

#pragma mark - Helper methods not related to protocol

- (BYPagingScrollView *)nestedScrollViewDequeuedFromScrollView:(BYPagingScrollView *)scrollView
{
    BYPagingScrollView *nestedScrollView = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([BYPagingScrollView class])];
    if (nestedScrollView == nil)
    {
        nestedScrollView = [[[BYPagingScrollView alloc] initWithFrame:scrollView.bounds] autorelease];
        nestedScrollView.backgroundColor = [UIColor blueColor];
        nestedScrollView.vertical = !scrollView.vertical;
        nestedScrollView.pageSource = self;
    }
    return nestedScrollView;
}

- (void)configureNestedScrollView:(BYPagingScrollView *)scrollView usingPageIndex:(NSUInteger)pageIndex
{
    if (scrollView.tag != pageIndex + 1)
    {
        scrollView.tag = pageIndex + 1;
        [scrollView reloadPages];
    }
}

#pragma mark -

- (UILabel *)labelDequeuedFromScrollView:(BYPagingScrollView *)scrollView
{
    UILabel *label = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([UILabel class])];
    if (label == nil)
    {
        label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        label.contentMode = UIViewContentModeCenter;
        label.backgroundColor = [UIColor colorWithWhite:.4 alpha:1];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:100];
        label.textColor = [UIColor colorWithWhite:.2 alpha:1];
        label.shadowColor = [UIColor colorWithWhite:.6 alpha:1];
        label.shadowOffset = CGSizeMake(0, 1);
    }
    return label;
}

- (void)configureLabel:(UILabel *)label forScrollView:(BYPagingScrollView *)scrollView usingPageIndex:(NSUInteger)pageIndex
{
    // Handle nested scroll view separately
    if (scrollView == self.view)
    {
        label.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
    }
    else
    {
        label.text = [NSString stringWithFormat:@"%d-%d", scrollView.tag, pageIndex + 1];
    }
}

#pragma mark - Data source protocol for paging scroll view

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView
{
    // Each nested scroll view will have 5 pages
    return (scrollView == self.view ? 10 : 5);
}

- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex
{
    id view = nil;
    if ((scrollView == self.view) && (pageIndex % 3 == 0)) // Each third view is a nested BYPagingScrollView
    {
        view = [self nestedScrollViewDequeuedFromScrollView:scrollView];
        [self configureNestedScrollView:view usingPageIndex:pageIndex];
    }
    else
    {
        view = [self labelDequeuedFromScrollView:scrollView];
        [self configureLabel:view forScrollView:scrollView usingPageIndex:pageIndex];
    }
    return view;
}

#pragma mark -

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex
{
    self.title = (scrollView == self.view ? [NSString stringWithFormat:@"%@", (newPageIndex + 1) % 2 == 0 ? @"Even" : @"Odd"] : @"Nested");
}

#pragma mark - Help paging scroll view to handle rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    // For Demo, allow Portrait upside down mode even on iPhone
    return YES;
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
