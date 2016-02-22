//
//  ZZYLocationSimulator.h
//  GPSSimulator
//
//  Created by Code on 16/2/20.
//  Copyright © 2016年 ZZY. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>
@interface ZZYLocationSimulator : CLLocationManager
@property (nonatomic,strong) CLLocation     *currentlocation;//保存当前位置
@property (nonatomic,strong) CLLocation     *previousLocation;//之前的位置
@property (nonatomic,strong) MKMapView      *mapView;//显示位置
@property (nonatomic,assign) BOOL           bKeepRunning;
//单例
+(ZZYLocationSimulator *)sharedInstance;
//从NSBundle中读取带有坐标的文件
-(void)loadLocationFile:(NSString *)pathToFile;
//开始更新位置信息
-(void)startUpdatingLocation;
//停止更新位置信息
-(void)stopUpdatingLocation;
@end
