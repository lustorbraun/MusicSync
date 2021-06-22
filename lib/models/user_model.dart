import 'package:cloud_firestore/cloud_firestore.dart';

class User{
  String userid;
  String userImageURL;
  String userUID;
  String displayName;

  User({this.userid,this.userImageURL,this.userUID,this.displayName});

  factory User.fromFirebase(DocumentSnapshot doc){
    return User(
      userid: doc.data()['userID'],
      userImageURL: doc.data()['userImageURL'],
      userUID: doc.data()['userUID'],
      displayName: doc.data()['displayName']
    );
  }
}