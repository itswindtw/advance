import os.path

import wcwidth


def main():
    base_path = os.path.dirname(os.path.abspath(__file__))

    report = []
    start_at = None

    with open(os.path.join(base_path, "../../priv/ucd/UnicodeData.txt"), "r") as f:
        for line in f:
            parts = line.split(";")
            codepoint, name = parts[:2]
            codepoint = int(parts[0], 16)

            if start_at is not None:
                for x in range(start_at, codepoint + 1):
                    report.append((x, wcwidth.wcwidth(chr(x))))

                start_at = None
            elif name.endswith(", First>"):
                start_at = codepoint
            else:
                report.append((codepoint, wcwidth.wcwidth(chr(codepoint))))

    with open(os.path.join(base_path, "report.csv"), "w") as f:
        for codepoint, width in report:
            f.write(f"{format(codepoint, 'x').upper()},{width}\n")


if __name__ == "__main__":
    main()
