import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:deliveryboy_multivendor/Helper/sim_btn.dart';
import 'package:deliveryboy_multivendor/Screens/wallet_history.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

import '../Helper/Session.dart';
import '../Helper/app_btn.dart';
import '../Helper/color.dart';
import '../Helper/color.dart';
import '../Helper/constant.dart';
import '../Helper/string.dart';
import '../Model/transaction_model.dart';

class PayAdmin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateAdmin();
  }
}
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;


class StateAdmin extends State<PayAdmin> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  List<TransactionModel> tempList = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  TextEditingController amount = TextEditingController();

  File? imagePath;
  String? filePath;
  TextEditingController? amtC, bankDetailC;
  // @override
  // void initState() {
  //   super.initState();
  //   getTransaction();
  //   controller.addListener(_scrollListener);
  //   buttonController = AnimationController(
  //       duration: Duration(milliseconds: 2000), vsync: this);
  //
  //   buttonSqueezeanimation = Tween(
  //     begin: deviceWidth! * 0.7,
  //     end: 50.0,
  //   ).animate(CurvedAnimation(
  //     parent: buttonController!,
  //     curve: Interval(
  //       0.0,
  //       0.150,
  //     ),
  //   ));
  //   amtC = TextEditingController();
  //   bankDetailC = TextEditingController();
  // }

  //Open gallery
  // pickImageFromGallery(ImageSource source) {
  //   setState(() {
  //     imageFile = ImagePicker.pickImage(source: source) ;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightWhite,
        key: _scaffoldKey,
        appBar: getAppBar(PAY_ADMIN, context),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Card(
                  child: Container(
                    decoration: BoxDecoration(),
                    width: 220,
                    child: InkWell(
                      onTap: () {
                        // if (mounted) {
                        getFromGallery();
                         // _imgFromGallery();
                          // onBtnSelected!();
                       // }
                      },
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsetsDirectional.only(end: 20),
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                               // shape: BoxShape.circle,
                                border: Border.all(
                                    width: 1.0, color: Colors.white)),
                            //  Theme.of(context).colorScheme.primary)),
                            child:
                            ClipRRect(
                              // borderRadius: BorderRadius.circular(100.0),
                                child:
                                // Consumer<UserProvider>(builder: (context, userProvider, _) {
                                // return
                                //    userProvider.profilePic != ''
                                //      ?
                                imagePath != null ?
                               // Image.asset("${imagePath}")
                                Image.file(imagePath!)
                                // FadeInImage(
                                //   fadeInDuration: Duration(milliseconds: 150),
                                //   image: NetworkImage(filePath!),
                                // // NetworkImage(filePath!),
                                //  // CachedNetworkImageProvider(userProvider.profilePic.toString()),
                                //   height: 64.0,
                                //   width: 64.0,
                                //   fit: BoxFit.cover,
                                //   imageErrorBuilder: (context, error, stackTrace) =>
                                //       errorWidget(64),
                                //   placeholder: placeHolder(64),
                                // )
                               : imagePlaceHolder(62),
                              // }),
                            ),
                          ),
                          Icon(Icons.download_rounded, color: primary,),
                          Text("Upload Image",),

                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey)
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: amount,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 20),
                        //prefix: Text(CUR_CURRENCY!),
                        border: InputBorder.none,
                        hintText: "Enter Amount"
                        //border: OutlineInputBorder()
                      ),
                    ),
                  ),
                ),
                SimBtn(
                  title: SUBMIT,
                  size: 0.5,
                  onBtnSelected: (){
                    getTransaction();
                  },
                ),
                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     primary: primary
                //   ),
                //     onPressed: (){},
                //     child: Text("Submit"))
              ],
            ),
          ),
        )
        // _isNetworkAvail
        //     ? _isLoading
        //     ? shimmer()
        //     : RefreshIndicator(
        //     key: _refreshIndicatorKey,
        //     onRefresh: _refresh,
        //     child: SingleChildScrollView(
        //       controller: controller,
        //       child: Column(
        //           children: [
        //             Text("data")
        //           ]),
        //     ))
        //     : noInternet(context)
    );
  }

  Future<void> getFromGallery() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        imagePath = File(pickedFile.path) ;
        filePath = imagePath!.path.toString();
      });
    }
  }
  // Widget showImage() {
  //   return FutureBuilder(
  //     future: getFromGallery(),
  //     builder: (BuildContext context, AsyncSnapshot snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done &&
  //           snapshot.data != null) {
  //         return Image.file(
  //           snapshot.data!,
  //           width: 300,
  //           height: 300,
  //         );
  //       } else if (snapshot.error != null) {
  //         return const Text(
  //           'Error Picking Image',
  //           textAlign: TextAlign.center,
  //         );
  //       } else {
  //         return const Text(
  //           'No Image Selected',
  //           textAlign: TextAlign.center,
  //         );
  //       }
  //     },
  //   );
  // }
  //
  // void _imgFromGallery() async {
  //   var result = await FilePicker.platform.pickFiles(
  //     type: FileType.image,
  //   );
  //   if (result != null) {
  //
  //      image = File(result.files.single.path!);
  //      imagePath = File(result.files.single.path!);
  //    //  print(image);
  //      print(result.files.single.path);
  //     // if (mounted) {
  //     //   await setProfilePic(image);
  //     // }
  //   } else {
  //     // User canceled the picker
  //   }
  // }
  // Future<void> setProfilePic(File _image) async {
  //   _isNetworkAvail = await isNetworkAvailable();
  //   if (_isNetworkAvail) {
  //     try {
  //       var image;
  //       var request = http.MultipartRequest("POST", (getUpdateUserApi));
  //       request.headers.addAll(headers);
  //       request.fields[USER_ID] = CUR_USERID!;
  //       var pic = await http.MultipartFile.fromPath(IMAGE, _image.path);
  //       request.files.add(pic);
  //       var response = await request.send();
  //       var responseData = await response.stream.toBytes();
  //       var responseString = String.fromCharCodes(responseData);
  //       var getdata = json.decode(responseString);
  //       bool error = getdata["error"];
  //       String? msg = getdata['message'];
  //       print("msg :$msg");
  //       print(
  //           " detail : ${pic.field}, ${pic.length} , ${pic.filename} , ${pic.contentType} , ${pic.toString()}");
  //       if (!error) {
  //         var data = getdata["data"];
  //         for (var i in data) {
  //           image = i[IMAGE];
  //         }
  //         var settingProvider =
  //         Provider.of<SettingProvider>(context, listen: false);
  //         settingProvider.setPrefrence(IMAGE, image!);
  //         var userProvider = Provider.of<UserProvider>(context, listen: false);
  //         userProvider.setProfilePic(image!);
  //         Navigator.pop(context);
  //         setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!);
  //       } else {
  //         setSnackbar(msg!);
  //       }
  //     } on TimeoutException catch (_) {
  //       setSnackbar(getTranslated(context, 'somethingMSg')!);
  //     }
  //   } else {
  //     if (mounted) {
  //       setState(() {
  //         _isNetworkAvail = false;
  //       });
  //     }
  //   }
  // }
  //
  // Future<Null> sendRequest() async {
  //   _isNetworkAvail = await isNetworkAvailable();
  //   if (_isNetworkAvail) {
  //     try {
  //       var parameter = {
  //         USER_ID: CUR_USERID,
  //         AMOUNT: amtC!.text.toString(),
  //         PAYMENT_ADD: bankDetailC!.text.toString()
  //       };
  //
  //       Response response =
  //       await post(sendWithReqApi, body: parameter, headers: headers)
  //           .timeout(Duration(seconds: timeOut));
  //
  //       var getdata = json.decode(response.body);
  //       bool error = getdata["error"];
  //       String msg = getdata["message"];
  //
  //       if (!error) {
  //         CUR_BALANCE = double.parse(getdata["data"]).toStringAsFixed(2);
  //       }
  //       if (mounted) setState(() {});
  //       setSnackbar(msg);
  //     } on TimeoutException catch (_) {
  //       setSnackbar(somethingMSg);
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   } else {
  //     if (mounted)
  //       setState(() {
  //         _isNetworkAvail = false;
  //         _isLoading = false;
  //       });
  //   }
  //
  //   return null;
  // }

  // Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
  //   return Stack(
  //     children: <Widget>[
  //       GestureDetector(
  //         onTap: () {
  //           if (mounted) {
  //             onBtnSelected!();
  //           }
  //         },
  //         child: Container(
  //           margin: EdgeInsetsDirectional.only(end: 20),
  //           height: 80,
  //           width: 80,
  //           decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               border: Border.all(
  //                   width: 1.0, color: Colors.white)),
  //             //  Theme.of(context).colorScheme.primary)),
  //           child: ClipRRect(
  //            // borderRadius: BorderRadius.circular(100.0),
  //             child:
  //            // Consumer<UserProvider>(builder: (context, userProvider, _) {
  //              // return
  //              //    userProvider.profilePic != ''
  //              //      ?
  //                  FadeInImage(
  //                 fadeInDuration: Duration(milliseconds: 150),
  //                 image:
  //                 CachedNetworkImageProvider(userProvider.profilePic.toString()),
  //                 height: 64.0,
  //                 width: 64.0,
  //                 fit: BoxFit.cover,
  //                 imageErrorBuilder: (context, error, stackTrace) =>
  //                     erroWidget(64),
  //                 placeholder: placeHolder(64),
  //               )
  //                  // : imagePlaceHolder(62),
  //            // }),
  //           ),
  //         ),
  //       ),
  //       /*CircleAvatar(
  //     radius: 40,
  //     backgroundColor: colors.primary,
  //     child: profileImage != ""
  //         ? ClipRRect(
  //             borderRadius: BorderRadius.circular(40),
  //             child: FadeInImage(
  //               fadeInDuration: Duration(milliseconds: 150),
  //               image: NetworkImage(profileImage),
  //               height: 100.0,
  //               width: 100.0,
  //               fit: BoxFit.cover,
  //               placeholder: placeHolder(100),
  //               imageErrorBuilder: (context, error, stackTrace) =>
  //                   erroWidget(100),
  //             ))
  //         : Icon(
  //             Icons.account_circle,
  //             size: 80,
  //             color: Theme.of(context).colorScheme.white,
  //           ),
  //   ),*/
  //       if (CUR_USERID != null)
  //         Positioned.directional(
  //             textDirection: Directionality.of(context),
  //             end: 20,
  //             bottom: 5,
  //             child: Container(
  //               height: 20,
  //               width: 20,
  //               child: InkWell(
  //                 child: Icon(
  //                   Icons.edit,
  //                   color: Colors.white,
  //                   //Theme.of(context).colorScheme.white,
  //                   size: 10,
  //                 ),
  //                 onTap: () {
  //                   if (mounted) {
  //                     onBtnSelected!();
  //                   }
  //                 },
  //               ),
  //               decoration: BoxDecoration(
  //                   color: primary,
  //                   borderRadius: const BorderRadius.all(
  //                     Radius.circular(20),
  //                   ),
  //                   border: Border.all(color: primary)),
  //             )),
  //     ],
  //   );
  // }

  getAppBar(String title, BuildContext context) {
    return AppBar(
      leading: Builder(builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_left,
                color: primary,
                size: 30,
              ),
            ),
          ),
        );
      }),
      title: Text(
        title,
        style: TextStyle(
          color: primary,
        ),
      ),
      backgroundColor: white,
      // actions: [
      //   Container(
      //       margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      //       child: InkWell(
      //         borderRadius: BorderRadius.circular(4),
      //         onTap: () {
      //           return filterDialog();
      //         },
      //         child: Padding(
      //           padding: const EdgeInsets.all(4.0),
      //           child: Icon(
      //             Icons.filter_alt_outlined,
      //             color: primary,
      //           ),
      //         ),
      //       ))
      // ],
    );
  }



  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<Null> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          AMT: amount.text,
          IMAGE: imagePath.toString(),
          USER_ID: CUR_USERID,
          "transaction_id" : "asdfghjk"
        };
        print(parameter);
        Response response =
        await post(dailyCollectionApi,  body: parameter)
            .timeout(Duration(seconds: timeOut));
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            print(response.statusCode);
            print(response.body);
            print(msg);
            setSnackbar("${msg}");
            // total = int.parse(getdata["total"]);
            // if ((offset) < total) {
            //   tempList.clear();
            //   var data = getdata["data"];
            //   tempList = (data as List)
            //       .map((data) => TransactionModel.fromJson(data))
            //       .toList();
            //
            //   tranList.addAll(tempList);
            //
            //   offset = offset + perPage;
            // }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else
      setState(() {
        _isNetworkAvail = false;
      });

    return null;
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      duration: Duration(seconds: 1),
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: black),
      ),
      backgroundColor: white,
      elevation: 1.0,
    ));

  }

  // @override
  // void dispose() {
  //   buttonController!.dispose();
  //   super.dispose();
  // }
  // Widget noInternet(BuildContext context) {
  //   return Center(
  //     child: SingleChildScrollView(
  //       child: Column(mainAxisSize: MainAxisSize.min, children: [
  //         noIntImage(),
  //         noIntText(context),
  //         noIntDec(context),
  //         AppBtn(
  //           title: TRY_AGAIN_INT_LBL,
  //           btnAnim: buttonSqueezeanimation,
  //           btnCntrl: buttonController,
  //           onBtnSelected: () async {
  //             _playAnimation();
  //
  //             Future.delayed(Duration(seconds: 2)).then((_) async {
  //               _isNetworkAvail = await isNetworkAvailable();
  //               if (_isNetworkAvail) {
  //                 getTransaction();
  //               } else {
  //                 await buttonController!.reverse();
  //                 setState(() {});
  //               }
  //             });
  //           },
  //         )
  //       ]),
  //     ),
  //   );
  // }
  // Future<Null> _refresh() {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   offset = 0;
  //   total = 0;
  //   //tranList.clear();
  //   return getTransaction();
  // }
  //
  // _scrollListener() {
  //   if (controller.offset >= controller.position.maxScrollExtent &&
  //       !controller.position.outOfRange) {
  //     if (this.mounted) {
  //       setState(() {
  //         isLoadingmore = true;
  //
  //         if (offset < total) getTransaction();
  //       });
  //     }
  //   }
  // }
}
