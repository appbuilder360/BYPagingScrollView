#import "BYPagingScrollView.h"

const NSUInteger kPageIndexNone = NSNotFound; // Used to identify initial state

@interface BYPagingScrollView () // Private

@end

#pragma mark -

@implementation BYPagingScrollView {
@private
    CGFloat _gapBetweenPages;            // Black interspacing between pages
    NSUInteger _currentPageIndex;
    NSUInteger _numberOfPages;
    NSMutableDictionary *_visiblePages;  // { Key: NSNumber with a page index -> Value: UIView representing a page }
    NSMutableDictionary *_recycledPages; // { Key: NSString class name of kind of pages -> Value: NSMutableSet of UIView descendants }
}

@synthesize pageSource = _pageSource;
@synthesize vertical = _vertical;

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _currentPageIndex = kPageIndexNone;
        _visiblePages = [[NSMutableDictionary alloc] init];
        _recycledPages = [[NSMutableDictionary alloc] init];
        
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
    [_visiblePages release];
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

#pragma mark - Handle visible pages

- (void)assertVisiblePages
{
    if (_currentPageIndex == kPageIndexNone)
    {
        return; // Do not request pages if none page is selected
    }
    
    NSLog(@"Load all visible pages for current index from the source");
}

- (void)resetContentOffsetAndSize
{
    if (_currentPageIndex == kPageIndexNone)
    {
        self.contentSize = CGSizeZero;
        self.contentOffset = CGPointZero;
        return; // Nullify content size and offset if none page is selected
    }
    
    NSLog(@"Reset content offset and size to display current page");
}

- (void)layoutVisiblePages
{
    [_visiblePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSLog(@"Add page %@ (%@) to its position related to current page index %d", key, obj, _currentPageIndex);
    }];
}

#pragma mark -

- (void)resetVisiblePages
{
    // Reset page model to the initial state
    _currentPageIndex = (_numberOfPages == 0 ? kPageIndexNone : 0);
    
    // Request pages from the source
    [self assertVisiblePages];
    
    // Reset content area for the new orientation
    [self resetContentOffsetAndSize];
    
    // Layout visible pages for the first time
    [self layoutVisiblePages];
}

#pragma mark - Recycle and reuse pages

- (void)recylePageWithIndex:(NSUInteger)pageIndex
{
    // Find a page in the visible set
    NSNumber *pageNumber = [NSNumber numberWithUnsignedInteger:pageIndex];
    UIView *visiblePage = [_visiblePages objectForKey:pageNumber];
    if (visiblePage)
    {
        // Remove the page from the scroll view
        [visiblePage removeFromSuperview];
        
        // Add the page to the recycled set
        NSString *className = NSStringFromClass([visiblePage class]);
        NSMutableSet *classPages = [_recycledPages objectForKey:className];
        if (classPages == nil)
        {
            classPages = [NSMutableSet set];
            [_recycledPages setObject:classPages forKey:className];
        }
        [classPages addObject:visiblePage];
        
        // Remove the page from the visible set
        [_visiblePages removeObjectForKey:pageNumber];
    }
}

- (void)recycleVisiblePages
{
    [_visiblePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
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
        [self recycleVisiblePages];
        
        // Reset cache by removing all recycled pages
        [self clearRecycledPages];
        
        // Ask the data source for a number of pages
        _numberOfPages = [_pageSource numberOfPagesInScrollView:self];
        
        // Update model and view
        [self resetVisiblePages];
    }
}

- (void)setVertical:(BOOL)vertical
{
    if (_vertical != vertical)
    {
        _vertical = vertical;
        
        // Recycle all visible pages
        [self recycleVisiblePages];
        
        // Update model and view
        [self resetVisiblePages];
    }
}

@end
