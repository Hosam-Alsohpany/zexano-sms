import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:zexano_sms/features/backup/domain/value_objects/backup_passphrase.dart';

class EncryptionService {
  static const int _ivLength = 16;
  static const int _keyLength = 32;

  List<int> _deriveKey(String passphrase) {
    return sha256.convert(utf8.encode(passphrase)).bytes.sublist(0, _keyLength);
  }

  Uint8List _generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_ivLength, (_) => random.nextInt(256)),
    );
  }

  String encrypt(String plaintext, BackupPassphrase passphrase) {
    final keyBytes = _deriveKey(passphrase.value);
    final iv = _generateIv();
    final plainBytes = utf8.encode(plaintext);

    final padded = _pad(plainBytes, 16);
    final encrypted = _aesCbcEncrypt(padded, keyBytes, iv);

    final combined = Uint8List(_ivLength + encrypted.length)
      ..setAll(0, iv)
      ..setAll(_ivLength, encrypted);

    return base64.encode(combined);
  }

  String decrypt(String ciphertextBase64, BackupPassphrase passphrase) {
    final keyBytes = _deriveKey(passphrase.value);
    final combined = base64.decode(ciphertextBase64);

    if (combined.length < _ivLength + 16) {
      throw ArgumentError('Invalid ciphertext: too short');
    }

    final iv = combined.sublist(0, _ivLength);
    final encrypted = combined.sublist(_ivLength);

    final decrypted = _aesCbcDecrypt(encrypted, keyBytes, iv);
    final unpadded = _unpad(decrypted, 16);

    return utf8.decode(unpadded);
  }

  Uint8List _aesCbcEncrypt(
    Uint8List plaintext,
    List<int> key,
    List<int> iv,
  ) {
    final expandedKey = _expandKey(key);
    final blocks = _splitBlocks(plaintext);
    final result = Uint8List(plaintext.length);
    var previous = iv;

    for (var i = 0; i < blocks.length; i++) {
      final block = _xorBlocks(blocks[i], previous);
      final encrypted = _encryptBlock(block, expandedKey);
      result.setAll(i * 16, encrypted);
      previous = encrypted;
    }

    return result;
  }

  Uint8List _aesCbcDecrypt(
    Uint8List ciphertext,
    List<int> key,
    List<int> iv,
  ) {
    final expandedKey = _expandKey(key);
    final blocks = _splitBlocks(ciphertext);
    final result = Uint8List(ciphertext.length);
    var previous = iv;

    for (var i = 0; i < blocks.length; i++) {
      final decrypted = _decryptBlock(blocks[i], expandedKey);
      final plain = _xorBlocks(decrypted, previous);
      result.setAll(i * 16, plain);
      previous = blocks[i];
    }

    return result;
  }

  List<Uint8List> _splitBlocks(Uint8List data) {
    final blocks = <Uint8List>[];
    for (var i = 0; i < data.length; i += 16) {
      blocks.add(Uint8List.sublistView(data, i, i + 16));
    }
    return blocks;
  }

  Uint8List _xorBlocks(List<int> a, List<int> b) {
    return Uint8List.fromList(
      List<int>.generate(16, (i) => a[i] ^ b[i]),
    );
  }

  Uint8List _pad(Uint8List data, int blockSize) {
    final padLen = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLen)
      ..setAll(0, data)
      ..fillRange(data.length, data.length + padLen, padLen);
    return padded;
  }

  Uint8List _unpad(Uint8List data, int blockSize) {
    final padLen = data[data.length - 1];
    if (padLen < 1 || padLen > blockSize) {
      throw ArgumentError('Invalid padding');
    }
    for (var i = data.length - padLen; i < data.length; i++) {
      if (data[i] != padLen) {
        throw ArgumentError('Invalid padding');
      }
    }
    return Uint8List.sublistView(data, 0, data.length - padLen);
  }

  static const List<int> _sBox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
    0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc,
    0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
    0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
    0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85,
    0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17,
    0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88,
    0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9,
    0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6,
    0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94,
    0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
    0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
  ];

  static const List<int> _rCon = [
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
    0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a,
  ];

  List<List<int>> _expandKey(List<int> key) {
    final nk = key.length ~/ 4;
    final nr = nk + 6;
    final totalWords = 4 * (nr + 1);
    final w = <List<int>>[];

    for (var i = 0; i < nk; i++) {
      w.add(key.sublist(i * 4, i * 4 + 4));
    }

    for (var i = nk; i < totalWords; i++) {
      var temp = List<int>.from(w[i - 1]);
      if (i % nk == 0) {
        temp = _rotWord(temp);
        temp = _subWord(temp);
        temp[0] ^= _rCon[i ~/ nk - 1];
      } else if (nk > 6 && i % nk == 4) {
        temp = _subWord(temp);
      }
      w.add(List<int>.generate(4, (j) => w[i - nk][j] ^ temp[j]));
    }

    final roundKeys = <List<int>>[];
    for (var r = 0; r <= nr; r++) {
      final rk = <int>[];
      for (var i = 0; i < 4; i++) {
        rk.addAll(w[r * 4 + i]);
      }
      roundKeys.add(rk);
    }
    return roundKeys;
  }

  List<int> _rotWord(List<int> word) {
    return [word[1], word[2], word[3], word[0]];
  }

  List<int> _subWord(List<int> word) {
    return word.map((b) => _sBox[b]).toList();
  }

  Uint8List _encryptBlock(Uint8List block, List<List<int>> roundKeys) {
    var state = block.toList();
    state = _addRoundKey(state, roundKeys[0]);

    for (var r = 1; r < roundKeys.length - 1; r++) {
      state = _subBytes(state);
      state = _shiftRows(state);
      state = _mixColumns(state);
      state = _addRoundKey(state, roundKeys[r]);
    }

    state = _subBytes(state);
    state = _shiftRows(state);
    state = _addRoundKey(state, roundKeys.last);

    return Uint8List.fromList(state);
  }

  Uint8List _decryptBlock(Uint8List block, List<List<int>> roundKeys) {
    var state = block.toList();
    state = _addRoundKey(state, roundKeys.last);

    for (var r = roundKeys.length - 2; r >= 1; r--) {
      state = _invShiftRows(state);
      state = _invSubBytes(state);
      state = _addRoundKey(state, roundKeys[r]);
      state = _invMixColumns(state);
    }

    state = _invShiftRows(state);
    state = _invSubBytes(state);
    state = _addRoundKey(state, roundKeys[0]);

    return Uint8List.fromList(state);
  }

  List<int> _addRoundKey(List<int> state, List<int> roundKey) {
    return List<int>.generate(16, (i) => state[i] ^ roundKey[i]);
  }

  List<int> _subBytes(List<int> state) {
    return state.map((b) => _sBox[b]).toList();
  }

  List<int> _invSubBytes(List<int> state) {
    return state.map((b) => _invSBox[b]).toList();
  }

  List<int> _shiftRows(List<int> state) {
    final s = List<int>.from(state);
    return [
      s[0], s[5], s[10], s[15],
      s[4], s[9], s[14], s[3],
      s[8], s[13], s[2], s[7],
      s[12], s[1], s[6], s[11],
    ];
  }

  List<int> _invShiftRows(List<int> state) {
    final s = List<int>.from(state);
    return [
      s[0], s[13], s[10], s[7],
      s[4], s[1], s[14], s[11],
      s[8], s[5], s[2], s[15],
      s[12], s[9], s[6], s[3],
    ];
  }

  int _gmul(int a, int b) {
    int p = 0;
    for (var i = 0; i < 8; i++) {
      if ((b & 1) != 0) p ^= a;
      final hi = a & 0x80;
      a = (a << 1) & 0xff;
      if (hi != 0) a ^= 0x1b;
      b >>= 1;
    }
    return p;
  }

  List<int> _mixColumns(List<int> state) {
    final s = List<int>.from(state);
    for (var c = 0; c < 4; c++) {
      final i = c * 4;
      s[i] = _gmul(2, state[i]) ^ _gmul(3, state[i + 1]) ^ state[i + 2] ^ state[i + 3];
      s[i + 1] = state[i] ^ _gmul(2, state[i + 1]) ^ _gmul(3, state[i + 2]) ^ state[i + 3];
      s[i + 2] = state[i] ^ state[i + 1] ^ _gmul(2, state[i + 2]) ^ _gmul(3, state[i + 3]);
      s[i + 3] = _gmul(3, state[i]) ^ state[i + 1] ^ state[i + 2] ^ _gmul(2, state[i + 3]);
    }
    return s;
  }

  List<int> _invMixColumns(List<int> state) {
    final s = List<int>.from(state);
    for (var c = 0; c < 4; c++) {
      final i = c * 4;
      s[i] = _gmul(14, state[i]) ^ _gmul(11, state[i + 1]) ^ _gmul(13, state[i + 2]) ^ _gmul(9, state[i + 3]);
      s[i + 1] = _gmul(9, state[i]) ^ _gmul(14, state[i + 1]) ^ _gmul(11, state[i + 2]) ^ _gmul(13, state[i + 3]);
      s[i + 2] = _gmul(13, state[i]) ^ _gmul(9, state[i + 1]) ^ _gmul(14, state[i + 2]) ^ _gmul(11, state[i + 3]);
      s[i + 3] = _gmul(11, state[i]) ^ _gmul(13, state[i + 1]) ^ _gmul(9, state[i + 2]) ^ _gmul(14, state[i + 3]);
    }
    return s;
  }

  static const List<int> _invSBox = [
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38,
    0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87,
    0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d,
    0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2,
    0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16,
    0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda,
    0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a,
    0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02,
    0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea,
    0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85,
    0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89,
    0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20,
    0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31,
    0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d,
    0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0,
    0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26,
    0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d,
  ];
}
