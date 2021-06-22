import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musicsyncreal/models/user_model.dart';

final auth.FirebaseAuth _auth =auth.FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersRef=FirebaseFirestore.instance.collection('users');

Future<User> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount=await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;
  final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
    idToken: googleSignInAuthentication.idToken,
    accessToken: googleSignInAuthentication.accessToken
  );

  final auth.UserCredential authResult = await _auth.signInWithCredential(credential);
  final auth.User user = authResult.user;

  assert(!user.isAnonymous);
  assert(await user.getIdToken()!=null);

  final auth.User currentUser= _auth.currentUser;
  assert(currentUser.uid==user.uid);

  usersRef.doc(user.uid).set({
   'userID':user.email,
   'userUID':user.uid,
   'userImageURL':user.photoURL,
   'displayName':user.displayName,
  });

  User currentUserModel=User(
    userUID: user.uid,
    userImageURL: user.photoURL,
    userid: user.email,
    displayName: user.displayName,
  );

  return currentUserModel;
}

void signOutGoogle() async{
  await googleSignIn.signOut();
}