import 'package:flutter/material.dart';
import 'view-utils.dart';


class CallPage extends StatefulWidget {
  @override
  _CallState createState() => _CallState();
}

class _CallState extends State<CallPage> {

  List<String> recent;

  @override
  void initState() { 
    super.initState();
    recent = ["", "", "", "", "", "", "", ""];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: recent.length,
      itemBuilder: (context, position) {
        return _RecentItem();
      },
    );
  }
}

class _RecentItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 60,
      child: IconButton(
        icon: Icon(Icons.call, color: Colors.blue),
        tooltip: 'View call info',
        onPressed: () {
          // handle the press
        },
      ),
    );

    final cont = InkWell(
      onTap: ()=>{},
      child: Padding(
      padding: EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              ProfileRound(),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Jane Doe"),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.call_missed, color: Colors.red, size: 15,),
                            Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text(
                                "(2) 4 October, 09:18",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              button,
            ],
          ),
          Container(margin:EdgeInsets.only(top: 9, left: 60), height: 1, color: Color.fromRGBO(0xe4, 0xe4, 0xf5, 1),)
        ],
      ),
    ),
    );

    return cont;
  }
}

