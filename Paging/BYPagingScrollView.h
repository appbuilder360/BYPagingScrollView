//
// Usual approach to implement a paging scroll view is to enclose it into a clipped view.
// As result, you easily set the gap between page views, but cannot nest cross-directional scroll views.
// BYPagingScrollView is more flexible because inherits from UIScrollView directly and allows nesting.
// This way, you can combine horizontal and vertical scroll views and even support Zoom.
//

#define DEFAULT_GAP_BETWEEN_PAGES 20

#pragma mark -

@protocol BYPagingScrollViewPageSource;

#pragma mark -

@interface BYPagingScrollView : UIScrollView <UIScrollViewDelegate> {

@private

    NSUInteger _numberOfPages;            // Cached number retrieved from the page source
    NSUInteger _firstPageInLayout;        // Index of the first page laid out in the scroll view
    NSUInteger _firstVisiblePage;         // Partially visible left (top) page
    NSUInteger _lastVisiblePage;          // Partially visible right (bottom) page
    NSUInteger _mostVisiblePage;          // Index of the current page which is the most visible
    NSMutableDictionary *_preloadedPages; // Visible and invisible subviews { NSNumber *pageIndex => UIView *pageView }
    NSMutableDictionary *_reusablePages;  // Page views for reusing { NSString *className => NSMutableSet *pageViews }
    
    CGFloat _gapBetweenPages;             // Black interspacing between pages, always even i.e. 0px, 2px, 4px etc.
    
    BOOL _rotating;                       // Rotation flag is used for optimization
}

@property (nonatomic, assign) id<BYPagingScrollViewPageSource>pageSource;

@property (nonatomic, getter = isVertical) BOOL vertical;
@property (nonatomic) CGFloat gapBetweenPages;
@property (nonatomic, readonly) NSUInteger currentPageIndex;

- (void)reloadPages;

- (id)pageViewAtIndex:(NSUInteger)pageIndex;
- (id)dequeReusablePageViewWithClassName:(NSString *)className;

- (void)beginTwoPartRotation;
- (void)endTwoPartRotation;

@end

#pragma mark -

@protocol BYPagingScrollViewPageSource<NSObject>

@required

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView;
- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex;

@optional

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex;

@end
