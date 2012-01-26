#import "BYPagingScrollView.h"

const NSUInteger kPageIndexNone = NSNotFound; // Used to identify initial state

@interface BYPagingScrollView () // Private

@property (nonatomic, readwrite) BOOL rotating;

@end

#pragma mark -

@implementation BYPagingScrollView

@synthesize pageSource = _pageSource;
@synthesize vertical = _vertical;
@synthesize rotating = _rotating;
@synthesize gapBetweenPages = _gapBetweenPages;

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.alwaysBounceHorizontal = NO;
        self.alwaysBounceVertical = NO;
        self.scrollsToTop = NO;
        
        _minVisiblePage = kPageIndexNone;
        _maxVisiblePage = kPageIndexNone;
        _preloadedPages = [[NSMutableDictionary alloc] init];
        _reusablePages = [[NSMutableDictionary alloc] init];
        
        _gapBetweenPages = DEFAULT_GAP_BETWEEN_PAGES;
        
        super.delegate = self;
        
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

#pragma mark - Disable delegate

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    // Take a look at [super setDelegate:self] in -[initWithFrame:]
    NSLog(@"Paging scroll view does not support delegate, you should use a property pageDelegate");
}

- (id<UIScrollViewDelegate>)delegate
{
    NSLog(@"You cannot access paging scroll view delegate, use a replacement property pageDelegate");
    return nil;
}

#pragma mark - Handle preloaded and visible pages

- (void)preloadPageWithIndex:(NSUInteger)pageIndex
{
    // Find out if a page is already pulled from the source
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *page = [_preloadedPages objectForKey:pageNumber];
    if (page == nil)
    {
        // If not, retrieve the page and add it to the preloaded set
        page = [self.pageSource scrollView:self viewForPageAtIndex:pageIndex];
        if (page)
        {
            [_preloadedPages setObject:page forKey:pageNumber];
        }
    }
}

- (void)preloadPagesIfNeeded
{
    if ((_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        return; // Do not call data source in the middle of scrolling and if none page is visible
    }
    
    // Load current page
    [self preloadPageWithIndex:_minVisiblePage];
    [self preloadPageWithIndex:_maxVisiblePage];
    
    // Load page at left
    if (_minVisiblePage > 0)
    {
        [self preloadPageWithIndex:_minVisiblePage - 1];
    }
    
    // Load page at right
    if (_maxVisiblePage + 1 < _numberOfPages)
    {
        [self preloadPageWithIndex:_maxVisiblePage + 1];
    }
}

- (NSUInteger)firstPreloadedPageIndex
{
    return (_preloadedPages.count == 0 ? kPageIndexNone
            : [[_preloadedPages valueForKeyPath:@"allKeys.unsignedIntegerValue.@min"] integerValue]);
}

- (void)resetContentSizeAndOffsetIfNeeded
{
    if ((_minVisiblePage != _maxVisiblePage) || (_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        return; // skip any handling while scrolling and if none page is visible
    }
    
    // Calculate and set the minimum required content size
    CGSize frameSize = self.frame.size;
    CGSize contentSize = (self.vertical
                          ? CGSizeMake(frameSize.width, _preloadedPages.count * frameSize.height)
                          : CGSizeMake(_preloadedPages.count * frameSize.width, frameSize.height));
    if (!CGSizeEqualToSize(self.contentSize, contentSize))
    {
        self.contentSize = contentSize;
    }
    
    // Move content to display current page
    CGPoint contentOffset = (self.vertical
                             ? CGPointMake(0, _minVisiblePage * frameSize.height)
                             : CGPointMake(_minVisiblePage * frameSize.width, 0));
    if (!CGPointEqualToPoint(self.contentOffset, contentOffset))
    {
        self.contentOffset = contentOffset;
    }
}

- (void)layoutPreloadedPages
{
    NSUInteger firstPageIndex = self.firstPreloadedPageIndex;
    CGSize contentSize = self.frame.size;
    CGPoint contentOffset = self.contentOffset;
    
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // Retrieve enumerated page index and default frame
        NSUInteger preloadedPage = [key unsignedIntegerValue];
        CGRect preloadedFrame = { contentOffset, contentSize };
        
        // Shift page vertically or horizontally
        if (self.vertical)
        {
            preloadedFrame.origin.y = ((int)preloadedPage - (int)firstPageIndex) * contentSize.height;
            preloadedFrame = CGRectInset(preloadedFrame, 0, _gapBetweenPages / 2);
        }
        else
        {
            preloadedFrame.origin.x = ((int)preloadedPage - (int)firstPageIndex) * contentSize.width;
            preloadedFrame = CGRectInset(preloadedFrame, _gapBetweenPages / 2, 0);
        }
        
        if (!CGRectEqualToRect([obj frame], preloadedFrame))
        {
            [obj setFrame:preloadedFrame];
        }
        
        // Insert page into the view hierarchy if needed
        if ([obj superview] == nil)
        {
            [self addSubview:obj];
        }
    }];
}

#pragma mark -

- (void)resetContentArea
{
    self.contentSize = CGSizeZero;
    self.contentOffset = CGPointZero;
}

- (void)resetBouncing
{
    self.alwaysBounceVertical = ((_numberOfPages > 0) && self.vertical);
    self.alwaysBounceHorizontal = ((_numberOfPages > 0) && !self.vertical);
}

- (void)resetPreloadedPages
{
    // Reset page model to the initial state
    _minVisiblePage = _maxVisiblePage = (_numberOfPages == 0 ? kPageIndexNone : 0);
    
    // Request pages from the source
    [self preloadPagesIfNeeded];
    
    // Reset scrolling content and offset to Zero
    [self resetContentArea];
    
    // Reset content area for the new orientation
    [self resetContentSizeAndOffsetIfNeeded];
    
    // Enable bouncing if needed
    [self resetBouncing];
    
    // Layout preloaded pages for the first time
    [self layoutPreloadedPages];
}

#pragma mark - Reuse pages

- (void)makeReusablePageAtIndex:(NSUInteger)pageIndex
{
    // Find a page in the preloaded set
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *preloadedPage = [_preloadedPages objectForKey:pageNumber];
    if (preloadedPage)
    {
        // Remove the page from the scroll view
        [preloadedPage removeFromSuperview];
        
        // Add the page to the reusable class of views
        NSString *className = NSStringFromClass([preloadedPage class]);
        NSMutableSet *reusableClass = [_reusablePages objectForKey:className];
        if (reusableClass == nil)
        {
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
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // It is allowed to modify _preloadedPages here, inside the block
        [self makeReusablePageAtIndex:[key unsignedIntegerValue]];
    }];
}

- (void)makeReusablePagesIfNeeded
{
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // Remove pages too far from visible
        NSUInteger preloadedPage = [key unsignedIntegerValue];
        if (((int)preloadedPage < (int)_minVisiblePage - 1) || ((int)preloadedPage > (int)_maxVisiblePage + 1))
        {
            // It is allowed to modify _preloadedPages here, inside the block
            [self makeReusablePageAtIndex:preloadedPage];
        }
    }];
}

- (void)clearReusablePages
{
    [_reusablePages removeAllObjects];
}

#pragma mark -

- (id)dequeReusablePageViewWithClassName:(NSString *)className
{
    // Reusable pages dictionary keeps view sets under class name keys
    NSMutableSet *reusableClass = [_reusablePages objectForKey:className];
    UIView *dequeuedPage = [[[reusableClass anyObject] retain] autorelease];
    [reusableClass removeObject:dequeuedPage];
    return dequeuedPage;
}

#pragma mark - Properties that reload content

- (void)setPageSource:(id<BYPagingScrollViewPageSource>)newPageSource
{
    if (_pageSource != newPageSource)
    {
        _pageSource = newPageSource;
        
        [self makeReusableAllPreloadedPages];
        
        // Reset cache by removing all reusable pages
        [self clearReusablePages];
        
        // Ask the data source for a number of pages
        _numberOfPages = [_pageSource numberOfPagesInScrollView:self];
        
        // Update model and view
        [self resetPreloadedPages];
    }
}

- (void)setVertical:(BOOL)vertical
{
    if (_vertical != vertical)
    {
        _vertical = vertical;
        
        [self makeReusableAllPreloadedPages];
        
        // Update view
        [self resetPreloadedPages];
    }
}

- (void)setGapBetweenPages:(CGFloat)gapBetweenPages
{
    // Ensure that the gap is even and integral
    gapBetweenPages = (int)(gapBetweenPages / 2) * 2;
    
    if ((int)_gapBetweenPages != (int)gapBetweenPages)
    {
        _gapBetweenPages = gapBetweenPages;
        
        [self makeReusableAllPreloadedPages];
        
        // Update view
        [self resetPreloadedPages];
    }
}

#pragma mark - Handling rotation

- (void)beginRotation
{
    // Remove all preloaded pages but visible in current frame
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSUInteger pageIndex = [key unsignedIntegerValue];
        if ((pageIndex != _minVisiblePage) && (pageIndex != _maxVisiblePage))
        {
            [self makeReusablePageAtIndex:pageIndex];
        }
    }];
    
    // Set flag that should be used for better rotation handling
    self.rotating = YES;
}

- (void)endRotation
{
    // Return pages removed previously back
    [self preloadPagesIfNeeded];
    
    // Reset flag used for better rotation handling
    self.rotating = NO;
}

#pragma mark - Preload pages while scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Find the first preloaded page in the scroll view
    NSInteger firstPage = self.firstPreloadedPageIndex;
    
    // Calculate new min and max visible indexes to update model
    CGFloat frameSize = (self.vertical ? CGRectGetHeight(self.frame) : CGRectGetWidth(scrollView.frame));
    CGFloat contentOffset = (self.vertical ? self.contentOffset.y : self.contentOffset.x);
    NSInteger minPage = (NSInteger)floorf(contentOffset / frameSize);
    NSInteger maxPage = (NSInteger)floorf((contentOffset + frameSize - 1) / frameSize);
    NSUInteger minVisiblePage = MAX(firstPage + minPage, 0);
    NSUInteger maxVisiblePage = MIN(firstPage + maxPage, _numberOfPages);
    
    // Update model if needed
    if ((_minVisiblePage != minVisiblePage) || (_maxVisiblePage != maxVisiblePage))
    {
        _minVisiblePage = minVisiblePage;
        _maxVisiblePage = maxVisiblePage;
        
        // Recycle too far pages
        [self makeReusablePagesIfNeeded];
        
        // Preload new pages to display soon
        [self preloadPagesIfNeeded];
        
        // Adjust content area for the new model
        [self resetContentSizeAndOffsetIfNeeded];
        
        // Add new pages to the scroll view
        [self layoutPreloadedPages];
    }
}

@end
