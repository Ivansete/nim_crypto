proc generateMask*(numBits: int): uint64 =
    var ret = 0'u64;

    let mask = 0x80_00_00_00_00_00_00_00'u64;

    for i in 0..numBits-1:
        ret = ret or (mask shr i)

    return ret

proc permutation*(input: uint64, index_perm: seq[int]): uint64 =
    var ret = 0'u64;

    let input_mask = 0x80_00_00_00_00_00_00_00'u64;

    for i in 0..index_perm.len-1:
        if (input and (input_mask shr (index_perm[i] - 1))) > 0:
            ret = ret or (input_mask shr i);

    return ret

proc initialPermutation*(input: uint64): uint64 =
    let index_perm = @[58, 50, 42, 34, 26, 18, 10, 2, 60, 52, 44, 36, 28, 20, 12, 4, 62, 54, 46, 38, 30, 22, 14, 6, 64, 56, 48, 40, 32, 24, 16, 8, 57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3, 61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7];
    return permutation(input, index_perm)

proc finalPermutation*(input: uint64): uint64 =
    let index_perm = @[40, 8, 48, 16, 56, 24, 64, 32, 39, 7, 47, 15, 55, 23, 63, 31, 38, 6, 46, 14, 54, 22, 62, 30, 37, 5, 45, 13, 53, 21, 61, 29, 36, 4, 44, 12, 52, 20, 60, 28, 35, 3, 43, 11, 51, 19, 59, 27, 34, 2, 42, 10, 50, 18, 58, 26, 33, 1, 41, 9, 49, 17, 57, 25];
    return permutation(input, index_perm)

proc expansion*(input: uint64): uint64 =
    let index_perm = @[32, 1, 2, 3, 4, 5, 4, 5, 6, 7, 8, 9, 8, 9, 10, 11, 12, 13, 12, 13, 14, 15, 16, 17, 16, 17, 18, 19, 20, 21, 20, 21, 22, 23, 24, 25, 24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32, 1];
    return permutation(input, index_perm)

proc permutChoice1*(input: uint64): uint64 =
    let index_perm = @[57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 63, 55, 47, 39, 31, 23, 15, 7, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 28, 20, 12, 4];
    return permutation(input, index_perm)

proc permutChoice2*(input: uint64): uint64 =
    let index_perm = @[14, 17, 11, 24, 1, 5, 3, 28, 15, 6, 21, 10, 23, 19, 12, 4, 26, 8, 16, 7, 27, 20, 13, 2, 41, 52, 31, 37, 47, 55, 30, 40, 51, 45, 33, 48, 44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32];
    return permutation(input, index_perm)

# Rotates the 'input' parameter 'shiftAmount' bits to the left
# in a cyclic way. The 'numBits' attribute is needed
# because we are using a uint64 variable but maybe we are interested
# in rotating an smaller word.
proc rotateLeft*(input: uint64, shiftAmount: int, numBits: int): uint64 =
    let left = input shl shift_amount;
    let right = input shr (numBits - shift_amount);

    return (left or right) and generate_mask(numBits);

proc generateSubkeys*(key: uint64): array[16, uint64] =
    var ret: array[16, uint64];

    let k = permutChoice1(key);

    let c0 = k and generateMask(28);
    let d0 = (k shl 28) and generate_mask(28);

    let shift_left_per_round = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];

    var ci = c0;
    var di = d0;
    for num_round in 0..15:
        ci = rotateLeft(ci,
                        shift_left_per_round[numRound],
                        28);

        di = rotateLeft(di,
                        shift_left_per_round[numRound],
                        28);

        let ci_di = ci or (di shr 28); # ci_di contains a 56-bit partial key
        let ki = permutChoice2(ci_di); # ki contains the 48-bit subkey

        ret[numRound] = ki;

    return ret

proc sBox(numBox, x, y: int): int =
    let s1 = [[14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
              [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
              [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
              [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13]];

    let s2 = [[15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
              [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
              [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
              [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9]];

    let s3 = [[10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
              [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
              [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
              [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12]];

    let s4 = [[7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
              [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
              [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
              [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14]];

    let s5 = [[2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
              [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
              [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
              [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3]];

    let s6 = [[12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
              [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
              [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
              [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13]];

    let s7 = [[4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
              [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
              [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
              [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12]];

    let s8 = [[13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
              [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
              [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
              [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11]];

    let boxes = [s1, s2, s3, s4, s5, s6, s7, s8];

    return boxes[num_box][y][x]

proc feistel*(half: uint64, subkey: uint64): uint64 =
    # Expansion
    let expanded = expansion(half);

    var ret = 0'u64;
    for numBox in 0..7:
        # Key mixing
        let mixed = expanded xor subkey;

        # Substitution

        # Only consider the 6 bits for each box input
        var boxInput = mixed shr (58 - 6*numBox);
        boxInput = boxInput and 0x3F;

        let x = (boxInput and 0x1E) shr 1;
        let y = (boxInput and 0x20) shr 4 or (boxInput and 0x01);

        let boxOutput = sBox(numBox, int(x), int(y));

        ret = ret or (uint64(boxOutput)) shl (60 - (4 * uint64(numBox)))

    # Permutation
    let index_perm = @[16, 7, 20, 21, 29, 12, 28, 17, 1, 15, 23, 26, 5, 18, 31, 10, 2, 8, 24, 14, 32, 27, 3, 9, 19, 13, 30, 6, 22, 11, 4, 25];
    return permutation(ret, index_perm)

proc encryptOrDecrypt*(input: uint64, key: uint64, encrypt: bool): uint64 =
    let iniPerm = initialPermutation(input);

    let l0 = iniPerm and generateMask(32);
    let r0 = (iniPerm shl 32) and generate_mask(32);

    let subkeys = generate_subkeys(key);

    var li = l0;
    var ri = r0;

    for numIteration in 0..15:
        var index = numIteration;
        if not encrypt:
            index = 15 - numIteration;

        let kn = subkeys[index];

        let prevLi = li;
        li = ri;
        ri = prevLi xor feistel(ri, kn);

    return final_permutation(ri or (li shr 32))

proc encrypt*(input: uint64, key: uint64): uint64 =
    return encryptOrDecrypt(input, key, true)

proc decrypt*(input: uint64, key: uint64): uint64 =
    return encryptOrDecrypt(input, key, false)

