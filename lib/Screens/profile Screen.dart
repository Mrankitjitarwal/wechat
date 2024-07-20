import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/get.dart'; // Import Get
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../Api/APi.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import 'auth/loginscreen.dart';

class ProfileScreenController extends GetxController {
  String? _image;

  // Method to update the image path
  void updateImagePath(String imagePath) {
    _image = imagePath;
    update(); // Notify listeners that the state has changed
  }
}

class ProfileScreen extends StatelessWidget {
  final ChatUser users;

  ProfileScreen({Key? key, required this.users}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ProfileScreenController profileScreenController = Get.put(ProfileScreenController());
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Screen')),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              Dialogs.showProgressBar(context);
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  APIs.auth = FirebaseAuth.instance;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
              });
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .03),
                  Stack(
                    children: [
                      profileScreenController._image != null
                          ? ClipRRect(
                        borderRadius:
                        BorderRadius.circular(mq.height * .1),
                        child: Image.file(
                          File(profileScreenController._image ?? ''),
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.cover,
                        ),
                      )
                          : ClipRRect(
                        borderRadius:
                        BorderRadius.circular(mq.height * .1),
                        child: CachedNetworkImage(
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.fill,
                          imageUrl: users.image,
                          errorWidget: (context, url, error) =>
                          const CircleAvatar(
                              child: Icon(CupertinoIcons.person)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 10,
                          onPressed: () {
                            _showBottomSheet(context);
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height * .03),
                  Text(
                    users.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  SizedBox(height: mq.height * .05),
                  TextFormField(
                    initialValue: users.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Ankit Jitarwal',
                      label: const Text('Name'),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  TextFormField(
                    initialValue: users.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About'),
                    ),
                  ),
                  SizedBox(height: mq.height * .05),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .5, mq.height * .06),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(
                              context, 'Profile Updated Successfully!');
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    final ProfileScreenController profileScreenController = Get.put(ProfileScreenController());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image Path: ${image.path}');
                      profileScreenController.updateImagePath(image.path); // Update image path
                      APIs.updateProfilePicture(File(image.path));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/add_image.png'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image Path: ${image.path}');
                      profileScreenController.updateImagePath(image.path); // Update image path
                      APIs.updateProfilePicture(File(image.path));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


/*
class ProfileScreen extends StatefulWidget {
  final ChatUser users;
  const ProfileScreen({super.key,required this.users});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;


   @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar:  AppBar(title: const Text('Profile Screen')),

      //floating button to log out
      floatingActionButton: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
      backgroundColor: Colors.redAccent,
      onPressed: () async {
      //for showing progress dialog
      Dialogs.showProgressBar(context);

         // await APIs.updateActiveStatus(false);

      //sign out from app
      await APIs.auth.signOut().then((value) async {
      await GoogleSignIn().signOut().then((value) {
      //for hiding progress dialog
      Navigator.pop(context);

      //for moving to home screen
      Navigator.pop(context);

      APIs.auth = FirebaseAuth.instance;

      //replacing home screen with login screen
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(
      builder: (_) => const LoginScreen()));
      });
      });
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout')),
      ),

       body: Form(
         key: _formKey,
         child: Padding(
           padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
           child: SingleChildScrollView(
             child: Column(
                    children: [
             SizedBox(
               width: mq.width,
               height: mq.height*.03,
             ),
             //user profile picture
             Stack(
               children: [
                 //profile picture
                 _image != null
                     ?

                 //local image
                 ClipRRect(
                   borderRadius: BorderRadius.circular(mq.height * .1),
                   child: Image.file(
                     File(_image ?? ''), // Use null-aware operator to handle null case
                     width: mq.height * .2,
                     height: mq.height * .2,
                     fit: BoxFit.cover,
                   ),
                 )
                     :

                 //image from server
                 ClipRRect(
                   borderRadius: BorderRadius.circular(mq.height * .1),
                   child: CachedNetworkImage(
                     width: mq.height * .2,
                     height: mq.height * .2,
                     fit: BoxFit.fill,
                     imageUrl: widget.users.image,
                     errorWidget: (context, url, error) =>
                     const CircleAvatar(child: Icon(CupertinoIcons.person)),
                   ),
                 ), Positioned(
                   bottom: 0,
                   right: 0,
                   child: MaterialButton(
                     elevation: 10,
                     onPressed: () {
                       _showBottomSheet();
                     },
                     shape: const CircleBorder(),
                     color: Colors.white,
                     child: const Icon(Icons.edit, color: Colors.blue),
                   ),
                 ),
               ],
             ),



             // for adding some space
             SizedBox(height: mq.height * .03),

             // user email label
             Text(widget.users.email,style: const TextStyle(color: Colors.black54,fontSize: 16),),
             // for adding some space
             SizedBox(height: mq.height * .05),

             // name input field
             TextFormField(
               initialValue: widget.users.name,
               onSaved: (val) => APIs.me.name = val ?? '',
               validator: (val) => val != null && val.isNotEmpty
                   ? null
                   : 'Required Field',
               decoration: InputDecoration(
                   prefixIcon: const Icon(Icons.person, color: Colors.blue),
                   border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12)),
               hintText: 'eg. Ankit Jitarwal',
                   label: const Text('Name')),
             ),
             // for adding some space
             SizedBox(height: mq.height * .02),

             // about input field
             TextFormField(
               initialValue: widget.users.about,
               onSaved: (val) => APIs.me.about = val ?? '',
               validator: (val) => val != null && val.isNotEmpty
                   ? null
                   : 'Required Field',
               decoration: InputDecoration(
                   prefixIcon: const Icon(Icons.info_outline,
                       color: Colors.blue),
                   border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12)),
                   hintText: 'eg. Feeling Happy',
                   label: const Text('About')),
             ),
             // for adding some space
             SizedBox(height: mq.height * .05),

             // update profile button
             ElevatedButton.icon(
               style: ElevatedButton.styleFrom(
                   shape: const StadiumBorder(),
                   minimumSize: Size(mq.width * .5, mq.height * .06)),
               onPressed: () {
                 if (_formKey.currentState!.validate()) {
                   _formKey.currentState!.save();
                   APIs.updateUserInfo().then((value) {
                     Dialogs.showSnackbar(
                         context, 'Profile Updated Successfully!');
                   });
                 }
               },
               icon: const Icon(Icons.edit, size: 28),
               label:
               const Text('UPDATE', style: TextStyle(fontSize: 16)),
             )
                    ],
             ),
           ),
         ),
       ),
      ),
    );
  }

   // bottom sheet for picking a profile picture for user
   void _showBottomSheet() {
     showModalBottomSheet(
         context: context,
         shape: const RoundedRectangleBorder(
             borderRadius: BorderRadius.only(
                 topLeft: Radius.circular(20), topRight: Radius.circular(20))),
         builder: (_) {
           return ListView(
             shrinkWrap: true,
             padding:
             EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
             children: [
               //pick profile picture label
               const Text('Pick Profile Picture',
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),

               //for adding some space
               SizedBox(height: mq.height * .02),

               //buttons
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   //pick from gallery button
                   ElevatedButton(
                       style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           shape: const CircleBorder(),
                           fixedSize: Size(mq.width * .3, mq.height * .15)),
                       onPressed: () async {
                         final ImagePicker picker = ImagePicker();

                         // Pick an image
                         final XFile? image = await picker.pickImage(
                             source: ImageSource.gallery, imageQuality: 80);
                         if (image != null) {
                           log('Image Path: ${image.path}');
                           setState(() {
                             _image = image.path;
                           });

                           APIs.updateProfilePicture(File(_image!));
                           // for hiding bottom sheet
                           Navigator.pop(context);
                         }
                       },
                       child: Image.asset('images/add_image.png')),

                   //take picture from camera button
                   ElevatedButton(
                       style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           shape: const CircleBorder(),
                           fixedSize: Size(mq.width * .3, mq.height * .15)),
                       onPressed: () async {
                         final ImagePicker picker = ImagePicker();

                         // Pick an image
                         final XFile? image = await picker.pickImage(
                             source: ImageSource.camera, imageQuality: 80);
                         if (image != null) {
                           log('Image Path: ${image.path}');
                           setState(() {
                             _image = image.path;
                           });

                           APIs.updateProfilePicture(File(_image!));
                           // for hiding bottom sheet
                           Navigator.pop(context);
                         }
                       },
                       child: Image.asset('images/camera.png')),
                 ],
               )
             ],
           );
         });
   }
}
*/
