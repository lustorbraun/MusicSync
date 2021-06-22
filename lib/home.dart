import 'package:flutter/material.dart';
import './models/user_model.dart';
import './screens/friendlist_screen.dart';
import 'components/auth.dart';
import 'screens/upload.dart';

User loggedinUser;

class HomePage extends StatefulWidget {
  final User currentUser;
  HomePage({this.currentUser});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentindex = 0;
  List tabs = [
    FriendListScreen(),
    Upload(isFromFriendScreen: false,),
  ];

  @override
  void initState() {
    super.initState();
    setCurrentUser();
  }

  setCurrentUser(){
    loggedinUser=widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              "MusicSync",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                fontSize: 45
              ),
            ),
            actions: [
              RaisedButton(
                child: Text('log out'),
                onPressed: (){
                  signOutGoogle();
                  Navigator.pop(context);
                },
                color: Colors.white.withOpacity(0),
                elevation: 0,
              )
            ],
            backgroundColor: Colors.white.withOpacity(0),
            elevation: 0,
          ),
          body: tabs[currentindex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentindex,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                title: Text('Home')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud_upload),
                  title: Text('Upload')
              ),
            ],
            onTap: (index) {
              setState(() {
                currentindex = index;
              });
            },
          ),
        );
  }
}