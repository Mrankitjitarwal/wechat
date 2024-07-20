import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'package:we_chat/Screens/SplashScreen.dart';
import 'Screens/auth/loginscreen.dart';
import 'firebase_options.dart';
late Size mq;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //enter full-screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  //for setting orientation to portrait only
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) {
    _initializeFirebase();
  runApp(const MyApp());
});}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'We Chat',
      theme: ThemeData(
        iconTheme: IconThemeData(color: Colors.blue),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
            elevation: 1,
           titleTextStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 19,color: Colors.black),
           backgroundColor: Colors.white,),
      ),
      home:  SplashScreen(),
    );
  }
}
_initializeFirebase() async{
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,);
       /*var result = await FlutterNotificationChannel.registerNotificationChannel(
   description: 'For Showing Message Notification',
   id: 'chats',
   importance: NotificationImportance.IMPORTANCE_HIGH,
   name: 'Chats');
   log('\nNotification Channel Result: $result');*/

 }