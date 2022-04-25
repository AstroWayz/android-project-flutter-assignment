import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
        ),
      ),
      home: const RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  SnappingSheetController controller = SnappingSheetController();
  final _saved = <WordPair>{};
  final _saved2 = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  var firebaseUser;
  final firestoreInstance = FirebaseFirestore.instance;

  // get passwordController => null;

  get direction => null;

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        // NEW from here...
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            if (AuthRepository.instance().status == Status.Authenticated) {
              FirebaseFirestore.instance
                  .collection("Users")
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection("Pair")
                  .where("WordPair ", isEqualTo: pair.toString().trim())
                  .get()
                  .then((value) {
                value.docs.forEach((element) {
                  FirebaseFirestore.instance
                      .collection("Users")
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection("Pair")
                      .doc(element.id)
                      .delete()
                      .then((value) {});
                });
              });
            }
            _saved.remove(pair);
          } else {
            if (AuthRepository.instance().status == Status.Authenticated) {
              firestoreInstance
                  .collection("Users")
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection("Pair")
                  .add({"WordPair ": pair.toString().trim()});
            }
            _saved.add(pair);
          }
        });
      }, // ... to here.
    );
  }

  Widget _snappingsheet()  {
    bool flag = false;

    return Scaffold(
      body: SnappingSheet(
        lockOverflowDrag: false,
        controller: controller,
        // TODO: Add your content that is placed
        // behind the sheet. (Can be left empty)
        child: _buildSuggestions(),
        grabbingHeight: 50,
        // TODO: Add your grabbing widget here,
        grabbing: GestureDetector(
          onTap: () {
    if(controller.isAttached){
    if (!flag) {
    flag = true;
    controller.snapToPosition(
    SnappingPosition.factor(positionFactor: 0.2));
    } else if (flag) {
    flag = false;
    controller
        .snapToPosition(SnappingPosition.factor(positionFactor: 0.025));
    }
    }
          },
          child: GrabbingWidget(),
        ),
        sheetBelow: SnappingSheetContent(
          draggable: true,
           // childScrollController: controller ,
          // TODO: Add your sheet content here
          child: currentProfile(),
        ),
      ),
    );
  }

    Widget currentProfile()    {
    String? currEmail = FirebaseAuth.instance.currentUser?.email;
    String? UID = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Row(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all( 10),
                child:  FutureBuilder(
                  future:AuthRepository.instance().Getuserimage() ,
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot){
                    return CircleAvatar(
                      backgroundImage: snapshot.data != null ? NetworkImage(snapshot.data.toString()) : null,

                      radius: 35,
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 15 , left: 3),
                child: Text(currEmail! , style: TextStyle(fontSize: 20),),
              ),
              Container(
                height: 40,
                padding: EdgeInsets.only(top:10 , right: 60),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(

                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal()),
                        primary: Colors.blue),
                    onPressed: () async{
                   PickedFile? Image =    await ImagePicker().getImage(source: ImageSource.gallery ,maxWidth: 1800,
                     maxHeight: 1800,) ;
                   if(Image != null){
                   File  imageFile = File(Image.path);
                      UID = FirebaseAuth.instance.currentUser?.uid;

                  // Imageu = (await FirebaseStorage.instance.ref("Images").child(UID!).getDownloadURL());
                   await FirebaseStorage.instance.ref("Images").child(UID!).putFile(imageFile);
                      setState(()  {

                      });
                   }
                    },
                    child: Text("Change avatar", style: TextStyle(fontSize : 12),)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // The itemBuilder callback is called once per suggested
      // word pairing, and places each suggestion into a ListTile
      // row. For even rows, the function adds a ListTile row for
      // the word pairing. For odd rows, the function adds a
      // Divider widget to visually separate the entries. Note that
      // the divider may be difficult to see on smaller devices.
      itemBuilder: (context, i) {
        // Add a one-pixel-high divider widget before each row
        // in the ListView.
        if (i.isOdd) {
          return const Divider();
        }

        // The syntax "i ~/ 2" divides i by 2 and returns an
        // integer result.
        // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
        // This calculates the actual number of word pairings
        // in the ListView,minus the divider widgets.
        final index = i ~/ 2;
        // If you've reached the end of the available word
        // pairings...
        if (index >= _suggestions.length) {
          // ...then generate 10 more and add them to the
          // suggestions list.
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add from here...
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () async {
              firebaseUser = FirebaseAuth.instance.currentUser;
              var result = await firestoreInstance
                  .collection("Users")
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection("Pair")
                  .get();
              List<DocumentSnapshot> documents = result.docs;
              Set<WordPair> _tempset = {};
              documents.forEach((DOC) {
                String result = DOC.data().toString().substring(
                    DOC.data().toString().indexOf(":") + 2,
                    DOC.data().toString().length - 1);
                String t1 = result.substring(0, 2);
                String t2 = result.substring(2, result.length);
                WordPair temp = WordPair(t1, t2);

                _tempset.add(temp);
                for (int i = 0; i < _saved.length; i++) {
                  // print(_saved.elementAt(i).toString());
                  if (_saved.elementAt(i).toString() == result) {
                    _tempset.remove(temp);
                  }
                }
              });

              _saved.addAll(_tempset);
              _pushSaved();
            },
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
              onPressed: () async {
                print(AuthRepository.instance().isAuthenticated);
                if (AuthRepository.instance().isAuthenticated) {
                  await AuthRepository.instance().signOut();
                  setState(() {});
                } else {
                  _loginbuild();
                }
              },
              icon: Icon(AuthRepository.instance().isAuthenticated
                  ? Icons.login
                  : Icons.exit_to_app)),
        ],
      ),
      body: AuthRepository.instance().isAuthenticated
          ? _snappingsheet()
          : _buildSuggestions(),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _saved.map(
            (pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              title: const Text('Saved Suggestions'),
            ),
            body: ListView.builder(
              itemCount: _saved.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _saved.elementAt(index);
                return Dismissible(
                    key: Key(item.toString()),
                    onDismissed: (direction) {
                      setState(() {
                        if (AuthRepository.instance().status ==
                            Status.Authenticated) {
                          FirebaseFirestore.instance
                              .collection("Users")
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection("Pair")
                              .where("WordPair ",
                                  isEqualTo: item.toString().trim())
                              .get()
                              .then((value) {
                            value.docs.forEach((element) {
                              FirebaseFirestore.instance
                                  .collection("Users")
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection("Pair")
                                  .doc(element.id)
                                  .delete()
                                  .then((value) {});
                            });
                          });
                        }

                        _saved.remove(item);
                        _saved2.remove(item);
                      });
                    },
                    confirmDismiss: (DismissDirection direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Delete Suggestion"),
                            content: Text("Are you sure you want to delete " +
                                item.toString() +
                                " from your saved suggestion?"),
                            actions: <Widget>[
                              FlatButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  //    firestoreInstance.collection("Users").doc(FirebaseAuth.instance.currentUser?.uid).collection("Pair").end
                                },
                                child: const Text("Yes"),
                              ),
                              FlatButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("No"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    background: Container(
                        padding: EdgeInsets.only(top: 6, left: 20),
                        color: Colors.deepPurple,
                        child: Row(
                          children: const <Widget>[
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            Text(
                              'Delete suggestion',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            )
                          ],
                        )),
                    secondaryBackground: Container(
                        padding: const EdgeInsets.only(left: 200, top: 6),
                        color: Colors.deepPurple,
                        child: Row(
                          children: const <Widget>[
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            Text(
                              'Delete suggestion',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            )
                          ],
                        )),
                    child: ListTile(
                      title: Text(item.toString()),
                    ));
              },
            ),
          );
        },
      ),
    );
  }

  Widget? _loginbuild() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final passwordContollerConfirm = TextEditingController();

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: const Text('Login'),
          ),
          body: ListView(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                child: const Text(
                  "welcome to startup name generator , please login below",
                  style: TextStyle(
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Email',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Password'),
                ),
              ),
              Container(
                height: 100,
                padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      primary: Colors.deepPurple),
                  onPressed: () async {
                    bool temp = await AuthRepository.instance().signIn(
                        emailController.text.toString(),
                        passwordController.text.toString());
                    CircularProgressIndicator();
                    if (temp) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyApp(),
                          ),
                          (route) => false);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("There was an error logging into the app"),
                      ));
                    }
                  },
                  child: const Text('login'),
                ),
              ),
              Container(
                height: 100,
                padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      primary: Colors.blue),
                  onPressed: () {
                    //TODO phase2
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        10),
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                      'Please confirm your password below:'),
                                  TextField(
                                    obscureText: true,
                                    controller: passwordContollerConfirm,
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Password'),
                                  ),
                                  ElevatedButton(
                                    child: const Text('Confirm'),
                                    onPressed: () async {
                                      if (passwordContollerConfirm.text
                                              .toString() ==
                                          passwordController.text.toString()) {
                                        await AuthRepository.instance().signUp(
                                            emailController.text.toString(),
                                            passwordController.text.toString());
                                        await AuthRepository.instance().signIn(
                                            emailController.text.toString(),
                                            passwordController.text.toString());
                                        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MyApp(),
                                            ),
                                            (route) => false);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text("Passwords must match"),
                                        ));
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('New user? Click to sign up'),
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

    //TODO phase 4
  Future<String> Getuserimage() async{
    String? UID = FirebaseAuth.instance.currentUser?.uid;
    try{
       return await FirebaseStorage.instance.ref("Images").child(UID!).getDownloadURL() ;}
    on Exception catch (e){
      return "https://t4.ftcdn.net/jpg/00/64/67/63/240_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg";
    }


  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}

class GrabbingWidget extends StatelessWidget {
  @override
  String? currEmail = FirebaseAuth.instance.currentUser?.email;

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey,
      ),

      //TODO hello
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Welcome back, " + currEmail!),
          ),
          Icon(Icons.keyboard_arrow_up),
          // Container(
          //   margin: EdgeInsets.only(top: 20),
          //   width: 100,
          //   height: 7,
          //   decoration: BoxDecoration(
          //     color: Colors.grey,
          //     borderRadius: BorderRadius.circular(5),
          //   ),
          // ),
          // Container(
          //   color: Colors.grey[200],
          //   height: 2,
          //   margin: EdgeInsets.all(15).copyWith(top: 0, bottom: 0),
          // )
        ],
      ),
    );
  }
}
