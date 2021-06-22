import 'package:flutter/material.dart';
import '../components/auth.dart';
import '../components/rounded_button.dart';

import '../home.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('MusicSync',style: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.w900,),),
              ],
            ),
            SizedBox(
              height: 48.0,
            ),
            _isLoading?CircularProgressIndicator():
            RoundedButton(
                title: 'Log In with google',
                colour: Colors.lightBlueAccent,
                onPressed: (){
                  setState(() {
                    _isLoading=true;
                  });
                 signInWithGoogle().then((user){
                 Navigator.push(context,MaterialPageRoute(builder: (context){
                 return HomePage(
                   currentUser: user,
                 );
                 }));
                 });
                  setState(() {
                    _isLoading=false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
