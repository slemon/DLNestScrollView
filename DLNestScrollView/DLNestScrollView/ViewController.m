//
//  ViewController.m
//  DLNestScrollView
//
//  Created by Dalong on 2017/8/20.
//  Copyright © 2017年 Dalong. All rights reserved.
//

#import "ViewController.h"
#import <MJRefresh.h>
#import <YYCategories.h>

@import WebKit;

static  NSString * kCellIdentifier = @"cell";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webview;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataList;
@property (nonatomic, assign) CGFloat webviewContentHeight;
@property (nonatomic, assign) BOOL isWebviewFinishLoad; //是否webview加载完毕


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.isWebviewFinishLoad = NO;
    
    //webview 做header view
    [self addWebViewAsTableHeaderView];
    
    //驱动webview滑动
    [self addDirveScrollView];
    
    
    //Load Webview
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://mp.weixin.qq.com/s/FH0DjxXJlOu0QRPaYk8r2Q"]];
    [self.webview loadRequest:request];
    
    @weakify(self);
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [weak_self requreDataList:NO];
    }];
    footer.triggerAutomaticallyRefreshPercent = -50;
    self.tableView.mj_footer = footer;
    
    [self requreDataList:YES];
}


- (void)addWebViewAsTableHeaderView {
    
    [self.view addSubview:self.scrollView];//此处添加scrollview 是为了比较内存占用
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.webview;
    
}

- (void)addDirveScrollView {
    
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.webview];
    [self.scrollView addSubview:self.tableView];
    self.tableView.top = kScreenHeight;
    self.webview.scrollView.scrollEnabled = NO;
    self.tableView.scrollEnabled = NO;
}



#pragma mark - Methods

- (void)requreDataList:(BOOL)isRefresh {
    
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [_tableView.mj_footer resetNoMoreData];
        [_tableView.mj_footer endRefreshing];
        
        NSInteger num = 20;
        while (num--) {
            [weak_self.dataList addObject:@(1)];
        }
        [weak_self.tableView reloadData];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.33 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //更新scorllview的contentsize
            [self updateScrollViewContentSize];
        });
        
    });
}

- (void)updateScrollViewContentSize {
    //webview 未加载完的时候也支持滑动
    CGFloat webviewContentHeight = self.isWebviewFinishLoad ?  self.webviewContentHeight : self.webview.height * 10;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.width, self.tableView.contentSize.height +  webviewContentHeight + self.tableView.contentInset.bottom);
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    return cell;
}

#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    //获取webview的内容高度
    [webView evaluateJavaScript:@"document.body.offsetHeight;"completionHandler:^(id _Nullable result,NSError *_Nullable error) {
        
        
        self.webviewContentHeight = MAX([result doubleValue], self.webview.height);
        
        if (self.tableView.tableHeaderView) {
            self.webview.height = self.webviewContentHeight;
            self.tableView.tableHeaderView = self.webview;
        }
        else {
            self.isWebviewFinishLoad = YES;
            [self updateScrollViewContentSize];
        }
        
    }];
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offset_y = scrollView.contentOffset.y;
    if (scrollView == self.scrollView) {
        CGFloat webTop =  self.webviewContentHeight - self.webview.height;
        if (offset_y < webTop) {
            //滚动webview
            [self.webview.scrollView setContentOffset:CGPointMake(0, offset_y)];
             self.webview.top = offset_y;
             self.tableView.top = self.webview.bottom;
        }else {
            //修正
            if (offset_y < self.webviewContentHeight) {
                if (self.tableView.contentOffset.y > 0) {
                    self.tableView.contentOffset = CGPointZero;
                    self.tableView.top = self.webview.bottom;
                }
            }else {
                //开始滚动tableview
                self.tableView.top = offset_y;
                [self.tableView setContentOffset:CGPointMake(0, offset_y - self.webviewContentHeight)];
            }
        }
        
    }
    
}


#pragma mark - Getter

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    }
    return _tableView;
}

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [UIScrollView new];
        _scrollView.frame = self.view.bounds;
        _scrollView.contentSize = CGSizeMake(kScreenWidth, kScreenHeight * 2);
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (WKWebView *)webview {
    if (_webview == nil) {
        _webview = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:[WKWebViewConfiguration new]];
        _webview.navigationDelegate = self;
    }
    return _webview;
}

- (NSMutableArray *)dataList {
    if (_dataList == nil) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
