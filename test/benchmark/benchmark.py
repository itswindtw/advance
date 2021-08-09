import timeit

import wcwidth


PLANE0 = 0xFFFF
PLANE16 = 0x10FFFF


def main():
    started_at = timeit.default_timer()

    for codepoint in range(0, PLANE16 + 1):
        wcwidth.wcwidth(chr(codepoint))

    elapsed = timeit.default_timer() - started_at
    print(elapsed)


if __name__ == "__main__":
    main()
