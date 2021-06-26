// required package imports
import 'dart:async';
import 'package:floor/floor.dart';

import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/host_dao.dart';
import 'entity/host.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Host])
abstract class AppDatabase extends FloorDatabase {
  HostDao get hostDao;
}