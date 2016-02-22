# iOS_GPS_Simulator
摸你iOS设备的位置移动，创建一个GPS模拟器，以及Map Kit框架简解


# Map Kit框架
![这里写图片描述](http://img.blog.csdn.net/20160220184024826)

## 摘要
**在iOS应用中显示和使用地图的框架，名叫MapKit。在iOS6之前，这些地图都是由Google公司提供的，被称为Google Maps。iOS6之后，苹果公司实现了自己的地图服务器，后来因为信息不准确等等一度被用户各种吐槽，苹果也在不断的对地图进行优化。**
	
**为了在应用中嵌入地图，Map Kit框架提供了一个地图界面。这个框架包含了一系列类，其中MKMapView是可以直接放置在视图上的类。其他的类中绝大部分与在MKMapView控件上呈现更详细的信息有关，日历标记和叠层。下面我们根据项目来了解MapKit框架。**

## 模拟iOS设备的位置移动
### GPS模拟器
  Xcode开发环境和iOS模拟器自从iOS 5.0版本就具有内置的能力使用GPX格式的文件。GPX代表GPS eXchange Format，被GPS设备使用的一种设备无关的数据格式。你可以使用Xcode开发环境创建一个GPX格式的文件(一个包含了一组坐标的XML文件)，并将其附加在模拟器上。这样的话就可以对摸你设备位置移动的实现方式拥有最大限度的控制。
  
### 创建GPS模拟器
模拟器本身是一个objective-C语言的子类，它继承于CLLocationManager类，并且实现了CLLocationManagerDelegate协议的各种方法。其中一个特殊的方法实现能够从包含一组GPS坐标的简单文本文件中加载数据。

打开xcode，使用Single View Application模板创建一个名为GPSSimulator新项目：

![这里写图片描述](http://img.blog.csdn.net/20160220170919530)

将MapKit.Framework和CoreLocation.Framework导入到项目中

![这里写图片描述](http://img.blog.csdn.net/20160220171627841)

创建一个集成于CLLocationManager类的新的objective-C类，将其命名为ZZYLocationSimulator。创建成功后如果报错，请将MapKit.h在ZZYLocationSimulator.h文件中导入一下，如下图:

![这里写图片描述](http://img.blog.csdn.net/20160220171846090)

**ZZYLocationSimulator.h文件中代码清单如下：**
```objc
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
```

**ZZYLocationSimulator.m文件中代码清单如下：**
```objc

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
    //Patse each line and add the coordinate to array 将位置信息解析后添加到数组中
    for (int i =0; i<allLines.count ; i++) {
        NSString * line =[[allLines objectAtIndex:i]stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray * latLong = [line componentsSeparatedByString:@","];
        CLLocationDegrees lat = [[latLong objectAtIndex:1] doubleValue];
        CLLocationDegrees lon = [[latLong objectAtIndex:0] doubleValue];
        CLLocation * loc = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
        [fakeLocations addObject:loc];
    }
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
//开始更新位置
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
//停止更新位置
-(void)stopUpdatingLocation
{
    updatingLocation = NO;
}
@end
/**
 *  注释一下这个类的作用
 1、首先在创建ZZYLocationSimulator类的sharedInstance对象后，调用loadLocationFile:方法读取带有位置坐标的文件，解析这个文件，将位置点从这个文件里保存到名为fakeLocations的可变数组中。
 2、当ViewController类调用startUpdatingLocation方法时，下一个位置点从fakeLocation数组中赋值到当前位置currentlocation变量中，并且调用fakeNewLocation方法。
 3、fakeNewLocation这个方法用来检测从之前的位置previousLocation到currentlocation的距离是否大于distanceFilter。如果大于的话，当前位置currentlocation将会赋值给previousLocation变量，并且使用previousLocation和currentlocation创建一个数组，将数组传递给CLLocationManager类的委托方法didUpdateLocations。
 4、如果设置了mapView属性，currentlocation会传给mapView的userLocation属性，用以模拟currentLocation就是userLocation。
 5、最后会检查是否已经到达fakelocations数组的末尾，还有这个方法是否应该在一个连续循环中运行。如果fakelocations中有更多可用的位置点，那么下一个对象会传给currentlocation属性，同事这个方法在updateInterval变量指定的一段时间后，再次调用自身。
 */
```
### 使用Google Maps创建GPS路线文件
创建一组ZZYLocationSimulator类中使用的GPS坐标文件的最简单的方法，是访问百度地图的路线API，将沿路的经纬度提取出来，使用它来创建一个路线。
[百度地图API](http://lbsyun.baidu.com/index.php?title=webapi/direction-api)

![这里写图片描述](http://img.blog.csdn.net/20160221205433275)

然后将拿到的json文件中沿途的经纬度坐标抽取出来 ，放进一个命名为coordinates.txt

![这里写图片描述](http://img.blog.csdn.net/20160221205828324)

将coordinates.txt添加到项目中，然后开始实现ZZYLocationSimulator类了。
### 实现ZZYLocationSimulator类
打开ViewController.h文件，将ZZYLocationSimulator类的头文件导入。
使用interface Builder打开Main.storyboard，将MKMapView的对象放在主视图上。使用Assistant Editor工具创建属性，并设置delegate对象。如下图：

![这里写图片描述](http://img.blog.csdn.net/20160221214553339)

**ViewController.h中代码清单如下图：**
```objc
#import <UIKit/UIKit.h>
#import "ZZYLocationSimulator.h"
#import <MapKit/MapKit.h>
@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end
```

**ViewController.m中代码清单如下图：**
```objc
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
/**
 *  本类功能说明
 *
 *  在ViewDidLoad中，使用起始坐标点初始化mapView属性，并通过调用sharedInstance的静态方法创建模拟器。
 *  通过调用loadLocationFile:方法传入coordinates.txt文件，来给locationManager的属性赋值。
 *  在viewDidLoad方法的末尾，延迟5秒调用startUpdating开始更新位置信息，5秒时间用来初始化和绘制地图。
 *  在locationManager:didUpdateLocations:方法中，获取到上一个位置和当前位置信息，然后调用updateMap:来更新mapView.
 *  [self.mapView setRegion:region animated:YES];来设置使地图居中显示当前位置。
 */
```

至此，代码已经结束，对于模拟iOS的GPS定位器便可以运行查看，运行效果如下图：

![这里写图片描述](http://img.blog.csdn.net/20160222102847332)