import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

import '../models/chat_user.dart';
import '../models/message.dart';

class APIs {
   // for authentication
   static FirebaseAuth auth = FirebaseAuth.instance;

   // for accessing cloud firestore database
   static FirebaseFirestore firestore = FirebaseFirestore.instance;

   // for accessing firebase storage
   static FirebaseStorage storage = FirebaseStorage.instance;
   // for accessing firebase messaging (Push Notification)
   static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

   // for getting firebase messaging token
   static Future<void> getFirebaseMessagingToken() async {
      await fMessaging.requestPermission();

      await fMessaging.getToken().then((t) {
         if (t != null) {
            me.pushToken = t;
            log('Push Token: $t');
         }
      });

      // for handling foreground messages
       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
         log('Got a message whilst in the foreground!');
         log('Message data: ${message.data}');

         if (message.notification != null) {
           log('Message also contained a notification: ${message.notification}');
         }
       });
   }
   // for sending push notification
   static Future<void> sendPushNotification(
       ChatUser chatUser, String msg) async {
      try {
         final body = {
            "to": chatUser.pushToken,
            "notification": {
               "title": me.name, //our name should be send
               "body": msg,
               "android_channel_id": "chats"
            },
             "data": {
              "some_data": "User ID: ${me.id}",
             },
         };

         var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
             headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader:
                'key=AAAAz7vDgtw:APA91bEe5psMx8v-nQOGkuaLd7-Rfvcvwua0nkv3IEHWhiRd5PnXZQ9alYJ97ArU7ZmD1ZunboTDfvcZQaHRJ3FbhZyLZnowlKmLDkuvC0TEIEkFWElzmV7PnhgBWwHCckiNqW3dY_qP'
             },
             body: jsonEncode(body));
         log('Response status: ${res.statusCode}');
         log('Response body: ${res.body}');
      } catch (e) {
         log('\nsendPushNotificationE: $e');
      }
   }

   // for checking if user exists or not?
   static Future<bool> userExists() async {
      return (await firestore
          .collection('user')
          .doc(users.uid)
          .get())
          .exists;
   }
   // for adding an chat user for our conversation
   static Future<bool> addChatUser(String email) async {
      final data = await firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      log('data: ${data.docs}');

      if (data.docs.isNotEmpty && data.docs.first.id != users.uid) {
         //user exists

         log('user exists: ${data.docs.first.data()}');

         firestore
             .collection('user')
             .doc(users.uid)
             .collection('my_users')
             .doc(data.docs.first.id)
             .set({});

         return true;
      } else {
         //user doesn't exists

         return false;
      }
   }

   static User get users => auth.currentUser!;
   static ChatUser me = ChatUser(
       id: users.uid,
       name: users.displayName.toString(),
       email: users.email.toString(),
       about: "Hey, I'm using We Chat!",
       image: users.photoURL.toString(),
       createdAt: '',
       isOnline: false,
       lastActive: '',
       pushToken: '');



   static Future<void> createuser() async {
      final time = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final chatUsers = ChatUser(
          id: users.uid,
          name: users.displayName.toString(),
          email: users.email.toString(),
          about: "Hey, I'm using We Chat!",
          image: users.photoURL.toString(),
          createdAt: time,
          isOnline: false,
          lastActive: time,
          pushToken: '');
      return await firestore
          .collection('user')
          .doc(users.uid)
          .set(chatUsers.toJson());
   }

   // for getting current user info
     static Future<void> getSelfInfo() async {
      await firestore.collection('user').doc(users.uid).get().then((users) async {
         if (users.exists) {
            me = ChatUser.fromJson(users.data()!);
            await getFirebaseMessagingToken();

            //for setting user status to active
            APIs.updateActiveStatus(true);
            log('My Data: ${users.data()}');
         } else {
            await createuser().then((value) => getSelfInfo());
         }
      });
   }
   // for getting id's of known users from firestore database
   static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
      return firestore
          .collection('user')
          .doc(users.uid)
          .collection('my_users')
          .snapshots();
   }
   // for getting all users from firestore database
   static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
       List<String> userIds) {
      log('\nUserIds: $userIds');

      return firestore
          .collection('user')
          .where('id',
          whereIn: userIds.isEmpty
              ? ['']
              : userIds) //because empty list throws an error
      // .where('id', isNotEqualTo: user.uid)
          .snapshots();
   }

// for adding an user to my user when first message is send
   static Future<void> sendFirstMessage(
       ChatUser chatUser, String msg, Type type) async {
      await firestore
          .collection('user')
          .doc(chatUser.id)
          .collection('my_users')
          .doc(users.uid)
          .set({}).then((value) => sendMessage(chatUser, msg, type));
   }


   // for updating user information
   static Future<void> updateUserInfo() async {
      await firestore.collection('user').doc(users.uid).update({
         'name': me.name,
         'about': me.about,
      });
   }
   // update profile picture of user
   static Future<void> updateProfilePicture(File file) async {
      //getting image file extension
      final ext = file.path
          .split('.')
          .last;
      log('Extension: $ext');

      //storage file ref with path
      final ref = storage.ref().child('profile_pictures/${users.uid}.$ext');

      //uploading image
      await ref
          .putFile(file, SettableMetadata(contentType: 'image/$ext'))
          .then((p0) {
         log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
      });

      //updating image in firestore database
      me.image = await ref.getDownloadURL();
      await firestore
          .collection('user')
          .doc(users.uid)
          .update({'image': me.image});
   }

   // for getting specific user info
   static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
       ChatUser chatUser) {
      return firestore
          .collection('user')
          .where('id', isEqualTo: chatUser.id)
          .snapshots();
   }

   // update online or last active status of user
   static Future<void> updateActiveStatus(bool isOnline) async {
      firestore.collection('user').doc(users.uid).update({
         'is_online': isOnline,
         'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
         'push_token': me.pushToken,
      });
   }
   ///************** Chat Screen Related APIs **************

// chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)

   // useful for getting conversation id
   static String getConversationID(String id) =>
       users.uid.hashCode <= id.hashCode
           ? '${users.uid}_$id'
           : '${id}_${users.uid}';

   // for getting all messages of a specific conversation from firestore database
   static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
       ChatUser users) {
      return firestore
          .collection('chats/${getConversationID(users.id)}/messages/')
          .orderBy('sent', descending: true)
          .snapshots();
   }

   // for sending message
   static Future<void> sendMessage(ChatUser chatUsers, String msg,
       Type type) async {
      //message sending time (also used as id)
      final time = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();

      //message to send
      final Message message = Message(
          toId: chatUsers.id,
          msg: msg,
          read: '',
          type:type,
          fromId: users.uid,
          sent: time);
      final ref = firestore
      .collection('chats/${getConversationID(chatUsers.id)}/messages');
      await ref.doc(time).set(message.toJson()).then((value) =>
          sendPushNotification(chatUsers, type == Type.text ? msg : 'image'));

   }
   //update read status of message
   static Future<void> updateMessageReadStatus(Message message) async {
      firestore
          .collection('chats/${getConversationID(message.fromId)}/messages/')
          .doc(message.sent)
          .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
   }

   //get only last message of a specific chat
   static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
       ChatUser users) {
      return firestore
          .collection('chats/${getConversationID(users.id)}/messages/')
          .orderBy('sent', descending: true)
          .limit(1)
          .snapshots();
   }
   //send chat image
   static Future<void> sendChatImage(ChatUser chatUser, File file) async {
      //getting image file extension
      final ext = file.path.split('.').last;

      //storage file ref with path
      final ref = storage.ref().child(
          'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

      //uploading image
      await ref
          .putFile(file, SettableMetadata(contentType: 'image/$ext'))
          .then((p0) {
         log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
      });

      //updating image in firestore database
      final imageUrl = await ref.getDownloadURL();
      await sendMessage(chatUser, imageUrl, Type.image);
   }
   //delete message
   static Future<void> deleteMessage(Message message) async {
      await firestore
          .collection('chats/${getConversationID(message.toId)}/messages/')
          .doc(message.sent)
          .delete();

      if (message.type == Type.image) {
         await storage.refFromURL(message.msg).delete();
      }
   }

   //update message
   static Future<void> updateMessage(Message message, String updatedMsg) async {
      await firestore
          .collection('chats/${getConversationID(message.toId)}/messages/')
          .doc(message.sent)
          .update({'msg': updatedMsg});
   }
}