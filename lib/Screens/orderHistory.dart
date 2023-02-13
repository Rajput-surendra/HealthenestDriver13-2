

import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/order_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';


class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key}) : super(key: key);

  @override
  _OrderHistoryState createState() => _OrderHistoryState();
}

int? total, offset;
List<Order_Model> orderList = [];
bool _isLoading = true;
bool isLoadingmore = true;
bool isLoadingItems = true;

class _OrderHistoryState extends State<OrderHistory> {

  String? activeStatus;
  bool _isNetworkAvail = true;
  List<Order_Model> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  final List<String> months = <String>[];
  final currentDate = DateTime.now();
  final List<String> items = [
    'Delivered',
    'Cancelled'
  ];
  final List<String> payments = [
    'Cash Payments',
    'Online Payments',
  ];
  String? selectedValue;
  String? selectedMonths;
  String? selectedPayment;
  String paymentMethod = "";
  String status = "";
  String monthSelected = "";

  @override
  void initState() {
    offset = 0;
    total = 0;
    orderList.clear();
    getMonthAYearFromCurrent();
   // getMonthAYearFromSelected();

    // generateListofMonths(DateTime.now());
    getOrder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text("Order History",
        style: TextStyle(
          color: Color(0xffFEBD11),
        ),),
      ),
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
                    SizedBox(height: 10,),
                    _filterOption(),
                    SizedBox(height: 10,),
                    _detailHeader(),
                    SizedBox(height: 10,),
                    orderList.isEmpty
                        ? isLoadingItems
                        ? const Center(
                        child: CircularProgressIndicator())
                        : const Center(child: Text(noOrder))
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: (offset! < total!)
                          ? orderList.length + 1
                          : orderList.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return (index == orderList.length &&
                            isLoadingmore)
                            ? const Center(
                            child:
                            CircularProgressIndicator())
                            : orderItem(index);
                      },
                    )
                    // FutureBuilder(
                    //   future: getOrder(),
                    //   builder: (context, AsyncSnapshot<String> snapshot) {
                    //     if (snapshot.connectionState == ConnectionState.waiting) {
                    //       return const CircularProgressIndicator();
                    //     }
                    //     return ;
                    //   },
                    // ),


                  ])),
        ),
      )
          : noInternet(context),
    );
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
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
                      color: primary,
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
          flex: 2,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: primary,
                  ),
                  Text(CASH_LBL,
                  textAlign: TextAlign.center),
                  Text(
                    "${CUR_CURRENCY!} $CASH_RECIEVED",
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
                    Icons.wallet,
                    color: primary,
                  ),
                  const Text(ONLINE_LBL),
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
      ],
    );
  }

  _filterOption(){
    return Row(
     // mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                hint: Row(
                  children: const [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: primary,
                    ),
                    SizedBox(width: 2,),

                    Expanded(
                      child: Text(
                        'Months',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items: months
                    .map((item) =>
                    DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                    .toList(),
                value: selectedMonths,
                onChanged: (value) {
                  setState(() {
                    selectedMonths = value as String;
                  });
                  getSelectedMonths();
                  _refresh();

                  print("MONTH SELECTED === $selectedMonths");
                },
                icon: const Icon(
                  Icons.arrow_forward_ios_outlined,
                ),
                iconSize: 14,
                iconEnabledColor: primary,
                // iconDisabledColor: Colors.grey,
                buttonHeight: 50,
                buttonWidth: 160,
                buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                buttonDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black26,
                  ),
                  color: Colors.white,
                ),
                // buttonElevation: 2,
                itemHeight: 40,
                itemPadding: const EdgeInsets.only(left: 14, right: 14),
                dropdownMaxHeight: 200,
                dropdownWidth: 140,
                dropdownPadding: null,
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // color: Colors.redAccent,
                ),
                dropdownElevation: 8,
                scrollbarRadius: const Radius.circular(40),
                scrollbarThickness: 6,
                scrollbarAlwaysShow: true,
                // offset: const Offset(-20, 0),
              ),
            ),
          ),
        ),
        SizedBox(width: 3,),
        Expanded(
          child: Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                hint: Row(
                  children: const [
                    Icon(
                      Icons.wallet,
                      size: 16,
                      color: primary,
                    ),
                    SizedBox(width: 4,),

                    Expanded(
                      child: Text(
                        'Payments',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items: payments
                    .map((item) =>
                    DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                    .toList(),
                value: selectedPayment,
                onChanged: (value) {
                  setState(() {
                    selectedPayment = value as String;
                    if(selectedPayment == "Cash Payments" ){
                      setState((){
                        paymentMethod = "COD";
                        _refresh();
                      });
                    } else{
                      setState((){
                        paymentMethod = "Online";
                        _refresh();

                      });

                    }
                  });

                  print("Payments SELECTED === $selectedPayment");
                },
                icon: const Icon(
                  Icons.arrow_forward_ios_outlined,
                ),
                iconSize: 14,
                iconEnabledColor: primary,
                // iconDisabledColor: Colors.grey,
                buttonHeight: 50,
                buttonWidth: 180,
                buttonPadding: const EdgeInsets.only(left: 7, right: 7),
                buttonDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black26,
                  ),
                  color: Colors.white,
                ),
                // buttonElevation: 2,
                itemHeight: 40,
                itemPadding: const EdgeInsets.only(left: 14, right: 14),
                dropdownMaxHeight: 200,
                dropdownWidth: 140,
                dropdownPadding: null,
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // color: Colors.redAccent,
                ),
                dropdownElevation: 8,
                scrollbarRadius: const Radius.circular(40),
                scrollbarThickness: 6,
                scrollbarAlwaysShow: true,
                // offset: const Offset(-20, 0),
              ),
            ),
          ),
        ),
        SizedBox(width: 3,),
        Expanded(
          child: Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                hint: Row(
                  children: const [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: primary,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items: items
                    .map((item) =>
                    DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                    .toList(),
                value: selectedValue,
                onChanged: (value) {
                  setState(() {
                    selectedValue = value as String;
                  });
                  if(selectedValue == "Delivered"){
                    setState(() {
                      status = "Delivered";
                      _refresh();
                    });
                  }else{
                    setState(() {
                      status = "Cancelled";
                      _refresh();
                    });
                  }
                  print("Filter SELECTED === $selectedValue");
                },
                icon: const Icon(
                  Icons.arrow_forward_ios_outlined,
                ),
                iconSize: 14,
                iconEnabledColor: primary,
                // iconDisabledColor: Colors.grey,
                buttonHeight: 50,
                buttonWidth: 160,
                buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                buttonDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black26,
                  ),
                  color: Colors.white,
                ),
                // buttonElevation: 2,
                itemHeight: 40,
                itemPadding: const EdgeInsets.only(left: 14, right: 14),
                dropdownMaxHeight: 200,
                dropdownWidth: 140,
                dropdownPadding: null,
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // color: Colors.redAccent,
                ),
                dropdownElevation: 8,
                scrollbarRadius: const Radius.circular(40),
                scrollbarThickness: 6,
                scrollbarAlwaysShow: true,
                // offset: const Offset(-20, 0),
              ),
            ),
          ),
        ),
      ],
    );
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

  Future<Null> _refresh() {
    offset = 0;
    total = 0;
    orderList.clear();

    setState(() {
      _isLoading = true;
      isLoadingItems = false;
    });
    orderList.clear();
    return getOrder();
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
    else
      back = Colors.red;

    return
      model.itemList![0].status == DELIVERD ||  model.itemList![0].status == CANCLED?
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
                    Text("Order No.${model.id!}" , style: TextStyle(fontWeight: FontWeight.bold),),
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
                        const Icon(Icons.money, size: 14),
                        Text(" Payable: ${CUR_CURRENCY!} ${model.payable!}"),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
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
              )
            ])),
        onTap: () {
        }
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

getOrder() async {
    print("paymentMethod is ${paymentMethod}");
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
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          ACTIVE_STATUS : status,
          PAYMENT_METHOD : paymentMethod,
          "month" : monthSelected

          //"month": "2022-09"
        };

        Response response =
        await post(getOrdersApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));
        print(parameter);
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        total = int.parse(getdata["total"]);

        if (!error) {
          if (offset! < total!) {
            tempList.clear();
            var data = getdata["data"];

            tempList = (data as List)
                .map((data) => Order_Model.fromJson(data))
                .toList();

            orderList.addAll(tempList);

            offset = offset! + perPage;
          }
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

  List<String> generateListofMonths(DateTime time) {
    String returnString = '';
    // List<String> months = [];
    for (int i = 0; i < 12; i++) {
      // increment the month value
      returnString += formatDate(DateTime(time.year, i, time.day), [M, '-']);
    }
    // remove the last dash (-)
    returnString = returnString.substring(0, returnString.length-1);
    // returnString = returnString.replaceAll('-', '\n');
    months.add(returnString);
    print(returnString);
    return months;
  }
  void getSelectedMonths() {
    if (selectedMonths == "January ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-01";
      });
    }
    else if (selectedMonths == "February ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-02";
      });
    }
    else if (selectedMonths == "March ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-03";
      });
    }
    else if (selectedMonths == "April ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-04";
      });
    }
    else if (selectedMonths == "May ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-05";
      });
    }
    else if (selectedMonths == "June ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-06";
      });
    }
    else if (selectedMonths == "July ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-07";
      });
    }
    else if (selectedMonths == "August ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-08";
      });
    }
    else if (selectedMonths == "September ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-09";
      });
    }

    else if (selectedMonths == "October ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-10";
      });
    }

    else if (selectedMonths == "November ${currentDate.year}") {
      setState(() {
        monthSelected = "2022-11";
      });
    }

    else {
      setState(() {
        monthSelected = "2022-12";
      });
    }
  }


  List<String> getMonthAYearFromCurrent({int length = 12}) {
    const listOfMonth = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];


    // final months = <String>[];

    for (var i = 0; i < length; i++) {
      final yearInt = currentDate.year - (0 - (currentDate.month - i) + 12) ~/ 12;
      final monthInt = (currentDate.month - i - 1) % 12;
      months.add('${listOfMonth[monthInt]} $yearInt');
     // monthSelected = "${currentDate.year}-0$monthInt";
    }
    print(currentDate.month);
    print("MONTHS==== $months");
    print("selected month is $monthSelected");
    return months;
  }

}
