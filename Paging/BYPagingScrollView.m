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
        self.alwaysBounceHorizontal = (self.vertical == NO);
        self.alwaysBounceVertical = (self.vertical == YES);
        
        _minVisiblePage = kPageIndexNone;
        _maxVisiblePage = kPageIndexNone;
        _activePages = [[NSMutableDictionary alloc] init];
        _recycledPages = [[NSMutableDictionary alloc] init];
        
        _gapBetweenPages = DEFAULT_GAP_BETWEEN_PAGES;
        
        super.delegate = self;
        
        // Recycled pages may be quite heavy, so it's better to perform cleanup on memory request
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearRecycledPages)
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
    [_activePages release];
    [_recycledPages release];
    
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

#pragma mark - Handle active and visible pages

- (void)assertPageWithIndex:(NSUInteger)pageIndex
{
    // Find out if a page is already pulled from the source
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *page = [_activePages objectForKey:pageNumber];
    if (page == nil)
    {
        // If not, retrieve the page and add it to the active set
        page = [self.pageSource scrollView:self viewForPageAtIndex:pageIndex];
        if (page)
        {
            [_activePages setObject:page forKey:pageNumber];
        }
    }
}

- (void)assertActivePages
{
    if ((_minVisiblePage != _maxVisiblePage) || (_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        return; // Do not call data source in the middle of scrolling and if none page is visible
    }
    
    // Load current page
    NSUInteger currentPage = _minVisiblePage; // _minVisiblePage == _maxVisiblePage
    [self assertPageWithIndex:currentPage];
    
    // Load page at left
    if (currentPage > 0)
    {
        [self assertPageWithIndex:currentPage - 1];
    }
    
    // Load page at right
    if (currentPage + 1 < _numberOfPages)
    {
        [self assertPageWithIndex:currentPage + 1];
    }
}

- (void)resetContentOffsetAndSize
{
    if (_minVisiblePage != _maxVisiblePage)
    {
        return; // Do not touch content area in the middle of scrolling
    }
    
    if ((_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        self.contentSize = CGSizeZero;
        self.contentOffset = CGPointZero;
        return; // Nullify content size and offset if none page is selected
    }
    
    // Calculate the minimum required content size
    CGSize frameSize = self.frame.size;
    CGSize contentSize = (self.vertical
                          ? CGSizeMake(frameSize.width, _activePages.count * frameSize.height)
                          : CGSizeMake(_activePages.count * frameSize.width, frameSize.height));
    if (!CGSizeEqualToSize(self.contentSize, contentSize))
    {
        self.contentSize = contentSize;
    }
    
    // Move content to display current page
    NSUInteger currentPage = _minVisiblePage; // _minVisiblePage == _maxVisiblePage
    CGPoint contentOffset = (self.vertical
                             ? CGPointMake(currentPage * frameSize.width, 0)
                             : CGPointMake(0, currentPage * frameSize.height));
    if (!CGPointEqualToPoint(self.contentOffset, contentOffset))
    {
        self.contentOffset = contentOffset;
    }
}

- (void)layoutActivePages
{
    if (_minVisiblePage != _maxVisiblePage)
    {
        return; // Do not layout subviews in the middle of scrolling
    }
    
    NSUInteger currentPage = _minVisiblePage; // _minVisiblePage == _maxVisiblePage
    CGSize contentSize = self.frame.size;
    CGPoint contentOffset = self.contentOffset;
    
    [_activePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // Retrieve enumerated page index and default frame
        NSUInteger activePage = [key unsignedIntegerValue];
        CGRect activeFrame = { contentOffset, contentSize };
        
        // Shift page vertically or horizontally
        if (self.vertical)
        {
            activeFrame.origin.y += ((int)activePage - (int)currentPage) * contentSize.height;
            activeFrame = CGRectInset(activeFrame, 0, _gapBetweenPages / 2);
        }
        else
        {
            activeFrame.origin.x += ((int)activePage - (int)currentPage) * contentSize.width;
            activeFrame = CGRectInset(activeFrame, _gapBetweenPages / 2, 0);
        }
        
        if (!CGRectEqualToRect([obj frame], activeFrame))
        {
            [obj setFrame:activeFrame];
        }
        
        // Insert page into the view hierarchy if needed
        if ([obj superview] == nil)
        {
            [self addSubview:obj];
        }
    }];
}

#pragma mark -

- (void)resetActivePages
{
    // Reset page model to the initial state
    _minVisiblePage = _maxVisiblePage = (_numberOfPages == 0 ? kPageIndexNone : 0);
    
    // Request pages from the source
    [self assertActivePages];
    
    // Reset content area for the new orientation
    [self resetContentOffsetAndSize];
    
    // Layout active pages for the first time
    [self layoutActivePages];
}

#pragma mark - Recycle and reuse pages

- (void)recylePageWithIndex:(NSUInteger)pageIndex
{
    // Find a page in the active set
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *activePage = [_activePages objectForKey:pageNumber];
    if (activePage)
    {
        // Remove the page from the scroll view
        [activePage removeFromSuperview];
        
        // Add the page to the recycled set
        NSString *className = NSStringFromClass([activePage class]);
        NSMutableSet *classPages = [_recycledPages objectForKey:className];
        if (classPages == nil)
        {
            classPages = [NSMutableSet set];
            [_recycledPages setObject:classPages forKey:className];
        }
        [classPages addObject:activePage];
        
        // Remove the page from the active set
        [_activePages removeObjectForKey:pageNumber];
    }
}

- (void)recycleAllActivePages
{
    [_activePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        // It is allowed to modify _visiblePages here, inside the block
        [self recylePageWithIndex:[key unsignedIntegerValue]];
    }];
}

- (void)clearRecycledPages
{
    [_recycledPages removeAllObjects];
}

#pragma mark -

- (UIView *)dequePageViewWithClassName:(NSString *)className
{
    // Recycled pages dictionary keeps view sets under class name keys
    NSMutableSet *classPages = [_recycledPages objectForKey:className];
    UIView *dequeuedPage = [[[classPages anyObject] retain] autorelease];
    [classPages removeObject:dequeuedPage];
    return dequeuedPage;
}

#pragma mark - Properties that reload content

- (void)setPageSource:(id<BYPagingScrollViewPageSource>)newPageSource
{
    if (_pageSource != newPageSource)
    {
        _pageSource = newPageSource;
        
        // Recycle all visible pages
        [self recycleAllActivePages];
        
        // Reset cache by removing all recycled pages
        [self clearRecycledPages];
        
        // Ask the data source for a number of pages
        _numberOfPages = [_pageSource numberOfPagesInScrollView:self];
        
        // Update model and view
        [self resetActivePages];
    }
}

- (void)setVertical:(BOOL)vertical
{
    if (_vertical != vertical)
    {
        _vertical = vertical;
        
        // Recycle all visible pages
        [self recycleAllActivePages];
        
        // Configure bounce behavior
        self.alwaysBounceHorizontal = (self.vertical == NO);
        self.alwaysBounceVertical = (self.vertical == YES);
        
        // Update view
        [self resetActivePages];
    }
}

- (void)setGapBetweenPages:(CGFloat)gapBetweenPages
{
    // Ensure that the gap is even and integral
    gapBetweenPages = (int)(gapBetweenPages / 2) * 2;
    
    if ((int)_gapBetweenPages != (int)gapBetweenPages)
    {
        _gapBetweenPages = gapBetweenPages;
        
        // Recycle all visible pages
        [self recycleAllActivePages];
        
        // Update view
        [self resetActivePages];
    }
}

#pragma mark - Handling rotation

- (void)beginRotation
{
    // Remove all pages but visible in current frame
    [_activePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSUInteger pageIndex = [key unsignedIntegerValue];
        if ((pageIndex != _minVisiblePage) && (pageIndex != _maxVisiblePage))
        {
            [self recylePageWithIndex:pageIndex];
        }
    }];
    
    // Set flag that should be used for better rotation handling
    self.rotating = YES;
}

- (void)endRotation
{
    // Return pages removed previously back
    [self assertActivePages];
    
    // Reset flag used for better rotation handling
    self.rotating = NO;
}

@end
