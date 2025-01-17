import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_chat/Screens/view%20profile%20screen.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/widget/message_card.dart';
import '../Api/APi.dart';
import '../helper/mydateuntil.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreenController extends GetxController {
  //for storing all messages
  List<Message> _list = [];
  //for handling message text changes
  final _textController = TextEditingController();
  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;
}

class ChatScreen extends StatelessWidget {
  final ChatUser users;
  const ChatScreen({Key? key, required this.users,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =Get.put(ChatScreenController()); // Initialize controller

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          //if emojis are shown & back button is pressed then hide emojis
          //or else simple close current screen on back button click
          onWillPop: () {
            if (controller._showEmoji) {
              controller._showEmoji = !controller._showEmoji;
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(context),
            ),
            backgroundColor: const Color.fromARGB(255, 234, 248, 255),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(users),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                      //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                      //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          controller._list = data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                              [];
                          if (controller._list.isNotEmpty) {
                            return ListView.builder(
                              reverse: true,
                              itemCount: controller._list.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return MessageCard(
                                  message: controller._list[index],
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: const Text(
                                'Say hii👋',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),
                //progress indicator for showing uploading
                /*Obx(() =>*/ controller._isUploading
                    ? const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 8, horizontal: 20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : const SizedBox()/*)*/,

                //chat input filed
                _chatInput(context, controller),
                //show emojis on keyboard emoji button click & vice versa
                if (controller._showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: controller._textController,
                      config: Config(
                        bgColor: const Color.fromARGB(255, 234, 248, 255),
                        columns: 8,
                        emojiSizeMax: 32 *
                            (Platform.isIOS ? 1.30 : 1.0), // Adjust as needed
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(()=> ViewProfileScreen(user: users));

      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(users),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list = data
              ?.map((e) => ChatUser.fromJson(e.data()))
              .toList() ??
              [];

          return Row(
            children: [
              //back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
              ),

              //user profile picture
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .03),
                child: CachedNetworkImage(
                  width: mq.height * .05,
                  height: mq.height * .05,
                  imageUrl: list.isNotEmpty ? list[0].image : users.image,
                  errorWidget: (context, url, error) => const CircleAvatar(
                    child: Icon(CupertinoIcons.person),
                  ),
                ),
              ),

              //for adding some space
              const SizedBox(width: 10),

              //user name & last seen time
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //user name
                  Text(
                    list.isNotEmpty ? list[0].name : users.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  //for adding some space
                  const SizedBox(height: 2),

                  //last seen time of user
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                        ? 'Online'
                        : MyDateUtil.getLastActiveTime(
                        context: context,
                        lastActive: list[0].lastActive)
                        : MyDateUtil.getLastActiveTime(
                      context: context,
                      lastActive: users.lastActive,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _chatInput(BuildContext context, ChatScreenController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * .01,
        horizontal: mq.width * .025,
      ),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      controller._showEmoji = !controller._showEmoji;
                    },
                    icon: Icon(Icons.emoji_emotions, color: Colors.blueAccent),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller._textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (controller._showEmoji) controller._showEmoji = false;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  //pick image from gallery button
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      // Picking multiple images
                      final List<XFile>? images =
                      await picker.pickMultiImage(imageQuality: 70);

                      // uploading & sending image one by one
                      if (images != null) {
                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          controller._isUploading = true;
                          await APIs.sendChatImage(users, File(i.path));
                          controller._isUploading = false;
                        }
                      }
                    },
                    icon: Icon(Icons.image, color: Colors.blueAccent),
                  ),
                  //take image from camera button
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      // Pick an image
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        log('Image Path: ${image.path}');
                        controller._isUploading = true;
                        await APIs.sendChatImage(users, File(image.path));
                        controller._isUploading = false;
                      }
                    },
                    icon: Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
                  ),
                  //adding some space
                  SizedBox(width: mq.width * .02),
                ],
              ),
            ),
          ),
          //send message button
          MaterialButton(
            onPressed: () {
              if (controller._textController.text.isNotEmpty) {
                APIs.sendMessage(users, controller._textController.text, Type.text);
                controller._textController.text = "";
              }
            },
            minWidth: 0,
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: Colors.green,
            child: const Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }
}


/*

class ChatScreen extends StatefulWidget {
  final ChatUser users;
  const ChatScreen({super.key, required this.users});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Message> _list =[];
  //for handling message text changes
  final _textController = TextEditingController();
  //showEmoji -- for storing value of showing or hiding emoji
  //isUploading -- for checking if image is uploading or not?
  bool _showEmoji = false, _isUploading = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          //if emojis are shown & back button is pressed then hide emojis
          //or else simple close current screen on back button click
          onWillPop: () {
            if (_showEmoji) {
              setState(() => _showEmoji = !_showEmoji);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,

              flexibleSpace: _appBar(),
            ),
            backgroundColor: const Color.fromARGB(255, 234, 248, 255),
            body: Column(
              children: [Expanded(child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.users),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                    //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const SizedBox();
          
                    //if some or all data is loaded then show it
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list=data
                            ?.map((e) => Message.fromJson(e.data()))
                            .toList() ??
                            [];
                         if (_list.isNotEmpty){
                        return ListView.builder(
                            reverse: true,
                            itemCount:  _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return MessageCard(message: _list[index]);

                            });
                       }else{
                         return Center(child: const Text('Say hii👋',style: TextStyle(fontSize: 20),));
                       }
                    }
                  })),
                //progress indicator for showing uploading
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(strokeWidth: 2))),

                //chat input filed
                _chatInput(),
                //show emojis on keyboard emoji button click & vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        bgColor: const Color.fromARGB(255, 234, 248, 255),
                        columns: 8,
                        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _appBar(){
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(user: widget.users)));
        },
        child: StreamBuilder(
            stream: APIs.getUserInfo(widget.users),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

              return Row(
                children: [
                  //back button
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                      const Icon(Icons.arrow_back, color: Colors.black54)),

                  //user profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      width: mq.height * .05,
                      height: mq.height * .05,
                      imageUrl:
                      list.isNotEmpty ? list[0].image : widget.users.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),

                  //for adding some space
                  const SizedBox(width: 10),

                  //user name & last seen time
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //user name
                      Text(list.isNotEmpty ? list[0].name : widget.users.name,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500)),

                      //for adding some space
                      const SizedBox(height: 2),

                      //last seen time of user
                      Text(
                          list.isNotEmpty
                              ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: list[0].lastActive)
                              : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.users.lastActive),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  )
                ],
              );
            }));
  }
  Widget _chatInput(){
    return Padding(
        padding: EdgeInsets.symmetric(
        vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                //emoji button
                IconButton(onPressed: (){
                  FocusScope.of(context).unfocus();
                  setState(() => _showEmoji = !_showEmoji);
                }, icon: Icon(Icons.emoji_emotions,color: Colors.blueAccent,)),
                Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji)
                          setState(() =>
                          _showEmoji = !_showEmoji);
                      },
                      decoration: const InputDecoration(
                          hintText: 'Type Something...',
                          hintStyle: TextStyle(color: Colors.blueAccent),
                          border: InputBorder.none),
                    )),
                //pick image from gallery button
                IconButton(onPressed: () async {
                  final ImagePicker picker = ImagePicker();

                  // Picking multiple images
                  final List<XFile> images =
                      await picker.pickMultiImage(imageQuality: 70);

                  // uploading & sending image one by one
                  for (var i in images) {
                    log('Image Path: ${i.path}');
                    setState(() => _isUploading = true);
                    await APIs.sendChatImage(widget.users, File(i.path));
                    setState(() => _isUploading = false);
                  }
                }, icon: Icon(Icons.image,color: Colors.blueAccent,)),
                //take image from camera button
                IconButton(onPressed: () async {
                  final ImagePicker picker = ImagePicker();

                  // Pick an image
                  final XFile? image = await picker.pickImage(
                      source: ImageSource.camera, imageQuality: 70);
                  if (image != null) {
                    log('Image Path: ${image.path}');
                    setState(() => _isUploading = true);

                    await APIs.sendChatImage(
                        widget.users, File(image.path));
                    setState(() => _isUploading = false);
                  }
                }, icon: Icon(Icons.camera_alt_rounded,color: Colors.blueAccent,)),
                //adding some space
                SizedBox(width: mq.width * .02),
              ],
            ),
          ),
        ),
          //send message button
        MaterialButton(
          onPressed: (){
    if (_textController.text.isNotEmpty) {
      APIs.sendMessage(widget.users,_textController.text,Type.text);
      _textController.text="";
    }
          },
          minWidth: 0,
          padding:
          const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
          shape: const CircleBorder(),
          color: Colors.green,
          child: const Icon(Icons.send, color: Colors.white, size: 28),
        )
        ],

      ),
    );

  }
}
*/
