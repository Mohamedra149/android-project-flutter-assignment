import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/utility.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;

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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => MyAuth.instance(),
        child: MaterialApp(
          title: 'Startup Name Generator',
          initialRoute: '/',
          routes: {
            '/': (context) => RandomWords(),
            '/login': (context) => LoginScreen(),
          },
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ));
  }
}

class _RandomWordsState extends State<RandomWords> {
  var user;
  final _suggestions = <WordPair>[];
  final _savedLocal = <WordPair>{};
  var _savedCloud = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var drag = true;
  SnappingSheetController sheetController = SnappingSheetController();

  @override
  Widget build(BuildContext context) {
    user = Provider.of<MyAuth>(context);
    var logVar = _loginScreen;
    var logIcon = Icons.login;

    if (user.status == Status.Authenticated) {
      _savedCloud = user.getData();
      logVar = _logoutScreen;
      logIcon = Icons.exit_to_app;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            color: Colors.white,
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
              icon: Icon(logIcon), color: Colors.white, onPressed: logVar),
        ],
      ),
      body: GestureDetector(
          child: SnappingSheet(
            controller: sheetController,
            snappingPositions: const [
              SnappingPosition.pixels(
                  positionPixels: 190,
                  snappingCurve: Curves.bounceOut,
                  snappingDuration: Duration(milliseconds: 350)),
              SnappingPosition.factor(
                  positionFactor: 1.0,
                  snappingCurve: Curves.easeInBack,
                  snappingDuration: Duration(milliseconds: 1)),
            ],
            lockOverflowDrag: true,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildSuggestions(),
                BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 5,
                    sigmaY: 5,
                  ),
                  child: drag && user.status == Status.Authenticated
                      ? Container(
                          color: Colors.transparent,
                        )
                      : null,
                )
              ],
            ),
            sheetBelow: user.status == Status.Authenticated
                ? SnappingSheetContent(
                    draggable: drag,
                    child: Container(
                      color: Colors.white,
                      child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Column(children: [
                              Row(children: <Widget>[
                                Expanded(
                                  child: Container(
                                    color: Colors.black12,
                                    height: 60,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Flexible(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                  "Welcome back, " +
                                                      user.getEmail(),
                                                  style: const TextStyle(
                                                      fontSize: 15.0)),
                                            )),
                                        const IconButton(
                                          icon: Icon(Icons.keyboard_arrow_up),
                                          onPressed: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),
                              const Padding(padding: EdgeInsets.all(8)),
                              Row(children: <Widget>[
                                const Padding(padding: EdgeInsets.all(8)),
                                FutureBuilder(
                                  future: user.getImage(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    return CircleAvatar(
                                      radius: 50.0,
                                      backgroundImage: snapshot.data != null
                                          ? NetworkImage(snapshot.data ??
                                              "") //muask might be null
                                          : null,
                                    );
                                  },
                                ),
                                const Padding(padding: EdgeInsets.all(10)),
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(user.getEmail(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 15)),
                                      const Padding(padding: EdgeInsets.all(3)),
                                      MaterialButton(
                                        //Change avatar button
                                        onPressed: () async {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: [
                                              'png',
                                              'jpg',
                                              'gif',
                                              'bmp',
                                              'jpeg',
                                              'webp'
                                            ],
                                          );
                                          File file;
                                          if (result != null) {
                                            file = File(
                                                result.files.single.path ?? "");
                                            user.uploadNewImage(file);
                                          } else
                                          {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(content: Text('No image selected')));
                                          }
                                        },
                                        textColor: Colors.white,
                                        padding: const EdgeInsets.only(
                                            left: 5.0,
                                            top: 3.0,
                                            bottom: 5.0,
                                            right: 8.0),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                Colors.blue,
                                                Colors.blueAccent,
                                              ],
                                            ),
                                          ),
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 7, 15, 7),
                                          child: const Text('Change Avatar',
                                              style: TextStyle(fontSize: 15)),
                                        ),
                                      ),
                                    ])
                              ]),
                            ]),
                          ]),
                    ),
                    //heightBehavior: SnappingSheetHeight.fit(),
                  )
                : null,
          ),
          onTap: () => {
                setState(() {
                  if (drag == false) {
                    drag = true;
                    sheetController
                        .snapToPosition(const SnappingPosition.factor(
                      positionFactor: 0.265,
                    ));
                  } else {
                    drag = false;
                    sheetController.snapToPosition(
                        const SnappingPosition.factor(
                            positionFactor: 0.083,
                            snappingCurve: Curves.easeInBack,
                            snappingDuration: Duration(milliseconds: 1)));
                  }
                })
              }),
      // #enddocregion itemBuilder
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _savedLocal.contains(pair);
    final alreadySavedData =
        (user.status == Status.Authenticated && _savedCloud.contains(pair));
    final isSaved = (alreadySaved || alreadySavedData);
    if (alreadySaved && !alreadySavedData) {
      user.addPair(pair.toString(), pair.first, pair.second);
    }
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        isSaved ? Icons.star : Icons.star_border,
        color: isSaved ? Colors.deepPurple : null,
        semanticLabel: isSaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (isSaved) {
            _savedLocal.remove(pair);
            user.removePair(pair.toString());
            _savedCloud = user.getData();
          } else {
            _savedLocal.add(pair);
            user.addPair(pair.toString(), pair.first, pair.second);
            _savedCloud = user.getData();
          }
        });
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  void _pushSaved() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            const TextStyle _biggerFont = const TextStyle(fontSize: 18);
            final user = Provider.of<MyAuth>(context);
            var favorites = _savedLocal;
            var text;
            final GlobalKey<ScaffoldState> _scaffoldKey =
                new GlobalKey<ScaffoldState>();
            if (user.status == Status.Authenticated) {
              favorites = _savedLocal.union(user.getData());
            } else {
              favorites = _savedLocal;
            }

            final tiles = favorites.map(
              (WordPair pair) {
                return Dismissible(
                    key: ObjectKey(pair),
                    onDismissed: (dir) {},
                    confirmDismiss: (dir) async {
                      showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: Text(
                                  'Are You sure you want to delete $pair from your saved'
                                  ' suggestions?'),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  // passing true
                                  child: const Text('Yes'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.deepPurple,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  // passing false
                                  child: const Text('No'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.deepPurple,
                                    onPrimary: Colors.white,
                                  ),
                                )
                              ],
                            );
                          }).then((exit) {
                        if (exit == null) return;

                        if (exit) {
                          // user pressed Yes button
                          setState(() {
                            user.removePair(pair.toString());
                            _savedCloud.remove(pair);
                            setState(() => _savedLocal.remove(pair));
                          });
                        } else {
                          // user press No button
                          Navigator.pop(context, 'current_user_location');
                        }
                      });
                    },
                    background: Container(
                      child: Row(
                        children: const [
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          Text(
                            'Delete Suggestion',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          )
                        ],
                      ),
                      color: Colors.deepPurple,
                    ),
                    child: ListTile(
                      title: Text(
                        pair.asPascalCase,
                        style: _biggerFont,
                      ),
                    ));
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
                title: const Text('Saved Suggestions',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.deepPurple,
                iconTheme: const IconThemeData(
                  color: Colors.white, //change your color here
                ),
              ),
              body: ListView(children: divided),
            );
          },
        );
      },
    ));
  }

  void _logoutScreen() async {
    _savedCloud.clear();
    _savedLocal.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Successfully logged out')));
    await user.signOut();
  }

  void _loginScreen() {
    Navigator.pushNamed(context, '/login');
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyAuth>(context);

    TextEditingController _email = TextEditingController(text: "");
    TextEditingController _password = TextEditingController(text: "");
    TextEditingController _confirm = TextEditingController(text: "");
    var Identical = true;
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Login', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.all(25.0),
                    child: (Text(
                      'Welcome to Startup Names Generator, please log in below',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ))),
                const SizedBox(height: 20),
                TextField(
                  controller: _email,
                  obscureText: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 45),
                user.status == Status.Authenticating
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!await user.signIn(
                                _email.text, _password.text)) {
                              const snackBar = SnackBar(
                                  content: Text(
                                      'There was an error logging into the app'));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(300, 48),
                            shape: const StadiumBorder(),
                            primary: Colors.deepPurple,
                            onPrimary: Colors.white,
                          ),
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return AnimatedPadding(
                              padding: MediaQuery.of(context).viewInsets,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.decelerate,
                              child: Container(
                                height: 200,
                                color: Colors.white,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text(
                                        "Please confirm your password below:",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        width: 350,
                                        child: TextField(
                                          controller: _confirm,
                                          obscureText: true,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            errorText: Identical
                                                ? null
                                                : 'Passwords must match',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ButtonTheme(
                                        minWidth: 350.0,
                                        height: 50,
                                        child: MaterialButton(
                                            color: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18.0),
                                                side: const BorderSide(
                                                    color: Colors.blue)),
                                            child: const Text(
                                              'Confirm',
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.white),
                                            ),
                                            onPressed: () async {
                                              if (_confirm.text ==
                                                  _password.text) {
                                                user.signUp(_email.text,
                                                    _password.text);
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              } else {
                                                setState(() {
                                                  Identical = false;
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          FocusNode());
                                                });
                                              }
                                            }),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                    },
                    child: const Text('New user? Click to sign up'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(300, 48),
                      shape: const StadiumBorder(),
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                    ),
                  ),
                )
              ],
            )));
  }
}
