import 'dart:developer';
import 'dart:io';

import 'package:dartis/dartis.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:logging/logging.dart';
import 'package:window_size/window_size.dart';
import 'db/database.dart';
import 'db/entity/host.dart';

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
    Logger.root.level=Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
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

class _RedisKey {
  final String value;
  final String type;

  _RedisKey(this.value, this.type);
}

class _MyHomePageState extends State<MyHomePage> {
  List<_RedisKey> keys = [];
  List<Host> hosts = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchHost();
  }

  void fetchHost() async {
    final database = await $FloorAppDatabase.databaseBuilder("app.db").build();
    final dao = database.hostDao;
    final hosts = await dao.findAllHosts();
    setState(() {
      this.hosts.clear();
      this.hosts.addAll(hosts);
    });


  }

  Future<Host> addHost() async {
    final database = await $FloorAppDatabase.databaseBuilder("app.db").build();
    final dao = database.hostDao;
    var password = passController.text;
    var url = hostController.text;
    final sp = url.split(":");

    var port = int.parse(sp[1]);
    var host = sp[0];
    final client = await Client.connect('redis://${host}:${port}');
    if (password.isNotEmpty) {
      await client.asCommands<String, String>().auth(password);
    }
    await client.asCommands<String, String>().ping("");
    client.disconnect();
    var hostModel = Host(0, host, port, password);
    await dao.addHost(hostModel);
    return hostModel;
  }

  Client? _client;

  fetchKeys(Host host) async {
    print("fetchKeys ${host}\n");
    await _client?.disconnect();
    _client = await Client.connect('redis://${host.host}:${host.port}');
    // Run some commands
    final commands = _client?.asCommands<String, String>();
    if (host.pass?.isNotEmpty == true) {
      await commands?.auth(host.pass);
    }
    final result = await _client?.asCommands<String, String>()?.keys("*") ?? [];
    final List<_RedisKey> keys = [];

    for (var key in result) {

      String type = await _client?.asCommands<String, String>()?.type(key) ?? "";
      if(type=='stream')continue;
      print('type:${type}  key:${key}\n');
      keys.add(_RedisKey(key, type));
    }
    setState(() {
      this.keys.clear();
      this.keys.addAll(keys);
    });
  }

  Widget drawer() {
    return Container(
        color: Colors.amber,
        child: ListView.builder(
            itemCount: hosts.length,
            itemBuilder: (BuildContext context, int index) {
              return buildHostItem(context, index);
            }));
  }

  Widget buildHostItem(BuildContext context, int index) {
    return GestureDetector(
      child: Text("${hosts[index].host}:${hosts[index].port}"),
      onDoubleTap: () {
        fetchKeys(hosts[index]);
        AppScreen.of(context).closeDrawer();
      },
    );
  }

  Widget drawerButton({required String title, required IconData icon}) {
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

  final hostController = TextEditingController();
  final passController = TextEditingController();

  @override
  void dispose() {
    hostController.dispose();
    passController.dispose();
    super.dispose();
  }

  void showAddHostDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext builer) {
          return AlertDialog(
            title: Text('添加主机'),
            content: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: hostController,
                    decoration: InputDecoration(
                      labelText: '主机地址',
                      hintText: '格式：127.0.0.1:3306',
                    ),
                    validator: (String? value) {
                      if (value?.trim().isEmpty == true) {
                        return '主机地址不能为空';
                      }
                      final pattern = r"^.+:\d{1,5}$";
                      RegExp regex = new RegExp(pattern);
                      if (regex.hasMatch(value?.trim() ?? "")) {
                      } else {
                        return '主机地址格式错误';
                      }
                    },
                  ),
                  TextFormField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '密码',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await addHost();
                            Navigator.pop(context, true);
                            fetchHost();
                          } catch (e) {
                            print(e);
                            Widget error = Text('数据库错误');
                            showDialog(
                                context: context,
                                builder: (builder) => AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [Icon(Icons.warning), error],
                                      ),
                                    ));
                          }
                        }
                      },
                      child: Text("确定"),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  _RedisKey? currentKey;
  Widget buildKeysList(BuildContext context) {
    Widget getType(String type) {
      var color=Colors.amber;
      if(type=='list'){
        color=Colors.deepPurple;
      }else if(type=='set'){
        color=Colors.red;
      }else if(type=='zset'){
        color=Colors.green;
      }else if(type=='hash'){
        color=Colors.blue;
      }
        return Container(
          width: 50,
          color: color,
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,

            ),
          ));
    }

    return ListView.builder(
        itemCount: keys.length,
        itemBuilder: (BuildContext context, int index) {
          var key = keys[index];
          return GestureDetector(
            child: Row(
              children: [Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0,horizontal: 2.0),
                child: getType(key.type),
              ), Text("${key.value}")],
            ),
            onTap: () async {
              onClickKey(key, index);
            },
          );
        });
  }

  void onClickKey(_RedisKey key, int index) async {

    print('get result by key(${key.type})==>${key.value}');
    if(key.type=='string'){
      var result=await _client?.asCommands<String, String>()?.get(key.value)??"";
      setState(() {
        this.contentString=result;
        this.currentKey=key;
      });
    }else if(key.type=='list'){

      var result=await _client?.asCommands<String, String>()?.lrange(key.value,0,-1)??[];
      setState(() {
        this.contentList=result;
        this.currentKey=key;
      });
    }else if(key.type=='set'){

      var result=await _client?.asCommands<String, String>()?.smembers(key.value)??[];
      setState(() {
        this.contentSet=result;
        this.currentKey=key;
      });
    }else if(key.type=='zset'){

      var result=await _client?.asCommands<String, String>()?.zscan(key.value,0);
      setState(() {
        this.contentZSet=result?.members??new Map();
        this.currentKey=key;
      });
    }else if(key.type=='hash'){

      var result=await _client?.asCommands<String, String>()?.hgetall(key.value);
      setState(() {
        this.contentHash=result??new Map();
        this.currentKey=key;
      });
    }else{
      setState(() {
        this.currentKey=key;
      });
    }
  }
  String contentString="";
  List<String> contentList=[];
  List<String> contentSet=[];
  Map<String,double> contentZSet=new Map();
  Map<String,String> contentHash=new Map();

  Widget buildStringContent(BuildContext context) {
    return Text(contentString);
  }
  Widget buildListContent(BuildContext context) {
    return ListView.builder(
      itemCount: contentList.length,
        itemBuilder: (context,index){
        return Text(contentList[index]);
    });
  }
  Widget buildSetContent(BuildContext context) {
    return ListView.builder(
        itemCount: contentSet.length,
        itemBuilder: (context,index){
          return Text(contentSet[index]);
        });
  }
  Widget buildZSetContent(BuildContext context) {
    return ListView.builder(
        itemCount: contentZSet.keys.length,
        itemBuilder: (context,index){
          var list = contentZSet.keys.toList();
          return Text("${list[index]}===>${contentZSet[list[index]]}");
        });
  }
  Widget buildHashContent(BuildContext context) {
    return ListView.builder(
        itemCount: contentHash.keys.length,
        itemBuilder: (context,index){
          var list = contentHash.keys.toList();
          return Text("${list[index]}===>${contentHash[list[index]]}");
        });
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
            builder: (BuildContext context) {
              return buildKeysList(context);
            },
          ),
          masterPaneMinWidth: 200,
          detailPane: Builder(
            builder: (BuildContext context) {
              if(this.currentKey?.type=='string'){
                return buildStringContent(context);
              }else if(this.currentKey?.type=='list'){
                return buildListContent(context);
              }else if(this.currentKey?.type=='set'){
                return buildSetContent(context);
              }if(this.currentKey?.type=='zset'){
                return buildZSetContent(context);
              }if(this.currentKey?.type=='hash'){
                return buildHashContent(context);
              }
              return Text("暂不支持此类型");
            },
          ),
          drawer: AppDrawer(
            defaultSmall: false,
            largeDrawerWidth: 200,
            largeDrawer: drawer(),
          ),
          menuList: [
            MenuItem(title: 'File', menuListItems: [
              MenuListItem(
                icon: Icons.open_in_new,
                title: 'Add Host',
                onPressed: () {
                  showAddHostDialog(context);
                },
                shortcut:
                    MenuShortcut(key: LogicalKeyboardKey.keyO, ctrl: true),
              ),
              MenuListItem(
                icon: Icons.exit_to_app,
                title: 'Exit',
                onPressed: () {
                  exit(0);
                },
                shortcut:
                    MenuShortcut(key: LogicalKeyboardKey.keyW, ctrl: true),
              ),
            ])
          ],
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
