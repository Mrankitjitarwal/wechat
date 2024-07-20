import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:we_chat/Screens/profile%20Screen.dart';
import 'package:we_chat/widget/chat%20user%20card.dart';

import '../Api/APi.dart';
import '../helper/dialogs.dart';
import '../models/chat_user.dart';

class HomeScreenController extends GetxController {
  // for storing all users
  List<ChatUser> list = [];
  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  RxBool isSearching = false.obs;

  void toggleSearch() {
    isSearching.toggle();
  }

  @override
  void onInit() {
    super.onInit();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });

  }
}

class HomeScreen extends GetView<HomeScreenController> {
  final HomeScreenController homeController = Get.put(HomeScreenController(),permanent: true);

  HomeScreen({super.key});
  @override
  void dispose() {

    homeController.dispose();
    SystemNavigator.pop(); // Close the app

  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope (
        onWillPop: () {
          if (homeController.isSearching.value) {
            homeController.toggleSearch();
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: Obx(() => homeController.isSearching.value
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email, ...',
              ),
              autofocus: true,
              style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
    //when search text changes then updated search list
    onChanged: (val) {
    //search logic
    homeController._searchList.clear();

         for (var i in homeController.list) {
          if (i.name.toLowerCase().contains(val.toLowerCase()) ||
        i.email.toLowerCase().contains(val.toLowerCase())) {
         homeController._searchList.add(i);
           homeController._searchList;

               }}})
                : const Text('We Chat')),
            actions: [
              Obx(() =>   IconButton(
                onPressed: () {
                  homeController.toggleSearch();
                },
                icon: Icon(homeController.isSearching.value
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search),
              ),),
                 IconButton(
                onPressed: () {
                  if (homeController.list.isNotEmpty) {
                    Get.to(() => ProfileScreen(users: APIs.me));
                  }
                },
                icon: const Icon(Icons.person),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog(context);
              },
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(snapshot.data?.docs
                        .map((e) => e.id)
                        .toList() ??
                        []),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(child: CircularProgressIndicator());
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          homeController.list = data
                              ?.map((e) => ChatUser.fromJson(e.data()))
                              .toList() ??
                              [];
                          return ListView.builder(
                            itemCount: homeController.isSearching.value
                                ? homeController._searchList.length
                                : homeController.list.length,
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ChatUserCard(
                                user: homeController.isSearching.value
                                    ? homeController._searchList[index]
                                    : homeController.list[index],
                              );
                            },
                          );
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void _addChatUserDialog(BuildContext context) {
    String email = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding:
        const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.blue,
              size: 28,
            ),
            Text('  Add User')
          ],
        ),
        content: TextFormField(
          maxLines: null,
          onChanged: (value) => email = value,
          decoration: InputDecoration(
            hintText: 'Email Id',
            prefixIcon: const Icon(Icons.email, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
          MaterialButton(
            onPressed: () async {
              Navigator.pop(context);
              if (email.isNotEmpty) {
                await APIs.addChatUser(email).then((value) {
                  if (!value) {
                    Dialogs.showSnackbar(context, 'User does not Exists!');
                  }
                });
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}

/*

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> list = [];
  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;


  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }
  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
        //for hiding keyboard when a tap is detected on screen
        onTap: () => FocusScope.of(context).unfocus(),
    child: WillPopScope(
    //if search is on & back button is pressed then close search
    //or else simple close current screen on back button click
    onWillPop: () {
    if (_isSearching) {
    setState(() {
    _isSearching = !_isSearching;
    });
    return Future.value(false);
    } else {
    return Future.value(true);
    }
    },
      child: Scaffold(
        appBar: AppBar(
          //Appbar
          leading: const Icon(CupertinoIcons.home),
          title: _isSearching
              ? TextField(
            decoration: const InputDecoration(
                border: InputBorder.none, hintText: 'Name, Email, ...'),
            autofocus: true,
            style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
            //when search text changes then updated search list
            onChanged: (val) {
              //search logic
              _searchList.clear();

              for (var i in list) {
                if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                    i.email.toLowerCase().contains(val.toLowerCase())) {
                  _searchList.add(i);
                  setState(() {
                    _searchList;
                  });
                }
              }
            },
          )
              : const Text('We Chat'),
          actions: [
            //Search Button
            IconButton(
            onPressed: () {
      setState(() {
      _isSearching = !_isSearching;
      });
      },
          icon: Icon(_isSearching
              ? CupertinoIcons.clear_circled_solid
              : Icons.search)),


            //More feature button to add new user
            IconButton(onPressed: (){
              if (list.isNotEmpty) {
                print("object");
                Navigator.push(
                  context,
                  MaterialPageRoute(

                    builder: (_) => ProfileScreen(users: APIs.me),
                  ),
                );
              } else {
                // Handle the case when the list is empty
                // You can show a message or perform some other action
              }
            }, icon: const Icon(Icons.more_vert),
            )
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
            onPressed: (){
              _addChatUserDialog();
            },child: const Icon(Icons.add_comment_rounded),
          ),
        ),
        body: StreamBuilder(
      stream: APIs.getMyUsersId(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
    //if data is loading
    case ConnectionState.waiting:
    case ConnectionState.none:
    return const Center(child: CircularProgressIndicator());

    //if some or all data is loaded then show it
    case ConnectionState.active:
    case ConnectionState.done:
    return StreamBuilder(
    stream: APIs.getAllUsers(
    snapshot.data?.docs.map((e) => e.id).toList() ?? []),

    //get only those user, who's ids are provided
    builder: (context, snapshot) {
    switch (snapshot.connectionState) {
    //if data is loading
    case ConnectionState.waiting:
    case ConnectionState.none:
    // return const Center(
    //     child: CircularProgressIndicator());

    //if some or all data is loaded then show it
    case ConnectionState.active:
    case ConnectionState.done:
    final data = snapshot.data?.docs;
    list=data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
    return ListView.builder(
    itemCount: _isSearching ? _searchList.length:list.length,
    padding: EdgeInsets.only(top: mq.height * .01),
    physics: const BouncingScrollPhysics(),
    itemBuilder: (context, index) {
    return ChatUserCard(user:
    _isSearching?_searchList[index]
        :list[index],);
    // print("Name:${_list[index]}");
    // return Text('Name:${_list[index]}');
    });
    }
    });
    }}),
    ) ));
    }
  // for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 10),

          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),

          //title
          title: Row(
            children: const [
              Icon(
                Icons.person_add,
                color: Colors.blue,
                size: 28,
              ),
              Text('  Add User')
            ],
          ),

          //content
          content: TextFormField(
            maxLines: null,
            onChanged: (value) => email = value,
            decoration: InputDecoration(
                hintText: 'Email Id',
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15))),
          ),

          //actions
          actions: [
            //cancel button
            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                },
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.blue, fontSize: 16))),

            //add button
            MaterialButton(
                onPressed: () async {
                  //hide alert dialog
                  Navigator.pop(context);
                  if (email.isNotEmpty) {
                    await APIs.addChatUser(email).then((value) {
                      if (!value) {
                        Dialogs.showSnackbar(
                            context, 'User does not Exists!');
                      }
                    });
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ))
          ],
        ));
  }
    }
*/
