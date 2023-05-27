import 'package:flutter/material.dart';
import '../chat_list/bottom_button.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/blocs/blocs.dart';
import 'package:flutter_chat_app/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/blocs/user/user_bloc.dart';
import 'package:flutter_chat_app/screens/chat/chat_screen.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_chat_app/screens/chat_list/chat_list_screen.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:flutter_chat_app/call/call.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> setupOneSignal(int userId) async {
    await initOneSignal();
    registerOneSignalEventListener(
      onOpened: onOpened,
      onReceivedInForeground: onReceivedInForeground,
    );
    promptPolicyPrivacy(userId);
  }

  void onOpened(OSNotificationOpenedResult result) {
    vLog('NOTIFICATION OPENED HANDLER CALLED WITH: ${result}');
    vLog(
        "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}");

    try {
      final data = result.notification.additionalData;
      if (data != null) {
        final chatId = (data['data']['chatId'] as int);
        final chatBloc = context.read<ChatBloc>();
        final selectedChat = chatBloc.state.selectedChat;

        if (chatId != selectedChat?.id) {
          chatBloc.add(ChatNotificationOpened(chatId));
          Navigator.of(context).pushNamed(ChatScreen.routeName);
        }
      }
    } catch (_) {}
  }

  void onReceivedInForeground(OSNotificationReceivedEvent event) {
    vLog(
        "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}");
    final chatBloc = context.read<ChatBloc>();
    try {
      final data = event.notification.additionalData;
      final selectedChat = chatBloc.state.selectedChat;

      if (selectedChat != null && data != null) {
        vLog(data);
        final chatId = (data['data']['chatId'] as int);

        if (selectedChat.id == chatId) {
          event.complete(null);
          return;
        }
      }
      chatBloc.add(const ChatStarted());
      event.complete(event.notification);

      vLog(data);
    } catch (_) {
      event.complete(null);
    }
  }

  Future<void> promptPolicyPrivacy(int userId) async {
    final oneSignalShared = OneSignal.shared;

    bool userProvidedPrivacyConsent =
    await oneSignalShared.userProvidedPrivacyConsent();

    if (userProvidedPrivacyConsent) {
      sendUserTag(userId);
    } else {
      bool requiresConsent = await oneSignalShared.requiresUserPrivacyConsent();

      if (requiresConsent) {
        final accepted =
        await oneSignalShared.promptUserForPushNotificationPermission();
        if (accepted) {
          await oneSignalShared.consentGranted(true);
          sendUserTag(userId);
        }
      } else {
        sendUserTag(userId);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final currentUser = authBloc.state.user!;
    final chatBloc = context.read<ChatBloc>();
    final userBloc = context.read<UserBloc>();
    return Scaffold(
      body: FutureBuilder<List<String>>(

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {

            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // Show an error message if data retrieval fails
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            // Data retrieval successful, assign values to variables
            String username = currentUser.username;
            String email = currentUser.email;
            String phone = '##########';


            return Column(
              children: [
                 Expanded(flex: 2, child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 50),
                      decoration: const BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          )),
                    ),
                    // arrow back
                    Positioned(
                      top: 50,
                      left: 20,
                      child: IconButton(
                        hoverColor: Colors.pink,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(

                          Icons.arrow_back_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: 150,

                        height: 150,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                        'https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_960_720.png')),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  decoration: const BoxDecoration(
                                      color: Colors.green, shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          username,
                          style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            TextFormField(
                              initialValue: email,
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              initialValue: phone,
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                hintText: '$phone',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            );

          }
        },

      ),
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        height: 50,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10),
          ),
        ),
        child: Row(
          children:  [

            Spacer(),
          
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  ChatListScreen(),
                  ),
                );
              },
              child: BottomNavBarCustomIcon(
                iconUrl: 'assets/svg/send_symbol.svg',
                notifications: 0,
              ),
            ),

            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  CallScreen(),
                  ),
                );
              },
              child: BottomNavBarCustomIcon(
                iconUrl: 'assets/svg/call.svg',
                notifications: 0,
              ),
            ),
            Spacer(flex: 3),
            GestureDetector(
              onTap: () {
                InfoAlertBox(
                  context: context,
                  title: 'Coming Soon',
                  infoMessage: 'This feature is coming soon',
                  buttonColor: Colors.purple,
                  titleTextColor: Colors.purple,


                );

              },
              child:  BottomNavBarCustomIcon(
                iconUrl: 'assets/svg/Group_font_awesome.svg',
                notifications: 0,

              ),
            ),

            Spacer(),


            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  ProfilePage(),
                  ),
                );
              },
              child: BottomNavBarCustomIcon(
                iconUrl: 'assets/svg/person.svg',
                notifications: 0,
              ),
            ),




            Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Lottie.network(
          'https://raw.githubusercontent.com/F0rS3c/Assets/main/wired-outline-49-plus-circle.json',
          height: 50,
          width: 50,
        ),
        onPressed: () {
          //redirect to component group_form


        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );




  }



}

