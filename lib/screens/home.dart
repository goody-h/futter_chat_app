import 'package:flutter/material.dart';
import 'home-scaler.dart';
import 'media-tab.dart';
import 'chat-tab.dart';
import 'call-tab.dart';
import '../status/preview/status-preview.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  double _offset;

  final _barKey = GlobalKey();
  final _test = GlobalKey();

  final _storyKey = GlobalKey<StoryScaffoldState>();
  bool sheetOpen = false;

  Size _mSize;
  double scaleUp;
  double scaleDown;

  bool ignore = false;
  ScrollController controller;

  @override
  void initState() {
    super.initState();

    controller = ScrollController();

    _mSize = Size(0, 0);
    _offset = 0.0;
    _tabController = TabController(vsync: this, length: 3, initialIndex: 1);

    _tabController.animation.addListener(animationListener);

    _tabController.addListener(tabListener);

    WidgetsBinding.instance.addPostFrameCallback(_getsize);
    WidgetsBinding.instance.addPersistentFrameCallback(_getsize);
  }

  void animationListener() {
      final index = _tabController.index;
      final offset = _tabController.offset;

      if (index == 2 ||
          (index == 1 && offset > 0) ||
          (offset == 0 && _offset != 0)) {
        setState(() {
          _offset = offset;
        });
      }

      print(_tabController.indexIsChanging);
  }

  void tabListener() {
    print(_tabController.index.toString());
      print("listener");
  }

  void _getsize(duration) {
    final size = _barKey.currentContext.size;
    if (size.width != _mSize.width || size.height != _mSize.height) {
      print(size);
      setState(() {
        _mSize = size;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var offset = _offset >= 0 ? _offset : 1 + _offset;

    var colorAlpha = 0.75 * offset;
    var color = Color.fromRGBO(0, 0, 0, colorAlpha);
    var xOffset = MediaQuery.of(context).size.width * (1 - offset);

    if (offset == 0.0) {
      color = Color.fromRGBO(0, 0, 0, 0.75);
      xOffset = 0.0;
    }

    final appBar = AppBar(
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Icon(Icons.call),
          ),
          Tab(
            child: Icon(Icons.chat),
          ),
          Tab(
            child: Icon(Icons.camera),
          ),
        ],
      ),
      title: Text('Wiconn'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.bubble_chart),
          tooltip: 'View stories',
          onPressed: () {

            _storyKey.currentState.openSheet();
          },
        ),
        IconButton(
          icon: Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            // handle the press
          },
        ),
      ],
    );

    final pages = TabBarView(
      controller: _tabController,
      children: [
        DownScale(
          origin: _mSize.height,
          child: CallPage(),
        ),
        DownScale(
          origin: _mSize.height,
          child: ChatPage(),
        ),
        MediaPage(
          offset: offset,
          offsetWidth: xOffset,
          color: color,
          origin: _mSize.height,
        ),
      ],
    );

    var yOffset = (appBar.preferredSize.height + 30) * offset;

    if (offset == 0 && _tabController.index == 2) {
      yOffset = appBar.preferredSize.height + 30;
    }

    return Stack(
      children: <Widget>[
        Scaffold(
          key: _test,
          appBar: PreferredSize(
            key: _barKey,
            preferredSize: appBar.preferredSize,
            child: Transform.translate(
              offset: Offset(0.0, -yOffset),
              child: appBar,
            ),
          ),
          drawer: Drawer(),
          body: Scale(
            origin: _mSize.height,
            child: pages,
          ),
          floatingActionButton: _tabController.index != 2 && !sheetOpen
              ? FloatingActionButton(
                  onPressed: () => {},
                )
              : null,
        ),
        StoryScaffold(
          key: _storyKey,
        ),
      ],
    );
  }
}
