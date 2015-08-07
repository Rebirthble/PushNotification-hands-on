//
//  AppDelegate.m
//  PushNotificationSample
//
//  Created by 大川雄生 on 2015/08/07.
//  Copyright (c) 2015年 OkawaUki. All rights reserved.
//

#import "AppDelegate.h"
#import <NCMB/NCMB.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //SDKの初期化
    [NCMB setApplicationKey:@"YOUR_APPLICATION_EKY"
                  clientKey:@"YOUR_CLIENT_KEY"];
    
    //Interactive Notifications用に承認するアクションを作成
    UIMutableUserNotificationAction *acceptAction =
    [[UIMutableUserNotificationAction alloc] init];
    acceptAction.identifier = @"ACCEPT_IDENTIFIER";
    acceptAction.title = @"Accept";
    acceptAction.activationMode = UIUserNotificationActivationModeBackground;
    //Interactive Notifications用に拒否アクションを作成
    UIMutableUserNotificationAction *denyAction =
    [[UIMutableUserNotificationAction alloc] init];
    denyAction.identifier = @"DENY_IDENTIFIER";
    denyAction.title = @"Deny";
    denyAction.activationMode = UIUserNotificationActivationModeBackground;
    
    //カテゴリを作成
    UIMutableUserNotificationCategory *friendReqCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    //プッシュ通知で指定するカテゴリ名を設定
    friendReqCategory.identifier = @"FRIEND_REQUEST";
    //表示するアクションを設定
    [friendReqCategory setActions:@[acceptAction, denyAction]
                       forContext:UIUserNotificationActionContextDefault];
    
    //カテゴリを集めたNSSetを作成
    NSSet *categories = [NSSet setWithObject:friendReqCategory];
    
    //プッシュ通知のタイプを設定して許可画面を表示する
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound |
    UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    //デバイストークンの要求
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    return YES;
}

//アクションが実行された場合に呼び出されるデリゲートメソッド
- (void)application:(UIApplication *) application
handleActionWithIdentifier: (NSString *) identifier
forRemoteNotification: (NSDictionary *) notification
  completionHandler: (void (^)()) completionHandler {
    //アクションのIdnetifierごとに処理を分けて実装する
    if ([identifier isEqualToString: @"ACCEPT_IDENTIFIER"]) {
        [self handleAcceptActionWithNotification];
    } else {
        [self handleDenyActionWithNotification];
    }
    //ハンドリングが終了する場合に必ず以下を実行する
    completionHandler();
}

//Acceptが実行された場合の処理
- (void)handleAcceptActionWithNotification{
    NSLog(@"Request accepted.");
}
//Denyが実行された場合の処理
- (void)handleDenyActionWithNotification{
    NSLog(@"Request denied.");
}

-(void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //NCMBInstallation作成
    NCMBInstallation *installation = [NCMBInstallation currentInstallation];
    //デバイストークンをセット
    [installation setDeviceTokenFromData:deviceToken];
    
    //キャリアを取得して端末情報に登録
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    [installation setObject:carrier.carrierName forKey:@"carrier"];
    
    //ニフティクラウド mobile  backendのデータストアに登録
    [installation saveInBackgroundWithBlock:^(NSError *error) {
        if(!error){
            //端末情報の登録が成功した場合の処理
            NSLog(@"installation saved.");
        } else {
            //端末情報の登録が失敗した場合の処理
            NSLog(@"error:%@", error);
        }
    }];
}

//Content-availableが1のプッシュ通知が受信されたときに呼び出されるデリゲートメソッド
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    //mobile backendのコンテンツを取得
    NCMBQuery *query = [NCMBQuery queryWithClassName:@"contents"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error){
            NSLog(@"search error:%@", error);
            completionHandler(UIBackgroundFetchResultNoData);
        } else {
            //このあとここに処理を書いていきます
            
            for (NCMBObject *obj in objects) {
                NSString *title = [obj objectForKey:@"title"];
                NSString *url = [obj objectForKey:@"url"];
                NSLog(@"title:%@, url:%@", title, url);
            }
            completionHandler(UIBackgroundFetchResultNewData);
        }
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
