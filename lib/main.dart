import 'dart:convert';
import 'dart:io';

import 'package:boxtag/constants/strings.dart';
import 'package:boxtag/pages/transporter/filelist.dart';
import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:open_file_safe/open_file_safe.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trust_location/trust_location.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// void main() {
//   runApp(const MyApp());
// }

final TruckNumberController = TextEditingController();
final ContainerNumberController = TextEditingController();

String OTypeChk = "";
bool viewExVisible = false;
bool _isPickupDisabled = true;
bool _isLoadFactoryDisabled = true;
bool _isUnloadFactoryDisabled = true;
bool _isDropDisabled = true;
bool _isPickupCameraDisabled = true;
bool _isLoadFactoryCameraDisabled = true;
bool _isUnloadFactoryCameraDisabled = true;
bool _isDropCameraDisabled = true;
var _disabledColor = Color.fromARGB(255, 91, 92, 94);
var _enabledColor = Color(0XFF0088FF);
var _Pickupcolor = _enabledColor;
var _LoadFactorycolor = _enabledColor;
var _UnloadFactorycolor = _enabledColor;
var _Dropcolor = _enabledColor;

List<XFile> fileslist = [];
var ImageListID = "";

List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // logError(e.code, e.description);
    print('Error in fetching the cameras: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
     return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sign In",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
List<XFile> imageArray = [];
 var image;
  var image1;
  final ImagePicker _picker = ImagePicker();

   DeviceInfoPlugin deviceInfo =
      DeviceInfoPlugin(); // instantiate device info plugin
  late AndroidDeviceInfo androidDeviceInfo;
 late bool isphysicaldevice;
  String _latitude = "";
  String _longitude = "";
  // bool _isMockLocation = false;
  late ServiceStatus serviceStatus;

  _MyHomePageState() {
    requestLocationPermission();
    // input seconds into parameter for getting location with repeating by timer.
    // this example set to 5 seconds.
    TrustLocation.start(1);
    getLocation();
    // requestMobilePermission();
    getDeviceinfo();
  }

   @override
  void initState() {
    _isPickupDisabled = true;
    _isLoadFactoryDisabled = true;
    _isUnloadFactoryDisabled = true;
    _isDropDisabled = true;
    _isPickupCameraDisabled=true;
    _isLoadFactoryCameraDisabled = true;
    _isUnloadFactoryCameraDisabled = true;
    _isDropCameraDisabled = true;
    super.initState();
  }

  Future<void> getLocation() async {
    try {
      TrustLocation.onChange.listen((values) => setState(() {
            _latitude = values.latitude!;
            _longitude = values.longitude!;
            // _isMockLocation = values.isMockLocation!;

            Strings.latitude = values.latitude!;
            Strings.longitude = values.longitude!;
            //         Fluttertoast.showToast(
            //     msg: '_isMockLocation: '+_isMockLocation.toString(),
            //     toastLength: Toast.LENGTH_SHORT,
            //     gravity: ToastGravity.BOTTOM,
            //     timeInSecForIos: 1,
            //     backgroundColor: Colors.red,
            //     textColor: Colors.yellow
            // );
          }));
    } on PlatformException catch (e) {
      print('PlatformException $e');
    }
  }

 void requestLocationPermission() async {
    PermissionStatus permission =
        await LocationPermissions().requestPermissions();

    print('permissions: $permission');
    PermissionStatus permission1 =
        await LocationPermissions().checkPermissionStatus();
    serviceStatus = await LocationPermissions().checkServiceStatus();

    //  MobileNumber.listenPhonePermission((isPermissionGranted) {
    //   if (isPermissionGranted) {
    //     initMobileNumberState();
    //   } else {}
    // });

    // initMobileNumberState();

  }

 void getDeviceinfo() async {
    androidDeviceInfo = await deviceInfo
        .androidInfo; // instantiate Android Device Infoformation
    setState(() {
      Strings.board = androidDeviceInfo.board;
      Strings.brand = androidDeviceInfo.brand;
      Strings.device = androidDeviceInfo.device;
      Strings.hardware = androidDeviceInfo.hardware;
      Strings.host = androidDeviceInfo.host;
      Strings.id = androidDeviceInfo.id;
      Strings.manufacture = androidDeviceInfo.manufacturer;
      Strings.model = androidDeviceInfo.model;
      Strings.product = androidDeviceInfo.product;
      Strings.type = androidDeviceInfo.type;
      isphysicaldevice = androidDeviceInfo.isPhysicalDevice;
      Strings.androidid = androidDeviceInfo.androidId;
      Strings.version = androidDeviceInfo.version.release;
      Strings.bootloader = androidDeviceInfo.bootloader;
      Strings.display = androidDeviceInfo.device;
      Strings.fingerprint = androidDeviceInfo.fingerprint;
      Strings.tags = androidDeviceInfo.tags;
    });
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    Strings.appName = packageInfo.appName;
    Strings.packageName = packageInfo.packageName;
    Strings.buildversion = packageInfo.version;
    Strings.buildNumber = packageInfo.buildNumber;

//isphysicaldevice == false - original device; true - simulator
//_isMockLocation - showing in reverse order i.e., --if mock enabled - false; disabled - true
    if (isphysicaldevice == true) {
      // exit(0);
      showAlertDialog(context, "Open application in physical device");
    }
    if (serviceStatus == ServiceStatus.disabled) {
      // exit(0);
      showAlertDialog(context, "Enable location");
    }
    
    if (_latitude == "" || _longitude == "") {
      var position = await TrustLocation.getLatLong;
      _latitude = position[0]!;
      _longitude = position[1]!;
    }
    _SaveData();
    // Navigator.push(context, MaterialPageRoute(builder: (_) => Mobile()));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Blackstone Shipping'),
        ),
        // backgroundColor: Colors.blueGrey[900],
        //  backgroundColor: Colors.transparent,
        body: Container(
          //  decoration: BoxDecoration(
          //         image: DecorationImage(
          //           image: AssetImage("asset/images/bliss_bg13.png"),
          //         fit: BoxFit.fill),
          //         ),
          child: SingleChildScrollView(
            // padding: new EdgeInsets.only(left: 0.0, bottom: 8.0, right: 0.0,top: 0.0),

            // decoration: new BoxDecoration(color: Colors.blue),
            child: Container(
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Text(
                  //   '0.00',
                  //   style: TextStyle(color: Colors.white, fontSize: 50.0, fontWeight: FontWeight.bold),
                  // ),
                  // Text(
                  //   'Current Balance',
                  //   style: TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.bold),
                  // ),
                   Card(
                    // elevation: 8,
                    color: Colors.white70,
                    child:  Column(
                      children: <Widget>[
                        // TextFieldContainer(key: key, child: child),
                      const SizedBox(height: 10.0),
                        TextField(
                          decoration: const InputDecoration(
                              hintText: 'Truck Number',
                              labelText: 'Truck Number',
                              contentPadding: EdgeInsets.all(10),
                              // hintStyle: TextStyle(color: Colors.white54),
                              // labelStyle:  TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.black87),
                              labelStyle: TextStyle(color: Colors.black),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blueGrey),
                              )),
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.black, fontSize: 18.0),
                          controller: TruckNumberController,
                          textCapitalization: TextCapitalization.characters,
                        ),
                       const SizedBox(height: 10.0),
                        TextField(
                          decoration: const InputDecoration(
                              hintText: 'Container Number',
                              labelText: 'Container Number',
                              contentPadding: EdgeInsets.all(10),
                              // hintStyle: TextStyle(color: Colors.white54),
                              // labelStyle:  TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.black87),
                              labelStyle: TextStyle(color: Colors.black),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.blueGrey),
                              )),
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.black, fontSize: 18.0),
                          controller: ContainerNumberController,
                          textCapitalization: TextCapitalization.characters,
                        ),

                        // SizedBox(height: 15.0),
                        // FlatButton(
                        //     onPressed: () async {
                        //       _openGallery();
                        //     },
                        //     splashColor: Colors.blueAccent,
                        //     color: Colors.blue,
                        //     textColor: Colors.white,
                        //     child: Center(
                        //       child: Text("Open Camera"),
                        //     )),
                        // Center(

                        //       child:
                        //       Container(
                        //         child:  Image.asset('asset/images/bliss_bg.jpg'),
                        //         // height: MediaQuery.of(context).size.height * .8,
                        //       height: MediaQuery.of(context).size.height / 4,
                        //       // decoration: BoxDecoration(border: Border.all(width: 2)),
                        //       padding: EdgeInsets.all(2),
                        //       )

                        //             ),

                        if (imageArray != null && imageArray.length > 0)
                          if (imageArray[0] != null)
                            Container(
                                // height: MediaQuery.of(context).size.height * .8,
                                height: MediaQuery.of(context).size.height / 4,
                                // decoration: BoxDecoration(border: Border.all(width: 2)),
                                padding: const EdgeInsets.all(2),
                                child: imageArray.isEmpty
                                    ? const Center(child: Text("No Image"))
                                    : GridView.count(
                                        crossAxisCount: 2,
                                        children: List.generate(
                                            imageArray.length, (index) {
                                          // var img = imageArray[index];
                                          // // return Container(child: Image.file(img));
                                          // var imgpath = "";
                                          // if (img != null) {
                                          //   imgpath = imageArray[index].path;
                                          //   Container(
                                          //     child: Image.file(File(imgpath)),
                                          //     padding: EdgeInsets.all(2),
                                          //   );
                                          // }
                                          return Container(
                                            padding: const EdgeInsets.all(2),
                                            child: Image.file(
                                                File(imageArray[index].path)),
                                          );
                                        }),
                                      )),

                        // if (imageArray.length > 0)
                        //   ElevatedButton(
                        //       onPressed: () {
                        //         loadSelectedFiles(imageArray, context);
                        //       },
                        //       child: Text('View Selected Files')),

                       const SizedBox(height: 12.0),
                        Center(
                          child: Container(
                            child:  Row(
                              mainAxisSize: MainAxisSize.min,
                              // buttonMinWidth: 100,
                              children: <Widget>[
                                Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      
                                      style: ElevatedButton.styleFrom(
                                          // shape: CircleBorder(),
                                          // padding: EdgeInsets.all(15),
                                          primary: Colors.grey),
                                          child: const Text(
                                        "1",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            // color: Colors.black,
                                            fontSize: 19.0),
                                      ),
                                    )),
                                Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isPickupDisabled && _isPickupCameraDisabled
                                          ? () {
                                              _openGallery();
                                            }
                                          : null,
                                     
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(15),
                                      ),
                                       child: const Icon(Icons.camera_alt, size: 30),
                                    )),
                                Expanded(
                                    flex: 7,
                                    child: TextButton(
                                        onPressed: _isPickupDisabled
                                            ? () {
                                                // _SaveEvent("V", "3575");
                                                // uploadFile(context, "transporter");
                                                setState(() =>
                                                    _isPickupDisabled = false);
                                                _Save(context, "V2", "3575");
                                              }
                                            : null,
                                        child: Container(
                                          height: 80.0,
                                          // width: 230.0,
                                                                              foregroundDecoration: BoxDecoration(
                                            color: _isPickupDisabled ? Colors.blue : Colors.grey,
                                            backgroundBlendMode: BlendMode.saturation,
                                          ),
                                          decoration: BoxDecoration(
                                            //                        image: DecorationImage(
                                            //   image: AssetImage("asset/images/Icon/1.jpg"),
                                            // fit: BoxFit.fill),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: <Color>[
                                                _Pickupcolor,
                                                const Color(0XFF70BDFF)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: const Center(
                                            child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Pickup',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 24.0),
                                                )),
                                          ),
                                        ))),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(height: 9.0),
                        Center(
                          child: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              // buttonMinWidth: 100,
                              children: <Widget>[
                                //  decoration: BoxDecoration(
                                //         image: DecorationImage(
                                //           image: AssetImage("asset/images/bliss_bg13.png"),
                                //         fit: BoxFit.fill),
                                //         ),
                                // new Image.asset('asset/images/Icon/load.png'),
                                Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: Text(
                                        "2",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            // color: Colors.black,
                                            fontSize: 19.0),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          // shape: CircleBorder(),
                                          // padding: EdgeInsets.all(15),
                                          primary: Colors.grey),
                                    )),
                                Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isLoadFactoryDisabled && _isLoadFactoryCameraDisabled
                                          ? () {
                                              _openGallery();
                                            }
                                          : null,
                                      child: Icon(Icons.camera_alt, size: 30),
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(15),
                                      ),
                                    )),
                                Expanded(
                                  flex: 7,
                                  child: TextButton(
                                      onPressed: _isLoadFactoryDisabled
                                          ? () {
                                              setState(() =>
                                                  _isLoadFactoryDisabled =
                                                      false);
                                              // _SaveEvent("V", "3576");
                                              _Save(context, "V2", "3576");
                                            }
                                          : null,
                                      child: Container(
                                        height: 80.0,
                                        // width: 230.0,
                                                                             foregroundDecoration: BoxDecoration(
                                          color: _isLoadFactoryDisabled ? Colors.blue : Colors.grey,
                                          backgroundBlendMode: BlendMode.saturation,
                                        ),
                                        decoration: BoxDecoration(
                                          //                       image: DecorationImage(
                                          //   image: AssetImage("asset/images/Icon/2.jpg"),
                                          // fit: BoxFit.fill),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: <Color>[
                                              _LoadFactorycolor,
                                              Color(0XFF70BDFF)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: const Center(
                                            // child: Image.asset('asset/images/Icon/load.png'),
                                            child: Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Load Factory/CFS',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 24.0),
                                          ),
                                        )
                                            // child: Text(
                                            //   'Load Factory/CFS',textAlign: TextAlign.end,
                                            //   style: TextStyle(
                                            //       fontWeight: FontWeight.bold,
                                            //       color: Colors.black,
                                            //       fontSize: 24.0),

                                            // ),
                                            ),
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(height: 9.0),
                        Center(
                          child: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              // buttonMinWidth: 100,
                              children: <Widget>[
                                Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: Text(
                                        "3",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            // color: Colors.black,
                                            fontSize: 19.0),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          // shape: CircleBorder(),
                                          // padding: EdgeInsets.all(15),
                                          primary: Colors.grey),
                                    )),
                                Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isUnloadFactoryDisabled && _isUnloadFactoryCameraDisabled
                                          ? () {
                                              _openGallery();
                                            }
                                          : null,
                                      child: Icon(Icons.camera_alt, size: 30),
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(15),
                                      ),
                                    )),
                                Expanded(
                                  flex: 7,
                                  child: TextButton(
                                      onPressed: _isUnloadFactoryDisabled
                                          ? () {
                                              setState(() =>
                                                  _isUnloadFactoryDisabled =
                                                      false);
                                              // _SaveEvent("V", "3577");
                                              _Save(context, "V2", "3577");
                                            }
                                          : null,
                                      child: Container(
                                        height: 80.0,
                                        // width: 230.0,
                                                                             foregroundDecoration: BoxDecoration(
                                          color: _isUnloadFactoryDisabled ? Colors.blue : Colors.grey,
                                          backgroundBlendMode: BlendMode.saturation,
                                        ),
                                        decoration: BoxDecoration(
                                          //                        image: DecorationImage(
                                          //   image: AssetImage("asset/images/Icon/3.jpg"),
                                          // fit: BoxFit.fill),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: <Color>[
                                              _UnloadFactorycolor,
                                              Color(0XFF70BDFF)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Center(
                                          child: Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Unload Factory/CFS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    fontSize: 24.0),
                                              )),
                                        ),
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(height: 9.0),
                        Center(
                          child: Container(
                            child:  Row(
                              mainAxisSize: MainAxisSize.min,
                              // buttonMinWidth: 100,
                              children: <Widget>[
                                Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: Text(
                                        "4",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            // color: Colors.black,
                                            fontSize: 19.0),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          // shape: CircleBorder(),
                                          // padding: EdgeInsets.all(15),
                                          primary: Colors.grey),
                                    )),
                                Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isDropDisabled && _isDropCameraDisabled
                                          ? () {
                                              _openGallery();
                                            }
                                          : null,
                                      child: Icon(Icons.camera_alt, size: 30),
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(15),
                                      ),
                                    )),
                                Expanded(
                                    flex: 7,
                                    child: TextButton(
                                        onPressed: _isDropDisabled
                                            ? () {
                                                setState(() =>
                                                    _isDropDisabled = false);
                                                // _SaveEvent("V", "3578");
                                                _Save(context, "V2", "3578");
                                              }
                                            : null,
                                        child: Container(
                                          height: 80.0,
                                          // width: 230.0,
                                                                               foregroundDecoration: BoxDecoration(
                                            color: _isDropDisabled ? Colors.blue : Colors.grey,
                                            backgroundBlendMode: BlendMode.saturation,
                                          ),
                                          decoration: BoxDecoration(
                                            //                       image: DecorationImage(
                                            //   image: AssetImage("asset/images/Icon/4.jpg"),
                                            // fit: BoxFit.fill),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: <Color>[
                                                _Dropcolor,
                                                Color(0XFF70BDFF)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Center(
                                            child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Drop',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                      fontSize: 24.0),
                                                )),
                                          ),
                                        ))),
                              ],
                            ),
                          ),
                        ),

//                         SizedBox(height: 15.0),
//                         Center(
//                           child: new ButtonBar(
//                             mainAxisSize: MainAxisSize.min,
//                             children: <Widget>[
//                               new TextButton(
//                                   onPressed: () {
//                                     _SaveTruck();
//                                   },
//                                   child: Container(
//                                     height: 40.0,
//                                     width: 100.0,
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         begin: Alignment.topCenter,
//                                         end: Alignment.bottomCenter,
//                                         colors: <Color>[
//                                           Color(0XFF0088FF),
//                                           Color(0XFF70BDFF)
//                                         ],
//                                       ),
//                                       // borderRadius: BorderRadius.circular(50.0),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         'Export',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.white,
//                                             fontSize: 18.0),
//                                       ),
//                                     ),
//                                   )),
//                               new TextButton(
//                                   onPressed: () {
//                                     // _SaveData(context);
//                                   },
//                                   child: Container(
//                                     height: 40.0,
//                                     width: 100.0,
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         begin: Alignment.topCenter,
//                                         end: Alignment.bottomCenter,
//                                         colors: <Color>[
//                                           Color.fromARGB(197, 18, 230, 64),
//                                           Color.fromARGB(255, 162, 231, 179)
//                                         ],
//                                       ),
//                                       // borderRadius: BorderRadius.circular(50.0),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         'Import',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.white,
//                                             fontSize: 18.0),
//                                       ),
//                                     ),
//                                   )),
//                             ],
//                           ),
//                         ),
// //  SizedBox(height: 15.0),
//                         Visibility(
//                             maintainSize: true,
//                             maintainAnimation: true,
//                             maintainState: true,
//                             visible: viewExVisible,
//                             child: Container(
//                               child: TextButton(
//                                   onPressed: _isExEmptyYardDisabled
//                                       ? () {
//                                           _SaveEvent("EX", "3565");
//                                         }
//                                       : null,
//                                   child: Container(
//                                     height: 40.0,
//                                     // width: 100.0,
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         begin: Alignment.topCenter,
//                                         end: Alignment.bottomCenter,
//                                         colors: <Color>[
//                                           _ExEmptyYardcolor,
//                                           Color(0XFF70BDFF)
//                                         ],
//                                       ),
//                                       // borderRadius: BorderRadius.circular(50.0),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         'Empty Yard Pickup',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.white,
//                                             fontSize: 18.0),
//                                       ),
//                                     ),
//                                   )),
//                             )),
//                         SizedBox(height: 15.0),
//                         Visibility(
//                           maintainSize: true,
//                           maintainAnimation: true,
//                           maintainState: true,
//                           visible: viewExVisible,
//                           child: TextButton(
//                               onPressed: _isExFactoryInDisabled
//                                   ? () {
//                                       _SaveEvent("EX", "3566");
//                                     }
//                                   : null,
//                               child: Container(
//                                 height: 40.0,
//                                 // width: 100.0,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: <Color>[
//                                       _ExFactoryIncolor,
//                                       Color(0XFF70BDFF)
//                                     ],
//                                   ),
//                                   // borderRadius: BorderRadius.circular(50.0),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Factory/CFS IN',
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                         fontSize: 18.0),
//                                   ),
//                                 ),
//                               )),
//                         ),

//                         SizedBox(height: 15.0),
//                         Visibility(
//                           maintainSize: true,
//                           maintainAnimation: true,
//                           maintainState: true,
//                           visible: viewExVisible,
//                           child: TextButton(
//                               onPressed: _isExFactoryOutDisabled
//                                   ? () {
//                                       _SaveEvent("EX", "3567");
//                                     }
//                                   : null,
//                               child: Container(
//                                 height: 40.0,
//                                 // width: 100.0,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: <Color>[
//                                       _ExFactoryOutcolor,
//                                       Color(0XFF70BDFF)
//                                     ],
//                                   ),
//                                   // borderRadius: BorderRadius.circular(50.0),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Factory/CFS OUT',
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                         fontSize: 18.0),
//                                   ),
//                                 ),
//                               )),
//                         ),

//                         SizedBox(height: 15.0),
//                         Visibility(
//                           maintainSize: true,
//                           maintainAnimation: true,
//                           maintainState: true,
//                           visible: viewExVisible,
//                           child: TextButton(
//                               onPressed: _isExPortInDisabled
//                                   ? () {
//                                       _SaveEvent("EX", "3568");
//                                     }
//                                   : null,
//                               child: Container(
//                                 height: 40.0,
//                                 // width: 100.0,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: <Color>[
//                                       _ExPortIncolor,
//                                       Color(0XFF70BDFF)
//                                     ],
//                                   ),
//                                   // borderRadius: BorderRadius.circular(50.0),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Port IN',
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                         fontSize: 18.0),
//                                   ),
//                                 ),
//                               )),
//                         ),

//                         SizedBox(height: 15.0),
//                         Visibility(
//                           maintainSize: true,
//                           maintainAnimation: true,
//                           maintainState: true,
//                           visible: viewExVisible,
//                           child: TextButton(
//                               onPressed: _isExContainerDropDisabled
//                                   ? () {
//                                       _SaveEvent("EX", "3569");
//                                     }
//                                   : null,
//                               child: Container(
//                                 height: 40.0,
//                                 // width: 100.0,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: <Color>[
//                                       _ExContainerDropcolor,
//                                       Color(0XFF70BDFF)
//                                     ],
//                                   ),
//                                   // borderRadius: BorderRadius.circular(50.0),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     'Container Drop at Port',
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white,
//                                         fontSize: 18.0),
//                                   ),
//                                 ),
//                               )),
//                         ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
  


  _openGallery() async {
    try {
      image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) imageArray.add(image);
      setState(() {
        imageArray;
        fileslist = imageArray;
      });
    } catch (e) {
      print(e);
    }
  }

  // multiple file selected
  // navigate user to 2nd screen to show selected files
  void loadSelectedFiles(List<XFile> files, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FileList(files: files, onOpenedFile: viewFile)));
  }

  // open the picked file
  void viewFile(XFile file) {
    OpenFile.open(file.path);
  }

  uploadFile(BuildContext context, String FolderName, String OType,
      String MovementID) async {
    var file_len = fileslist.length;

    var uri = Uri.parse(
        Strings.webApiUrl + "/FileStorage/uploadFile?FolderName=" + FolderName);
    var request = http.MultipartRequest('POST', uri);
    for (var i = 0; i <= file_len - 1; i++) {
      var filename = fileslist[i].name;
      var filepath = fileslist[i].path;

      request.files.add(
        http.MultipartFile('image', File(filepath).readAsBytes().asStream(),
            File(filepath).lengthSync(),
            filename: filename.split("/").last),
      );
    }
    var response = await request.send();
    final respStr = await response.stream.bytesToString();
// String thivya='{"status":"200","result":{"Table1":[{"FileName":"VID_20220331_124618.mp4","StoredFileName":"838911364-46685604VID_20220331_124618.mp4","isActive":1}]},"response":null,"Additional1":null,"fileBytes":null,"downloadFiles":null}';
    // String respStr =
    //     '{"status":"200","result":{"Table1":[{"FileName":"bb7e0f59-1431-4d8c-ac80-3cbf4a8db5b17807856052158901869.jpg","StoredFileName":"209235414-195325311bb7e0f59-1431-4d8c-ac80-3cbf4a8db5b17807856052158901869.jpg","isActive":1},{"FileName":"7eee15d5-8970-49bd-8ab0-a31bb6ca272a8002186815562049513.jpg","StoredFileName":"907991788-497974457eee15d5-8970-49bd-8ab0-a31bb6ca272a8002186815562049513.jpg","isActive":1}]},"response":null,"Additional1":null,"fileBytes":null,"downloadFiles":null}';
    if (response.statusCode == 200) {
      Map<dynamic, dynamic> responseJson = json.decode(respStr);
      var jsonMap1 = jsonDecode(respStr)["result"]["Table1"];
      for (int i = 0; i <= jsonMap1.length - 1; i++) {
        var jsonMap = jsonMap1[i];
        _SaveImage(jsonMap["StoredFileName"], i, jsonMap1.length - 1, OType,
            MovementID);
      }
    }
  }

  _SaveImage(String StorageName, int currentIndex, int totalLength,
      String OType, String MovementID) async {
    try {
      var builder = new xml.XmlBuilder();
      // builder.processing('xml', 'version="1.0" encoding="iso-8859-9"');
      builder.element('XML', nest: () {
        builder.element('TruckID', nest: Strings.TransId);
        builder.element('ImageFileName', nest: StorageName);
        builder.element('isActive', nest: 1);
      });
      var bookshelfXml = builder.buildDocument();
      String _uriMsj = bookshelfXml.toString();
      // Strings.TransId="22";
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ExportTruck()));
      var url1 = Uri.parse(Strings.webApiUrl +
          "/Container_Transport/Update_Container_Transport_ImageList_XML?XML=" +
          _uriMsj);
      var response = await http.post(url1);
      if (response.statusCode == 200) {
        var jsonString = response.body;
        Map<dynamic, dynamic> responseJson = json.decode(response.body);
        var jsonMap1 = jsonDecode(jsonString)["result"]["Table"];
        var jsonMap = jsonMap1[0];
        if (ImageListID == "") {
          ImageListID = jsonMap["ID"].toString();
        } else {
          ImageListID = ImageListID + "," + jsonMap["ID"].toString();
        }
        if (currentIndex == totalLength) {
          _SaveEvent(OType, MovementID);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  _SaveData() async {
    try {
      // Fluttertoast.showToast(
      //         msg: "Entered _SaveData",
      //         toastLength: Toast.LENGTH_SHORT,
      //         gravity: ToastGravity.BOTTOM,
      //         timeInSecForIos: 1,
      //         backgroundColor: Colors.red,
      //         textColor: Colors.yellow);
      var builder = new xml.XmlBuilder();
      // builder.processing('xml', 'version="1.0" encoding="iso-8859-9"');
      builder.element('XML', nest: () {
        builder.element('MAC', nest: Strings.androidid);
        builder.element('ComputerName', nest: Strings.host);
        builder.element('Manufacturer', nest: Strings.manufacture);
        builder.element('Model', nest: Strings.model);
        builder.element('SerialNumber', nest: Strings.id);
        builder.element('MobileNo', nest: Strings.mobileNumber);
      });
      var bookshelfXml = builder.buildDocument();
      String _uriMsj = bookshelfXml.toString();
        // Fluttertoast.showToast(
        //       msg: _uriMsj,
        //       toastLength: Toast.LENGTH_SHORT,
        //       gravity: ToastGravity.BOTTOM,
        //       timeInSecForIos: 1,
        //       backgroundColor: Colors.red,
        //       textColor: Colors.yellow);
      // Strings.TransId="22";
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ExportTruck()));
      var url1 = Uri.parse(Strings.webApiUrl +
          "/Container_Transport/Update_Container_Transport_XML?XML=" +
          _uriMsj);
      var response = await http.post(url1);
      if (response.statusCode == 200) {
        var jsonString = response.body;
        Map<dynamic, dynamic> responseJson = json.decode(response.body);
        var jsonMap1 = jsonDecode(jsonString)["result"]["Table"];
        var jsonMap = jsonMap1[0];
        Strings.TransId = jsonMap["TransID"].toString();
        Strings.TruckNo = jsonMap["TruckNo"].toString();
        Strings.ContainerNo = jsonMap["ContainerNo"].toString();
        TruckNumberController.text = Strings.TruckNo;
        ContainerNumberController.text = Strings.ContainerNo;
        // var jsonMap2 = jsonDecode(jsonString)["result"]["Table1"];
        // var jsonMapT1 = jsonMap2[0];
        // OTypeChk = jsonMap["OTypeChk"].toString();

        var jsonMap2 = jsonDecode(jsonString)["result"]["Table1"];
        var jsonMapT1 = jsonMap2[0];

        // if (jsonMapT1["OTypeChk"].toString() == "EX" ||
        //     jsonMapT1["OTypeChk"].toString() == "") {
        //   showWidget();
        // }

        if (jsonMapT1["isEnable"].toString() == "0") {
          _isPickupDisabled = false;
          _Pickupcolor = _disabledColor;
        }
        var jsonMapT2 = jsonMap2[1];
        if (jsonMapT2["isEnable"].toString() == "0") {
          _isLoadFactoryDisabled = false;
          _LoadFactorycolor = _disabledColor;
        }
        var jsonMapT3 = jsonMap2[2];
        if (jsonMapT3["isEnable"].toString() == "0") {
          _isUnloadFactoryDisabled = false;
          _UnloadFactorycolor = _disabledColor;
        }
        var jsonMapT4 = jsonMap2[3];
        if (jsonMapT4["isEnable"].toString() == "0") {
          _isDropDisabled = false;
          _Dropcolor = _disabledColor;
        }

        // var status = jsonDecode(jsonString)["status"];
        // if (status == "200") {
        //   // Navigator.push(
        //   //     context, MaterialPageRoute(builder: (_) => ExportTruck()));
        // } else {
        //   Fluttertoast.showToast(
        //       msg: jsonMap['Message'],
        //       toastLength: Toast.LENGTH_SHORT,
        //       gravity: ToastGravity.BOTTOM,
        //       timeInSecForIos: 1,
        //       backgroundColor: Colors.red,
        //       textColor: Colors.yellow);
        // }
      }
    } catch (e) {
      print(e);
    }
  }

  _SaveTruck() async {
    try {
      var builder = new xml.XmlBuilder();
      // builder.processing('xml', 'version="1.0" encoding="iso-8859-9"');
      builder.element('XML', nest: () {
        builder.element('MAC', nest: Strings.androidid);
        builder.element('ComputerName', nest: Strings.host);
        builder.element('Manufacturer', nest: Strings.manufacture);
        builder.element('Model', nest: Strings.model);
        builder.element('SerialNumber', nest: Strings.id);
        builder.element('TruckNo', nest: TruckNumberController.text);
        builder.element('TruckNoEntry', nest: TruckNumberController.text);
        builder.element('TransID', nest: Strings.TransId);
      });
      var bookshelfXml = builder.buildDocument();
      String _uriMsj = bookshelfXml.toString();
      var url1 = Uri.parse(Strings.webApiUrl +
          "/Container_Transport/Update_Container_Transport_XML?XML=" +
          _uriMsj);
      var response = await http.post(url1);
      if (response.statusCode == 200) {
        var jsonString = response.body;
        Map<dynamic, dynamic> responseJson = json.decode(response.body);
        var jsonMap1 = jsonDecode(jsonString)["result"]["Table"];
        var jsonMap = jsonMap1[0];
        Strings.TransId = jsonMap["TransID"].toString();

        // showWidget();

        var jsonMap2 = jsonDecode(jsonString)["result"]["Table1"];
        var jsonMapT1 = jsonMap2[0];
        OTypeChk = jsonMap["OTypeChk"].toString();

//         // var jsonMap = (jsonMap1)["[0]"];
//         var jsonMap = jsonMap1[0];
//         var status = jsonDecode(jsonString)["Status"];
//         if (status == "200") {
// // Navigator.push(context, MaterialPageRoute(builder: (_) => SaleLead()));
//         } else {
//           Fluttertoast.showToast(
//               msg: jsonMap['Message'],
//               toastLength: Toast.LENGTH_SHORT,
//               gravity: ToastGravity.BOTTOM,
//               timeInSecForIos: 1,
//               backgroundColor: Colors.red,
//               textColor: Colors.yellow);
//         }
      }
    } catch (ex) {
      Fluttertoast.showToast(
          msg: ex.toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.yellow);
    }
  }

  _Save(BuildContext context, String OType, String MovementID) async {
    var msg = _Validate(MovementID);
    if (msg != "") {
      Fluttertoast.showToast(
          msg: msg,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } else {
      _SaveTruck();
      if (fileslist != null && fileslist.length > 0)
        uploadFile(context, "Transporter", OType, MovementID);
      else
        _SaveEvent(OType, MovementID);
    }
  }

  String _Validate(String MovementID) {
    String msg = "";
    if (TruckNumberController.text == "") {
      msg = "Enter truck number";
    } else if (ContainerNumberController.text == "") {
      msg = "Enter container number";
    } else if (!RegExp(r'([A-Z]{3})([U])(\d{6})(\d)')
        .hasMatch(ContainerNumberController.text)) {
      msg = "Enter valid container number";
    }
     if (MovementID == "3575")
        _isPickupDisabled = true;
      else if (MovementID == "3576")
        _isLoadFactoryDisabled = true;
      else if (MovementID == "3577")
        _isUnloadFactoryDisabled = true;
      else if (MovementID == "3578") _isDropDisabled = true;
    return msg;
  }

  _SaveEvent(String OType, String MovementID) async {
    try {
      var builder = new xml.XmlBuilder();
      // builder.processing('xml', 'version="1.0" encoding="iso-8859-9"');
      builder.element('XML', nest: () {
        builder.element('OType', nest: OType);
        builder.element('TruckID', nest: Strings.TransId);
        builder.element('MAC', nest: Strings.androidid);
        builder.element('Lat', nest: Strings.latitude);
        builder.element('Lon', nest: Strings.longitude);
        builder.element('MovementID', nest: MovementID);
        builder.element('ContainerNo', nest: ContainerNumberController.text);
        builder.element('ImageIDList', nest: ImageListID);
      });
      var bookshelfXml = builder.buildDocument();
      String _uriMsj = bookshelfXml.toString();
      var url1 = Uri.parse(Strings.webApiUrl +
          "/Container_Transport/Update_Container_Transport_Event_XML?XML=" +
          _uriMsj);
      var response = await http.post(url1);
      if (response.statusCode == 200) {
        var jsonString = response.body;
        Map<dynamic, dynamic> responseJson = json.decode(response.body);
        var jsonMap1 = jsonDecode(jsonString)["result"]["Table"];
        var jsonMap3 = jsonDecode(jsonString)["result"]["Table2"];
        // Strings.TruckNo = jsonMap3["TruckNo"].toString();
        Strings.ContainerNo = jsonMap3[0]["ContainerNo"].toString();
        TruckNumberController.text = Strings.TruckNo;
        ContainerNumberController.text = Strings.ContainerNo;
        // _isExEmptyYardDisabled = false;

        var jsonMap2 = jsonDecode(jsonString)["result"]["Table1"];
        var jsonMapT1 = jsonMap2[0];
        if (jsonMapT1["isEnable"].toString() == "0") {
          _isPickupDisabled = false;
          _Pickupcolor = _disabledColor;
          _isPickupCameraDisabled=false;
        } else {
          _isPickupDisabled = true;
          _Pickupcolor = _enabledColor;
          _isPickupCameraDisabled=true;
        }
        var jsonMapT2 = jsonMap2[1];
        if (jsonMapT2["isEnable"].toString() == "0") {
          _isLoadFactoryDisabled = false;
          _LoadFactorycolor = _disabledColor;
          _isLoadFactoryCameraDisabled=false;
        } else {
          _isLoadFactoryDisabled = true;
          _LoadFactorycolor = _enabledColor;
          _isLoadFactoryCameraDisabled=true;
        }
        var jsonMapT3 = jsonMap2[2];
        if (jsonMapT3["isEnable"].toString() == "0") {
          _isUnloadFactoryDisabled = false;
          _UnloadFactorycolor = _disabledColor;
          _isUnloadFactoryCameraDisabled=false;
        } else {
          _isUnloadFactoryDisabled = true;
          _UnloadFactorycolor = _enabledColor;
          _isUnloadFactoryCameraDisabled=true;
        }
        var jsonMapT4 = jsonMap2[3];
        if (jsonMapT4["isEnable"].toString() == "0") {
          _isDropDisabled = false;
          _Dropcolor = _disabledColor;
          _isDropCameraDisabled=false;
        } else {
          _isDropDisabled = true;
          _Dropcolor = _enabledColor;
          _isDropCameraDisabled=true;
        }
        // OTypeChk = jsonMap["OTypeChk"].toString();
        imageArray = [];
        ImageListID = "";
        Fluttertoast.showToast(
            msg: "Saved !",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white);
      }
    } catch (ex) {
      if (MovementID == "3575")
        _isPickupDisabled = true;
      else if (MovementID == "3576")
        _isLoadFactoryDisabled = true;
      else if (MovementID == "3577")
        _isUnloadFactoryDisabled = true;
      else if (MovementID == "3578") _isDropDisabled = true;
      Fluttertoast.showToast(
          msg: ex.toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.yellow);
    }
  }


}

showAlertDialog(BuildContext context, String message) {
  // Create button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
      exit(0);
    },
  );

  // Create AlertDialog
  AlertDialog alert = AlertDialog(
    // title: Text("Error!"),
    content: Text(message),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

