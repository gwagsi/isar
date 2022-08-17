import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../../util/common.dart';
import '../../util/sync_async_helper.dart';

part 'filter_link_nested_test.g.dart';

@Collection()
class SourceModel {
  SourceModel(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final links = IsarLinks<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  String toString() {
    return 'SourceModel{id: $id}';
  }
}

@Collection()
class TargetModel {
  TargetModel(this.name);

  Id id = Isar.autoIncrement;

  final String name;

  final nestedLinks = IsarLinks<NestedTargetModel>();

  @Backlink(to: 'links')
  final linksBacklinks = IsarLinks<SourceModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'TargetModel{id: $id, name: $name}';
  }
}

@Collection()
class NestedTargetModel {
  NestedTargetModel(this.name);

  Id id = Isar.autoIncrement;

  final String name;

  @Backlink(to: 'nestedLinks')
  final nestedLinksBacklinks = IsarLinks<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NestedTargetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'NestedTargetModel{id: $id, name: $name}';
  }
}

void main() {
  group('Filter link nested', () {
    late Isar isar;

    late SourceModel source1;
    late SourceModel source2;
    late SourceModel source3;
    late SourceModel source4;
    late SourceModel source5;
    late SourceModel source6;

    late TargetModel target1;
    late TargetModel target2;
    late TargetModel target3;
    late TargetModel target4;
    late TargetModel target5;
    late TargetModel target6;

    late NestedTargetModel nestedTarget1;
    late NestedTargetModel nestedTarget2;
    late NestedTargetModel nestedTarget3;
    late NestedTargetModel nestedTarget4;
    late NestedTargetModel nestedTarget5;
    late NestedTargetModel nestedTarget6;

    setUp(() async {
      isar = await openTempIsar([
        SourceModelSchema,
        TargetModelSchema,
        NestedTargetModelSchema,
      ]);

      source1 = SourceModel('source 1');
      source2 = SourceModel('source 2');
      source3 = SourceModel('source 3');
      source4 = SourceModel('source 4');
      source5 = SourceModel('source 5');
      source6 = SourceModel('source 6');

      target1 = TargetModel('target 1');
      target2 = TargetModel('target 2');
      target3 = TargetModel('target 3');
      target4 = TargetModel('target 4');
      target5 = TargetModel('target 5');
      target6 = TargetModel('target 6');

      nestedTarget1 = NestedTargetModel('nested target 1');
      nestedTarget2 = NestedTargetModel('nested target 2');
      nestedTarget3 = NestedTargetModel('nested target 3');
      nestedTarget4 = NestedTargetModel('nested target 4');
      nestedTarget5 = NestedTargetModel('nested target 5');
      nestedTarget6 = NestedTargetModel('nested target 6');

      await isar.tWriteTxn(
        () => Future.wait([
          isar.sourceModels.tPutAll([
            source1,
            source2,
            source3,
            source4,
            source5,
            source6,
          ]),
          isar.targetModels.tPutAll([
            target1,
            target2,
            target3,
            target4,
            target5,
            target6,
          ]),
          isar.nestedTargetModels.tPutAll([
            nestedTarget1,
            nestedTarget2,
            nestedTarget3,
            nestedTarget4,
            nestedTarget5,
            nestedTarget6,
          ]),
        ]),
      );

      source1.links.add(target1);
      source2.links.addAll([target1, target2]);
      source3.links.addAll([target1, target2, target3]);
      source4.links.addAll([target3, target4]);
      source5.links.add(target5);

      target1.nestedLinks.add(nestedTarget1);
      target2.nestedLinks.addAll([nestedTarget1, nestedTarget2]);
      target3.nestedLinks.addAll([nestedTarget1, nestedTarget2, nestedTarget3]);
      target4.nestedLinks.addAll([nestedTarget3, nestedTarget4, nestedTarget5]);
      target6.nestedLinks.add(nestedTarget5);

      await isar.tWriteTxn(
        () => Future.wait([
          source1.links.tSave(),
          source2.links.tSave(),
          source3.links.tSave(),
          source4.links.tSave(),
          source5.links.tSave(),
          target1.nestedLinks.tSave(),
          target2.nestedLinks.tSave(),
          target3.nestedLinks.tSave(),
          target4.nestedLinks.tSave(),
        ]),
      );
    });

    group('Links', () {
      isarTest('.links()', () async {
        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameStartsWith('target'))
              .tFindAll(),
          [source1, source2, source3, source4, source5],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('target 1'))
              .tFindAll(),
          [source1, source2, source3],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('target 2'))
              .tFindAll(),
          [source2, source3],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('target 3'))
              .tFindAll(),
          [source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('target 4'))
              .tFindAll(),
          [source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('target 5'))
              .tFindAll(),
          [source5],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nameEqualTo('non existing'))
              .tFindAll(),
          [],
        );
      });

      // FIXME(severe): Nested links filters returns all values
      // Seems that the nested query is completely ignored
      isarTest('.links() with .nestedLinks()', () async {
        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameStartsWith('nested target')),
              )
              .tFindAll(),
          [source1, source2, source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 1')),
              )
              .tFindAll(),
          [source1, source2, source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 2')),
              )
              .tFindAll(),
          [source2, source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 3')),
              )
              .tFindAll(),
          [source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 4')),
              )
              .tFindAll(),
          [source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 5')),
              )
              .tFindAll(),
          [source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('nested target 6')),
              )
              .tFindAll(),
          [],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links(
                (q) => q.nestedLinks((q) => q.nameEqualTo('non existing')),
              )
              .tFindAll(),
          [],
        );
      });

      // FIXME(severe): Nested links filters returns all values
      // Seems that the nested query is completely ignored
      isarTest('.links() with .nestedLinksLengthEqualTo()', () async {
        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksLengthEqualTo(0))
              .tFindAll(),
          [source5],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksLengthEqualTo(1))
              .tFindAll(),
          [source1, source2, source3],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksLengthEqualTo(2))
              .tFindAll(),
          [source2, source3],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksLengthEqualTo(3))
              .tFindAll(),
          [source3, source4],
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksLengthEqualTo(4))
              .tFindAll(),
          [],
        );
      });

      // FIXME(severe): Nested links filters returns all values
      // Seems that the nested query is completely ignored
      isarTest('.links() with .nestedLinkIsEmpty()', () async {
        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksIsEmpty())
              .tFindAll(),
          [source5],
        );

        await isar.tWriteTxn(() => target1.nestedLinks.tReset());

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksIsEmpty())
              .tFindAll(),
          [source1, source5],
        );

        await isar.tWriteTxn(
          () => isar.nestedTargetModels.where().tDeleteAll(),
        );

        await qEqualSet(
          isar.sourceModels
              .filter()
              .links((q) => q.nestedLinksIsEmpty())
              .tFindAll(),
          [source1, source2, source3, source4, source5],
        );
      });
    });

    group('Backlinks', () {
      isarTest('.nestedLinksBacklinks()', () async {
        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target'))
              .tFindAll(),
          [
            nestedTarget1,
            nestedTarget2,
            nestedTarget3,
            nestedTarget4,
            nestedTarget5,
          ],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 1'))
              .tFindAll(),
          [nestedTarget1],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 2'))
              .tFindAll(),
          [nestedTarget1, nestedTarget2],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 3'))
              .tFindAll(),
          [nestedTarget1, nestedTarget2, nestedTarget3],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 4'))
              .tFindAll(),
          [nestedTarget3, nestedTarget4, nestedTarget5],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 5'))
              .tFindAll(),
          [],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('target 6'))
              .tFindAll(),
          [],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.nameStartsWith('non existing'))
              .tFindAll(),
          [],
        );
      });

      // FIXME(severe): Nested links filters returns all values
      // Seems that the nested query is completely ignored
      isarTest('.nestedLinksBackLinks', () async {
        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameStartsWith('source')),
              )
              .tFindAll(),
          [
            nestedTarget1,
            nestedTarget2,
            nestedTarget3,
            nestedTarget4,
            nestedTarget5,
          ],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 1')),
              )
              .tFindAll(),
          [nestedTarget1],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 2')),
              )
              .tFindAll(),
          [nestedTarget1, nestedTarget2],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 3')),
              )
              .tFindAll(),
          [nestedTarget1, nestedTarget2, nestedTarget3],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 4')),
              )
              .tFindAll(),
          [
            nestedTarget1,
            nestedTarget2,
            nestedTarget3,
            nestedTarget4,
            nestedTarget5,
          ],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 5')),
              )
              .tFindAll(),
          [],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('source 6')),
              )
              .tFindAll(),
          [],
        );

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks(
                (q) => q.linksBacklinks((q) => q.nameEqualTo('non existing')),
              )
              .tFindAll(),
          [],
        );
      });

      // FIXME(severe): Nested links filters returns all values
      // Seems that the nested query is completely ignored
      isarTest(
        '.nestedLinksBacklinks() with .linksBacklinksLengthEqualTo()',
        () async {
          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(0))
                .tFindAll(),
            [nestedTarget5],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(1))
                .tFindAll(),
            [nestedTarget3, nestedTarget4, nestedTarget5],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(2))
                .tFindAll(),
            [nestedTarget1, nestedTarget2, nestedTarget3],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(3))
                .tFindAll(),
            [nestedTarget1],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(4))
                .tFindAll(),
            [],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(5))
                .tFindAll(),
            [],
          );

          await qEqualSet(
            isar.nestedTargetModels
                .filter()
                .nestedLinksBacklinks((q) => q.linksBacklinksLengthEqualTo(6))
                .tFindAll(),
            [],
          );
        },
      );
    });

    // FIXME(severe): Nested links filters returns all values
    // Seems that the nested query is completely ignored
    isarTest(
      '.nestedLinksBacklinks() with .linksBacklinksIsEmpty()',
      () async {
        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.linksBacklinksIsEmpty())
              .tFindAll(),
          [nestedTarget5],
        );

        return;
        // FIXME: IsarError: Cannot perform this operation from within an active
        // transaction.
        // Are we suppose to a able to reset backlinks?
        //
        // It seems that a sync method is called in an async transaction
        // Also seems to only happen on `.reset()` of backlinks
        await isar.tWriteTxn(() => target1.linksBacklinks.tReset());

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.linksBacklinksIsEmpty())
              .tFindAll(),
          [nestedTarget1, nestedTarget5],
        );

        await isar.tWriteTxn(() => isar.sourceModels.where().tDeleteAll());

        await qEqualSet(
          isar.nestedTargetModels
              .filter()
              .nestedLinksBacklinks((q) => q.linksBacklinksIsEmpty())
              .tFindAll(),
          [
            nestedTarget1,
            nestedTarget2,
            nestedTarget3,
            nestedTarget4,
            nestedTarget5,
          ],
        );
      },
    );
  });
}
