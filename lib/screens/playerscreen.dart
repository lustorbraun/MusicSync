import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../home.dart';
import '../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

class PlayerScreen extends StatefulWidget {
  final String songName,
      artistName,
      songUrl,
      imageUrl,
      ownerUID,
      tenantUID,
      groupID,
      songID;
  PlayerScreen(
      {this.artistName,
        this.imageUrl,
        this.songName,
        this.songUrl,
        this.ownerUID,
        this.tenantUID,
        this.groupID,
        this.songID});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isplaying = false;
  AudioPlayer audioPlayer;
  Duration _sliderDuration,_songMilliseconds;
  bool _isPermissionGiven, _isBothOnBoard;
  DatabaseReference realTimeRef = FirebaseDatabase.instance.reference();
  final messageTextController = TextEditingController();
  String messageText;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _songMilliseconds=Duration(milliseconds: 0);
    _sliderDuration=Duration(milliseconds: 1);
    _handleLoadMusic();
    _isPermissionGiven = false;
    _isBothOnBoard = false;
    messageText = '';
    _makeRealTimeDataBase();
  }

  @override
  dispose() {
    super.dispose();
    audioPlayer.dispose();
    _setRealTimeDataBase();
  }

  _makeRealTimeDataBase() async {
    DataSnapshot doc = await realTimeRef
        .child('group-${widget.groupID}')
        .child('song-${widget.songID}')
        .once();
    if (doc == null) {
      _setRealTimeDataBase();
    }
  }

  _setRealTimeDataBase() {
    realTimeRef.child('group-${widget.groupID}').child('song-${widget.songID}').set({
      'owner Permission': false,
      'tenant Permission': false,
      'song playing': false,
      'song duration':0,
    });
    setState(() {});
  }

  _handleLoadMusic() async {
    await audioPlayer.play(widget.songUrl);
    audioPlayer.onDurationChanged.listen((Duration updatedDuration) {
      setState(() {
        _sliderDuration = updatedDuration;
      });
    });
    audioPlayer.onAudioPositionChanged.listen((updatedPosition) {
      setState(() {
        _songMilliseconds=updatedPosition;
      });
    });
    _handlePause();
  }

  _handlePlay() {
    audioPlayer.resume();
  }

  _handlePause() {
    audioPlayer.pause();
  }

  _handleSeeking(int newmilliseconds) {
    audioPlayer.seek(Duration(milliseconds: newmilliseconds));
  }

  _changePermissions(String whoisThis) {
    if (_isPermissionGiven == false) {
      realTimeRef
          .child('group-${widget.groupID}')
          .child('song-${widget.songID}')
          .update({
        '$whoisThis Permission': true,
      });
      setState(() {
        _isPermissionGiven = true;
      });
    } else {
      realTimeRef
          .child('group-${widget.groupID}')
          .child('song-${widget.songID}')
          .update({
        '$whoisThis Permission': false,
        'song playing': false,
      });
      setState(() {
        _isPermissionGiven = false;
        _isBothOnBoard = false;
      });
    }
  }

  _tooglePermission() {
    setState(() {
      _isplaying = false;
    });
    if (loggedinUser.userUID == widget.ownerUID) {
      _changePermissions('owner');
    } else if (loggedinUser.userUID != widget.ownerUID) {
      _changePermissions('tenant');
    }
  }

  _playonBothDevice() async{
    await realTimeRef
        .child('group-${widget.groupID}')
        .child('song-${widget.songID}')
        .update({
      'song playing': true,
      'song duration':_songMilliseconds.inMilliseconds
    });
    setState(() {
      _isplaying = true;
    });
  }

  _pauseonBothDevice() async{
    await realTimeRef
        .child('group-${widget.groupID}')
        .child('song-${widget.songID}')
        .update({
      'song playing': false,
      'song duration':_songMilliseconds.inMilliseconds
    });
    setState(() {
      _isplaying = false;
    });
  }

  addMessagestoFirebase() {
    messageTextController.clear();
    _firestore
        .collection("groups")
        .doc(widget.groupID)
        .collection('messages')
        .add({
      'text': messageText,
      'sender': loggedinUser.displayName,
      'time': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          elevation: 0,
          title: Text(widget.songName, overflow: TextOverflow.ellipsis),
          actions: <Widget>[
            StreamBuilder(
              stream: realTimeRef
                  .child('group-${widget.groupID}')
                  .child('song-${widget.songID}')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('');
                }
                DataSnapshot dataValues = snapshot.data.snapshot;
                Map<dynamic, dynamic> values = dataValues.value;
                _isBothOnBoard =
                ((values['owner Permission']) && (values['tenant Permission']));
                if (_isBothOnBoard) {
                  if (values['song playing']) {
                    _isplaying = true;
                    _handlePlay();
                  } else if (!values['song playing']) {
                    _isplaying = false;
                    _handlePause();
                    _handleSeeking(values['song duration']);
                  }
                }
                return Row(
                  children: [
                    (_isBothOnBoard)
                        ? (_isplaying
                        ? IconButton(
                        icon: Icon(
                          Icons.pause,
                          size: 20,
                        ),
                        onPressed: _pauseonBothDevice)
                        : IconButton(
                        icon: Icon(
                          Icons.play_arrow,
                        ),
                        onPressed: _playonBothDevice))
                        : Text(''),
                    _isPermissionGiven
                        ? FlatButton(
                        child: Text('Turn Sync Off',style: TextStyle(color: Colors.red),), onPressed: _tooglePermission)
                        : FlatButton(
                        child: Text('Turn Sync On',style: TextStyle(color: Colors.green),), onPressed: _tooglePermission),
                    CircleAvatar(
                      backgroundColor: _isBothOnBoard ? Colors.green : Colors.red,
                      radius: 5,
                    ),
                    SizedBox(
                      width: 10,
                    )
                  ],
                );
              },
            ),
          ]),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueGrey, Colors.black54],
            ),
          ),
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MessagesStream(
                      groupChatId: widget.groupID,
                    ),
                    Card(
                      color: Colors.black.withOpacity(.9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: messageTextController,
                              maxLines: 3,
                              minLines: 1,
                              onChanged: (value) {
                                messageText = value.trim();
                              },
                              decoration: kMessageTextFieldDecoration,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () {
                              if (messageText.isNotEmpty) {
                                addMessagestoFirebase();
                                setState(() {
                                  messageText = '';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: _isBothOnBoard?MediaQuery.of(context).size.height * .18:MediaQuery.of(context).size.height * .24,
                child: Card(
                  color: Colors.white.withOpacity(.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(100),
                  )),
                  child: Column(
                            children: <Widget>[
                              Slider(
                                value: _songMilliseconds.inMilliseconds
                                    .floorToDouble(),
                                max: _sliderDuration.inMilliseconds.toDouble(),
                                min: 0,
                                onChanged: (newPosition) {
                                  _handleSeeking(newPosition.toInt());
                                },
                                activeColor: Colors.deepOrange,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('     ${_songMilliseconds.toString().split('.').first}'),
                                  Text("${_sliderDuration.toString().split('.').first}     "),
                                ],
                              ),
                              _isBothOnBoard
                                  ? Text('')
                                  : buildOfflinePlayerControls(_songMilliseconds),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOfflinePlayerControls(Duration _currentPosition) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            audioPlayer.seek(Duration(seconds: _currentPosition.inSeconds-10));
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepOrange,
            child: Icon(
              Icons.fast_rewind,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _isplaying ? _handlePause() : _handlePlay();
            setState(() {
              _isplaying = !_isplaying;
            });
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepOrange,
            child: Icon(
              _isplaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            audioPlayer.seek(Duration(seconds: _currentPosition.inSeconds+10));
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepOrange,
            child: Icon(
              Icons.fast_forward,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class MessagesStream extends StatelessWidget {
  final String groupChatId;
  MessagesStream({@required this.groupChatId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("groups")
          .doc(groupChatId)
          .collection('messages')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.data()['text'];
          final messageSender = message.data()['sender'];

          final currentUser = loggedinUser.displayName;

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
