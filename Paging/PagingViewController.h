//
// Example view controller that uses paging scroll view.
//

#import "BYPagingScrollView.h"

@interface PagingViewController : UIViewController <BYPagingScrollViewPageSource>

@property (nonatomic, readonly) BYPagingScrollView *pagingScrollView;

@end
