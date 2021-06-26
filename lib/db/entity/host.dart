import 'package:floor/floor.dart';

@entity
class Host {
  @primaryKey
  final int id;
  final String host;
  final int port;
  final String? pass;
  Host(this.id, this.host, this.port, this.pass);
}