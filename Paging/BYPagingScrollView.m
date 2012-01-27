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
        
        _firstVisiblePage = kPageIndexNone;
        _lastVisiblePage = kPageIndexNone;
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

#pragma mark - Disable native scroll view delegate

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

#pragma mark - Preloading and displaying page views

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

- (void)preloadRequiredPages
{
    if ((_firstVisiblePage == kPageIndexNone) || (_lastVisiblePage == kPageIndexNone))
    {
        return; // Do not call data source in the middle of scrolling and if none page is visible
    }
    
    // Load the visible pages
    [self preloadPageWithIndex:_firstVisiblePage];
    [self preloadPageWithIndex:_lastVisiblePage];
    
    // Load the page before the first page
    if (_firstVisiblePage > 0)
    {
        [self preloadPageWithIndex:_firstVisiblePage - 1];
    }
    
    // Load the page after the last page
    if (_lastVisiblePage + 1 < _numberOfPages)
    {
        [self preloadPageWithIndex:_lastVisiblePage + 1];
    }
}

- (void)layoutPreloadedPages
{
    CGSize contentSize = self.frame.size;
    CGPoint contentOffset = self.contentOffset;
    
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // Retrieve enumerated page index and default frame
        NSUInteger preloadedPage = [key unsignedIntegerValue];
        CGRect preloadedFrame = { contentOffset, contentSize };
        
        // Shift page vertically or horizontally
        if (self.vertical)
        {
            preloadedFrame.origin.y = ((int)preloadedPage - (int)_firstPageInLayout) * contentSize.height;
            preloadedFrame = CGRectInset(preloadedFrame, 0, _gapBetweenPages / 2);
        }
        else
        {
            preloadedFrame.origin.x = ((int)preloadedPage - (int)_firstPageInLayout) * contentSize.width;
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

#pragma mark - Adjust content area for the data model

- (void)adjustContentSizeAndOffsetIfNeeded
{
    if ((_firstVisiblePage != _lastVisiblePage) || (_firstVisiblePage == kPageIndexNone) || (_lastVisiblePage == kPageIndexNone))
    {
        return; // skip any handling while scrolling and if none page is visible
    }
    
    // Start loading from the page before the first visible page
    // We update data model here, because it is guaranteed that
    // we are not in the middle of scrolling process at the moment
    _firstPageInLayout = MAX((int)_firstVisiblePage - 1, 0);
    
    // Setup content size required to embed all preloaded pages
    CGSize frameSize = self.frame.size;
    CGSize contentSize = (self.vertical
                          ? CGSizeMake(frameSize.width, _preloadedPages.count * frameSize.height)
                          : CGSizeMake(_preloadedPages.count * frameSize.width, frameSize.height));
    if (!CGSizeEqualToSize(self.contentSize, contentSize))
    {
        self.contentSize = contentSize;
    }
    
    // Adjust content offset to focus on the first visible page
    CGPoint contentOffset = (self.vertical
                             ? CGPointMake(0, frameSize.height * (_firstVisiblePage - _firstPageInLayout))
                             : CGPointMake(frameSize.width * (_firstVisiblePage - _firstPageInLayout), 0));
    if (!CGPointEqualToPoint(self.contentOffset, contentOffset))
    {
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
    self.alwaysBounceVertical = ((_numberOfPages > 0) && self.vertical);
    self.alwaysBounceHorizontal = ((_numberOfPages > 0) && !self.vertical);
}

#pragma mark - Reset preloaded and reusable caches

- (void)resetPreloadedPages
{
    // Reset data model to the initial state
    _firstVisiblePage = kPageIndexNone;
    _lastVisiblePage = kPageIndexNone;
    _firstPageInLayout = 0;
    
    // Focus on the first page if possible
    if (_numberOfPages > 0)
    {
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

- (void)collectPagesForReusing
{
    [_preloadedPages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // Remove pages too far from visible
        NSUInteger preloadedPage = [key unsignedIntegerValue];
        if (((int)preloadedPage < (int)_firstVisiblePage - 1) || ((int)preloadedPage > (int)_lastVisiblePage + 1))
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

- (id)dequeReusablePageViewWithClassName:(NSString *)className
{
    // Reusable pages dictionary keeps view sets under class name keys
    NSMutableSet *reusableClass = [_reusablePages objectForKey:className];
    id dequeuedPage = [[[reusableClass anyObject] retain] autorelease];
    if (dequeuedPage)
    {
        [reusableClass removeObject:dequeuedPage];
    }
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
        if ((pageIndex != _firstVisiblePage) && (pageIndex != _lastVisiblePage))
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
    [self preloadRequiredPages];
    
    // Reset flag used for better rotation handling
    self.rotating = NO;
}

#pragma mark - Handle scrolling by changing data model

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Calculate new min and max visible indexes to update model
    CGFloat frameSize = (self.vertical ? CGRectGetHeight(self.frame) : CGRectGetWidth(scrollView.frame));
    CGFloat contentOffset = (self.vertical ? self.contentOffset.y : self.contentOffset.x);
    NSInteger minPage = (NSInteger)floorf(contentOffset / frameSize);
    NSInteger maxPage = (NSInteger)floorf((contentOffset + frameSize - 1) / frameSize);
    NSUInteger newMinVisiblePage = MAX((int)_firstPageInLayout + (int)minPage, 0);
    NSUInteger newMaxVisiblePage = MIN((int)_firstPageInLayout + (int)maxPage, _numberOfPages - 1);

    CGFloat pageRatio = (contentOffset - floorf(contentOffset / frameSize) * frameSize) / frameSize;
    if (((pageRatio < 0.5) && (newMaxVisiblePage > _lastVisiblePage)) ||
        ((pageRatio > 0.5) && (newMinVisiblePage < _firstVisiblePage)))
    {
        return; // Scrolling does not worth changes when less than half of the page is scrolled
    }
    
    // Update model and layout if visible pages have beed changed
    if ((_firstVisiblePage != newMinVisiblePage) || (_lastVisiblePage != newMaxVisiblePage))
    {
        _firstVisiblePage = newMinVisiblePage;
        _lastVisiblePage = newMaxVisiblePage;
        
        // Recycle too far pages
        [self collectPagesForReusing];
        
        // Preload new pages to display soon
        [self preloadRequiredPages];
        
        // Adjust content area for the new model
        [self adjustContentSizeAndOffsetIfNeeded];
        
        // Add new pages to the scroll view
        [self layoutPreloadedPages];
    }
}

@end
