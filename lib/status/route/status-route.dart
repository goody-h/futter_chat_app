import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import './status-group-info.dart';
import './controllers/status-progress-controller.dart';
import './status-progress-bar.dart';
import './status-group-tab.dart';
import '../../chat-input-field.dart';

class Status extends StatefulWidget {
  Status({Key key, this.startGroup}) : super(key: key);
  final int startGroup;
  @override
  State<StatefulWidget> createState() {
    return StatusState();
  }
}

class StatusState extends State<Status> with TickerProviderStateMixin {
  static const platform = const MethodChannel("com.example.wiconn/f");
  Timer _clickTimer;
  bool pause;
  TabController _controller;
  int pointerDownCount = 0;

  List<SystemUiOverlay> overlays;
  List<SystemUiOverlay> updateOverlays = [SystemUiOverlay.bottom];

  List<StatusGroup> groups;

  int currentGroup = 0;

  ProgressController progressController;

  @override
  void initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 3);
    platform.invokeMethod("setTranslucentNav");

    pause = false;

    currentGroup = widget.startGroup ?? 0;

    progressController = ProgressController(
      vsync: this,
      group: groups[currentGroup],
    );

    _controller.addListener(tabListener);
    _controller.animation.addListener(animationListener);
  }

  @override
    void dispose() {
      super.dispose();
      _controller.dispose();
      progressController.dispose();
    }

  void tabListener() {
    if (_controller.offset == 0) {
      setState(() {});
    }
  }

  void animationListener() {
    if (_controller.index != currentGroup) {
      setState(() {
        currentGroup = _controller.index;
        progressController.updateGroup(groups[currentGroup]);
      });
    }
  }

  void clearPointer() {
    if (pointerDownCount > 0) {
      pointerDownCount--;
    }
    print("clear pointer, count = $pointerDownCount");
    if (pointerDownCount == 0) {
      if (_clickTimer.isActive) {
        _clickTimer.cancel();
      }
      setState(() {
        updateOverlays = [SystemUiOverlay.bottom];
        pause = false;
      });
    }
  }

  void nextStatusGroup() {
    if (_controller.index < _controller.length - 1) {
      _controller.animateTo(_controller.index + 1);
    } else {
      // end status show
    }
  }

  void previousStatusGroup() {
    if (_controller.index > 0) {
      _controller.animateTo(_controller.index - 1);
    } else {
      // end status show
    }
  }

  List<Widget> getTabs() {
    List<Widget> tabs = [];
    for (var i = 0; i < groups.length; i++) {
      tabs.add(StatusGroupTab(
        group: groups[i],
        controller: progressController,
        canPlay: !pause && _controller.offset == 0 && i == currentGroup,
        getClickTick: () => _clickTimer.tick,
        onFinish: nextStatusGroup,
        prevStatus: previousStatusGroup,
      ));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    if (updateOverlays != overlays) {
      overlays = updateOverlays;
      SystemChrome.setEnabledSystemUIOverlays(overlays);
    } else {
      Timer(Duration(seconds: 3), () {
        SystemChrome.setEnabledSystemUIOverlays(overlays);
      });
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Container(
            height: double.infinity,
            width: double.infinity,
            child: NotificationListener(
              onNotification: (Notification notification) {
                if (notification is ScrollStartNotification) {
                  print("scroll start");
                  pointerDownCount++;
                  print("count = $pointerDownCount");
                } else if (notification is ScrollEndNotification) {
                  print("scroll end");
                  clearPointer();
                }
                return false;
              },
              child: Listener(
                onPointerDown: (p) {
                  pointerDownCount++;

                  print("pointer down, count = $pointerDownCount");

                  if (pointerDownCount == 1) {
                    setState(() {
                      pause = true;
                    });
                    _clickTimer =
                        Timer.periodic(Duration(milliseconds: 250), (t) {
                      if (t.tick > 5) {
                        t.cancel();
                        setState(() {
                          updateOverlays = [];
                          // hide layout details
                        });
                      }
                    });
                    print("timer set, count = $pointerDownCount");
                  }
                },
                onPointerUp: (p) {
                  print("pointer up");
                  clearPointer();
                },
                onPointerCancel: (p) {
                  print("pointer cancel");
                  clearPointer();
                },
                child: TabBarView(
                  controller: _controller,
                  children: getTabs(),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: overlays.isEmpty ? 0 : 1,
            duration: Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: overlays.isEmpty,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: MediaQuery.of(context).padding.left,
                  right: MediaQuery.of(context).padding.right,
                ),
                child: Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        StatusProgress(
                          controller: progressController,
                        ),
                        AppBar(
                          primary: false,
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          leading: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () {},
                          ),
                          titleSpacing: 0,
                          title: Row(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    "assets/images/profile_pic.jpg",
                                    fit: BoxFit.fill,
                                    width: 35,
                                    height: 35,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Jane Doe",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      "Today, 01:25",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white24),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          actions: <Widget>[
                            IconButton(
                              icon: Icon(Icons.file_download),
                              onPressed: () {},
                            ),
                            PopupMenuButton<int>(
                              onSelected: (index) {
                                print("selected");
                                setState(() {
                                  pause = false;
                                });
                              },
                              onCanceled: () {
                                print("canceled");
                                setState(() {
                                  pause = false;
                                });
                              },
                              itemBuilder: (context) {
                                print("build menu");
                                setState(() {
                                  pause = true;
                                });
                                return [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Text("Mute"),
                                  ),
                                ];
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: ChatInput(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}