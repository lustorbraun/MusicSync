import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../components/auth.dart';
import '../constants.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';
import '../home.dart';

class Upload extends StatefulWidget {
  final bool isFromFriendScreen;
  final User friendUserModel;
  final String groupID;
  Upload({this.isFromFriendScreen,this.friendUserModel,this.groupID});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {

  TextEditingController songname = TextEditingController();
  TextEditingController sharewithTextController = TextEditingController();

  File song;
  String songpath,songID,groupId;
  List<String> songSharedBetween=[];
  String _tenantUid,_tenantPhotoURL,_tenantId;
  Reference ref;
  var  songDownUrl;
  final firestoreinstance = FirebaseFirestore.instance;
  bool _isSongPicked,_isUploadedPressed;
  UploadTask songuploadTask;
  Future<QuerySnapshot> searchResultsFuture;

  searchUserInDatabase(String query) {
    Future<QuerySnapshot> users = usersRef
        .where("displayName", isGreaterThanOrEqualTo: query)
        .get();
    setState(() {
      searchResultsFuture = users;
    });
  }

  @override
  void initState() {
    super.initState();
    _isSongPicked=false;
    _isUploadedPressed=false;
    songSharedBetween.add(loggedinUser.displayName);
    songSharedBetween.add('');
    songID=Uuid().v1();
    if(widget.isFromFriendScreen){
      fillDetails();
    }
  }

  fillDetails(){
    sharewithTextController.text=widget.friendUserModel.displayName;
    _tenantUid=widget.friendUserModel.userUID;
    _tenantPhotoURL=widget.friendUserModel.userImageURL;
    groupId=widget.groupID;
  }

  void selectsong() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();

    setState(() {
      song = File(result.files.single.path);
      song==null?_isSongPicked=false:_isSongPicked=true;
    });
  }

  Future<void> uploadsongfile(List<int> song) async {
    ref = FirebaseStorage.instance.ref().child("song$songID");
    songuploadTask = ref.putData(song);
    songDownUrl = await ref.getDownloadURL();
  }

  finalupload(context) async{
    if(widget.isFromFriendScreen){
      songSharedBetween[1]=widget.friendUserModel.displayName;
    }
    if(songname.text.isNotEmpty&&_isSongPicked&&sharewithTextController.text.isNotEmpty){
      setState(() {
        _isUploadedPressed=true;
      });
    await uploadsongfile(song.readAsBytesSync());

      var data = {
        "song_name": songname.text,
        "song_url": songDownUrl.toString(),
        "uploaded_by":loggedinUser.displayName,
        "songID":songID,
        "shareWith":[songSharedBetween[0],songSharedBetween[1]],
        'ownerUid':loggedinUser.userUID,
        'tenantUid':_tenantUid,
        'GroupID':groupId
      };

      firestoreinstance
          .collection("groups")
          .doc(groupId)
          .collection('songs')
          .doc(songID)
          .set(data)
          .whenComplete(() => showDialog(
        context: context,
        builder: (context) => _onTapButton(context,"Files Uploaded Successfully :)"),
      ));

      firestoreinstance
          .collection('friendList')
          .doc("user${loggedinUser.userUID}")
          .collection('userFriendsUID')
          .doc(_tenantUid)
          .set({
        'FriendName':songSharedBetween[1],
        'FriendUID':_tenantUid,
        'FriendPhotoURL':_tenantPhotoURL,
        'FriendID': _tenantId,
        'GroupID':groupId
      });

      firestoreinstance
          .collection('friendList')
          .doc("user$_tenantUid")
          .collection('userFriendsUID')
          .doc(loggedinUser.userUID)
          .set({
        'FriendName':songSharedBetween[0],
        'FriendID':loggedinUser.userid,
        'FriendUID':loggedinUser.userUID,
        'FriendPhotoURL':loggedinUser.userImageURL,
        'GroupID':groupId
      });
    }
    else{
      Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text('fill all the details'),
            duration: Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
      );
    }
  }

  _onTapButton(BuildContext context,data) {
    return AlertDialog(title: Text(data));
  }

  void creategroupchatId()async{
    int one=loggedinUser.userUID.codeUnits.fold(0, (p, c) => p + c);
    int two=_tenantUid.codeUnits.fold(0, (p, c) => p + c);
    if ( one <= two) {
      groupId = '${loggedinUser.userUID}-$_tenantUid';
    } else {
      groupId = '$_tenantUid-${loggedinUser.userUID}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploadedPressed) {

      /// Manage the task state and event subscription with a StreamBuilder
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Text('Song Upload'),
              StreamBuilder<TaskSnapshot>(
                  stream: songuploadTask.snapshotEvents,
                  builder: (_, snapshot) {

                    double progressPercent = snapshot.data != null
                        ? snapshot.data.bytesTransferred / snapshot.data.totalBytes
                        : 0;

                    return Column(

                      children: [
                        if (snapshot.data.bytesTransferred==snapshot.data.totalBytes)
                          Text('🎉🎉🎉'),
                        LinearProgressIndicator(value: progressPercent),
                        Text(
                            '${(progressPercent * 100).toStringAsFixed(2)} % '
                        ),
                        (widget.isFromFriendScreen&&snapshot.data.bytesTransferred==snapshot.data.totalBytes)?RaisedButton(
                          child: Text('Okay'),
                          onPressed: (){
                            Navigator.pop(context);
                          },
                        ):Text('')
                      ],
                    );
                  }),
            ],
          ),
        ),
      );


    } else {

      // Allows user to decide when to start the upload
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RaisedButton(
                          onPressed: () => selectsong(),
                          child: Text("Select Song",style: kRaisedButtonTextStyle,),
                        ),
                        _isSongPicked?Text('song Selected',style: kRaisedButtonTextStyle.copyWith(fontSize: 15),):Text('Song not Selected yet',style: kRaisedButtonTextStyle.copyWith(fontSize: 15),)
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      child: TextField(
                        controller: songname,
                        decoration: InputDecoration(
                          hintText: "Enter song name",
                          hintStyle: kRaisedButtonTextStyle.copyWith(color: Colors.black45),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      child:
                      widget.isFromFriendScreen?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('to be shared with ${widget.friendUserModel.displayName}'),
                          SizedBox(width: 5,),
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: NetworkImage(widget.friendUserModel.userImageURL),
                          )
                        ],
                      ):
                      Column(
                        children: [
                          TextField(
                            controller: sharewithTextController,
                            onChanged: (value){
                              searchUserInDatabase(value);
                            },
                            decoration: InputDecoration(
                              hintText: "share with",
                              hintStyle: kRaisedButtonTextStyle.copyWith(color: Colors.black45),
                            ),
                          ),
                          searchResultsFuture == null ? Text('') : buildSearchResults(),
                        ],
                      ),
                    ),
                    RaisedButton(
                      onPressed: () => finalupload(context),
                      child: Text("Upload",style: kRaisedButtonTextStyle,),
                    ),
                  ],
                )
            ),
          ),
        ),
      );
    }
  }

  Widget buildSearchResults(){
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (_,snapshot){
        if(snapshot.hasData){
          List<User> searchUserModels=[];
          snapshot.data.documents.forEach((doc) {
            searchUserModels.add(User.fromFirebase(doc));
          });
          return Container(
            height: 150,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              itemCount: searchUserModels.length,
              itemBuilder: (context,index){
                return Container(
                  margin: EdgeInsets.all(4),
                  child: InkWell(
                    onTap: (){
                      setState(() {
                        songSharedBetween[1]=searchUserModels[index].displayName;
                        _tenantUid=searchUserModels[index].userUID;
                        _tenantPhotoURL=searchUserModels[index].userImageURL;
                        _tenantId=searchUserModels[index].userid;
                        sharewithTextController.text=songSharedBetween[1];
                        searchResultsFuture=null;
                        creategroupchatId();
                      });
                    },
                      child: UserTile(
                        email: searchUserModels[index].userid,
                        photoURL: searchUserModels[index].userImageURL,
                        name: searchUserModels[index].displayName
                      ),
                  ),
                );
              },
            ),
          );
        }
        else{
          return Text('No such Users');
        }
      },
    );
  }
}

class UserTile extends StatelessWidget {
  final String email;
  final String name;
  final String photoURL;
  UserTile({this.email,this.photoURL,this.name});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: ListTile(
        leading: CircleAvatar(radius: 20,backgroundImage: NetworkImage(photoURL),),
        title: Text(name),
        subtitle: Text(email),
      ),
    );
  }
}
