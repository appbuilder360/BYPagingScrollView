//
// Usual approach to implement a paging scroll view is to enclose it into a clipped view.
// As result, you easily set the gap between page views, but cannot nest cross-directional scroll views.
// BYPagingScrollView is more flexible because inherits from UIScrollView directly and allows nesting.
// This way, you can combine horizontal and vertical scroll views and even support Zoom.
//

#define DEFAULT_GAP_BETWEEN_PAGES 20      // Can be used to inset page views properly

#pragma mark -

@protocol BYPagingScrollViewPageSource;

#pragma mark -

@interface BYPagingScrollView : UIScrollView <UIScrollViewDelegate> {
    
    NSUInteger _numberOfPages;            // Cached number retrieved from the page source
    NSUInteger _firstPageInLayout;        // The first page in the list of preloaded views
    NSUInteger _firstVisiblePage;         // Partially visible left (top) page
    NSUInteger _lastVisiblePage;          // Partially visible right (bottom) page
    NSUInteger _mostVisiblePage;          // Index of the current page which is the most visible
    NSMutableDictionary *_preloadedPages; // Visible and invisible subviews { NSNumber *pageIndex => UIView *pageView }
    NSMutableDictionary *_reusablePages;  // Page views for reusing { NSString *className => NSMutableSet *pageViews }
    CGFloat _gapBetweenPages;             // Black interspacing between pages that is always even i.e. 0px, 2px, 4px etc.
    BOOL _rotating;                       // Rotation flag is used for optimization
}

@property (nonatomic, getter = isVertical) BOOL vertical;                 // Changes scrolling direction from left-right to up-down
@property (nonatomic) CGFloat gapBetweenPages;                            // Interspacing between neighbor page views
@property (nonatomic, readonly) NSUInteger currentPageIndex;              // KVO-compliant property enabling UI updates
@property (nonatomic, readonly) id currentPageView;                       // KVO-compliant property to access the most visible page

@property (nonatomic, assign) id<BYPagingScrollViewPageSource>pageSource; // Analogue of the -[UITableView dataSource]

// Just like in the UITableView, you can reload contents and reuse pages by their class name
- (void)reloadPages;                                             // Analogue of the -[UITableView reloadData]
- (id)dequeReusablePageViewWithClassName:(NSString *)className;  // Analogue of the -[UITableView dequeueReusableCellWithIdentifier:]

// To keep a page layout consistent, rotation must be performed explicitly
- (void)beginTwoPartRotation; // Must be called from -[UIViewController willRotateToInterfaceOrientation:duration:]
- (void)endTwoPartRotation;   // Must be called from -[UIViewController didRotateFromInterfaceOrientation:]

@end

#pragma mark -

@protocol BYPagingScrollViewPageSource<NSObject>
@required

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView;
- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex;

@end
