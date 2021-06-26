import 'package:floor/floor.dart';
import 'package:redis_dekstop/db/entity/host.dart';

@dao
abstract class HostDao {
  @Query('SELECT * FROM Host')
  Future<List<Host>> findAllHosts();
  @Insert()
  Future<int> addHost(Host host);
}