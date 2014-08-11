//
//  WebsiteController.m
//  ickComm
//
//  Created by Karsten Silz on 28.10.10.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#import "WebsiteController.h"
#import "RegexKitLite.h"
#import "UIView_ickStream.h"
#import <QuartzCore/QuartzCore.h>

// height of the buttons in the nav bar
static int kCustomButtonHeight	=	30;

#define REFRESH_HEADER_HEIGHT 52.0f
#define SEARCH_BAR_HEIGHT   44.0f
#define REFRESH_HEADER_TOP  (REFRESH_HEADER_HEIGHT + ((_capabilities & kWebsiteEntryField) ? SEARCH_BAR_HEIGHT : 0.0))

@interface IPWebView()

@property (nonatomic, weak) UIView * barView;
@property (nonatomic, readwrite, weak) UISearchBar * searchBar;
@property (nonatomic) IPWebsiteViewCapabilities capabilities;

@end


@implementation IPWebView
@synthesize lastTouchPoint;
@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner;

- (UIScrollView *)myScrollView {
    return (UIScrollView *)[self findSubviewOfClass:[UIScrollView class]];
}

- (UITextField *)mySearchTextField {
    if (!_capabilities & kWebsiteEntryField)
        return nil;
    return (UITextField *)[_searchBar findSubviewOfClass:[UITextField class]];
}

- (id)initWithCapabilities:(IPWebsiteViewCapabilities)capa {
    self = [super init];
    if (self) {
        _capabilities = capa;
        textPull = [[NSString alloc] initWithString:NSLocalizedString(@"Pull down to refresh...", nil)];
        textRelease = [[NSString alloc] initWithString:NSLocalizedString(@"Release to refresh...", nil)];
        textLoading = [[NSString alloc] initWithString:NSLocalizedString(@"Loading...", nil)];
        [self addPullToRefreshHeader];
    }
    return self;
}

- (void)setDelegate:(id<UIWebViewDelegate,UISearchBarDelegate>)delegate {
    [super setDelegate:delegate];
    _searchBar.delegate = delegate;
}

#pragma mark -
#pragma mark pull to refresh stuff

- (void)addPullToRefreshHeader {
    refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_TOP, 320, REFRESH_HEADER_HEIGHT)];
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ickComm Bundle.bundle/refresharrow.png"]];
    refreshArrow.frame = CGRectMake((REFRESH_HEADER_HEIGHT - 27) / 2,
                                    (REFRESH_HEADER_HEIGHT - 44) / 2,
                                    27, 44);
    
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    refreshSpinner.frame = CGRectMake((REFRESH_HEADER_HEIGHT - 20) / 2, (REFRESH_HEADER_HEIGHT - 20) / 2, 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    
    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [self.myScrollView addSubview:refreshHeaderView];
    
    UIToolbar * tb;
    
    //    if (!IS_ON_PAD) {
    if ((_capabilities & kWebsiteEntryField)) {
        __strong UISearchBar * sb = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 276.0, 44.0)];
        self.searchBar = sb;
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0 - SEARCH_BAR_HEIGHT, 320.0, 44.0)];
        tb.autoresizingMask = UIViewAutoresizingNone;// UIViewAutoresizingFlexibleWidth;
        _barView = tb;
        
        if ((_capabilities & kWebsiteNavigation)) {
            __strong UIButton * bbutton = [UIButton buttonWithType:UIButtonTypeCustom];
            __strong UIImage * bImage = [UIImage imageNamed:@"ickComm Bundle.bundle/back.png"];
            [bbutton setImage:bImage forState:UIControlStateNormal];
            bbutton.frame = CGRectMake(0.0, 0.0, bImage.size.width, bImage.size.height);
            [bbutton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
            
            tb.items = @[[[UIBarButtonItem alloc] initWithCustomView:bbutton],
                         [[UIBarButtonItem alloc] initWithCustomView:_searchBar]];
        } else
            tb.items = @[[[UIBarButtonItem alloc] initWithCustomView:_searchBar]];
    }
    
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchBar.keyboardType = UIKeyboardTypeURL;
    _searchBar.placeholder = @"URL";
    _searchBar.showsBookmarkButton = (_capabilities & kWebsiteBookmarks);
    if (_barView)
        [self.myScrollView addSubview:_barView];
    UITextField * tf = self.mySearchTextField;
    tf.leftViewMode = UITextFieldViewModeNever;
    tf.returnKeyType = UIReturnKeyGo;
    tf.borderStyle = UITextBorderStyleRoundedRect;
}

- (void)setFrame:(CGRect)frame {
    if (_barView) {
        CGRect bframe = _barView.frame;
        bframe.size.width = frame.size.width;
        _barView.frame = bframe;
    }
    [super setFrame:frame];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (isLoading) return;
    isDragging = YES;
    if ([super respondsToSelector:@selector(scrollViewWillBeginDragging:)])
        [super scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isLoading) {
        // Update the content inset, good for section headers
        if ((scrollView.contentOffset.y >= -REFRESH_HEADER_TOP) && (scrollView.contentOffset.y <= 0))
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [UIView beginAnimations:nil context:NULL];
        if (scrollView.contentOffset.y < -REFRESH_HEADER_TOP) {
            // User is scrolling above the header
            refreshLabel.text = self.textRelease;
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
        } else { // User is scrolling somewhere within the header
            refreshLabel.text = self.textPull;
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
        }
        [UIView commitAnimations];
    }
    CGRect frame = refreshHeaderView.frame;
    CGPoint offset = scrollView.contentOffset;
    if (frame.origin.x != offset.x) {
        refreshHeaderView.frame = CGRectMake(offset.x, frame.origin.y, frame.size.width, frame.size.height);
        if (_barView) {
            frame = _barView.frame;
            _barView.frame = CGRectMake(offset.x, frame.origin.y, frame.size.width, frame.size.height);
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (isDragging || isLoading)
        return;
    if (scrollView.contentOffset.y < 0) {
        [UIView animateWithDuration:0.3 animations:^{
            CGFloat yOffset = scrollView.contentOffset.y;
            if ((_capabilities & kWebsiteEntryField) &&
                (yOffset <= -(SEARCH_BAR_HEIGHT / 2.0))) {
                scrollView.contentInset = UIEdgeInsetsMake(SEARCH_BAR_HEIGHT, 0, 0, 0);
                scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, -SEARCH_BAR_HEIGHT);
            } else
                scrollView.contentInset = UIEdgeInsetsZero;
        }];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) return;
    isDragging = NO;
    CGFloat yOffset = scrollView.contentOffset.y;
    if (yOffset <= -REFRESH_HEADER_TOP) {
        // Released above the header
        [self startLoading];
    } else if ((_capabilities & kWebsiteEntryField) &&
               (yOffset <= -(SEARCH_BAR_HEIGHT / 2.0))) {
        scrollView.contentInset = UIEdgeInsetsMake(SEARCH_BAR_HEIGHT, 0, 0, 0);
        if (!decelerate) {
            [UIView animateWithDuration:0.3 animations:^{
                scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, -SEARCH_BAR_HEIGHT);
            }];
        }
    } else {
        if (!decelerate) {
            [UIView animateWithDuration:0.3 animations:^{
                scrollView.contentInset = UIEdgeInsetsZero;
            }];
        } else
            scrollView.contentInset = UIEdgeInsetsZero;
    }
    if ([super respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)startLoading {
    isLoading = YES;
    
    // Show the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    self.myScrollView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_TOP, 0, 0, 0);
    refreshLabel.text = self.textLoading;
    refreshArrow.hidden = YES;
    [refreshSpinner startAnimating];
    
    [UIView commitAnimations];
    
    // Refresh action!
    if ([self.delegate respondsToSelector:@selector(refresh)])
        [self.delegate performSelector:@selector(refresh)];
    
    [self performSelector:@selector(stopLoading) withObject:nil afterDelay:2.0];
}

- (void)stopLoading {
    isLoading = NO;
    
    // Hide the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    self.myScrollView.contentInset = UIEdgeInsetsZero;
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [UIView commitAnimations];
}

- (void)stopLoadingComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    // Reset the header
    refreshLabel.text = self.textPull;
    refreshArrow.hidden = NO;
    [refreshSpinner stopAnimating];
}

- (void)showSearchBar {
    if (!(_capabilities & kWebsiteEntryField))
        return;
    UIScrollView * scrollView = self.myScrollView;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    scrollView.contentInset = UIEdgeInsetsMake(SEARCH_BAR_HEIGHT, 0.0, 0.0, 0.0);
    scrollView.contentOffset = CGPointMake(0.0, -SEARCH_BAR_HEIGHT);
    [UIView commitAnimations];
}

- (NSString *)selectedText {
    return [self stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
}


@end



@interface WebsiteController()

@property (nonatomic) IPWebsiteViewCapabilities capabilities;
@property (nonatomic, strong) BOOL(^linkCheckerBlock)(IPWebView *, NSURLRequest *, UIWebViewNavigationType);
// back / forward buttons for web view
@property (nonatomic, weak) UISegmentedControl * browserControl;

@end


static WebsiteController * _webSiteSingleton = nil;
static __strong NSMutableSet * _allWebSites = nil;
static __strong NSMutableDictionary * _navControllers = nil;



@implementation WebsiteController


@synthesize website;
@synthesize link;


- (id)init {
    self = [super init];
    _capabilities = kWebsitePlain;
    [_allWebSites addObject:self];
    return self;
}

- (id)initWithCapabilities:(IPWebsiteViewCapabilities)capa andCommand:(id)aCmd {
    self = [super init];
    if (self) {
        [_allWebSites addObject:self];
        _capabilities = capa;
        self.linkCheckerBlock = nil;
        if (aCmd && ![aCmd isKindOfClass:[NSURL class]])
            [self performSelector:@selector(setLink:) withObject:[NSURL URLWithString:aCmd] afterDelay:0];
        else
            [self performSelector:@selector(setLink:) withObject:aCmd afterDelay:0];
    }
    return self;
}


+ (void)initialize {
    if (!_allWebSites)
        _allWebSites = [NSMutableSet setWithCapacity:2];
    if (!_navControllers)
        _navControllers = [NSMutableDictionary dictionaryWithCapacity:5];
}

+ (WebsiteController *)websiteSingleton {
    if (!_webSiteSingleton) {
        _webSiteSingleton = [[WebsiteController alloc] init];
    }
    return _webSiteSingleton;
}

- (void)createRightBarButton {
}

- (void)createLeftBarButton {
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
	// "Segmented" control in the middle
    __strong NSArray * imageArray = nil;
    __strong UISegmentedControl * bCtrl = nil;
    
    //    if (IS_ON_PAD) {
    if ((_capabilities & kWebsiteNavigation) && !(_capabilities & kWebsiteEntryField)) {
        CGFloat controlWidth = 70.0;
        if (_capabilities & kWebsiteBookmarks) {
            usesBookmarkInHeader = YES;
            imageArray = @[[UIImage imageNamed:@"ickComm Bundle.bundle/back.png"],
                           [UIImage imageNamed:@"ickComm Bundle.bundle/addbookmark.png"],
                           [UIImage imageNamed:@"ickComm Bundle.bundle/forward.png"]];
            ((UIImage *)imageArray[0]).accessibilityLabel = NSLocalizedString(@"Previous", nil);
            ((UIImage *)imageArray[1]).accessibilityLabel = NSLocalizedString(@"Bookmarks", nil);
            ((UIImage *)imageArray[2]).accessibilityLabel = NSLocalizedString(@"Next", nil);
            controlWidth += 32.0;
        } else {
            usesBookmarkInHeader = NO;
            imageArray = @[[UIImage imageNamed:@"ickComm Bundle.bundle/back.png"],
                           [UIImage imageNamed:@"ickComm Bundle.bundle/forward.png"]];
            ((UIImage *)imageArray[0]).accessibilityLabel = NSLocalizedString(@"Previous", nil);
            ((UIImage *)imageArray[1]).accessibilityLabel = NSLocalizedString(@"Next", nil);
        }
        
        
        bCtrl = [[UISegmentedControl alloc] initWithItems:imageArray];
        
        [bCtrl addTarget:self action:@selector(handleBrowserControl) forControlEvents:UIControlEventValueChanged];
        
        bCtrl.frame = CGRectMake(0, 0, controlWidth, kCustomButtonHeight);
        bCtrl.momentary = YES;
        self.navigationItem.titleView = bCtrl;
        self.browserControl = bCtrl;
    } else {
        usesBookmarkInHeader = YES;
        self.browserControl = nil;
        UIView * dummyHeader = [[UIView alloc] init];
        dummyHeader.backgroundColor = [UIColor clearColor];
        self.navigationItem.titleView = dummyHeader;
    }
	progressCounter = 0;
    
    [self createRightBarButton];
    [self createLeftBarButton];
    
    //    [self addSearchMenu];
}


- (void)loadView {
    self.website = [[IPWebView alloc] initWithCapabilities:_capabilities];
	self.website.scalesPageToFit = YES;
    self.website.dataDetectorTypes = UIDataDetectorTypeLink;
    //	self.website.frame = CGRectMake(0,0,320,416);
    self.website.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.website.delegate = self;
    self.view = self.website;
	
    self.website.allowsInlineMediaPlayback = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	
    [self.navigationController setNavigationBarHidden:NO animated:YES];

	
    if (!noReload && link) {
        [self refresh];
        self.website.searchBar.text = [[self.website.request URL] description];
    } else if (!link) {
        [self.website showSearchBar];
    }
}

- (void)_pushSelfToNC:(UINavigationController *)myNav {
    [myNav pushViewController:self animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self stopNetworkActivity];
		
    [super viewWillDisappear:animated];
}


 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
    return YES;
    // return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	self.browserControl = nil;
	
	if (self.website) {
		self.website.delegate = nil;
        //		[self.website removeFromSuperview];
		self.website = nil;
	}
	
    [super viewDidUnload];
}



- (void)refresh:(BOOL)enforce {
    // This reloads the current link. Override this method with your custom reload action.
    // Don't call stopLoading at the end, will happen automatically after 2s.
    if (link) {
        [WebsiteController stopOtherLoading:self];
        if (enforce) {
            NSURLRequest* request = [NSURLRequest requestWithURL:link];
            [self.website loadRequest:request];
            self.website.searchBar.text = [[request URL] description];
            self.website.searchBar.text = [[website.request URL] description];
        } else
            [website reload];
    } else
        [self.website showSearchBar];
    noReload = NO;
}

- (void)refresh {
    [self refresh:NO];
}

- (void)dealloc {
	self.browserControl = nil;
	
	if (self.website) {
		self.website.delegate = nil;
        [self.website removeFromSuperview];
		self.website = nil;
	}
    [_allWebSites removeObject:self];
}


// called when user clicks on back / forward button

- (void) handleBrowserControl {
	
    switch (_browserControl.selectedSegmentIndex) {
        case 0:
            if (self.website.canGoBack) {
                [self.website goBack];
            }
            break;
        case 1:
            if (usesBookmarkInHeader) {
                [self searchBarBookmarkButtonClicked:nil];
            } else if (self.website.canGoForward) {
                [self.website goForward];
            }
            break;
        case 2:
            if (self.website.canGoForward) {
                [self.website goForward];
            }            
    }
}

#pragma mark - loading and indicators

- (void)startNetworkActivity {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)stopNetworkActivity {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)interruptLoading {
    [website stopLoading];
    unfinishedLoad = YES;
    noReload = NO;
}

+ (void)stopOtherLoading:(WebsiteController *)except {
    for (WebsiteController * wc in _allWebSites)
        if ((wc != except) && wc.website.loading)
            [wc interruptLoading];
}

- (NSURL *)_checkForReplacementLinks:(NSURL *)linkURL {
    return linkURL;
}


- (void)setLink:(NSURL *)newLink andStore:(BOOL)store {
    if (self.navigationController && store) {
    }
    noReload = YES;
    newLink = [self _checkForReplacementLinks:newLink];
    if ([[website.request URL] isEqual:newLink]) {
        if (unfinishedLoad)
            noReload = NO;
        return;
    }
    link = newLink;
    if (!link) {
        self.website.searchBar.text = nil;
        return;
    }
    [WebsiteController stopOtherLoading:self];
    NSURLRequest* request = [NSURLRequest requestWithURL:link];
    [self.website loadRequest:request];
    self.website.searchBar.text = [link description];
}

- (void)setLink:(NSURL *)newlink {
    [self setLink:newlink andStore:YES];
}

- (void)addLinkCheckBlock:(BOOL (^)(IPWebView *, NSURLRequest *, UIWebViewNavigationType))block {
    self.linkCheckerBlock = block;
}


#pragma mark -
#pragma mark Popover Controller delegate


- (void)showContextMenu:(UIViewController *)cm {
	if (!cm)
		return;
    {
        UINavigationController * nav = self.navigationController;
        if (!nav && [self.parentViewController isKindOfClass:[UINavigationController class]])
            nav = (UINavigationController *)self.parentViewController;
        [nav pushViewController:cm animated:YES];
    }
}


- (void)_cleanupJS {
}


- (BOOL)webView:(IPWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

	BOOL feedback = YES;
    
    if (_linkCheckerBlock)
        feedback = _linkCheckerBlock(webView, request, navigationType);
    

    if (feedback &&
        ((navigationType == UIWebViewNavigationTypeLinkClicked) ||
        (navigationType == UIWebViewNavigationTypeBackForward)
         ))
        self.website.searchBar.text = [[request URL] description];
	return feedback;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	progressCounter--;
	
	if (progressCounter < 0) {
		progressCounter = 0;
	}
	
		//NSLog(@"Stopping web site progress view for error: %d, %@", progressCounter, error);

	if (progressCounter == 0) {
        [self stopNetworkActivity];
	}
	
    unfinishedLoad = NO;
    noReload = NO;
}

static NSString * _audioPlayOverride = @"";


- (void)webViewDidStartLoad:(UIWebView *)webView {
    [WebsiteController stopOtherLoading:self];
    
	progressCounter++;
	
	
	if (progressCounter == 1) {
        [self startNetworkActivity];
	}
    [webView stringByEvaluatingJavaScriptFromString:_audioPlayOverride];
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {	
	progressCounter--;
	
	if (progressCounter < 0) {
		progressCounter = 0;
	}
	
		//NSLog(@"Stopping web site progress view just fine: %d", progressCounter);
	
	if (progressCounter == 0) {
        [self stopNetworkActivity];
	}
    
    [webView stringByEvaluatingJavaScriptFromString:_audioPlayOverride];
    
    unfinishedLoad = NO;
    noReload = NO;

}

- (NSMutableDictionary *)bookmarkForCurrentSite {
    return nil;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = [[self.website.request URL] description];
    [searchBar resignFirstResponder];
}

- (void)handleNewURL:(NSString *)text {
    if (![[text lowercaseString] hasPrefix:@"http://"] && ![[text lowercaseString] hasPrefix:@"https://"]) {
        if ([text hasPrefix:@"//"])
            text = [NSString stringWithFormat:@"http:%@", text];
        else
            text = [NSString stringWithFormat:@"http://%@", text];
    }
    self.link = [NSURL URLWithString:text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    if (![searchBar.text length])
        return YES;
    [self handleNewURL:searchBar.text];
    return YES;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}


@end
