import 'dart:async';
import 'dart:convert';
import 'package:blinking_point/blinking_point.dart';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/location_details.dart';
import 'package:deliveryboy_multivendor/Helper/push_notification_service.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/BoyStatusModel.dart';
import 'package:deliveryboy_multivendor/Model/OrderAcceptRejectModel.dart';
import 'package:deliveryboy_multivendor/Model/order_model.dart';
import 'package:deliveryboy_multivendor/Screens/Authentication/login.dart';
import 'package:deliveryboy_multivendor/Screens/orderHistory.dart';
import 'package:deliveryboy_multivendor/Screens/working_hours.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_lIst.dart';
import 'order_detail.dart';
import 'privacy_policy.dart';
import 'profile.dart';
import 'wallet_history.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateHome();
  }
}

int? total, offset;
List<Order_Model> orderList = [];
bool _isLoading = true;
bool isLoadingmore = true;
bool isLoadingItems = true;

class StateHome extends State<Home> with TickerProviderStateMixin {
  int curDrwSel = 0;
  bool onOff = false;

  bool _isNetworkAvail = true;
  List<Order_Model> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String? profile;
  ScrollController controller = ScrollController();
  List<String> statusList = [
    ALL,
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
  //  CANCLED,
  //  RETURNED,
   // awaitingPayment
  ];
  String? activeStatus;
  var value = 0;
  var driverStatus = 0;

  acceptOrderDialog(type, orderId, userId) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
            ),
            title: Text("Are You Sure?"),
            content: type =="1"?
            Text(
                "Accepting order will assign you this order and have to complete on time."):Text("Canceling the order request, are you sure want to cancel the order request"),
            actions: [
              TextButton(
                  onPressed: () async {
                OrderAcceptRejectModel? model =await acceptReject(type, orderId, userId);
                if(model!.error == false){

                  Navigator.pop(context);
                  _refresh();

                   setState(() {
                     Fluttertoast.showToast(
                         msg: "${model.message}",
                         toastLength: Toast.LENGTH_SHORT,
                         gravity: ToastGravity.SNACKBAR,
                         timeInSecForIosWeb: 1,
                         backgroundColor:type =="1"? Colors.green:Colors.red,
                         textColor: Colors.white,
                         fontSize: 14.0
                     );
                   });
                }else{

                }
              }, child: Text("Confirm")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel")),
            ],
          );
        });
  }

  Future<OrderAcceptRejectModel?> acceptReject(type, orderId, userId) async {
    var request = http.MultipartRequest('POST', getAcceptRejectOrder);
    request.fields.addAll({
      'accept_reject': '$type',
      'order_id': '$orderId',
      'user_id': '$userId'
    });

    print(request.fields);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final str = await response.stream.bytesToString();
      print(str);
      return OrderAcceptRejectModel.fromJson(json.decode(str));
    }
    else {
      return null;
    }
  }
Timer? _timer;
  @override
  void initState() {
    setState((){
    _timer = Timer(Duration(seconds: 60), () {
      //setState((){
        _refresh();
     // });
    });
      // SOMETHING
    });
    offset = 0;
    total = 0;
    orderList.clear();
    getSetting();
    getOrder();
    getUserDetail();
    GetLocation getLocation = new GetLocation();
    getLocation.getLoc();
    final pushNotificationService = PushNotificationService(context: context,onResult: (result){

      if(result=="yes"){
        setState(() {
          offset = 0;
          orderList.clear();
          _isLoading = true;
          isLoadingItems = false;
        });
        getOrder();
        _refresh();
      }

    });
    pushNotificationService.initialise();


    buttonController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: Interval(
        0.0,
        0.150,
      ),
    ));
    controller.addListener(_scrollListener);

    super.initState();
  }
  bool statusOn = false;
  bool changeOnTap = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightWhite,
      appBar: AppBar(
        title: Text(
          appName,
          style: TextStyle(
            color: grad2Color,
          ),
        ),
        iconTheme: IconThemeData(color: grad2Color),
        backgroundColor: white,
        actions: [
          InkWell(
              onTap: filterDialog,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.filter_alt_outlined,
                    color: primary,
                  ))),
        ],
      ),
      drawer: _getDrawer(),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer()
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: ToggleSwitch(
                                  activeBgColor: [
                                    driverStatus == 0
                                        ? Colors.red
                                        : driverStatus == 1
                                        ? Colors.green
                                        : Colors.orange
                                  ],
                                  inactiveBgColor: driverStatus == 0
                                      ? Colors.grey[300]
                                      : driverStatus == 1
                                      ? Colors.grey[300]
                                      : Colors.green,
                                  activeFgColor: driverStatus == 0
                                      ? Colors.black
                                      : driverStatus == 1
                                      ? Colors.white
                                      : Colors.black,
                                  initialLabelIndex: driverStatus,
                                  changeOnTap: changeOnTap,
                                  totalSwitches: 2,
                                  labels: ['Offline', 'Online'],
                                  onToggle: (index) async {
                                    if(!statusOn){
                                      print("ok");

                                      setState(() {
                                        driverStatus = index!;
                                      });
                                      BoyStatusModel? model = await boyStatus();
                                      if (model!.error == false) {
                                        final snackBar = SnackBar(
                                          content: Text(
                                            model.message.toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );

                                        // Find the ScaffoldMessenger in the widget tree
                                        // and use it to show a SnackBar.
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }
                                    }else{
                                      setState((){
                                        changeOnTap = false;
                                      });

                                      setSnackbar("You have running order");
                                    }

                                  },
                                ),
                              ),

                              // _detailHeader(),
                              // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor
                              SizedBox(
                                height: 10,
                              ),
                              orderList.isEmpty
                                  ? isLoadingItems
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : const Center(child: Text(noItem))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: (offset! < total!)
                                          ? orderList.length + 1
                                          : orderList.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return (index == orderList.length &&
                                                isLoadingmore)
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : orderList[index].itemList!.length > 0
                                            ? orderItem(index)
                                            : SizedBox();
                                      },
                                    )
                            ])),
                  ),
                )
          : noInternet(context),
    );
  }

  void filterDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ButtonBarTheme(
            data: const ButtonBarThemeData(
              alignment: MainAxisAlignment.center,
            ),
            child: AlertDialog(
                elevation: 2.0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0))),
                contentPadding: const EdgeInsets.all(0.0),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding:
                            EdgeInsetsDirectional.only(top: 19.0, bottom: 16.0),
                        child: Text(
                          'Filter By',
                          style: Theme.of(context)
                              .textTheme
                              .headline6!
                              .copyWith(color: fontColor),
                        )),
                    Divider(color: lightBlack),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: getStatusList()),
                      ),
                    ),
                  ]),
                )),
          );
        });
  }

  List<Widget> getStatusList() {
    return statusList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            Column(
              children: [
                Container(
                  width: double.maxFinite,
                  child: TextButton(
                      child: Text(capitalize(statusList[index]),
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: lightBlack)),
                      onPressed: () {
                        setState(() {
                          activeStatus = index == 0 ? null : statusList[index];
                          isLoadingmore = true;
                          offset = 0;
                          isLoadingItems = true;
                        });

                        getOrder();

                        Navigator.pop(context, 'option $index');
                      }),
                ),
                const Divider(
                  color: lightBlack,
                  height: 1,
                ),
              ],
            ),
          ),
        )
        .values
        .toList();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset! < total!) getOrder();
        });
      }
    }
  }

  Drawer _getDrawer() {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: white,
          child: ListView(
            padding: EdgeInsets.all(0),
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              _getHeader(),
              Divider(),
              _getDrawerItem(0, HOME_LBL, Icons.home_outlined),
              // _getDrawerItem(7, WALLET, Icons.account_balance_wallet_outlined),
              //  _getDrawerItem(5, WORK_HOURS, Icons.access_time),
              _getDivider(),
              _getDrawerItem(8, PRIVACY, Icons.lock_outline),
              _getDrawerItem(9, TERM, Icons.speaker_notes_outlined),
              CUR_USERID == "" || CUR_USERID == null
                  ? Container()
                  : _getDivider(),
              CUR_USERID == "" || CUR_USERID == null
                  ? Container()
                  : _getDrawerItem(11, LOGOUT, Icons.input),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getHeader() {
    return InkWell(
      child: Container(
        decoration: back(),
        padding: const EdgeInsets.only(left: 10.0, bottom: 10),
        child: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 20, left: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CUR_USERNAME!,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: white, fontWeight: FontWeight.bold),
                    ),
                    // Text("$WALLET_BAL: ${CUR_CURRENCY!}$CUR_BALANCE",
                    //     style: Theme.of(context)
                    //         .textTheme
                    //         .caption!
                    //         .copyWith(color: white)),
                    Padding(
                        padding: const EdgeInsets.only(
                          top: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(EDIT_PROFILE_LBL,
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .copyWith(color: white)),
                            const Icon(
                              Icons.arrow_right_outlined,
                              color: white,
                              size: 20,
                            ),
                          ],
                        ))
                  ],
                )),
            Spacer(),
            Container(
              margin: const EdgeInsets.only(top: 20, right: 20),
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.0, color: white)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: imagePlaceHolder(62),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(),
            ));

        setState(() {});
      },
    );
  }

  Widget _getDivider() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Divider(
        height: 1,
      ),
    );
  }

  Widget _getDrawerItem(int index, String title, IconData icn) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
          gradient: curDrwSel == index
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                      secondary.withOpacity(0.2),
                      primary.withOpacity(0.2)
                    ],
                  stops: [
                      0,
                      1
                    ])
              : null,
          // color: curDrwSel == index ? primary.withOpacity(0.2) : Colors.transparent,

          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(50),
            bottomRight: Radius.circular(50),
          )),
      child: ListTile(
        dense: true,
        leading: Icon(
          icn,
          color: curDrwSel == index ? primary : lightBlack2,
        ),
        title: Text(
          title,
          style: TextStyle(
              color: curDrwSel == index ? primary : lightBlack2, fontSize: 15),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (title == HOME_LBL) {
            setState(() {
              curDrwSel = index;
            });
            Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
          } else if (title == NOTIFICATION) {
            setState(() {
              curDrwSel = index;
            });

            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationList(),
                ));
          } else if (title == LOGOUT) {
            logOutDailog();
          } else if (title == PRIVACY) {
            setState(() {
              curDrwSel = index;
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicy(
                    title: PRIVACY,
                  ),
                ));
          } else if (title == TERM) {
            setState(() {
              curDrwSel = index;
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicy(
                    title: TERM,
                  ),
                ));
          } else if (title == WALLET) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletHistory(),
                ));
          }
          else if (title == WORK_HOURS) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkingHours(),
                ));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _refresh() {
    offset = 0;
    total = 0;
    orderList.clear();

    setState(() {
      _timer = Timer(Duration(seconds: 60), () {
        //setState((){
          _refresh();
       // });
      });
      _isLoading = true;
      isLoadingItems = false;
    });
    orderList.clear();
    return getOrder();
  }

  logOutDailog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: Text(
                LOGOUTTXT,
                style: Theme.of(this.context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                    child: Text(
                      LOGOUTNO,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2!
                          .copyWith(
                              color: lightBlack, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                TextButton(
                    child: Text(
                      LOGOUTYES,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2!
                          .copyWith(
                              color: fontColor, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      clearUserSession();

                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => Login()),
                          (Route<dynamic> route) => false);
                    })
              ],
            );
          });
        });
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
                  getOrder();
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

  Future<Null> getOrder() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (offset == 0) {
        orderList = [];
      }
      try {
        CUR_USERID = await getPrefrence(ID);
        CUR_USERNAME = await getPrefrence(USERNAME);

        var parameter = {
          USER_ID: CUR_USERID,
          // LIMIT: perPage.toString(),
          OFFSET: offset.toString()
        };
        if (activeStatus != null) {
          if (activeStatus == awaitingPayment) activeStatus = "awaiting";
          parameter[ACTIVE_STATUS] = activeStatus;
        }
        print(headers);
        print(parameter);
        Response response =
            await post(getOrdersApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(getOrdersApi);
        var getdata = json.decode(response.body);
        print(getdata);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        total = int.parse(getdata["total"]);

        if (!error) {
          setState(() {
            orderList.clear();
            tempList.clear();
            statusOn = false;
            var data = getdata["data"];

            tempList = (data as List)
                .map((data) => Order_Model.fromJson(data))
                .toList();
            orderList.addAll(tempList);
            offset = offset! + perPage;
          });
        }
        if (mounted)
          setState(() {
            _isLoading = false;
            isLoadingItems = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isLoading = false;
          isLoadingItems = false;
        });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          _isLoading = false;
          isLoadingItems = false;
        });
    }
    return null;
  }

  Future<Null> getUserDetail() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        CUR_USERID = await getPrefrence(ID);

        var parameter = {ID: CUR_USERID};
        Response response =
            await post(getBoyDetailApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(parameter);
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"][0];
          driverStatus = int.parse(data["online_status"].toString());
          print(data);
          print(data['cash_received']);
          CUR_BALANCE = double.parse(data[BALANCE]).toStringAsFixed(2);
          CASH_RECIEVED = double.parse(data['cash_received']).toStringAsFixed(2);
           //   getdata['cod_balance']).toStringAsFixed(2);
          CUR_BONUS = double.parse(getdata['online_balance']).toStringAsFixed(2);
        }
        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          _isLoading = false;
        });
    }

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

  Widget orderItem(int index) {
    Order_Model model = orderList[index];
    Color back;
    if ((model.itemList![0].status!) == DELIVERD)
      back = Colors.green;
    else if ((model.itemList![0].status!) == SHIPED)
      back = Colors.orange;
    else if ((model.itemList![0].status!) == CANCLED ||
        model.itemList![0].status! == RETURNED)
      back = Colors.red;
    else if ((model.itemList![0].status!) == PROCESSED)
      back = Colors.indigo;
    else if (model.itemList![0].status! == WAITING)
      back = Colors.black;
    else
      back = Colors.cyan;
    if(model.itemList![0].status!=DELIVERD&&model.itemList![0].status!=RETURNED){
      if(!statusOn){
        statusOn = true;
        if(driverStatus==0){
          driverStatus=1;
          boyStatus();
        }
      }
    }
    return
      model.itemList![0].status != DELIVERD
          && model.itemList![0].status != CANCLED
          && model.itemList![0].status != RETURNED ?
      Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                    Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Order No.${model.id!}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: back,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4.0))),
                      child: Text(
                        capitalize(model.itemList![0].status!),
                        style: const TextStyle(color: white),
                      ),
                    )
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14),
                          Expanded(
                            child: Text(
                              model.name != null && model.name!.isNotEmpty
                                  ? " ${capitalize(model.name!)}"
                                  : " ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call,
                            size: 14,
                            color: fontColor,
                          ),
                          Text(
                            " ${model.mobile!}",
                            style: const TextStyle(
                                color: fontColor,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      onTap: () {
                        _launchCaller(index);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.money, size: 14),
                        Text(" Payable: ${CUR_CURRENCY!} ${model.payable!}"),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                      BlinkingPoint(
                      xCoor: -10.0, // The x coordinate of the point
                      yCoor: 0.0, // The y coordinate of the point
                      pointColor: model.payMethod.toString()=="COD"?Colors.red:Colors.green, // The color of the point
                      pointSize: 6.0, // The size of the point
                    ),
                        const Icon(Icons.payment, size: 14),
                        Text(" ${model.payMethod!}"),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 14),
                    Text(" Order on: ${model.orderDate!}"),
                  ],
                ),
              ),
              model.itemList![0].status == "delivered" ? Container() :
              model.itemList![0].accept_reject_driver == null||model.itemList![0].accept_reject_driver == "0"
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.green)),
                            onPressed: () {
                             acceptOrderDialog("1", model.id, CUR_USERID);
                            },
                            child: Text(
                              "Accept",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red)),
                            onPressed: () {
                              acceptOrderDialog("2", model.id, CUR_USERID);
                            },
                            child: Text(
                              "Reject",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container()
            ])),
        onTap: () async {
          /*Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrderDetail(model: orderList[index])),
          );*/
          if (driverStatus == 0) {
            final snackBar = SnackBar(
              content: const Text('Currently You are Offline , Go Online'),
            );

            // Find the ScaffoldMessenger in the widget tree
            // and use it to show a SnackBar.
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else if (driverStatus == 2) {
            final snackBar = SnackBar(
              content: const Text('You are on Break, Go Online'),
            );

            // Find the ScaffoldMessenger in the widget tree
            // and use it to show a SnackBar.
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else {
            print(model.itemList![0].accept_reject_driver);
            model.itemList![0].accept_reject_driver == "1"?
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OrderDetail(model: orderList[index])),
            ):print("hey");
            setState(() {
              /* _isLoading = true;
             total=0;
             offset=0;
orderList.clear();*/
              getUserDetail();
            });
          }
          // getOrder();
        },
      ),
    )
    : SizedBox(height: 0,);
  }

  _launchCaller(index) async {
    var url = "tel:${orderList[index].mobile}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _detailHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: fontColor,
                    ),
                    Text(ORDER),
                    Text(
                      total.toString(),
                      style: const TextStyle(
                          color: fontColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )),
        ),
        Expanded(
          flex: 3,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: fontColor,
                  ),
                  Text(BAL_LBL),
                  Text(
                    "${CUR_CURRENCY!} $CUR_BALANCE",
                    style: const TextStyle(
                        color: fontColor, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.wallet_giftcard,
                    color: fontColor,
                  ),
                  const Text(BONUS_LBL),
                  Text(
                    CUR_BALANCE,
                    style: const TextStyle(
                        color: fontColor, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> getSetting() async {
    try {
      CUR_USERID = await getPrefrence(ID);

      var parameter = {TYPE: CURRENCY};

      Response response =
          await post(getSettingApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          CUR_CURRENCY = getdata["currency"];
        } else {
          setSnackbar(msg!);
        }
      }
    } on TimeoutException catch (_) {
      setSnackbar(somethingMSg);
    }
  }

  Future<BoyStatusModel?> boyStatus() async {
    CUR_USERID = await getPrefrence(ID);
    var header = headers;
    var request = http.MultipartRequest('POST', onlineOfflineApi);
    request.fields.addAll({
      'delivery_boy_id': '$CUR_USERID',
      'open_close_status': '$driverStatus',
    });


    request.headers.addAll(header);

    http.StreamedResponse response = await request.send();
    print(request.fields);
    if (response.statusCode == 200) {
      print(onlineOfflineApi);
      final str = await response.stream.bytesToString();
      return BoyStatusModel.fromJson(json.decode(str));
    } else {
      return null;
    }
  }
}
