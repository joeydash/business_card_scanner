import '../models/group.dart';
import 'database_helper.dart';

class GroupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createGroup(String name) async {
    return await _dbHelper.createGroup(name);
  }

  Future<List<GroupWithCount>> getAllGroupsWithCounts() async {
    final groupMaps = await _dbHelper.readAllGroups();
    final List<GroupWithCount> groups = [];

    for (final map in groupMaps) {
      final group = Group.fromMap(map);
      final count = await _dbHelper.getGroupCardCount(group.id);
      groups.add(GroupWithCount(group: group, cardCount: count));
    }

    // Add "Ungrouped" category
    final ungroupedCount = await _dbHelper.getGroupCardCount(null);
    if (ungroupedCount > 0) {
      groups.add(GroupWithCount(
        group: Group(
          id: null,
          name: 'Ungrouped',
          createdAt: DateTime.now(),
        ),
        cardCount: ungroupedCount,
      ));
    }

    return groups;
  }

  Future<void> renameGroup(int id, String newName) async {
    await _dbHelper.updateGroup(id, newName);
  }

  Future<void> deleteGroup(int id) async {
    await _dbHelper.deleteGroup(id);
  }
}

class GroupWithCount {
  final Group group;
  final int cardCount;

  GroupWithCount({
    required this.group,
    required this.cardCount,
  });
}
