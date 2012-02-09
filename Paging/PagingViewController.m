#import "PagingViewController.h"
#import "TextScrollView.h"

#define USE_VERTICAL_SCROLLING_DIRECTION NO // Change to YES to change scrolling direction

@implementation PagingViewController

@synthesize pagingScrollView = _pagingScrollView;

#pragma mark -

- (void)dealloc
{
    [_pagingScrollView removeObserver:self forKeyPath:@"currentPageIndex"];
    [_pagingScrollView release];
    
    [super dealloc];
}

#pragma mark - How to embed paging scroll view into the view hierarchy

void *kContextCurrentPageIndex = &kContextCurrentPageIndex;

- (BYPagingScrollView *)pagingScrollView
{
    if (_pagingScrollView == nil) {
        
        CGRect scrollRect = (USE_VERTICAL_SCROLLING_DIRECTION
                             ? CGRectInset(self.view.bounds, 0, - DEFAULT_GAP_BETWEEN_PAGES / 2)
                             : CGRectInset(self.view.bounds, - DEFAULT_GAP_BETWEEN_PAGES / 2, 0));
        
        _pagingScrollView = [[BYPagingScrollView alloc] initWithFrame:scrollRect];
        _pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _pagingScrollView.vertical = USE_VERTICAL_SCROLLING_DIRECTION;
        _pagingScrollView.pageSource = self;
        
        // Watch for scrolling changes to update a title in the navigation bar
        [_pagingScrollView addObserver:self forKeyPath:@"currentPageIndex"
                               options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                               context:kContextCurrentPageIndex];
    }
    return _pagingScrollView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kContextCurrentPageIndex)
        self.title = ([[change valueForKey:NSKeyValueChangeNewKey] intValue] % 2 ? @"Odd" :@"Even");
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
        nestedScrollView = [[[BYPagingScrollView alloc] initWithFrame:scrollView.bounds] autorelease];
        nestedScrollView.vertical = !scrollView.vertical;
        nestedScrollView.pageSource = self;
    }
    return nestedScrollView;
}

- (void)configureNestedScrollView:(BYPagingScrollView *)scrollView usingPageIndex:(NSUInteger)pageIndex
{
    // Tag is used as a prefix in page labels
    if (scrollView.tag != pageIndex + 1) {
        scrollView.tag = pageIndex + 1;
        [scrollView reloadPages];
    }
}

#pragma mark -

- (TextScrollView *)textViewDequeuedFromScrollView:(BYPagingScrollView *)scrollView
{
    TextScrollView *textView = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([TextScrollView class])];
    if (textView == nil) {
        textView = [[[TextScrollView alloc] initWithFrame:self.view.bounds] autorelease];
    }
    return textView;
}

- (void)configureTextView:(TextScrollView *)textView forScrollView:(BYPagingScrollView *)scrollView usingPageIndex:(NSUInteger)pageIndex
{
    if (scrollView == self.pagingScrollView)
        textView.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
    else // text view is a subview of a nested scroll view
        textView.text = [NSString stringWithFormat:@"%d-%d", scrollView.tag, pageIndex + 1];
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
        TextScrollView *textView = [self textViewDequeuedFromScrollView:scrollView];
        [self configureTextView:textView forScrollView:scrollView usingPageIndex:pageIndex];
        return textView;
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
