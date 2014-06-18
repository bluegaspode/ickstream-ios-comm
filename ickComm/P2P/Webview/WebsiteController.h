//
//  WebsiteController.h
//  TwitterTest
//
//  Created by Karsten Silz on 28.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "IPBookmarkSelector.h"

typedef enum {
    kWebsitePlain       = 0x0,
    kWebsiteEntryField  = 0x01,
    kWebsiteBookmarks   = 0x02,
    kWebsiteNavigation  = 0x04,
    kWebsiteMusicFinder = 0x08,
    kWebsitePasteTrack  = 0x10,
    kWebsiteIsOnTop     = 0x20
} IPWebsiteViewCapabilities;


@interface IPWebView : UIWebView {
    // Pull to refresh
    UIView *refreshHeaderView;
    UILabel *refreshLabel;
    UIImageView *refreshArrow;
    UIActivityIndicatorView *refreshSpinner;
    BOOL isDragging;
    BOOL isLoading;
    NSString *textPull;
    NSString *textRelease;
    NSString *textLoading;
        
@private
    CGPoint lastTouchPoint;
}

@property (nonatomic, readonly) CGPoint lastTouchPoint;

@property (nonatomic, retain) UIView *refreshHeaderView;
@property (nonatomic, retain) UILabel *refreshLabel;
@property (nonatomic, retain) UIImageView *refreshArrow;
@property (nonatomic, retain) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic, copy) NSString *textPull;
@property (nonatomic, copy) NSString *textRelease;
@property (nonatomic, copy) NSString *textLoading;
@property (nonatomic, readonly) UIScrollView * myScrollView;
@property (nonatomic, readonly) UITextField * mySearchTextField;
@property (nonatomic, readonly, weak) UISearchBar * searchBar;
@property (nonatomic, readonly) NSString * selectedText;

- (void)addPullToRefreshHeader;
- (void)startLoading;
- (void)stopLoading;
- (void)showSearchBar;

@end



// controller for the web site that checks the links that users click for music
#ifdef __iPeng4iPad__
@interface WebsiteController : UIViewController <UIWebViewDelegate, UISearchBarDelegate, UIPopoverControllerDelegate, IPBookmarkSelectorDelegate>
#else
@interface WebsiteController : UIViewController <UIWebViewDelegate, UISearchBarDelegate/*, IPBookmarkSelectorDelegate*/>
#endif
{
    IPWebView*               website;
    __strong NSURL*							link;
    
    // indicates that the WebView should not be reloaded when it appears. Facebook tweak.
    BOOL        noReload;
    
	@private
	
		
  // HTTP request counter so we know when to stop showing the "network activity"
	// indicator (a single HTML page can fire dozens of requests)
	int										progressCounter;
    BOOL                    usesBookmarkInHeader;
    BOOL                    unfinishedLoad;
}


@property (nonatomic, strong) IBOutlet IPWebView*               website;
@property (nonatomic, strong) NSURL*							link;

+ (WebsiteController *)websiteSingleton;
- (void)refresh:(BOOL)enforce;
- (void)refresh;
+ (void)stopOtherLoading:(WebsiteController *)wc;
- (void)setLink:(NSURL *)newLink andStore:(BOOL)store;
- (id)initWithCapabilities:(IPWebsiteViewCapabilities)capa andCommand:(id)aCmd;
- (void)addLinkCheckBlock:(BOOL(^)(IPWebView * webView, NSURLRequest * request, UIWebViewNavigationType navigationType))block;

@end
