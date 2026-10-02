import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/features/contacts/data/handlers/csv_vcf_contacts_handler.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

void main() {
  late CsvVcfContactsHandler handler;

  setUp(() => handler = CsvVcfContactsHandler());

  group('parseCsvLine()', () {
    test('splits simple comma-separated values', () {
      expect(handler.parseCsvLine('a,b,c'), ['a', 'b', 'c']);
    });

    test('trims whitespace from values', () {
      expect(handler.parseCsvLine('  a , b , c  '), ['a', 'b', 'c']);
    });

    test('handles quoted fields with commas', () {
      expect(handler.parseCsvLine('"Doe, John",123,"note"'), ['Doe, John', '123', 'note']);
    });

    test('handles escaped quotes inside quoted fields', () {
      expect(handler.parseCsvLine('"say ""hello""",val'), ['say "hello"', 'val']);
    });

    test('handles single value', () {
      expect(handler.parseCsvLine('justone'), ['justone']);
    });
  });

  group('findColumn()', () {
    test('finds column by first matching alias', () {
      expect(handler.findColumn(['name', 'phone', 'email'], ['phone', 'tel']), 1);
    });

    test('ignores case and underscores', () {
      expect(handler.findColumn(['First Name', 'Phone Number'], ['first_name']), 0);
    });

    test('returns -1 when no column matches', () {
      expect(handler.findColumn(['a', 'b', 'c'], ['phone']), -1);
    });
  });

  group('parseCsv()', () {
    test('parses standard CSV with first_name, last_name, phone', () {
      final csv = 'first_name,last_name,phone\nJohn,Doe,+1234567890\nJane,Smith,+9876543210';
      final contacts = handler.parseCsv(csv);
      expect(contacts, hasLength(2));
      expect(contacts[0].firstName, 'John');
      expect(contacts[0].lastName, 'Doe');
      expect(contacts[0].phoneNumber, '+1234567890');
      expect(contacts[1].firstName, 'Jane');
      expect(contacts[1].lastName, 'Smith');
      expect(contacts[1].phoneNumber, '+9876543210');
    });

    test('parses CSV with full_name column', () {
      final csv = 'full_name,phone\n"John Doe",+1234567890\n"Jane Smith",+9876543210';
      final contacts = handler.parseCsv(csv);
      expect(contacts, hasLength(2));
      expect(contacts[0].firstName, 'John');
      expect(contacts[0].lastName, 'Doe');
      expect(contacts[1].firstName, 'Jane');
      expect(contacts[1].lastName, 'Smith');
    });

    test('parses CSV with only full_name (no space splits correctly)', () {
      final csv = 'name,phone\nJohn,+123\nSingleName,+456';
      final contacts = handler.parseCsv(csv);
      expect(contacts, hasLength(2));
      expect(contacts[0].firstName, 'John');
      expect(contacts[0].lastName, '');
      expect(contacts[1].firstName, 'SingleName');
      expect(contacts[1].lastName, '');
    });

    test('parses CSV with notes column', () {
      final csv = 'first,last,phone,notes\nJohn,Doe,+1234567890,my friend';
      final contacts = handler.parseCsv(csv);
      expect(contacts, hasLength(1));
      expect(contacts[0].notes, 'my friend');
    });

    test('returns empty list when CSV has no phone column', () {
      final csv = 'name,email\nJohn,john@test.com';
      expect(handler.parseCsv(csv), isEmpty);
    });

    test('returns empty list when CSV has only header', () {
      final csv = 'first_name,last_name,phone';
      expect(handler.parseCsv(csv), isEmpty);
    });

    test('returns empty list for empty content', () {
      expect(handler.parseCsv(''), isEmpty);
    });

    test('skips rows with empty phone', () {
      final csv = 'phone,first\n+123,John\n,Jane\n+456,Joe';
      final contacts = handler.parseCsv(csv);
      expect(contacts, hasLength(2));
    });
  });

  group('decodeQuotedPrintable()', () {
    test('decodes simple ASCII unchanged', () {
      expect(handler.decodeQuotedPrintable('Hello World'), 'Hello World');
    });

    test('decodes QP-encoded space', () {
      expect(handler.decodeQuotedPrintable('=20'), ' ');
    });

    test('decodes QP-encoded Arabic text', () {
      final decoded = handler.decodeQuotedPrintable(
        '=D9=87=D9=8A=D8=AB=D9=85=20=D8=AF=D9=87=D8=A7=D9=82',
      );
      expect(decoded, 'هيثم دهاق');
    });

    test('decodes mixed ASCII and QP', () {
      final decoded = handler.decodeQuotedPrintable('Hello=20=D8=A7=D9=84=D8=B9=D8=A7=D9=84=D9=85');
      expect(decoded, 'Hello العالم');
    });

    test('handles lone = at end without crashing', () {
      expect(handler.decodeQuotedPrintable('test='), 'test=');
    });

    test('falls back to Latin-1 when bytes are not valid UTF-8', () {
      // Latin-1 QP: =E9 =E0 =E7 =E3 =C9 =F4 =E9 =E1 =E3 =E7 =E4 =E5 =E3
      // Decodes to Latin-1 bytes, not valid UTF-8
      final decoded = handler.decodeQuotedPrintable('=E9=E0=E7=E3');
      expect(decoded, isNotEmpty);
    });
  });

  group('parseVcf()', () {
    test('parses a single vCard', () {
      final vcf = 'BEGIN:VCARD\nFN:John Doe\nTEL:+1234567890\nNOTE:Friend\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'John');
      expect(contacts[0].lastName, 'Doe');
      expect(contacts[0].phoneNumber, '+1234567890');
      expect(contacts[0].notes, 'Friend');
    });

    test('parses multiple vCards', () {
      final vcf = 'BEGIN:VCARD\nFN:John Doe\nTEL:+111\nEND:VCARD\nBEGIN:VCARD\nFN:Jane Smith\nTEL:+222\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(2));
      expect(contacts[0].firstName, 'John');
      expect(contacts[1].firstName, 'Jane');
    });

    test('uses N property when FN is absent', () {
      final vcf = 'BEGIN:VCARD\nN:Smith;Jane;;;\nTEL:+1234567890\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'Jane');
      expect(contacts[0].lastName, 'Smith');
    });

    test('skips vCard without phone number', () {
      final vcf = 'BEGIN:VCARD\nFN:John Doe\nEND:VCARD';
      expect(handler.parseVcf(vcf), isEmpty);
    });

    test('returns empty list for empty content', () {
      expect(handler.parseVcf(''), isEmpty);
    });

    test('parses vCard with TEL prefixed with TYPE', () {
      final vcf = 'BEGIN:VCARD\nFN:John\nTEL;TYPE=CELL:+123\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].phoneNumber, '+123');
    });

    test('decodes QP-encoded Arabic FN', () {
      final vcf = 'BEGIN:VCARD\nFN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=D9=87=D9=8A=D8=AB=D9=85=20=D8=AF=D9=87=D8=A7=D9=82\nTEL:+967771234567\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'هيثم');
      expect(contacts[0].lastName, 'دهاق');
    });

    test('decodes QP-encoded N property', () {
      final vcf = 'BEGIN:VCARD\nN;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:=D8=AF=D9=87=D8=A7=D9=82;=D9=87=D9=8A=D8=AB=D9=85;;;\nTEL:+967771234567\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'هيثم');
      expect(contacts[0].lastName, 'دهاق');
    });

    test('merges QP soft line break ( = at end of line)', () {
      // FN value spans two lines: soft break splits between =D9 and =85 (=م)
      final vcf = 'BEGIN:VCARD\nFN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=D8=A7=D8=A8=D8=B1=D8=A7=D9=87=D9=8A=D9=\n =85=20=D8=B3=D8=B9=D9=8A=D8=AF\nTEL:+967701351194\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'ابراهيم');
      expect(contacts[0].lastName, 'سعيد');
    });

    test('handles emoji in raw (non-QP) vCard', () {
      // Name is split on last space → firstName='Test', lastName='😀'
      final vcf = 'BEGIN:VCARD\nFN:Test😀\nTEL:+123\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'Test😀');
    });

    test('handles emoji in QP-encoded vCard', () {
      // 😀 = F0 9F 98 80 in UTF-8
      final vcf = 'BEGIN:VCARD\nFN;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:=F0=9F=98=80\nTEL:+123\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, '😀');
    });

    test('handles Arabic QP with soft break and emoji', () {
      // "هيثم" + space + "😀" → split on space → firstName='هيثم', lastName='😀'
      final vcf =
          'BEGIN:VCARD\nFN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=D9=87=D9=8A=D8=AB=D9=85=20=F0=\n =9F=98=80\nTEL:+967771234567\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'هيثم');
      expect(contacts[0].lastName, '😀');
    });

    test('handles vCard folding (tab-continued line)', () {
      // In vCard, folded lines continue with a leading space or tab
      // The space/tab is the fold marker and is removed when unfolding
      final vcf = 'BEGIN:VCARD\nFN:John\nNOTE:This is long\n\ttext\nTEL:+123\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].notes, 'This is longtext');
    });

    test('does not crash on raw Arabic text with QP flag', () {
      // Some vCards mark ENCODING=QUOTED-PRINTABLE but the value is
      // actually raw UTF-8 (already decoded by readAsString()).
      final vcf =
          'BEGIN:VCARD\nFN;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:ابراهيم سعيد\nTEL:+967701351194\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'ابراهيم');
      expect(contacts[0].lastName, 'سعيد');
    });

    test('handles mixed raw text with QP hex sequences gracefully', () {
      // Value has both raw Arabic characters and trailing =XX QP hex
      final vcf =
          'BEGIN:VCARD\nFN;ENCODING=QUOTED-PRINTABLE:ابراهيم\nTEL:+123\nEND:VCARD';
      final contacts = handler.parseVcf(vcf);
      expect(contacts, hasLength(1));
      expect(contacts[0].firstName, 'ابراهيم');
    });
  });

  group('generateVcf() and VCF Escaping', () {
    test('generates valid vCard 3.0 representation', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+1234567890',
        notes: 'Friend',
        createdAt: 0,
      );
      final vcf = handler.generateVcf([contact]);
      expect(vcf, contains('BEGIN:VCARD'));
      expect(vcf, contains('VERSION:3.0'));
      expect(vcf, contains('FN:John Doe'));
      expect(vcf, contains('N:;John Doe;;;'));
      expect(vcf, contains('TEL;TYPE=CELL:+1234567890'));
      expect(vcf, contains('NOTE:Friend'));
      expect(vcf, contains('END:VCARD'));
    });

    test('escapes special characters in FN and NOTE for VCF', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'Smith; John, Jr.',
        lastName: '',
        phoneNumber: '+123',
        notes: r'Note with \ backslash, comma, and ; semicolon' + '\nNext line',
        createdAt: 0,
      );
      final vcf = handler.generateVcf([contact]);
      expect(vcf, contains(r'FN:Smith\; John\, Jr.'));
      expect(vcf, contains(r'NOTE:Note with \\ backslash\, comma\, and \; semicolon\nNext line'));
    });
  });

  group('generateCsv() and CSV Escaping', () {
    test('generates UTF-8 BOM CSV with full_name, phone, notes', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'حن🤍',
        phoneNumber: '+967771234567',
        notes: 'أفضل جهة اتصال',
        createdAt: 0,
      );
      final csv = handler.generateCsv([contact]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('full_name,phone,notes'));
      expect(csv, contains('عمتي حن🤍,+967771234567,أفضل جهة اتصال'));
    });

    test('escapes commas, quotes, and newlines in CSV fields', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'أحمد',
        lastName: '"محمد"',
        phoneNumber: '+967700000000',
        notes: 'السطر الأول\nالسطر الثاني, وملاحظة',
        createdAt: 0,
      );
      final csv = handler.generateCsv([contact]);
      expect(csv, contains('"أحمد ""محمد"""'));
      expect(csv, contains('"السطر الأول\nالسطر الثاني, وملاحظة"'));
    });
  });

  group('Round-Trip Tests (Contact -> Export -> Import -> Contact)', () {
    test('VCF round trip preserves fullName, phone, notes', () {
      final original = Contact(
        id: 'c1',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'حن🤍',
        phoneNumber: '+967771111111',
        notes: 'ملاحظة خاصة',
        createdAt: 0,
      );

      final vcf = handler.generateVcf([original]);
      final imported = handler.parseVcf(vcf);

      expect(imported, hasLength(1));
      expect(imported[0].fullName, original.fullName);
      expect(imported[0].phoneNumber, original.phoneNumber);
      expect(imported[0].notes, original.notes);
    });

    test('CSV round trip preserves fullName, phone, notes with BOM', () {
      final original = Contact(
        id: 'c2',
        tenantId: 'default',
        firstName: 'عمتي',
        lastName: 'مد🤍',
        phoneNumber: '+967772222222',
        notes: 'ملاحظة ثانية',
        createdAt: 0,
      );

      final csv = handler.generateCsv([original]);
      final imported = handler.parseCsv(csv);

      expect(imported, hasLength(1));
      expect(imported[0].fullName, original.fullName);
      expect(imported[0].phoneNumber, original.phoneNumber);
      expect(imported[0].notes, original.notes);
    });
  });

  group('Mandatory Unicode & Emoji Contact Name Cases (VCF & CSV)', () {
    final testNames = [
      'عمتي حن🤍',
      'عمتي مد🤍',
      'عمتي نس🤍',
      'محمد أحمد علي',
      'محمد أحمد علي 🤍',
      'عبدالله محمد أحمد',
      'أحمد محمد 😊',
      '🤍 عمتي',
      '😊 أحمد',
      'محمد أحمد 👨💻',
      'محمد أحمد علي 🤍 😊',
    ];

    for (final name in testNames) {
      test('Preserves "$name" in VCF round-trip', () {
        // Construct contact
        final spaceIdx = name.lastIndexOf(' ');
        final String first = spaceIdx > 0 ? name.substring(0, spaceIdx).trim() : name;
        final String last = spaceIdx > 0 ? name.substring(spaceIdx + 1).trim() : '';
        final contact = Contact(
          id: 'test',
          tenantId: 'default',
          firstName: first,
          lastName: last,
          phoneNumber: '+967770000001',
          notes: 'Test note',
          createdAt: 0,
        );
        expect(contact.fullName, name);

        final vcf = handler.generateVcf([contact]);
        final imported = handler.parseVcf(vcf);

        expect(imported, hasLength(1));
        expect(imported[0].fullName, name);
      });

      test('Preserves "$name" in CSV round-trip', () {
        final spaceIdx = name.lastIndexOf(' ');
        final String first = spaceIdx > 0 ? name.substring(0, spaceIdx).trim() : name;
        final String last = spaceIdx > 0 ? name.substring(spaceIdx + 1).trim() : '';
        final contact = Contact(
          id: 'test',
          tenantId: 'default',
          firstName: first,
          lastName: last,
          phoneNumber: '+967770000002',
          notes: 'Test note',
          createdAt: 0,
        );
        expect(contact.fullName, name);

        final csv = handler.generateCsv([contact]);
        final imported = handler.parseCsv(csv);

        expect(imported, hasLength(1));
        expect(imported[0].fullName, name);
      });
    }
  });

  group('CSV Edge Cases (quotes, commas, newlines)', () {
    test('handles Arabic comma in name', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'أحمد،',
        lastName: 'محمد',
        phoneNumber: '+967771234567',
        notes: '',
        createdAt: 0,
      );
      final csv = handler.generateCsv([contact]);
      final imported = handler.parseCsv(csv);
      expect(imported, hasLength(1));
      expect(imported[0].fullName, 'أحمد، محمد');
    });

    test('handles quotes in name', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'أحمد',
        lastName: '"محمد"',
        phoneNumber: '+967771234567',
        notes: '',
        createdAt: 0,
      );
      final csv = handler.generateCsv([contact]);
      final imported = handler.parseCsv(csv);
      expect(imported, hasLength(1));
      expect(imported[0].fullName, 'أحمد "محمد"');
    });

    test('handles multiline notes with commas and quotes', () {
      final contact = Contact(
        id: '1',
        tenantId: 'default',
        firstName: 'أحمد',
        lastName: 'علي',
        phoneNumber: '+967771234567',
        notes: 'السطر الأول\nالسطر الثاني, وملاحظة إضافية مع "علامات تنصيص"',
        createdAt: 0,
      );
      final csv = handler.generateCsv([contact]);
      final imported = handler.parseCsv(csv);
      expect(imported, hasLength(1));
      expect(imported[0].fullName, 'أحمد علي');
      expect(imported[0].notes, 'السطر الأول\nالسطر الثاني, وملاحظة إضافية مع "علامات تنصيص"');
    });
  });

  group('ExportFileResult Model Tests', () {
    test('success state sets properties correctly', () {
      const result = ExportFileResult.success('content://media/external/file.vcf');
      expect(result.status, ExportFileStatus.success);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.isFailed, isFalse);
      expect(result.pathOrUri, 'content://media/external/file.vcf');
      expect(result.errorMessage, isNull);
    });

    test('cancelled state sets properties correctly', () {
      const result = ExportFileResult.cancelled();
      expect(result.status, ExportFileStatus.cancelled);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.pathOrUri, isNull);
      expect(result.errorMessage, isNull);
    });

    test('failed state sets properties correctly', () {
      const result = ExportFileResult.failed('Storage permission denied');
      expect(result.status, ExportFileStatus.failed);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.isFailed, isTrue);
      expect(result.pathOrUri, isNull);
      expect(result.errorMessage, 'Storage permission denied');
    });
  });
}
