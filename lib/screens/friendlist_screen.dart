import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../home.dart';
import '../models/user_model.dart';
import '../screens/private_room_screen.dart';

class FriendListScreen extends StatefulWidget {
  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<DocumentSnapshot> _list;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('friendList')
          .doc("user${loggedinUser.userUID}")
          .collection('userFriendsUID')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          _list = snapshot.data.docs;

          if(_list.length==0){
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Your FriendList Appears Here',style: TextStyle(fontSize: 25,fontWeight: FontWeight.w800),),
                  SizedBox(height: 20,),
                  Text('share song with friends from upload screen',style: TextStyle(fontWeight: FontWeight.w600),),
                ],
              ),
            );
          }

          return ListView.custom(
              childrenDelegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  return buildList(context, _list[index]);
                },
                childCount: _list.length,
              ));
        }
      },
    );
  }

  Widget buildList(BuildContext context, DocumentSnapshot documentSnapshot) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PrivateRoom(
                friendUserModel: User(
                  userid: documentSnapshot.data()['FriendID'],
                  userImageURL: documentSnapshot.data()['FriendPhotoURL'],
                  userUID: documentSnapshot.data()['FriendUID'],
                  displayName: documentSnapshot.data()['FriendName']
                ),
                groupId: documentSnapshot.data()['GroupID'],
              ))),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10,vertical:8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(documentSnapshot.data()['FriendPhotoURL']),
              ),
              title: Text(
                documentSnapshot.data()["FriendName"],
                style: kRaisedButtonTextStyle.copyWith(fontSize: 18)
              ),
            ),
          ),
          Divider(
            indent: 20,
          ),
        ],
      ),
    );
  }

}