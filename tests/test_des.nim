import unittest

import nim_cryptopkg/des

test "Mask":
  check generateMask(0) == 0
  check generateMask(1) == 0x80_00_00_00_00_00_00_00'u64
  check generateMask(28) == 0xFFFFFFF000000000'u64
  check generateMask(64) == 0xFFFFFFFFFFFFFFFF'u64

test "Fesitel function":
  # https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm
  let input_key = 0b00010011_00110100_01010111_01111001_10011011_10111100_11011111_11110001'u64;
  let subkeys = generate_subkeys(input_key);
  let expected = 0b0010001101001010101010011011101100000000000000000000000000000000'u64;
  let r0 = 0b11110000101010101111000010101010_00000000_00000000_00000000_00000000'u64;
  check expected == feistel(r0, subkeys[0]);

test "Expansion function":
  # https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm
  let input = 0b1111000010101010111100001010101000000000000000000000000000000000'u64;
  let expected = 0b011110100001010101010101011110100001010101010101_00000000_00000000'u64;
  check expected == expansion(input);

test "Subkeys generation":
  # https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm
  let input_key = 0b00010011_00110100_01010111_01111001_10011011_10111100_11011111_11110001'u64;
  let subkeys = generateSubkeys(input_key);
  let expected = 0b1100101100111101100010110000111000010111111101010000000000000000'u64;
  check expected == subkeys[15];

test "Permut choice 1":
  # https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm
  let input = 0b00010011_00110100_01010111_01111001_10011011_10111100_11011111_11110001'u64;
  let expected = 0b1111000011001100101010101111010101010110011001111000111100000000'u64;
  check expected == permutChoice1(input);

test "Permutation":
  var input = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000000'u64;
  var expected = 0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000'u64;
  check expected == initialPermutation(input);

  input = 0b00000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000'u64;
  expected = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001'u64;
  check expected == initialPermutation(input);

test "Left shift":
  var expected = 0x2000001000000000'u64;
  var input = 0x90_00_00_00_00_00_00_00'u64;
  check expected == rotateLeft(input, 1, 28);

  expected = 0x4000002000000000'u64;
  input = 0x90_00_00_00_00_00_00_00'u64;
  check expected == rotateLeft(input, 2, 28);

test "Initial and final permutation":
  let input = 0x80_01_3F_00_D0_23_77_9A'u64;
  check input == finalPermutation(initialPermutation(input));

test "Encrypt and decrypt":
  let input = 123123'u64;
  let key = 112312323123'u64;
  check input == decrypt(encrypt(input, key), key);

test "Encrypt":
  # https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm
  let input = 0x0123456789ABCDEF'u64;
  let key = 0x133457799BBCDFF1'u64;
  check 0x85E813540F0AB405'u64 == encrypt(input, key);
