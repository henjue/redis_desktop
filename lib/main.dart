import 'dart:io';

import 'package:dartis/dartis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:window_size/window_size.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Redis Desktop Flutter');
    setWindowMinSize(const Size(700, 500));
    setWindowMaxSize(Size.infinite);

  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);



  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> keys = [];
  String _drawerTitle = 'Tap a drawerItem';
   _incrementCounter() async {
    final client = await Client.connect('redis://192.168.60.40:7002');
    // Run some commands
    final commands = client.asCommands<String, String>();
    final result = await commands.keys("*");
    setState(() {
      this.keys.clear();
      this.keys.addAll(result);
    });
    client.disconnect();

  }
  Widget drawer() {
    return Container(
        color: Colors.amber,
        child: ListView(
          children: [
            drawerButton(
                title: 'User', icon: Icons.account_circle),
            drawerButton(title: 'Inbox', icon: Icons.inbox),
            drawerButton(title: 'Files', icon: Icons.save),
            drawerButton(
              title: 'Clients',
              icon: Icons.supervised_user_circle,
            ),
            drawerButton(
              title: 'Settings',
              icon: Icons.settings,
            ),
          ],
        ));
  }
  Widget drawerButton(
      {required String title, required IconData icon}) {
    return drawerLargeButton(icon: icon, title: title);
  }

  Widget drawerLargeButton({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
      child: Card(
          elevation: 3,
          child: ListTile(
            title: Text(title),
          )),
    );
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: null,
      body: AppScreen(
        masterPane: Builder(
          builder: (BuildContext context){
              return Text('key List');
          },
        ),
        masterPaneMinWidth: 200,
        detailPane: Builder(
          builder: (BuildContext context){
            return Text('detail');
          },
        ),
        drawer: AppDrawer(
          defaultSmall: false,
          largeDrawerWidth: 200,
          largeDrawer: drawer(),
        ),
        menuList: [
          MenuItem(title: 'File', menuListItems: [  MenuListItem(
            icon: Icons.open_in_new,
            title: 'Open',
            onPressed: () {
              print("open");
            },
            shortcut: MenuShortcut(key: LogicalKeyboardKey.keyO, ctrl: true),
          ),])
        ],
      )
 // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
