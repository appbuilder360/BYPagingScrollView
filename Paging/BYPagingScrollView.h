//
// Usual approach to implement a paging scroll view is to enclose it into a clipped view.
// As result, you can control gaps between page views, but cannot nest cross-directional scroll views.
// BYPagingScrollView is more flexible because inherits from UIScrollView directly and allows nesting.
// This way, you can combine horizontal and vertical scroll views supporting Zoom.
//

#define DEFAULT_GAP_BETWEEN_PAGES 20

#pragma mark -

@protocol BYPagingScrollViewPageSource;

#pragma mark -

@interface BYPagingScrollView : UIScrollView <UIScrollViewDelegate> {

@private

    NSUInteger _numberOfPages;            // Retrieved from the page source
    NSUInteger _minVisiblePage;           // Partially visible page 1
    NSUInteger _maxVisiblePage;           // Partially visible page 2
    NSMutableDictionary *_preloadedPages; // Visible and invisible subviews { NSNumber *pageIndex => UIView *pageView }
    NSMutableDictionary *_reusablePages;  // Page views for reusing { NSString *className => NSMutableSet *pageViews }
    
    CGFloat _gapBetweenPages;             // Black interspacing between pages, always even i.e. 0px, 2px, 4px etc.
}

@property (nonatomic, assign) id<BYPagingScrollViewPageSource>pageSource;

@property (nonatomic, getter = isVertical) BOOL vertical;
@property (nonatomic, readonly, getter = isRotating) BOOL rotating;
@property (nonatomic) CGFloat gapBetweenPages;

- (id)dequeReusablePageViewWithClassName:(NSString *)className;

- (void)beginRotation;
- (void)endRotation;

@end

#pragma mark -

@protocol BYPagingScrollViewPageSource<NSObject>

@required

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView;
- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex;

@optional

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex;

@end
