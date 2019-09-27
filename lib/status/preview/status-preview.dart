import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_bottom_sheet.dart';
import 'package:scrollable_bottom_sheet/scrollable_controller.dart';
import './status-preview-image.dart';

class StoryScaffold extends StatefulWidget {
  StoryScaffold({Key key}) : super(key: key);
  @override
  StoryScaffoldState createState() => StoryScaffoldState();
}

class StoryScaffoldState extends State<StoryScaffold> {
  final _barKey = GlobalKey();
  bool isSheetOpen = false;

  bool _test = true;

  final ScrollableController controller = ScrollableController();


  final GlobalKey<_SheetState> sKey = GlobalKey<_SheetState>();

  _Sheet sheet;

  PersistentBottomSheetController sheetController;


  AppBar _getAppBar() {
    return AppBar(
      title: Text("Status"),
      actions: <Widget>[
        Container(
          width: 50,
          child: Center(
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.redAccent,
              elevation: 1,
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ),
        ),
        Container(
          width: 50,
          child: Center(
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.redAccent,
              elevation: 1,
              child: Icon(
                Icons.bubble_chart,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width / 2 - 48 * 2 - 50),
          child: IconButton(
            icon: Icon(Icons.live_tv),
            tooltip: 'Search',
            onPressed: () {
              // handle the press
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.view_quilt),
          //icon: Icon(Icons.view_list),
          tooltip: 'Search',
          onPressed: () {
            // handle the press
            setState(() {
              _test = !_test;
              sKey.currentState.updateColor(_test);
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    sheet = _Sheet(
      key: sKey,
    );
  }

  void openSheet() {
    sheetController = showBottomSheet(
        context: _barKey.currentContext, builder: (context) => sheet)
      ..closed.then((value) {
        setState(() {
          isSheetOpen = false;
        });
      });

    setState(() {
      isSheetOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = _getAppBar();

    return IgnorePointer(
      ignoring: !isSheetOpen,
      child: Scaffold(
        backgroundColor:
            isSheetOpen ? Color.fromRGBO(0, 0, 0, 0.4) : Colors.transparent,
        appBar: PreferredSize(
          key: _barKey,
          preferredSize: appBar.preferredSize,
          child: Visibility(
            visible: isSheetOpen,
            child: appBar,
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatefulWidget {
  _Sheet({Key key}) : super(key: key);

  @override
  _SheetState createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Color color;
  final ScrollableController controller = ScrollableController();

  void updateColor(bool col) {
    setState(() {
      color = col ? Colors.red : Colors.yellow;
    });
  }

  @override
  void initState() {
    super.initState();
    color = Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableBottomSheetByContent(
      Container(),
      _buildContent(),
      autoPop: true,
      scrollTo: ScrollState.full,
      controller: controller,
      callback: (state) {
        print(state);
      },
    );
  }

  _buildContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 20),
      //color: color,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          MyItem(),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 15),
            padding: EdgeInsets.all(10),
            color: Colors.grey.withOpacity(0.2),
            child: Text(
              "Recent updates",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(5),
            child: Wrap(
              children: orders
                  .map((v) => _RecentItem())
                  //.map((v) => ListTile(title: Text(v), subtitle: Text("Qty: $v pcs")))
                  .toList(),
              alignment: WrapAlignment.spaceBetween,
            ),
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 15),
            padding: EdgeInsets.all(10),
            color: Colors.grey.withOpacity(0.2),
            child: Text(
              "Viewed updates",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(5),
            child: Wrap(
              children: orders
                  .map((v) => _RecentItem())
                  //.map((v) => ListTile(title: Text(v), subtitle: Text("Qty: $v pcs")))
                  .toList(),
              alignment: WrapAlignment.spaceBetween,
            ),
          ),
        ],
      ),
    );
  }

  final orders = [
    "Apple",
    "Apricot",
    "Blackberry",
    "Cherry",
    "Dragonfruit",
    "Grape",
    "Honeydew",
    "Jujube",
    "Kumquat",
    "Lime",
    "Papaya",
    "Passon Fruit",
    "Peach",
    "Pineapple",
    "Plum",
    "Raspberry",
    "Tomato"
  ];
}

class _RecentItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => {},
      child: Padding(
        padding: EdgeInsets.only(top: 10, left: 2, right: 2),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  StatusImage(),
                  Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Text(
                      "Jane Doe",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  "12h",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 60,
      child: IconButton(
        icon: Icon(Icons.settings, color: Colors.black),
        tooltip: 'Story settings',
        onPressed: () {
          // handle the press
        },
      ),
    );

    final cont = InkWell(
      onTap: () => {},
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Stack(
              children: <Widget>[
                StatusImage(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("My status"),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        "Tap to add status update",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            button,
          ],
        ),
      ),
    );

    return cont;
  }
}
