#!/usr/bin/env python3

import sys

# bitmap swap tables: 3 input bytes (3*8 pixels, MSB on left) to 4 output bytes (4*6 pixels, LSB on left)
swap_tables = []
# swap_tables[0] = input byte 0 swap tables: output bytes 0, 1
# swap_tables[1] = input byte 1 swap tables: output bytes 1, 2
# swap_tables[2] = input byte 2 swap tables: output bytes 2, 3

def swap_bits2(n, i):
    result = 0
    b1, b2 = 0, 0
    for j in range(8):
        result <<= 1
        result |= n & 1
        n >>= 1
    if i == 0:
        b1 = result & 0x3F
        b2 = (result & 0xC0) >> 6
    elif i == 1:
        b1 = (result & 0x0F) << 2
        b2 = (result & 0xF0) >> 4
    elif i == 2:
        b1 = (result & 0x03) << 4
        b2 = (result & 0xFC) >> 2
    return b1, b2

def prepare_swap_tables():
    n = 0
    for i in range(3):
        swap_tables.append(([], []))
        for b in range(256):
            swap_lo, swap_hi = swap_bits2(b, i)
            swap_tables[i][0].append(swap_lo)
            swap_tables[i][1].append(swap_hi)

def three_to_four(in0, in1, in2):
    out0 = swap_tables[0][0][in0]
    out1 = swap_tables[0][1][in0]

    out1 |= swap_tables[1][0][in1]
    out2 =  swap_tables[1][1][in1]

    out2 |= swap_tables[2][0][in2]
    out3 =  swap_tables[2][1][in2]

    return out0, out1, out2, out3


def main():
    prepare_swap_tables()
    # ib = (255,0,0)
    # print(ib, "->", three_to_four(*ib))
    for img_fname in sys.argv[1:]:
        with open(img_fname, "rb") as f:
            input_data = f.read()
    output_data = []
    with open("banner.dat", "wb") as f:
        # process data rows, each row is 32 bytes
        for row_offset in range(0, len(input_data), 32):
            # process 30 bytes on each row, skip first and last byte
            for input_offset in range(row_offset + 1, row_offset + 31, 3):
                f.write(bytes(
                    three_to_four(
                        input_data[input_offset],
                        input_data[input_offset+1],
                        input_data[input_offset+2])
                ))


if __name__ == '__main__':
    sys.exit(main())
