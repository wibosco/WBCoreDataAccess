//
//  CDEUserBackgroundContextViewController.m
//  iOSExample
//
//  Created by William Boles on 25/01/2016.
//  Copyright © 2016 Boles. All rights reserved.
//

#import "CDEUserBackgroundContextViewController.h"

#import <CoreDataServices/CoreDataServices-Swift.h>
#import <PureLayout/PureLayout.h>

#import "CDEUser.h"
#import "CDEUserTableViewCell.h"
#import "CDEUserInsertionOperation.h"

@interface CDEUserBackgroundContextViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *users;

@property (nonatomic, strong) UIBarButtonItem *insertUserBarButtonItem;

@property (nonatomic, strong) NSOperationQueue *queue;

- (void)insertButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation CDEUserBackgroundContextViewController

#pragma mark - ViewLifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*-------------------*/
    
    self.navigationItem.rightBarButtonItem = self.insertUserBarButtonItem;
    
    /*-------------------*/
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /*-------------------*/
    
    self.users = nil;
    [self.tableView reloadData];
}

#pragma mark - Subview

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame
                                                  style:UITableViewStylePlain];
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        [_tableView registerClass:[CDEUserTableViewCell class]
           forCellReuseIdentifier:[CDEUserTableViewCell reuseIdentifier]];
    }
    
    return _tableView;
}

- (UIBarButtonItem *)insertUserBarButtonItem
{
    if (!_insertUserBarButtonItem)
    {
        _insertUserBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                 target:self
                                                                                 action:@selector(insertButtonPressed:)];
    }
    
    return _insertUserBarButtonItem;
}

#pragma mark - Users

- (NSArray *)users
{
    if (!_users)
    {
        NSSortDescriptor *ageSort = [NSSortDescriptor sortDescriptorWithKey:@"age"
                                                                  ascending:YES];
        
        _users = [[CDSServiceManager sharedInstance].mainManagedObjectContext cds_retrieveEntriesForEntityClass:[CDEUser class]
                                                                                            sortDescriptors:@[ageSort]];
    }
    
    return _users;
}

#pragma mark - Queue

- (NSOperationQueue *)queue
{
    if (!_queue)
    {
        _queue = [[NSOperationQueue alloc] init];
    }
    
    return _queue;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDEUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[CDEUserTableViewCell reuseIdentifier]
                                                                 forIndexPath:indexPath];
    
    CDEUser *user = self.users[indexPath.row];
    
    cell.nameLabel.text = user.name;
    cell.ageLabel.text = [NSString stringWithFormat:@"%@", user.age];
    
    [cell layoutByApplyingConstraints];
    
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Total Users: %@", @([[CDSServiceManager sharedInstance].mainManagedObjectContext cds_retrieveEntriesCountForEntityClass:[CDEUser class]])];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CDEUser *user = self.users[indexPath.row];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID MATCHES %@", user.userID]; //I could have passed the user itself but I wanted to demostrate a predicate being used
    
    [[CDSServiceManager sharedInstance].mainManagedObjectContext cds_deleteEntriesForEntityClass:[CDEUser class]
                                                                                   predicate:predicate];
    
    self.users = nil;
    
    [self.tableView reloadData];
}

#pragma mark - Insert

- (void)insertButtonPressed:(UIBarButtonItem *)sender
{
    CDEUserInsertionOperation *operation = [[CDEUserInsertionOperation alloc] initWithCompletion:^
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            self.users = nil;
            
            [self.tableView reloadData];
        });
    }];
    
    [self.queue addOperation:operation];
}

@end
