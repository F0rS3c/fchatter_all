import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'size_config.dart';
import 'constants.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';


const String appId = "";

void main() => runApp(const MaterialApp(home: CallScreen()));

class CallScreen extends StatefulWidget {
  const CallScreen({Key? key}) : super(key: key);
  static const routeName = "call";


  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool flag = true;
  Stream<int> timerStream = StreamController<int>.broadcast().stream;
  StreamSubscription<int>? timerSubscription = null;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';
  Stream<int> stopWatchStream() {
    StreamController<int> streamController;
    Timer timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void stopTimer() {
      Timer? timer; // Declare 'timer' as nullable Timer type
      int counter = 0; // Initialize 'counter' with a value

      if (timer != null) {
        timer.cancel();
        timer = null;
        counter = 0;
      }

      StreamController<int>? streamController; // Declare 'streamController' as nullable StreamController<int> type

      if (streamController != null) {
        streamController.close();
      }
    }


    void tick(_) {
      counter++;

      StreamController<int>? streamController; // Declare 'streamController' as nullable StreamController<int> type

      if (streamController != null) {
        streamController.add(counter);
        if (!flag) {
          stopTimer();
        }
      }
    }


    void startTimer() {
      timer = Timer.periodic(timerInterval, tick);
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onResume: startTimer,
      onPause: stopTimer,
    );

    return streamController.stream;
  }


  String channelName = "fchatter";
  String token ="007eJxTYHg6dyHbHgdpO5++x2nLmyylJi1+Ub1RQa2Fp3y7/55l5VcVGIwsUg0TLQyNLVPT0kyMU0wsjE0NzBJNDQ2STIzMLS0SFwflpTQEMjKkzNBnYmSAQBCfgyEtOSOxpCS1iIEBAJEcH9E=";

  late dynamic arguments;
  late int currentUser;
  late int selectedUser ;
  late String selectedUserName = "" ;
  int uid = 0; // uid of the local user
  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
  bool _isCall = false; // Indicates if the local user is muted
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey
  = GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
  // Build UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(

        body: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.asset(
              "assets/images/bg.jpg",
              fit: BoxFit.cover,
            ),
            // Black Layer
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$selectedUserName",
                      style: Theme.of(context)
                          .textTheme
                          .headline3
                          ?.copyWith(color: Colors.white),
                    ),
                        Container(
                          height: 40,
                          child: Center(child: _status()),
                        ),
                    VerticalSpacing(of: 10),

                    Spacer(),
                    Center(
                      child: Visibility(

                        child:
                      Text(
                        "$hoursStr:$minutesStr:$secondsStr",
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Colors.white,

                        ),
                      ),
                      )
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Visibility(
                          child: SizedBox(
                            height: 60,
                            width: 60,
                            child: TextButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.all(15 / 64 * 64),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                  ),
                                ),
                                backgroundColor: MaterialStateProperty.all(kGreenColor),
                              ),
                              onPressed: () {
                                join();

                                timerStream = stopWatchStream();
                                timerSubscription = timerStream.listen((int newTick) {
                                  setState(() {
                                    _isCall = true;
                                    hoursStr = ((newTick / (60 * 60)) % 60)
                                        .floor()
                                        .toString()
                                        .padLeft(2, '0');
                                    minutesStr = ((newTick / 60) % 60)
                                        .floor()
                                        .toString()
                                        .padLeft(2, '0');
                                    secondsStr =
                                        (newTick % 60).floor().toString().padLeft(2, '0');
                                  });
                                });
                              },
                              //icon flutter
                              child: Icon(
                                Icons.call,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                EdgeInsets.all(15 / 64 * 64),
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(100)),
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all(kRedColor),
                            ),
                            onPressed: () {
                              leave();
                              setState(() {
                              });
                            },
                            //icon flutter
                            child: Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                          ),
                        ),





                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

      ),
      debugShowCheckedModeBanner: false,
    );

  }

  Widget _status(){
    String statusText;

    if (!_isJoined)
      statusText = 'Join a channel';
    else if (_remoteUid == null)
      statusText = 'Waiting for a remote user to join...';
    else
      statusText = 'Connected to remote user, uid:$_remoteUid';

    return Text(
      statusText,
    );
  }
  @override
  void initState() {
    super.initState();
    // Set up an instance of Agora engine
    setupVoiceSDKEngine();
    Future.delayed(Duration.zero, () {
      arguments = ModalRoute.of(context)!.settings.arguments;
      currentUser = arguments["currentUser"];
      selectedUser = arguments["selectedUser"];
      selectedUserName = arguments["selectedUserName"];


      uid = currentUser;
      _remoteUid = selectedUser;

      print("currentUser: $uid");
      print("selectedUser: $_remoteUid");
      print("selectedUserName: $selectedUserName");


    });
  }
  Future<void> setupVoiceSDKEngine() async {
    // retrieve or request microphone permission
    await [Permission.microphone].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(const RtcEngineContext(
        appId: appId
    ));

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage("Local user uid:${connection.localUid} joined the channel");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
  }
  void  join() async {

    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }
  void leave() {
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    agoraEngine.leaveChannel();
  }
// Clean up the resources when you leave
  @override
  void dispose() async {
    await agoraEngine.leaveChannel();
    super.dispose();
  }




}




















