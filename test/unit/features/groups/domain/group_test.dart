import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/groups/domain/entities/group.dart';

void main() {
  group('Group', () {
    const baseGroup = Group(
      id: 'group-1',
      tenantId: 'tenant-1',
      name: 'Test Group',
      description: 'A test group description',
      createdAt: 1000000,
      memberCount: 5,
    );

    test('copyWith updates specified fields', () {
      final renamed = baseGroup.copyWith(name: 'Renamed Group');
      expect(renamed.name, 'Renamed Group');
      expect(renamed.description, baseGroup.description);
    });

    test('copyWith preserves unchanged fields', () {
      expect(baseGroup.copyWith(), baseGroup);
    });

    test('toMap serializes all fields', () {
      final map = baseGroup.toMap();
      expect(map['id'], 'group-1');
      expect(map['name'], 'Test Group');
      expect(map['description'], 'A test group description');
      expect(map['memberCount'], 5);
      expect(map['createdAt'], 1000000);
    });

    test('fromMap deserializes correctly', () {
      final group = Group.fromMap({
        'id': 'group-2',
        'tenantId': 'tenant-1',
        'name': 'Another Group',
        'description': 'Description',
        'createdAt': 2000000,
        'memberCount': 3,
      });
      expect(group.id, 'group-2');
      expect(group.name, 'Another Group');
      expect(group.memberCount, 3);
    });

    test('fromMap handles null optional fields', () {
      final group = Group.fromMap({
        'id': 'group-3',
        'tenantId': 'tenant-1',
        'name': 'Minimal Group',
      });
      expect(group.description, '');
      expect(group.createdAt, 0);
      expect(group.memberCount, 0);
    });

    test('equality based on id only', () {
      expect(baseGroup, baseGroup.copyWith(name: 'Different Name'));
      expect(baseGroup, isNot(baseGroup.copyWith(id: 'other-id')));
    });

    test('toString contains id, name, and memberCount', () {
      final str = baseGroup.toString();
      expect(str, contains('group-1'));
      expect(str, contains('Test Group'));
      expect(str, contains('5'));
    });
  });
}
