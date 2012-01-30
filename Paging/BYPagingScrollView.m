#import "BYPagingScrollView.h"

const NSUInteger kPageIndexNone = NSNotFound; // Used to identify initial state

@interface BYPagingScrollView () // Private

@property (nonatomic, readwrite) NSUInteger currentPageIndex;

@end

#pragma mark -

@implementation BYPagingScrollView

@synthesize pageSource = _pageSource;
@synthesize vertical = _vertical;
@synthesize gapBetweenPages = _gapBetweenPages;
@synthesize currentPageIndex = _mostVisiblePage;

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceHorizontal = NO;
        self.alwaysBounceVertical = NO;
        self.scrollsToTop = NO;
        self.directionalLockEnabled = YES;
        
        _firstVisiblePage = kPageIndexNone;
        _lastVisiblePage = kPageIndexNone;
        _mostVisiblePage = kPageIndexNone;
        _preloadedPages = [[NSMutableDictionary alloc] init];
        _reusablePages = [[NSMutableDictionary alloc] init];
        
        _gapBetweenPages = DEFAULT_GAP_BETWEEN_PAGES;
        
        self.delegate = self;
        
        // Reusable pages may be quite heavy, so it's better to perform cleanup on memory request
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearReusablePages)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];
    [_preloadedPages release];
    [_reusablePages release];
    
    [super dealloc];
}

#pragma mark - Disable native scroll view delegate

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if ((delegate == nil) || [delegate isKindOfClass:[BYPagingScrollView class]]) {
        [super setDelegate:delegate];
    }
    else {
        // Take a look at self.delegate = self in -[initWithFrame:]
        NSLog(@"Paging scroll view does not support delegate, you should use a property pageDelegate");
    }
}

- (id<UIScrollViewDelegate>)delegate
{
    NSLog(@"You should not access paging scroll view delegate, use a replacement property pageDelegate");
    return [super delegate];
}

#pragma mark - Preloading and displaying page views

- (void)preloadPageWithIndex:(NSUInteger)pageIndex
{
    // Find out if a page is already pulled from the source
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *page = [_preloadedPages objectForKey:pageNumber];
    if (page == nil) {
        
        // If not, retrieve the page and add it to the preloaded set
        page = [self.pageSource scrollView:self viewForPageAtIndex:pageIndex];
        if (page) {
            [_preloadedPages setObject:page forKey:pageNumber];
        }
    }
}

- (void)preloadRequiredPages
{
    if ((_firstVisiblePage == kPageIndexNone) || (_lastVisiblePage == kPageIndexNone)) {
        return; // Do not call data source in the middle of scrolling and if none page is visible
    }
    
    // Load the visible pages
    [self preloadPageWithIndex:_firstVisiblePage];
    [self preloadPageWithIndex:_lastVisiblePage];
    
    // Load the page before the first page
    if (_firstVisiblePage > 0) {
        [self preloadPageWithIndex:_firstVisiblePage - 1];
    }
    
    // Load the page after the last page
    if (_lastVisiblePage + 1 < _numberOfPages) {
        [self preloadPageWithIndex:_lastVisiblePage + 1];
    }
}

- (void)enumeratePreloadedPagesUsingBlock:(void (^)(NSUInteger pageIndex, UIView *pageView))block
{
    if (block) {
        NSDictionary *copy = [_preloadedPages copy];
        for (id key in copy) {
            block([key unsignedIntegerValue], [copy objectForKey:key]);
        }
        [copy release];
    }
}

- (void)layoutPreloadedPages
{
    CGSize contentSize = self.frame.size;
    CGPoint contentOffset = self.contentOffset;
    
    [self enumeratePreloadedPagesUsingBlock:^(NSUInteger pageIndex, UIView *pageView) {
        
        // Retrieve enumerated page index and default frame
        CGRect preloadedFrame = { contentOffset, contentSize };
        
        // Shift page vertically or horizontally
        if (_vertical) {
            preloadedFrame.origin.y = ((int)pageIndex - (int)_firstPageInLayout) * contentSize.height;
            preloadedFrame = CGRectInset(preloadedFrame, 0, _gapBetweenPages / 2);
        }
        else {
            preloadedFrame.origin.x = ((int)pageIndex - (int)_firstPageInLayout) * contentSize.width;
            preloadedFrame = CGRectInset(preloadedFrame, _gapBetweenPages / 2, 0);
        }
        
        if (!CGRectEqualToRect([pageView frame], preloadedFrame)) {
            pageView.frame = preloadedFrame;
        }
        
        // Insert page into the view hierarchy if needed
        if (pageView.superview == nil) {
            [self addSubview:pageView];
        }
    }];
}

#pragma mark - Adjust content area for the data model

- (void)adjustContentSizeAndOffsetIfNeeded
{
    if ((_firstVisiblePage != _lastVisiblePage) || (_firstVisiblePage == kPageIndexNone) || (_lastVisiblePage == kPageIndexNone)) {
        return; // skip any handling while scrolling and if none page is visible
    }
    
    // Start loading from the page before the first visible page
    // We update data model here, because it is guaranteed that
    // we are not in the middle of scrolling process at the moment
    _firstPageInLayout = MAX((int)_firstVisiblePage - 1, 0);
    
    // Setup content size required to embed all preloaded pages
    CGSize pageSize = self.bounds.size;
    CGSize contentSize = (_vertical
                          ? CGSizeMake(pageSize.width, _preloadedPages.count * pageSize.height)
                          : CGSizeMake(_preloadedPages.count * pageSize.width, pageSize.height));
    if (!CGSizeEqualToSize(self.contentSize, contentSize)) {
        self.contentSize = contentSize;
    }
    
    // Adjust content offset to focus on the first visible page
    CGPoint contentOffset = (_vertical
                             ? CGPointMake(0, pageSize.height * (_firstVisiblePage - _firstPageInLayout))
                             : CGPointMake(pageSize.width * (_firstVisiblePage - _firstPageInLayout), 0));
    if (!CGPointEqualToPoint(self.contentOffset, contentOffset)) {
        self.contentOffset = contentOffset;
    }
}


#pragma mark - Configure scroll view appearance

- (void)resetContentArea
{
    self.contentSize = CGSizeZero;
    self.contentOffset = CGPointZero;
}

- (void)resetBouncing
{
    self.alwaysBounceVertical = ((_numberOfPages > 0) && _vertical);
    self.alwaysBounceHorizontal = ((_numberOfPages > 0) && !_vertical);
}

#pragma mark - Reset preloaded and reusable caches

- (void)resetPreloadedPages
{
    // Reset data model to the initial state
    _firstVisiblePage = kPageIndexNone;
    _lastVisiblePage = kPageIndexNone;
    _firstPageInLayout = 0;
    
    // Focus on the first page if possible
    if (_numberOfPages > 0) {
        _firstVisiblePage = 0;
        _lastVisiblePage = 0;
    }
    
    // Request pages from the source
    [self preloadRequiredPages];
    
    // Reset scrolling content and offset to Zero
    [self resetContentArea];
    
    // Reset content area for the new orientation
    [self adjustContentSizeAndOffsetIfNeeded];
    
    // Enable bouncing if needed
    [self resetBouncing];
    
    // Layout preloaded pages for the first time
    [self layoutPreloadedPages];
    
    // Notify the page source after page index reset to 0
    self.currentPageIndex = _firstVisiblePage;
}

#pragma mark - Reuse pages

- (void)makeReusablePageAtIndex:(NSUInteger)pageIndex
{
    // Find a page in the preloaded set
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *preloadedPage = [_preloadedPages objectForKey:pageNumber];
    if (preloadedPage) {
        
        // Remove the page from the scroll view
        [preloadedPage removeFromSuperview];
        
        // Add the page to the reusable class of views
        NSString *className = NSStringFromClass([preloadedPage class]);
        NSMutableSet *reusableClass = [_reusablePages objectForKey:className];
        if (reusableClass == nil) {
            reusableClass = [NSMutableSet set];
            [_reusablePages setObject:reusableClass forKey:className];
        }
        [reusableClass addObject:preloadedPage];
        
        // Remove the page from the preloaded set
        [_preloadedPages removeObjectForKey:pageNumber];
    }
}

- (void)makeReusableAllPreloadedPages
{
    [self enumeratePreloadedPagesUsingBlock:^(NSUInteger pageIndex, UIView *pageView) {
        
        // It is allowed to modify _preloadedPages here, inside the block
        [self makeReusablePageAtIndex:pageIndex];
    }];
}

- (void)collectPagesForReusing
{
    [self enumeratePreloadedPagesUsingBlock:^(NSUInteger pageIndex, UIView *pageView) {
        
        // Remove pages too far from visible
        if ((pageIndex + 1 < _firstVisiblePage) || (_lastVisiblePage < pageIndex - 1)) {
            
            // It is allowed to modify _preloadedPages here, inside the block
            [self makeReusablePageAtIndex:pageIndex];
        }
    }];
}

- (void)clearReusablePages
{
    [_reusablePages removeAllObjects];
}

- (id)dequeReusablePageViewWithClassName:(NSString *)className
{
    // Reusable pages dictionary keeps view sets under class name keys
    NSMutableSet *reusableClass = [_reusablePages objectForKey:className];
    id dequeuedPage = [[[reusableClass anyObject] retain] autorelease];
    if (dequeuedPage) {
        [reusableClass removeObject:dequeuedPage];
    }
    return dequeuedPage;
}

#pragma mark - Public methods that reload content

- (void)resetNumberOfPages
{
    _numberOfPages = [_pageSource numberOfPagesInScrollView:self];
}

- (void)reloadPages
{
    // Remove all subviews
    [self makeReusableAllPreloadedPages];
    
    // Ask the data source for a number of pages
    [self resetNumberOfPages];
    
    // Update model and view
    [self resetPreloadedPages];
}

- (void)setPageSource:(id<BYPagingScrollViewPageSource>)newPageSource
{
    if (_pageSource != newPageSource) {
        _pageSource = newPageSource;
        
        // Remove all subviews
        [self makeReusableAllPreloadedPages];
        
        // Reset cache by removing all reusable pages
        [self clearReusablePages];
        
        // Ask the data source for a number of pages
        [self resetNumberOfPages];
        
        // Update model and view
        [self resetPreloadedPages];
    }
}

- (void)setVertical:(BOOL)vertical
{
    if (_vertical != vertical) {
        _vertical = vertical;
        
        // Remove all subviews
        [self makeReusableAllPreloadedPages];
        
        // Update view
        [self resetPreloadedPages];
    }
}

- (void)setGapBetweenPages:(CGFloat)gapBetweenPages
{
    // Ensure that the gap is even and integral
    gapBetweenPages = roundf(gapBetweenPages / 2) * 2;
    
    if ((int)_gapBetweenPages != (int)gapBetweenPages) {
        _gapBetweenPages = gapBetweenPages;
        
        // Remove all subviews
        [self makeReusableAllPreloadedPages];
        
        // Update view
        [self resetPreloadedPages];
    }
}

#pragma mark - Handling rotation

- (void)getFirstVisiblePage:(NSUInteger *)firstPtr lastVisiblePage:(NSUInteger *)lastPtr pageRatio:(CGFloat *)ratioPtr;
{
    // Instruments -> self.bounds is faster than self.frame
    CGFloat pageSize = (_vertical ? self.bounds.size.height : self.bounds.size.width);
    CGFloat contentOffset = (_vertical ? self.contentOffset.y : self.contentOffset.x);
    
    NSInteger firstLayoutPage = contentOffset / pageSize;
    NSInteger lastLayoutPage = (contentOffset + pageSize - 1) / pageSize;
    
    NSUInteger firstVisiblePage = MAX((NSInteger)_firstPageInLayout + firstLayoutPage, 0);
    NSUInteger lastVisiblePage = MIN((NSInteger)_firstPageInLayout + lastLayoutPage, (NSInteger)_numberOfPages - 1);
    
    CGFloat pageRatio = (contentOffset - floorf(contentOffset / pageSize) * pageSize) / pageSize;
    
    if (firstPtr) {
        *firstPtr = firstVisiblePage;
    }
    if (lastPtr) {
        *lastPtr = lastVisiblePage;
    }
    if (ratioPtr) {
        *ratioPtr = pageRatio;
    }
}

- (void)layoutVisiblePageDuringRotation
{
    // Reset content area to display only current page
    self.contentSize = self.bounds.size;
    self.contentOffset = CGPointZero;
    
    // There must be only one visible page at the moment
    UIView *visiblePage = [_preloadedPages objectForKey:[NSNumber numberWithUnsignedInteger:_firstVisiblePage]];
    
    // Center the single visible page in the scroll view
    CGRect pageFrame = (_vertical
                        ? CGRectInset(self.bounds, 0, _gapBetweenPages / 2)
                        : CGRectInset(self.bounds, _gapBetweenPages / 2, 0));
    if (!CGRectEqualToRect(visiblePage.frame, pageFrame)) {
        visiblePage.frame = pageFrame;
    }
}

- (id)pageViewAtIndex:(NSUInteger)pageIndex
{
    UIView *pageView = [_preloadedPages objectForKey:[NSNumber numberWithUnsignedInteger:pageIndex]];
    return pageView;
}

- (void)beginTwoPartRotation
{
    // Set flag that should be used for better rotation handling
    _rotating = YES;
    
    // Calculate visible pages
    NSUInteger firstVisiblePage = kPageIndexNone, lastVisiblePage = kPageIndexNone;
    CGFloat visiblePageRatio = 0;
    [self getFirstVisiblePage:&firstVisiblePage lastVisiblePage:&lastVisiblePage pageRatio:&visiblePageRatio];
    
    // Focus on the page taking more space on the screen
    NSUInteger newVisiblePage = (visiblePageRatio < 0.5 ? lastVisiblePage : firstVisiblePage);
    _firstVisiblePage = _lastVisiblePage = newVisiblePage;
    
    // Remove all preloaded pages but visible
    [self enumeratePreloadedPagesUsingBlock:^(NSUInteger pageIndex, UIView *pageView) {
        
        if ((pageIndex != _firstVisiblePage) && (pageIndex != _lastVisiblePage)) {
            
            [self makeReusablePageAtIndex:pageIndex];
        }
    }];
    
    // Center the single visible page
    [self layoutVisiblePageDuringRotation];
    
    // Notify the page source about a new focused page
    self.currentPageIndex = newVisiblePage;
    
    // Nested scroll view should be also notified about rotation
    id nestedScrollView = [self pageViewAtIndex:newVisiblePage];
    if ([nestedScrollView isKindOfClass:[BYPagingScrollView class]]) {
        [nestedScrollView beginTwoPartRotation];
    }
}

- (void)layoutSubviews
{
    // Apply custom layout during rotation
    if (_rotating) {
        [self layoutVisiblePageDuringRotation];
    }
    else {
        [super layoutSubviews];
    }
}

- (void)endTwoPartRotation
{
    // Nested scroll view should be notified explicitly
    id nestedScrollView = [self pageViewAtIndex:_mostVisiblePage];
    if ([nestedScrollView isKindOfClass:[BYPagingScrollView class]]) {
        [nestedScrollView endTwoPartRotation];
    }
        
    // Reset flag used for better rotation handling
    _rotating = NO;
    
    // Request missed pages from the source
    [self preloadRequiredPages];
    
    // Reset content area for the new orientation
    [self adjustContentSizeAndOffsetIfNeeded];
    
    // Layout preloaded pages after rotation
    [self layoutPreloadedPages];
}

#pragma mark - Provide external access to the current page

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return !([key isEqualToString:@"currentPageIndex"] || [key isEqualToString:@"currentPageView"]);
}

- (void)setCurrentPageIndex:(NSUInteger)currentPageIndex
{
    if (_mostVisiblePage != currentPageIndex) {
        
        // Remember the last visible page to notify the page source
        NSUInteger lastPageIndex = _mostVisiblePage;
        
        // Perform a KVO-compliant update
        if (lastPageIndex != kPageIndexNone) {
            [self willChangeValueForKey:@"currentPageIndex"];
            [self willChangeValueForKey:@"currentPageView"];
        }
        _mostVisiblePage = currentPageIndex;
        if (lastPageIndex != kPageIndexNone) {
            [self didChangeValueForKey:@"currentPageIndex"];
            [self didChangeValueForKey:@"currentPageView"];
        }
    }
}

- (id)currentPageView
{
    return [self pageViewAtIndex:self.currentPageIndex];
}

#pragma mark - Handle scrolling by changing data model

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Custom rotation plays with scroll offset, but we should not react on that
    if (_rotating) {
        return;
    }
    
    // Calculate visible page indexes to update model
    NSUInteger firstVisiblePage = kPageIndexNone, lastVisiblePage = kPageIndexNone;
    CGFloat visiblePageRatio = 0;
    [self getFirstVisiblePage:&firstVisiblePage lastVisiblePage:&lastVisiblePage pageRatio:&visiblePageRatio];
    
    if (((visiblePageRatio < 0.5) && (lastVisiblePage > _lastVisiblePage)) ||
        ((visiblePageRatio > 0.5) && (firstVisiblePage < _firstVisiblePage))) {
        
        return; // Scrolling does not worth changes when less than half of the page is scrolled
    }
    
    // Update model and layout if visible pages have beed changed
    if ((_firstVisiblePage != firstVisiblePage) ||
        (_lastVisiblePage != lastVisiblePage)) {
        
        _firstVisiblePage = firstVisiblePage;
        _lastVisiblePage = lastVisiblePage;
        
        // Recycle too far pages
        [self collectPagesForReusing];
        
        // Preload new pages to display soon
        [self preloadRequiredPages];
        
        // Adjust content area for the new model
        [self adjustContentSizeAndOffsetIfNeeded];
        
        // Add new pages to the scroll view
        [self layoutPreloadedPages];
        
        // Notify the page source about a new focused page
        self.currentPageIndex = (visiblePageRatio < 0.5 ? _lastVisiblePage : _firstVisiblePage);
    }
}

@end
