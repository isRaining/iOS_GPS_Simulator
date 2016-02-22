//
//  ZZYLocationSimulator.m
//  GPSSimulator
//
//  Created by Code on 16/2/20.
//  Copyright © 2016年 ZZY. All rights reserved.
//

/**
 *  注释一下这个类的作用
 1、首先在创建ZZYLocationSimulator类的sharedInstance对象后，调用loadLocationFile:方法读取带有位置坐标的文件，解析这个文件，将位置点从这个文件里保存到名为fakeLocations的可变数组中。
 2、当ViewController类调用startUpdatingLocation方法时，下一个位置点从fakeLocation数组中赋值到当前位置currentlocation变量中，并且调用fakeNewLocation方法。
 3、fakeNewLocation这个方法用来检测从之前的位置previousLocation到currentlocation的距离是否大于distanceFilter。如果大于的话，当前位置currentlocation将会赋值给previousLocation变量，并且使用previousLocation和currentlocation创建一个数组，将数组传递给CLLocationManager类的委托方法didUpdateLocations。
 4、如果设置了mapView属性，currentlocation会传给mapView的userLocation属性，用以模拟currentLocation就是userLocation。
 5、最后会检查是否已经到达fakelocations数组的末尾，还有这个方法是否应该在一个连续循环中运行。如果fakelocations中有更多可用的位置点，那么下一个对象会传给currentlocation属性，同事这个方法在updateInterval变量指定的一段时间后，再次调用自身。
 */

#import "ZZYLocationSimulator.h"

@implementation ZZYLocationSimulator
{
    @private
    id<CLLocationManagerDelegate>   delegate;
    ZZYLocationSimulator            *sharedInstance;
    BOOL                            updatingLocation;
    NSMutableArray                  *fakeLocations;//伪造位置数组 fake伪造,捏造
    NSInteger                       index;
    NSTimeInterval                  updateIntervel;
    CLLocationDistance              distanceFilter;
}
static ZZYLocationSimulator * sharedInstance = nil;

+(ZZYLocationSimulator * )sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL]init];
    }
    return sharedInstance;
}
//从NSBundle中拿出位置数据放进fakeLocations数组
-(void)loadLocationFile:(NSString *)pathToFile
{
    //从文件中读取
    NSString * fileContents = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:nil];
    //first，separate by new line
    NSArray * allLines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    //if the fakeLocations array is nil creat it
    if (fakeLocations == nil) {
        fakeLocations = [[NSMutableArray alloc]init];
    }
    NSLog(@"%@",allLines);
    NSLog(@"%@",allLines[0]);
    //Patse each line and add the coordinate to array 将位置信息解析后添加到数组中
    for (int i =0; i<allLines.count ; i++) {
        NSString * line =[[allLines objectAtIndex:i]stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray * latLong = [line componentsSeparatedByString:@","];
        CLLocationDegrees lat = [[latLong objectAtIndex:1] doubleValue];
        CLLocationDegrees lon = [[latLong objectAtIndex:0] doubleValue];
        CLLocation * loc = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
        [fakeLocations addObject:loc];
    }
    NSLog(@"%@",fakeLocations);
}
//模拟一个新的位置信息,是从fakeLocations数组中取出下一个约定位置
-(void)fakeNewLocation
{
    if ((!self.previousLocation || [self.currentlocation distanceFromLocation:self.previousLocation]>distanceFilter)) {
        if (!self.previousLocation) {
            self.previousLocation = self.currentlocation;
        }
        NSLog(@"%@",self.previousLocation);
        //Creat an NSArray with the old location and new location and call the delegate
        NSArray * locs = @[self.previousLocation,self.currentlocation];
        [self.delegate locationManager:nil didUpdateLocations:locs];
        self.previousLocation = self.currentlocation;
        
        //update the userLocation in the mapView if one is assigned
        if (_mapView) {
            [self.mapView.userLocation setCoordinate:self.currentlocation.coordinate];
        }
        //iterate(迭代) to next fake location
        if(updatingLocation){
            index++;
            if (index == fakeLocations.count) {
                index = 0;
                if (!_bKeepRunning) {
                    [self stopUpdatingLocation];
                    updatingLocation = NO;
                }else{
                    self.currentlocation = [fakeLocations objectAtIndex:index];
                }
            }else{
                self.currentlocation = [fakeLocations objectAtIndex:index];
            }
        }
        
        [self performSelector:@selector(fakeNewLocation) withObject:nil afterDelay:updateIntervel];
    }
}

-(void)startUpdatingLocation
{
    updatingLocation = YES;
    //updateInterval in seconds will trigger a new location every xx seconds
    updateIntervel = 1.0f;
    if ([fakeLocations count]> 0) {
        self.currentlocation = [fakeLocations objectAtIndex:0];
        [self fakeNewLocation];
    }
}

-(void)stopUpdatingLocation
{
    updatingLocation = NO;
}


@end
