//
// Usual approach to implement a paging scroll view is to enclose it into a clipped view.
// As result, you can control gaps between page views, but cannot nest cross-directional scroll views.
// BYPagingScrollView is more flexible because inherits from UIScrollView directly and allows nesting.
// This way, you can combine horizontal and vertical scroll views supporting Zoom.
//

@protocol BYPagingScrollViewPageSource;

#pragma mark -

@interface BYPagingScrollView : UIScrollView <UIScrollViewDelegate> {

@private

    NSUInteger _numberOfPages;           // Retrieved from the page source
    NSUInteger _minVisiblePage;          // Partially visible page from the left
    NSUInteger _maxVisiblePage;          // Partially visible page from the right
    NSMutableDictionary *_activePages;   // Visible and invisible subviews { NSNumber *pageIndex => UIView *pageView }
    NSMutableDictionary *_recycledPages; // Page views for dequeuing { NSString *className => NSMutableSet *pageViews }
    
    CGFloat _gapBetweenPages;            // Black interspacing between pages
}

@property (nonatomic, assign) id<BYPagingScrollViewPageSource>pageSource;

@property (nonatomic, getter = isVertical) BOOL vertical;
@property (nonatomic, readonly, getter = isRotating) BOOL rotating;

- (UIView *)dequePageViewWithClassName:(NSString *)className;

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
