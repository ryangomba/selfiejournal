//
//  SJViewController.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/10/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJViewController.h"

#import "SJDatabaseController+Entries.h"
#import "SJDatabaseViewDataSource.h"
#import "SJCameraViewController.h"
#import "SJEntryCell.h"

static NSString * const kCellReuseID = @"cell";

@interface SJViewController ()<UITableViewDataSource, UITableViewDelegate, SJDatabaseViewDataSourceDelegate, SJCameraViewControllerDelegate>

@property (nonatomic, strong) SJDatabaseViewDataSource *dataSource;

@property (nonatomic, strong) UITableView *tableView;

@end


@implementation SJViewController

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [SJDatabaseController removeDependent:self forExtensionNamed:kAllEntriesViewName];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onClearButtonTapped)];
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(onAddButtonTapped)];
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor redColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[SJEntryCell class] forCellReuseIdentifier:kCellReuseID];
}


#pragma mark -
#pragma mark Properties

- (SJDatabaseViewDataSource *)dataSource {
    if (!_dataSource) {
        // TODO this setup is a little odd
        
        // register the view
        YapDatabaseView *view = [SJDatabaseController allEntriesView];
        [SJDatabaseController addDependent:self forExtension:view extensionName:kAllEntriesViewName];
        
        // create some mappings
        NSArray *groups = @[kAllItemsGroup];
        YapDatabaseViewMappings *mappings =
        [[YapDatabaseViewMappings alloc] initWithGroups:groups view:view.registeredName];
        
        // make a data source
        self.dataSource = [[SJDatabaseViewDataSource alloc] initWithMappings:mappings database:[SJDatabaseController database]];
        self.dataSource.delegate = self;
    }
    return _dataSource;
}


#pragma mark -
#pragma mark Button Listeners

- (void)onClearButtonTapped {
    [SJDatabaseController flushDatabase];
}

- (void)onAddButtonTapped {
    SJCameraViewController *cameraVC = [[SJCameraViewController alloc] initWithNibName:nil bundle:nil];
    [self presentViewController:cameraVC animated:NO completion:nil];
    cameraVC.delegate = self;
}


#pragma mark -
#pragma mark SJCameraViewControllerDelegate

- (void)cameraViewControllerWantsDismissal:(SJCameraViewController *)viewController {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)cameraViewController:(SJCameraViewController *)viewController
       didCaptureVideoAtPath:(NSString *)videoPath {

    // TODO find a better place to store these files
    NSError *error = nil;
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *filename = [NSString stringWithFormat:@"%@.mov", uuid];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    BOOL moveSuccess = [[NSFileManager defaultManager] moveItemAtPath:videoPath toPath:filePath error:&error];
    NSAssert(moveSuccess, error.localizedDescription);
    
    SJEntry *entry = [SJEntry newInstance];
    entry.text = [NSString stringWithFormat:@"PK: %@", entry.pk];
    entry.date = [NSDate date];
    entry.filePath = filePath;
    [SJDatabaseController saveEntry:entry];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfItemsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.bounds.size.width;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SJEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseID forIndexPath:indexPath];
    
    SJEntry *entry = [self.dataSource itemAtIndexPath:indexPath];
    cell.entry = entry;
    
    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SJEntry *entry = [self.dataSource itemAtIndexPath:indexPath];
        [SJDatabaseController deleteEntry:entry];
    }
}


#pragma mark -
#pragma mark SJDatabaseViewDataSourceDelegate

- (void)dataSourceDidChange:(SJDatabaseViewDataSource *)dataSource
           insertedSections:(NSIndexSet *)insertedSections
            deletedSections:(NSIndexSet *)deletedSections
              insertedItems:(NSArray *)insertedItems
               deletedItems:(NSArray *)deletedItems
               changedItems:(NSArray *)changedItems {
    
    [self.tableView beginUpdates];
    
    [self.tableView insertSections:insertedSections withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView insertRowsAtIndexPaths:insertedItems withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:deletedItems withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:changedItems withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
}

@end
