#import "PagingViewController.h"

@implementation PagingViewController

@synthesize pagingScrollView = _pagingScrollView;

#pragma mark -

- (void)dealloc
{
    [_pagingScrollView release];
    
    [super dealloc];
}

#pragma mark - How to embed paging scroll view into the view hierarchy

- (BYPagingScrollView *)pagingScrollView
{
    if (_pagingScrollView == nil) {
        _pagingScrollView = [[BYPagingScrollView alloc] initWithFrame:self.view.bounds];
        _pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                              UIViewAutoresizingFlexibleHeight);
        _pagingScrollView.backgroundColor = [UIColor redColor];
        _pagingScrollView.pageSource = self;
    }
    return _pagingScrollView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.pagingScrollView];
}

#pragma mark - Helper methods not related to the paging source protocol

- (BYPagingScrollView *)nestedScrollViewDequeuedFromScrollView:(BYPagingScrollView *)scrollView
{
    BYPagingScrollView *nestedScrollView = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([BYPagingScrollView class])];
    if (nestedScrollView == nil) {
        
        CGRect scrollRect = scrollView.bounds;
        if (scrollView.vertical) {
            scrollRect.size.height -= DEFAULT_GAP_BETWEEN_PAGES;
        }
        else {
            scrollRect.size.width -= DEFAULT_GAP_BETWEEN_PAGES;
        }
        
        nestedScrollView = [[[BYPagingScrollView alloc] initWithFrame:scrollRect] autorelease];
        nestedScrollView.backgroundColor = [UIColor blueColor];
        nestedScrollView.vertical = !scrollView.vertical;
        nestedScrollView.pageSource = self;
    }
    return nestedScrollView;
}

- (void)configureNestedScrollView:(BYPagingScrollView *)scrollView usingPageIndex:(NSUInteger)pageIndex
{
    // Check new frame after possible device rotation while the scroll view was in the reuse cache
    CGRect scrollRect = self.pagingScrollView.frame;
    if (scrollView.vertical) {
        scrollRect.size.width -= DEFAULT_GAP_BETWEEN_PAGES;
    }
    else {
        scrollRect.size.height -= DEFAULT_GAP_BETWEEN_PAGES;
    }
    
    // Pages will be reloaded to apply a new layout if the device was rotated
    BOOL sizeChanged = !CGSizeEqualToSize(scrollRect.size, scrollView.frame.size);
    if (sizeChanged) {
        scrollView.frame = scrollRect;
    }
    
    // Reload pages if the scroll view data or frame was changed
    if (sizeChanged || (scrollView.tag != pageIndex + 1)) {
        scrollView.tag = pageIndex + 1;
        [scrollView reloadPages];
    }
}

#pragma mark -

- (UILabel *)labelDequeuedFromScrollView:(BYPagingScrollView *)scrollView
{
    UILabel *label = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([UILabel class])];
    if (label == nil) {
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
    if (scrollView == self.pagingScrollView) {
        label.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
    }
    else {
        label.text = [NSString stringWithFormat:@"%d-%d", scrollView.tag, pageIndex + 1];
    }
}

#pragma mark - Data source protocol for paging scroll view

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView
{
    return (scrollView == self.pagingScrollView ? 10 : 5); // Nested scroll views will contain 5 pages
}

- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex
{
    // Each 3rd page is another nested paging scroll view 
    if ((scrollView == self.pagingScrollView) && (pageIndex % 3 == 0)) {
        
        BYPagingScrollView *nestedScrollView = [self nestedScrollViewDequeuedFromScrollView:scrollView];
        [self configureNestedScrollView:nestedScrollView usingPageIndex:pageIndex];
        return nestedScrollView;
    }
    else {
        UILabel *label = [self labelDequeuedFromScrollView:scrollView];
        [self configureLabel:label forScrollView:scrollView usingPageIndex:pageIndex];
        return label;
    }
}

#pragma mark -

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex
{
    if (scrollView == self.pagingScrollView) {
        self.title = [NSString stringWithFormat:@"%@", (newPageIndex + 1) % 2 == 0 ? @"Even" : @"Odd"];
    }
}

#pragma mark - With paging scroll view, you have to perform rotation explicitly

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES; // During Development, allow Portrait upside down mode even on iPhone
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.pagingScrollView beginTwoPartRotation]; // Explicitly notify scroll view that it is being rotated
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.pagingScrollView endTwoPartRotation]; // Explicitly notify scroll view that rotation is completed
}

@end
