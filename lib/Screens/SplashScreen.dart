import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

import '../../main.dart';
import '../Api/APi.dart';
import 'auth/loginscreen.dart';
import 'homescreen.dart';

class SplashController extends GetxController{
  login(){
    Future.delayed(const Duration(seconds: 2), () {
      //exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Colors.white));
      //Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginScreen()));
      if (APIs.auth.currentUser != null) {
        log('\nUser: ${APIs.auth.currentUser}');
        //navigate to home screen
        Get.to(() => HomeScreen());
      } else {
        //navigate to login screen
        Get.to(()=> LoginScreen());
      }
    });}

}
//splash screen
class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});
  final SplashController splashcontroller =Get.put(SplashController(),permanent: true);
  @override
  void dispose() {
    splashcontroller.dispose();
  }
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
 splashcontroller.login();
    return Scaffold(
      //body
      body: Stack(children: [
        //app logo
        Positioned(
            top: mq.height * .15,
            right: mq.width * .25,
            width: mq.width * .5,
            child: Image.asset('images/We Chat.png')),

        //google login button
        Positioned(
          bottom: mq.height * .15,
          width: mq.width,
          child:
          RichText(text:TextSpan( style: TextStyle(
              fontSize: 16, color: Colors.black87, letterSpacing: .5),
              children:[TextSpan(
                text: 'MADE IN INDIA WITH ❤️',),
                TextSpan(text:'\n    By Ankit Jitarwal' ,style: TextStyle(fontSize: 12))
              ]),textAlign: TextAlign.center,
          ),)
      ]),
    );
  }
}
