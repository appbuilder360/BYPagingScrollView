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

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _minVisiblePage = kPageIndexNone;
        _maxVisiblePage = kPageIndexNone;
        _activePages = [[NSMutableDictionary alloc] init];
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

#pragma mark - Handle visible pages

- (void)assertActivePages
{
    if ((_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        return; // Do not request pages if none page is visible
    }
    
    NSLog(@"Load from the source all active pages for current visible page indexes");
}

- (void)resetContentOffsetAndSize
{
    if ((_minVisiblePage == kPageIndexNone) || (_maxVisiblePage == kPageIndexNone))
    {
        self.contentSize = CGSizeZero;
        self.contentOffset = CGPointZero;
        return; // Nullify content size and offset if none page is selected
    }
    
    NSLog(@"Reset content offset and size to display current visible page");
}

- (void)layoutActivePages
{
    [_activePages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSLog(@"Add page %@ (%@) to its position related to visible page indexes %d and %d", key, obj, _minVisiblePage, _maxVisiblePage);
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
        
        // Update model and view
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
