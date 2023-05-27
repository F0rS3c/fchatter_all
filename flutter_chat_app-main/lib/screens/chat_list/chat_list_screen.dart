import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/blocs/blocs.dart';
import 'package:flutter_chat_app/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/blocs/user/user_bloc.dart';
import 'package:flutter_chat_app/cubits/cubits.dart';
import 'package:flutter_chat_app/models/models.dart';
import 'package:flutter_chat_app/screens/chat/chat_screen.dart';
import 'package:flutter_chat_app/screens/chat_list/chat_list_item.dart';
import 'package:flutter_chat_app/screens/guest/guest_screen.dart';
import 'package:flutter_chat_app/utils/utils.dart';
import 'package:flutter_chat_app/widgets/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:search_page/search_page.dart';
import 'package:flutter_chat_app/screens/chat_list/bottom_button.dart';
import 'package:flutter_chat_app/screens/profile/profile.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static const routeName = "chat-list";

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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

    return StartUpContainer(
      onInit: () async {
        chatBloc.add(const ChatStarted());
        userBloc.add(const UserStarted());

        LaravelEcho.init(token: authBloc.state.token!);
        setupOneSignal(authBloc.state.user!.id);
      },
      onDisposed: () {
        LaravelEcho.instance.disconnect();
      },
      child: Scaffold(
        appBar: AppBar(

          actions: [
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (!state.isAuthenticated) {
                  deleteUserTag();
                  Navigator.of(context)
                      .pushReplacementNamed(GuestScreen.routeName);
                }
              },
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    context.read<GuestCubit>().signOut();
                  },
                  icon: const Icon(Icons.logout),
                );
              },
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            chatBloc.add(const ChatStarted());
            userBloc.add(const UserStarted());
          },
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (_, __) {},
            builder: (context, state) {
              if (state.chats.isEmpty) {
                return const BlankContent(
                  content: "No chat available",
                  icon: Icons.chat_rounded,
                );
              }

              return ListView.separated(
                itemBuilder: (context, index) {
                  final item = state.chats[index];

                  return ChatListItem(
                    key: ValueKey(item.id),
                    item: item,
                    currentUser: currentUser,
                    onPressed: (chat) {
                      chatBloc.add(ChatSelected(chat));
                      Navigator.of(context).pushNamed(ChatScreen.routeName);
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(
                  height: 1.5,
                ),
                itemCount: state.chats.length,
              );
            },
          ),
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
              BlocConsumer<ChatBloc , ChatState>(
                  listener: (_, __) {},
                  builder: (context, state) {
                    int itemco = state.chats.length;
                    if (state.chats.length == 0) {
                      return  BottomNavBarCustomIcon(

                        iconUrl: 'assets/svg/send_symbol.svg',
                        isActive: false,
                        notifications: 0,


                      );
                    }
                    else{
                      return  BottomNavBarCustomIcon(

                        iconUrl: 'assets/svg/send_symbol.svg',
                        isActive: true,
                        notifications: itemco,

                      );
                    }
                  }),



              Spacer(),
              BottomNavBarCustomIcon(
                iconUrl: 'assets/svg/call.svg',
                notifications: 0,
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
        floatingActionButton:
            BlocSelector<UserBloc, UserState, List<UserEntity>>(
          selector: (state) {
            return state.map(
              initial: (_) => [],
              loaded: (state) => state.users,
            );
          },
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () => _showSearch(context, state),
              backgroundColor: Colors.white,
              child: Lottie.network(
                'https://raw.githubusercontent.com/F0rS3c/Assets/main/wired-outline-49-plus-circle.json',
                height: 50,
                width: 50,
              ),
            );
          },
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),

    );
  }

  void _showSearch(BuildContext context, List<UserEntity> users) {
    showSearch(
      context: context,
      delegate: SearchPage<UserEntity>(
        items: users,
        searchLabel: 'Search people',
        suggestion: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.search,
                size: 25.0,
                color: Colors.grey,
              ),
              Text(
                'Search users by username',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        failure: const Center(
          child: Text(
            'No person found :(',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
        filter: (user) => [
          user.email,
        ],
        builder: (user) => ListTile(
          leading: const Icon(Icons.account_circle, size: 50.0),
          title: Text(user.username),
          subtitle: Text(user.email),
          onTap: () {
            /// selected user
            context.read<ChatBloc>().add(UserSelected(user));

            /// push to chat screen
            Navigator.of(context).pushNamed(ChatScreen.routeName);
          },
        ),
      ),
    );
  }
}
