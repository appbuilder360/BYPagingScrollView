//
// Usual approach to implement a paging scroll view is to enclose it into a clipped view.
// As result, you can control gaps between page views, but cannot nest cross-directional scroll views.
// BYPagingScrollView is more flexible because inherits from UIScrollView directly and allows nesting.
// This way, you can combine horizontal and vertical scroll views supporting Zoom.
//

@protocol BYPagingScrollViewPageSource;

#pragma mark -

@interface BYPagingScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, assign) id<BYPagingScrollViewPageSource>pageSource;

@property (nonatomic, getter = isVertical) BOOL vertical;

- (UIView *)dequePageViewWithClassName:(NSString *)className;

@end

#pragma mark -

@protocol BYPagingScrollViewPageSource<NSObject>

@required

- (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView;
- (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex;

@optional

- (void)scrollView:(BYPagingScrollView *)scrollView didScrollToPage:(NSUInteger)newPageIndex fromPage:(NSUInteger)oldPageIndex;

@end
