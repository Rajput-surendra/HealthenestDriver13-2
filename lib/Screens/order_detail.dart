import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:blinking_point/blinking_point.dart';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/order_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../Helper/color.dart';


class OrderDetail extends StatefulWidget {
  final Order_Model? model;
  final Function? updateHome;

  const OrderDetail({
    Key? key,
    this.model,
    this.updateHome,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final statusList = [
    "assign",
   PLACED,
    SHIPED,
    PROCESSED,
    DELIVERD,
    // CANCLED,
    // RETURNED,
    // WAITING
  ];
  bool? _isCancleable, _isReturnable, _isLoading = true;
  bool _isProgress = false;
  String? curStatus;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController? otpC;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.model!.itemList!.length; i++) {
      widget.model!.itemList![i].curSelected =
          widget.model!.itemList![i].status;
    }

    if (widget.model!.payMethod == "Bank Transfer") {
      statusList.removeWhere((element) => element == PLACED);
    }

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: TRY_AGAIN_INT_LBL,
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }
  final colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  final colorizeTextStyle = TextStyle(
    fontSize: 14.0,
    fontFamily: 'Horizon',
  );

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    Order_Model model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;

    if (model.listStatus!.contains(PLACED)) {
      pDate = model.listDate![model.listStatus!.indexOf(PLACED)];

      if (pDate != null) {
        List d = pDate.split(" ");
        pDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(PROCESSED)) {
      prDate = model.listDate![model.listStatus!.indexOf(PROCESSED)];
      if (prDate != null) {
        List d = prDate.split(" ");
        prDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(SHIPED)) {
      sDate = model.listDate![model.listStatus!.indexOf(SHIPED)];
      if (sDate != null) {
        List d = sDate.split(" ");
        sDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(DELIVERD)) {
      dDate = model.listDate![model.listStatus!.indexOf(DELIVERD)];
      if (dDate != null) {
        List d = dDate.split(" ");
        dDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(CANCLED)) {
      cDate = model.listDate![model.listStatus!.indexOf(CANCLED)];
      if (cDate != null) {
        List d = cDate.split(" ");
        cDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(RETURNED)) {
      rDate = model.listDate![model.listStatus!.indexOf(RETURNED)];
      if (rDate != null) {
        List d = rDate.split(" ");
        rDate = d[0] + "\n" + d[1];
      }
    }
    print(" list here ${model.listStatus}");

    _isCancleable = model.isCancleable == "1" ? true : false;
    _isReturnable = model.isReturnable == "1" ? true : false;

    return SafeArea(
      top: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: lightWhite,
        appBar: getAppBar(ORDER_DETAIL, context),
        body: _isNetworkAvail
            ? Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Card(
                              elevation: 0,
                              child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "$ORDER_ID_LBL - ${model.id!}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                color: black,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),

                                        ],
                                      ),
                                      Text("$ORDER_DATE- ${model.orderDate}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                            color: black,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          BlinkingPoint(
                                            xCoor: -10.0, // The x coordinate of the point
                                            yCoor: 0.0, // The y coordinate of the point
                                            pointColor: model.payMethod.toString()=="COD"?Colors.red:Colors.green, // The color of the point
                                            pointSize: 6.0, // The size of the point
                                          ),
                                          Text(
                                            "$PAYMENT_MTHD - ${model.payMethod!}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(color: black,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ))),
                          model.delDate != null && model.delDate!.isNotEmpty
                              ? Card(
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "$PREFER_DATE_TIME: ${model.delDate!} - ${model.delTime!}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(color: lightBlack2),
                                ),
                              ))
                             : Container(),

                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: model.itemList!.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, i) {
                              OrderItem orderItem = model.itemList![i];
                              return productItem(orderItem, model, i);
                            },
                          ),
                          widget.model!.driverAmount != 0 || widget.model!.driverAmount!.isNotEmpty ?
                          Card(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              width: MediaQuery.of(context).size.width,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  ColorizeAnimatedText(
                                    "Extra amount credited to you due to heavy rain : $CUR_CURRENCY ${widget.model!.driverAmount!}",
                                    // proStatus==DELIVERD||searchList[index].payMethod.toString()!="COD"?"Paid":"COD",
                                    textStyle: colorizeTextStyle,
                                    colors: colorizeColors,
                                  ),
                                ],
                                pause: Duration(milliseconds: 100),
                                isRepeatingAnimation: true,
                                totalRepeatCount: 100,
                                onTap: () {
                                  print("Tap Event");
                                },
                              ),
                            ),
                          )
                          : SizedBox(height: 0,),
                          updateStatus(),
                          sellerDetails(),

                          shippingDetails(),
                          callRequest(),
                          priceDetails(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(10.0),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: Padding(
                //           padding: const EdgeInsets.only(right: 8.0),
                //           child: DropdownButtonFormField(
                //             dropdownColor: lightWhite,
                //             isDense: true,
                //             iconEnabledColor: fontColor,
                //
                //             hint: new Text(
                //               "Update Status",
                //               style: Theme.of(this.context)
                //                   .textTheme
                //                   .subtitle2!
                //                   .copyWith(
                //                       color: fontColor,
                //                       fontWeight: FontWeight.bold),
                //             ),
                //            decoration: InputDecoration(
                //               filled: true,
                //               isDense: true,
                //               fillColor: lightWhite,
                //               contentPadding: EdgeInsets.symmetric(
                //                   vertical: 10, horizontal: 10),
                //               enabledBorder: OutlineInputBorder(
                //                 borderSide: BorderSide(color: fontColor),
                //               ),
                //             ),
                //             value: widget.model!.activeStatus,
                //             onChanged: (dynamic newValue) {
                //               setState(() {
                //                 curStatus = newValue;
                //               });
                //             },
                //             items: statusList.map((String st) {
                //               return DropdownMenuItem<String>(
                //                 value: st,
                //                 child: Text(
                //                   capitalize(st),
                //                   style: Theme.of(this.context)
                //                       .textTheme
                //                       .subtitle2!
                //                       .copyWith(
                //                           color: fontColor,
                //                           fontWeight: FontWeight.bold),
                //                 ),
                //               );
                //             }).toList(),
                //           ),
                //         ),
                //       ),
                //       RawMaterialButton(
                //         constraints:
                //             BoxConstraints.expand(width: 42, height: 42),
                //         onPressed: () {
                //           if (model.otp != null &&
                //               model.otp!.isNotEmpty &&
                //               model.otp != "0" &&
                //               curStatus == DELIVERD)
                //             otpDialog(
                //                 curStatus, model.otp, model.id, false, 0);
                //           else
                //             updateOrder(curStatus, updateOrderApi, model.id,
                //                 false, 0);
                //         },
                //         elevation: 2.0,
                //         fillColor: fontColor,
                //         padding: EdgeInsets.only(left: 5),
                //         child: Align(
                //           alignment: Alignment.center,
                //           child: Icon(
                //             Icons.send,
                //             size: 20,
                //             color: white,
                //           ),
                //         ),
                //         shape: CircleBorder(),
                //       )
                //     ],
                //   ),
                // )
              ],
            ),
            showCircularProgress(_isProgress, primary),
          ],
        )
            : noInternet(context),
      ),
    );
  }
  Widget callRequest(){
    return InkWell(
      onTap: (){
        setState(() {
          callLoading = true;
        });
        callAdmin( widget.model!.id);
      },
      child: Card(
        color: primary,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Center(
            child: !callLoading?Text("Call To Admin", style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)):CircularProgressIndicator(color: Colors.white,),
          ),
        ),
      ),
    );
  }
  otpDialog(String? curSelected, String? otp, String? id, bool item,
      int index) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(0.0),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                                padding:
                                const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                                child: Text(
                                  OTP_LBL,
                                  style: Theme.of(this.context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: fontColor),
                                )),
                            const Divider(color: lightBlack),
                            Form(
                                key: _formkey,
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20.0, 0, 20.0, 0),
                                        child: TextFormField(
                                          keyboardType: TextInputType.number,
                                          validator: (String? value) {
                                            if (value!.isEmpty) {
                                              return FIELD_REQUIRED;
                                            } else if (value.trim() != otp) {
                                              return OTPERROR;
                                            } else {
                                              return null;
                                            }
                                          },
                                          autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                          decoration: InputDecoration(
                                            hintText: OTP_ENTER,
                                            hintStyle: Theme.of(this.context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                color: lightBlack,
                                                fontWeight: FontWeight.normal),
                                          ),
                                          controller: otpC,
                                        )),
                                  ],
                                ))
                          ])),
                  actions: <Widget>[
                    TextButton(
                        child: Text(
                          CANCEL,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: lightBlack, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    TextButton(
                        child: Text(
                          SEND_LBL,
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: fontColor, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final form = _formkey.currentState!;
                          if (form.validate()) {
                            form.save();
                            setState(() {
                              Navigator.pop(context);
                            });
                            updateOrder(curSelected, id, item, index, otp);
                          }

                        })
                  ],
                );
              });
        });
  }

  _launchMap(lat, lng) async {
    var url = '';

    if (Platform.isAndroid) {
      url =
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate";
    } else {
      url =
      "http://maps.apple.com/?saddr=&daddr=$lat,$lng&directionsmode=driving&dir_action=navigate";
    }
    await launch(url);
/*    if (await canLaunch(url)) {

    } else {
      throw 'Could not launch $url';
    }*/
  }

  Widget priceDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Text(PRICE_DETAIL,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: fontColor, fontWeight: FontWeight.bold))),
              const Divider(
                color: lightBlack,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$PRICE_LBL :",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text("${CUR_CURRENCY!} ${widget.model!.subTotal!}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("GST & Service Charges" + " " + ":",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack2)),
                    Text("+ " + CUR_CURRENCY! + widget.model!.gstAmount!,
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack2))
                  ],
                ),
              ),


              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$DELIVERY_CHARGE :",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text("+ ${CUR_CURRENCY!} ${widget.model!.delCharge!}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                  ],
                ),
              ),
              widget.model!.extraDelCharge != null || widget.model!.extraDelCharge!.isNotEmpty ?
              Padding(
                padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Extra Delivery Charge" + " " + ":",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack2)),
                    Text("+ " + CUR_CURRENCY! + " " + widget.model!.extraDelCharge!,
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack2))
                  ],
                ),
              )
              : SizedBox(height: 0,),
              //
              // Padding(
              //   padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text("$TAXPER (${widget.model!.taxPer!}) :",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2)),
              //       Text("+ ${CUR_CURRENCY!} ${widget.model!.taxAmt!}",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2))
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$PROMO_CODE_DIS_LBL :",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text("- ${CUR_CURRENCY!} ${widget.model!.promoDis!}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text("$WALLET_BAL :",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2)),
              //       Text("- ${CUR_CURRENCY!} ${widget.model!.walBal!}",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2))
              //     ],
              //   ),
              // ),
              Padding(
                padding:
                const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$TOTAL_PRICE :",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: black, fontWeight: FontWeight.bold, fontSize: 20)),
                    Text("${CUR_CURRENCY!} ${widget.model!.total!}",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: black, fontWeight: FontWeight.bold, fontSize: 20))
                  ],
                ),
              ),
            ])));
  }

  Widget updateStatus(){
    OrderItem orderItem = widget.model!.itemList![0];
    return     widget.model!.itemList!.length >= 1
        ? Card(
      elevation: 0,
          child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
            vertical: 10.0),
      child: orderItem.status!=DELIVERD?
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Text(ORDER_STATUS,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: fontColor, fontWeight: FontWeight.bold))),
          const Divider(
            color: lightBlack,
          ),
          Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 8.0),
                    child:
                    DropdownButtonFormField(
                      dropdownColor: lightWhite,
                      isDense: true,
                      iconEnabledColor: fontColor,
                      //iconSize: 40,
                      hint: Text(
                        "Update Status",
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2!
                            .copyWith(
                            color: fontColor,
                            fontWeight:
                            FontWeight.bold),
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        isDense: true,
                        fillColor: lightWhite,
                        contentPadding:
                        EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10),
                        enabledBorder:
                        OutlineInputBorder(
                          borderSide: BorderSide(
                              color: fontColor),
                        ),
                      ),
                      value: orderItem.status,
                      onChanged: (String? newValue) {
                        setState(() {
                          orderItem.curSelected =
                              newValue;
                          print("selected value here ${orderItem.curSelected}");
                        });
                      },
                      items: statusList.map((String st) {
                        print("checking list values here ${st} ");
                        return DropdownMenuItem(
                          value: st,
                          child:
                          Text(
                            capitalize(st),
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                color: fontColor,
                                fontWeight:
                                FontWeight
                                    .bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                RawMaterialButton(
                  constraints:
                  const BoxConstraints.expand(
                      width: 42, height: 42),
                  onPressed: () {
                    if (widget.model!.otp != null &&
                        widget.model!.otp!.isNotEmpty &&
                        widget.model!.otp != "0" &&
                        orderItem.curSelected ==
                            DELIVERD) {
                      otpDialog(
                          orderItem.curSelected,
                          widget.model!.otp,
                          widget.model!.id,
                          true,
                          0);
                    } else {
                      updateOrder(
                          orderItem.curSelected,
                          widget.model!.id,
                          true,
                          0,
                          widget.model!.otp);
                    }
                  },
                  elevation: 2.0,
                  fillColor: fontColor,
                  padding:
                  const EdgeInsets.only(left: 5),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.send,
                      size: 20,
                      color: white,
                    ),
                  ),
                  shape: const CircleBorder(),
                )
              ],
          ),
        ],
      ):
      Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                  color:  Colors.green,
                  borderRadius:
                  const BorderRadius.all(Radius.circular(4.0))),
              child: Center(
                child: Text(
                  capitalize(orderItem.status.toString()),
                  style: const TextStyle(color: white,fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
        )
        : Container();
  }
  Widget shippingDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Row(
                    children: [
                      Text(SHIPPING_DETAIL,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: fontColor,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      widget.model!.latitude != "" &&
                          widget.model!.longitude != ""
                          ? Container(
                        height: 30,
                        child: IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: fontColor,
                            ),
                            onPressed: () {
                              _launchMap(widget.model!.latitude,
                                  widget.model!.longitude);
                            }),
                      )
                          : Container()
                    ],
                  )),
              const Divider(
                color: lightBlack,
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Text(
                    widget.model!.name != null && widget.model!.name!.isNotEmpty
                        ? " ${capitalize(widget.model!.name!)}"
                        : " ",
                  )),
              Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 3),
                  child: Text(capitalize(widget.model!.address!),
                      style: const TextStyle(color: lightBlack2))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.call,
                                size: 15,
                                color: fontColor,
                              ),
                              Text(" ${widget.model!.mobile!}",
                                  style: const TextStyle(
                                      color: fontColor,
                                      decoration: TextDecoration.underline)),
                            ],
                          )),

                      onTap: (){
                        _launchCaller(widget.model!.mobile!);
                      }
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        rateSeller=false;
                        openBottomSheet(context,widget.model!.user_id.toString());
                      },
                      icon: Icon(Icons.rate_review_outlined,
                          color: primary),
                      label: Text(
                        "Rate User",
                        style: TextStyle(color: primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color:
                            primary),
                      ),
                    ),
                  )
                ],
              ),
            ])));
  }

  Widget sellerDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Row(
                    children: [
                      Text(SELLER_DETAILS,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: fontColor,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      widget.model!.itemList![0].storeLatitude != "" &&
                          widget.model!.itemList![0].storeLongitude != ""
                          ? Container(
                        height: 30,
                        child: IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: fontColor,
                            ),
                            onPressed: () {
                              _launchMap(
                                  widget
                                      .model!.itemList![0].storeLatitude,
                                  widget.model!.itemList![0]
                                      .storeLongitude);
                            }),
                      )
                          : Container(),
                    ],
                  )),
              const Divider(
                color: lightBlack,
              ),
              Row(
                children: [
                  widget.model!.itemList![0].storeImage!= null ?
                      Container(
                        height: 90,
                          width: 90,
                          child:
                          Image.network(widget.model!.itemList![0].storeImage!))
                  : placeHolder(90),
                  // Expanded(
                  //   child: ClipRRect(
                  //       borderRadius: BorderRadius.circular(10.0),
                  //       child: FadeInImage(
                  //         fadeInDuration: const Duration(milliseconds: 150),
                  //         image: NetworkImage(widget.model!.itemList![0].storeImage!),
                  //         height: 90.0,
                  //         width: 90.0,
                  //         placeholder: placeHolder(90),
                  //       )),
                  // ),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 15.0, right: 15.0),
                              child: Text(
                                widget.model!.itemList![0].storeName != null &&
                                    widget.model!.itemList![0].storeName!
                                        .isNotEmpty
                                    ? " ${capitalize(widget.model!.itemList![0].storeName!)}"
                                    : " ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 3),
                              child: Text(capitalize(widget.model!.itemList![0].sellerAddress.toString()),
                                  style: const TextStyle(color: lightBlack2))),
                          InkWell(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15.0, vertical: 5),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.call,
                                        size: 15,
                                        color: fontColor,
                                      ),
                                      Text(" ${widget.model!.itemList![0].sellerMobileNumber.toString()}",
                                          style: const TextStyle(
                                              color: fontColor,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline)),
                                    ],
                                  )),
                              onTap: (){
                                _launchCaller(widget.model!.itemList![0].sellerMobileNumber.toString());
                              }
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 5),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                rateSeller=true;
                                openBottomSheet(context,widget.model!.itemList![0].seller_id.toString());
                              },
                              icon: Icon(Icons.rate_review_outlined,
                                  color: primary),
                              label: Text(
                                "Rate Shop",
                                style: TextStyle(color: primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                    primary),
                              ),
                            ),
                          )
                        ],
                      ))
                ],
              ),
            ])));
  }

  Widget productItem(OrderItem orderItem, Order_Model model, int i) {
    List att = [], val = [];
    if (orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }

    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    orderItem.image!= null ?
                        Container(
                          height: 80,
                            width: 80,
                            child: Image.network(orderItem.image!)
                        ):
                        placeHolder(80),
                    // ClipRRect(
                    //     borderRadius: BorderRadius.circular(10.0),
                    //     child: FadeInImage(
                    //       fadeInDuration: const Duration(milliseconds: 150),
                    //       image: NetworkImage(orderItem.image!),
                    //       height: 120.0,
                    //       width: 100.0,
                    //       placeholder: placeHolder(90),
                    //     )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderItem.name ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                  color: lightBlack,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            orderItem.attr_name!.isNotEmpty
                                ? ListView.builder(
                                physics:
                                const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(children: [
                                    Flexible(
                                      child: Text(
                                        att[index].trim() + ":",
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(color: lightBlack2),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5.0),
                                      child: Text(
                                        val[index],
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(color: lightBlack),
                                      ),
                                    )
                                  ]);
                                })
                                : Container(),
                            Row(children: [
                              Text(
                                "$QUANTITY_LBL:",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(color: lightBlack),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Text(
                                  orderItem.qty.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(color: lightBlack),
                                ),
                              )
                            ]),
                            Text(
                              "${CUR_CURRENCY!} ${orderItem.price.toString()}",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: fontColor),
                            ),

                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            )));
         }

  bool callLoading = false;
  Future<void> callAdmin(id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        /*setState(() {
          _isProgress = true;
        });*/
        var parameter = {
          "order_id": id,
          "call_request": "1",
        };
        print(parameter.toString());
        Response response =
        await post(callAdminApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        setSnackbar(msg);
        setState(() {
          callLoading = false;
        });
        if (!error) {
        }
        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_){
        setSnackbar(somethingMSg);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Future<void> updateOrder(
      String? status, String? id, bool item, int index, String? otp) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        setState(() {
          _isProgress = true;
        });
        var parameter = {
          ORDERID: id,
          STATUS: status,
          DEL_BOY_ID: CUR_USERID,
          OTP: otp
        };
        if (item) parameter[ORDERITEMID] = widget.model!.itemList![index].id;

        print(parameter.toString());
        //return;
        Response response =
        await post(updateOrderApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        setSnackbar(msg);
        if (!error) {
          if (item) {
            widget.model!.itemList![index].status = status;
          } else {
            widget.model!.activeStatus = status;
          }
        }

        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  bool rateSeller = false;
  void openBottomSheet(BuildContext context,String id) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    bottomSheetHandle(),
                    rateTextLabel(),
                    ratingWidget(),
                    writeReviewLabel(),
                    writeReviewField(),
                    sendReviewButton(id),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Widget bottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: lightBlack),
        height: 5,
        width: MediaQuery.of(context).size.width * 0.3,
      ),
    );
  }

  Widget rateTextLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child:  Text(rateSeller?"Rate Shop":"Rate User"),
    );
  }

  Widget ratingWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingBar.builder(
        initialRating: 0,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 5,
        itemSize: 32,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color:Colors.yellow,
        ),
        onRatingUpdate: (rating) {
          curRating = rating;
        },
      ),
    );
  }

  Widget writeReviewLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        "Please share your opinion",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.subtitle1!,
      ),
    );
  }

  Widget writeReviewField() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: TextField(
          controller: commentTextController,
          style: Theme.of(context).textTheme.subtitle2,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: lightBlack
                    ,
                    width: 1.0)),
            hintText:"Write your review here...",
            hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
                color:
                lightBlack2.withOpacity(0.7)),
          ),
        ));
  }



  Widget sendReviewButton(id) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              onPressed: () async {
                Navigator.pop(context);
                setRating(curRating, commentTextController.text,
                    id,widget.model!.id);
              },
              child: Text("Send Review"),
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Text getHeading(
      String title,
      ) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headline6!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }
  TextEditingController commentTextController = TextEditingController();
  double curRating = 0.0;
  Future<void> setRating(
      double rating, String comment,var userId,orderId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {

      try {
        var request = await http.post(setRatingApi,body: {
          "user_seller_id": userId,
          "order_id": orderId,
          "delivery_boy_id": CUR_USERID,
          "review": comment!=""?"Nice":comment,
          "rating": rating.toString(),
        },headers: headers);
        print({
          "user_seller_id": userId,
          "order_id": orderId,
          "delivery_boy_id": CUR_USERID,
          "review": comment!=""?"Nice":comment,
          "rating": rating.toString(),
        });
        var getdata =  jsonDecode(request.body);
        bool error = getdata["error"];
        String? msg = getdata['message'];

        if (!error) {
          setSnackbar(msg!);
        } else {
          setSnackbar(msg!);
        }
        commentTextController.text = "";
      } on TimeoutException catch (_) {
        setSnackbar("Something went wrong");
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }
  void _launchCaller(String phoneNumber) async {
    var url = "tel:$phoneNumber";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      setSnackbar('Could not launch $url');
      throw 'Could not launch $url';
    }
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
}
