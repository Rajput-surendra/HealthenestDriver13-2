import 'dart:async';
import 'dart:convert';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/sim_btn.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/transaction_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';


class WorkingHours extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateWorkHours();
  }
}

List<TransactionModel> tranList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class StateWorkHours extends State<WorkingHours> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];
  TextEditingController? amtC, bankDetailC;

  @override
  void initState() {
    super.initState();
    getTransaction();
    sendRequest();
    controller.addListener(_scrollListener);
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
    amtC = TextEditingController();
    bankDetailC = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightWhite,
        key: _scaffoldKey,
        appBar: getAppBar(WORK_HOURS, context),
        body: _isNetworkAvail
            ? _isLoading
            ? shimmer()
            : RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                  children: [
                    _detailHeader(),
                    // tranList.length == 0
                    //     ? Center(child: Text(noItem))
                    //     :
                    _workingHrsList(),
                    // ListView.builder(
                    //   shrinkWrap: true,
                    //   itemCount: (offset < total)
                    //       ? tranList.length + 1
                    //       : tranList.length,
                    //   physics: NeverScrollableScrollPhysics(),
                    //   itemBuilder: (context, index) {
                    //     return (index == tranList.length &&
                    //         isLoadingmore)
                    //         ? Center(
                    //         child: CircularProgressIndicator())
                    //         : listItem(index);
                    //   },
                    // ),
                  ]),
            ))
            : noInternet(context));
  }
  _detailHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10),
      child: Card(
        child: Container(
          padding: EdgeInsets.only(left: 60, right: 30),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Day",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fontColor
                ),),
              Padding(
                padding: const EdgeInsets.only(left: 35.0),
                child: SizedBox(
                  height: 30,
                    child: VerticalDivider(
                      color: Colors.grey,
                      width: 1,
                    )),
              ),
              Text(WORK_HOURS,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fontColor
              ),)


            ],
          ),
        ),
      ),
    );
  }

  _workingHrsList(){
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: data.length,
              itemBuilder: (context, i){
            return Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10),
              child: Card(
                child: Container(
                  padding: EdgeInsets.only(left: 40, right: 60),
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data[i]['date'].toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: fontColor
                        ),),
                      Padding(
                        padding: const EdgeInsets.only(right: 30.0),
                        child: SizedBox(
                            height: 30,
                            child: VerticalDivider(
                              color: Colors.grey,
                              width: 1,
                            )),
                      ),
                      Text(data[i]['in_hrs'].toString(),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: fontColor
                        ),)


                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
  List data = [];

  Future<Null> sendRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };

        Response response =
        await post(getWorkingHours, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          data = getdata['data'];
         // CUR_BALANCE = double.parse(getdata["data"]).toStringAsFixed(2);
        }
        if (mounted) setState(() {});
        setSnackbar(msg);
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
      actions: [
        Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                return filterDialog();
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: primary,
                ),
              ),
            ))
      ],
    );
  }

  void filterDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ButtonBarTheme(
            data: ButtonBarThemeData(
              alignment: MainAxisAlignment.center,
            ),
            child: AlertDialog(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0))),
                contentPadding: const EdgeInsets.all(0.0),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: EdgeInsets.only(top: 19.0, bottom: 16.0),
                      child: Text(
                        FILTER_BY,
                        style: Theme.of(context).textTheme.headline6,
                      )),
                  Divider(color: lightBlack),
                  TextButton(
                      child: Text(SHOW_TRANS,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: lightBlack)),
                      onPressed: () {
                        tranList.clear();
                        offset = 0;
                        total = 0;
                        setState(() {
                          _isLoading = true;
                        });
                        getTransaction();
                        Navigator.pop(context, 'option 1');
                      }),
                  Divider(color: lightBlack),
                  TextButton(
                      child: Text(SHOW_REQ,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: lightBlack)),
                      onPressed: () {
                        tranList.clear();
                        offset = 0;
                        total = 0;
                        setState(() {
                          _isLoading = true;
                        });
                        getRequest();
                        Navigator.pop(context, 'option 1');
                      }),
                  Divider(
                    color: white,
                  )
                ])),
          );
        });
  }

  // _showDialog() async {
  //   await showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return StatefulBuilder(
  //             builder: (BuildContext context, StateSetter setStater) {
  //               return AlertDialog(
  //                 contentPadding: const EdgeInsets.all(0.0),
  //                 shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.all(Radius.circular(5.0))),
  //                 content: SingleChildScrollView(
  //                     scrollDirection: Axis.vertical,
  //                     child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Padding(
  //                               padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
  //                               child: Text(
  //                                 SEND_REQUEST,
  //                                 style: Theme.of(this.context)
  //                                     .textTheme
  //                                     .subtitle1!
  //                                     .copyWith(color: fontColor),
  //                               )),
  //                           Divider(color: lightBlack),
  //                           Form(
  //                               key: _formkey,
  //                               child: Column(
  //                                 children: <Widget>[
  //                                   Padding(
  //                                       padding:
  //                                       EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
  //                                       child: TextFormField(
  //                                         keyboardType: TextInputType.number,
  //                                         validator: validateField,
  //                                         autovalidateMode:
  //                                         AutovalidateMode.onUserInteraction,
  //                                         decoration: InputDecoration(
  //                                           hintText: WITHDRWAL_AMT,
  //                                           hintStyle: Theme.of(this.context)
  //                                               .textTheme
  //                                               .subtitle1!
  //                                               .copyWith(
  //                                               color: lightBlack,
  //                                               fontWeight: FontWeight.normal),
  //                                         ),
  //                                         controller: amtC,
  //                                       )),
  //                                   Padding(
  //                                       padding:
  //                                       EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
  //                                       child: TextFormField(
  //                                         validator: validateField,
  //                                         keyboardType: TextInputType.multiline,
  //                                         maxLines: null,
  //                                         autovalidateMode:
  //                                         AutovalidateMode.onUserInteraction,
  //                                         decoration: InputDecoration(
  //                                           hintText: BANK_DETAIL,
  //                                           hintStyle: Theme.of(this.context)
  //                                               .textTheme
  //                                               .subtitle1!
  //                                               .copyWith(
  //                                               color: lightBlack,
  //                                               fontWeight: FontWeight.normal),
  //                                         ),
  //                                         controller: bankDetailC,
  //                                       )),
  //                                 ],
  //                               ))
  //                         ])),
  //                 actions: <Widget>[
  //                   ElevatedButton(
  //                       child: Text(
  //                         CANCEL,
  //                         style: Theme.of(this.context)
  //                             .textTheme
  //                             .subtitle2!
  //                             .copyWith(
  //                             color: lightBlack, fontWeight: FontWeight.bold),
  //                       ),
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                       }),
  //                   ElevatedButton(
  //                       child: Text(
  //                         SEND_LBL,
  //                         style: Theme.of(this.context)
  //                             .textTheme
  //                             .subtitle2!
  //                             .copyWith(
  //                             color: fontColor, fontWeight: FontWeight.bold),
  //                       ),
  //                       onPressed: () {
  //                         final form = _formkey.currentState!;
  //                         if (form.validate()) {
  //                           form.save();
  //                           setState(() {
  //                             Navigator.pop(context);
  //                           });
  //                           sendRequest();
  //                         }
  //                       })
  //                 ],
  //               );
  //             });
  //       });
  // }

  listItem(int index) {
    Color back;
    if (tranList[index].status == "success" ||
        tranList[index].status == ACCEPTED) {
      back = Colors.green;
    } else if (tranList[index].status == PENDING)
      back = Colors.orange;
    else
      back = Colors.red;
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          AMT_LBL +
                              " : " +
                              CUR_CURRENCY! +
                              " " +
                              tranList[index].amt!,
                          style: TextStyle(
                              color: fontColor, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Text(tranList[index].date!),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(ID_LBL + " : " + tranList[index].id!),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius:
                              BorderRadius.all(const Radius.circular(4.0))),
                          child: Text(
                            capitalize(tranList[index].status!),
                            style: TextStyle(color: white),
                          ),
                        )
                      ],
                    ),
                    tranList[index].opnBal != null &&
                        tranList[index].opnBal!.isNotEmpty
                        ? Text(OPNBL_LBL + " : " + tranList[index].opnBal!)
                        : Container(),
                    tranList[index].clsBal != null &&
                        tranList[index].clsBal!.isNotEmpty
                        ? Text(CLBL_LBL + " : " + tranList[index].clsBal!)
                        : Container(),
                    tranList[index].msg != null &&
                        tranList[index].msg!.isNotEmpty
                        ? Text(MSG_LBL + " : " + tranList[index].msg!)
                        : Container(),
                  ]))),
    );
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
                  getTransaction();
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

  Future<Null> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
        await post(getFundTransferApi, headers: headers, body: parameter)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
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

  Future<Null> getRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
        await post(getWithReqApi, headers: headers, body: parameter)
            .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromReqJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
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

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _refresh() {
    setState(() {
      _isLoading = true;
    });
    offset = 0;
    total = 0;
    tranList.clear();
    return getTransaction();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) getTransaction();
        });
      }
    }
  }
}
