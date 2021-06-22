import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import '../models/user_model.dart';
import '../screens/playerscreen.dart';
import '../screens/upload.dart';
import '../constants.dart';


Reference storageRef=FirebaseStorage.instance.ref();

class PrivateRoom extends StatefulWidget {
  final User friendUserModel;
  final String groupId;
  PrivateRoom({this.groupId,this.friendUserModel});

  @override
  _PrivateRoomState createState() => _PrivateRoomState();
}

class _PrivateRoomState extends State<PrivateRoom> {
  List<DocumentSnapshot> _list;
  DatabaseReference realTimeRef=FirebaseDatabase.instance.reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
          backgroundColor: Colors.white.withOpacity(0),
          elevation: 0,
        title: Text("${widget.friendUserModel.displayName}",
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontSize: 30
          ),
        ),
        actions: [IconButton(
          icon: Icon(Icons.add,
            color: Colors.black,
            size: 30,
          ),
          onPressed: (){
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Upload(
                      isFromFriendScreen: true,
                      friendUserModel: widget.friendUserModel,
                      groupID: widget.groupId,
                    )));
          },
        ),]
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("groups")
            .doc(widget.groupId)
            .collection('songs')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            _list = snapshot.data.docs;

            return ListView.custom(
                childrenDelegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    return buildList(context, _list[index]);
                  },
                  childCount: _list.length,
                ));
          }
        },
      ),
    );
  }

  Widget buildList(BuildContext context, DocumentSnapshot documentSnapshot) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerScreen(
                songName: documentSnapshot.data()["song_name"],
                artistName: documentSnapshot.data()["artist_name"],
                songUrl: documentSnapshot.data()["song_url"],
                ownerUID: documentSnapshot.data()["ownerUid"],
                tenantUID: documentSnapshot.data()["tenantUid"],
                songID: documentSnapshot.data()['songID'],
                groupID: documentSnapshot.data()['GroupID'],
              ))),
      child: Card(
        shadowColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20,vertical: 2),
          child: ListTile(
            title: Text(
              documentSnapshot.data()["song_name"],
              style: kRaisedButtonTextStyle.copyWith(fontSize: 20),
            ),
            subtitle: documentSnapshot.data()["shareWith"]!=null?
            Text("shared by: ${documentSnapshot.data()["shareWith"][0]}",maxLines: 1,style: TextStyle(fontWeight: FontWeight.w500),):
            Text('uploader not known')
            ,
            trailing: loggedinUser.displayName==documentSnapshot.data()["uploaded_by"]?IconButton(icon: Icon(Icons.delete),
                onPressed: ()async{
                  await realTimeRef
                      .child('group-${widget.groupId}')
                      .child('song-${documentSnapshot.data()['songID']}')
                      .remove();
                  var desertRef = storageRef.child('song${documentSnapshot.data()['songID']}');
                  desertRef.delete();
              FirebaseFirestore.instance
                  .collection("groups")
                  .doc(widget.groupId)
                  .collection('songs')
                  .doc(documentSnapshot.data()['songID']).delete();
            }
            ):Text(''),
          ),
        ),
        elevation: 20.0,
      ),
    );
  }
}