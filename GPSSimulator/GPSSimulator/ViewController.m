//
//  ViewController.m
//  GPSSimulator
//
//  Created by Code on 16/2/20.
//  Copyright © 2016年 ZZY. All rights reserved.
//

/**
 *  本类功能说明
 *
 *  在ViewDidLoad中，使用起始坐标点初始化mapView属性，并通过调用sharedInstance的静态方法创建模拟器。
 *  通过调用loadLocationFile:方法传入coordinates.txt文件，来给locationManager的属性赋值。
 *  在viewDidLoad方法的末尾，延迟5秒调用startUpdating开始更新位置信息，5秒时间用来初始化和绘制地图。
 *  在locationManager:didUpdateLocations:方法中，获取到上一个位置和当前位置信息，然后调用updateMap:来更新mapView.
 *  [self.mapView setRegion:region animated:YES];来设置使地图居中显示当前位置。
 */

#import "ViewController.h"
@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>

@end

@implementation ViewController
//声明模拟器对应的locationManager变量
    ZZYLocationSimulator * locationManager;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.showsUserLocation = YES;
    CLLocationDegrees lat = (double)40.04571393206;
    CLLocationDegrees lon = (double)116.31150300652;
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(lat, lon);
    self.mapView.delegate=self;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(lat, lon), 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    
    ZZYLocationSimulator * simulator = [ZZYLocationSimulator sharedInstance];
    [simulator loadLocationFile:[[NSBundle mainBundle]pathForResource:@"coordinates" ofType:@"txt"]];
    locationManager = simulator;
    locationManager.delegate = self;
    locationManager.mapView = _mapView;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    //wait 5 seconds for the map to draw itself
    [self performSelector:@selector(startUpdating) withObject:nil afterDelay:5.0];
}
//开始更新位置
-(void)startUpdating
{
    [locationManager startUpdatingLocation];
}
#pragma CLLocationManager delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation * oldLocation = [locations objectAtIndex:0];
    CLLocation * newLocation = [locations lastObject];
    [self updateMap:oldLocation andNewLocation:newLocation];
}
//更新地图聚焦位置
-(void)updateMap:(CLLocation *)oldLocation andNewLocation:(CLLocation *)newLocation
{
    if (newLocation) {
        if(oldLocation.coordinate.latitude != newLocation.coordinate.latitude && oldLocation.coordinate.longitude != newLocation.coordinate.longitude){
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 100, 100);
            [_mapView setRegion:region animated:YES];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
