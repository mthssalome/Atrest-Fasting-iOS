import os
import re
import math
from xml.etree import ElementTree as ET

SVG_DIR = "Sources/DesignSystem/Resources"  # adjust if needed
OUTPUT_FILE = os.path.join("Sources", "DesignSystem", "TreePaths.swift")

NUMBER = r"-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
TOKEN_RE = re.compile(rf"([MmLlHhVvCcSsQqTtAaZz])|({NUMBER})")

def tokenize(d):
    return [a or b for a, b in TOKEN_RE.findall(d)]

def arc_to_cubic(x0, y0, rx, ry, phi, large, sweep, x1, y1):
    # Degenerates per SVG spec: treat as straight line / noop
    if x0 == x1 and y0 == y1:
        return []  # noop
    if rx == 0 or ry == 0:
        return []  # line fallback handled by caller

    phi = math.radians(phi % 360)
    cos_phi = math.cos(phi)
    sin_phi = math.sin(phi)

    dx = (x0 - x1) / 2
    dy = (y0 - y1) / 2
    x_ = cos_phi * dx + sin_phi * dy
    y_ = -sin_phi * dx + cos_phi * dy

    rx = abs(rx)
    ry = abs(ry)

    lam = (x_**2)/(rx**2) + (y_**2)/(ry**2)
    if lam > 1:
        s = math.sqrt(lam)
        rx *= s
        ry *= s

    sign = -1 if large == sweep else 1
    num = rx**2 * ry**2 - rx**2 * y_**2 - ry**2 * x_**2
    den = rx**2 * y_**2 + ry**2 * x_**2
    if den == 0:
        return []  # line fallback

    c = sign * math.sqrt(max(0, num / den))

    cx_ = c * (rx * y_) / ry
    cy_ = c * (-ry * x_) / rx

    cx = cos_phi * cx_ - sin_phi * cy_ + (x0 + x1) / 2
    cy = sin_phi * cx_ + cos_phi * cy_ + (y0 + y1) / 2

    def angle(u, v):
        dot = u[0]*v[0] + u[1]*v[1]
        mag = math.hypot(*u) * math.hypot(*v)
        if mag == 0:
            return 0.0
        s = u[0]*v[1] - u[1]*v[0]
        return math.copysign(math.acos(max(-1, min(1, dot/mag))), s)

    v0 = ((x_ - cx_) / rx, (y_ - cy_) / ry)
    v1 = ((-x_ - cx_) / rx, (-y_ - cy_) / ry)

    theta1 = angle((1, 0), v0)
    delta = angle(v0, v1)
    if not sweep and delta > 0:
        delta -= 2 * math.pi
    if sweep and delta < 0:
        delta += 2 * math.pi

    segments = max(1, int(abs(delta) / (math.pi / 2)) + 1)
    delta_seg = delta / segments

    curves = []
    for i in range(segments):
        t1 = theta1 + i * delta_seg
        t2 = t1 + delta_seg
        alpha = math.tan(delta_seg / 4) * 4 / 3

        p1 = (math.cos(t1), math.sin(t1))
        p2 = (math.cos(t2), math.sin(t2))

        c1 = (p1[0] - alpha * p1[1], p1[1] + alpha * p1[0])
        c2 = (p2[0] + alpha * p2[1], p2[1] - alpha * p2[0])

        def map_pt(p):
            return (
                cx + rx * (cos_phi * p[0] - sin_phi * p[1]),
                cy + ry * (sin_phi * p[0] + cos_phi * p[1]),
            )

        curves.append((map_pt(c1), map_pt(c2), map_pt(p2)))

    return curves

def parse_path(d):
    t = tokenize(d)
    i = 0
    x = y = 0.0
    sx = sy = 0.0

    # last cubic control2 (for S)
    cx = cy = 0.0
    # last quadratic control (for T)
    qx = qy = 0.0

    out = []
    last = None  # last command letter, uppercased

    def f():
        nonlocal i
        v = float(t[i])
        i += 1
        return v

    while i < len(t):
        cmd = t[i]
        i += 1
        up = cmd.upper()

        # Reset smooth-reflection state if the previous command was not a compatible curve
        if last not in ("C", "S"):
            cx, cy = x, y
        if last not in ("Q", "T"):
            qx, qy = x, y

        if cmd in "Mm":
            first = True
            while i < len(t) and not t[i].isalpha():
                nx, ny = f(), f()
                if cmd == "m":
                    nx += x; ny += y
                x, y = nx, ny
                if first:
                    out.append(f"p.move(to: CGPoint(x: {x}, y: {y}))")
                    sx, sy = x, y
                    first = False
                else:
                    out.append(f"p.addLine(to: CGPoint(x: {x}, y: {y}))")

        elif cmd in "Ll":
            while i < len(t) and not t[i].isalpha():
                nx, ny = f(), f()
                if cmd == "l":
                    nx += x; ny += y
                x, y = nx, ny
                out.append(f"p.addLine(to: CGPoint(x: {x}, y: {y}))")

        elif cmd in "Hh":
            while i < len(t) and not t[i].isalpha():
                nx = f()
                if cmd == "h":
                    nx += x
                x = nx
                out.append(f"p.addLine(to: CGPoint(x: {x}, y: {y}))")

        elif cmd in "Vv":
            while i < len(t) and not t[i].isalpha():
                ny = f()
                if cmd == "v":
                    ny += y
                y = ny
                out.append(f"p.addLine(to: CGPoint(x: {x}, y: {y}))")

        elif cmd in "Cc":
            while i < len(t) and not t[i].isalpha():
                x1, y1 = f(), f()
                x2, y2 = f(), f()
                nx, ny = f(), f()
                if cmd == "c":
                    x1 += x; y1 += y
                    x2 += x; y2 += y
                    nx += x; ny += y
                out.append(
                    f"p.addCurve(to: CGPoint(x: {nx}, y: {ny}), "
                    f"control1: CGPoint(x: {x1}, y: {y1}), "
                    f"control2: CGPoint(x: {x2}, y: {y2}))"
                )
                cx, cy = x2, y2
                x, y = nx, ny

        elif cmd in "Ss":
            while i < len(t) and not t[i].isalpha():
                x2, y2 = f(), f()
                nx, ny = f(), f()
                if cmd == "s":
                    x2 += x; y2 += y
                    nx += x; ny += y

                # If previous wasn't C/S, reflection is from current point (handled by reset above)
                x1 = 2 * x - cx
                y1 = 2 * y - cy

                out.append(
                    f"p.addCurve(to: CGPoint(x: {nx}, y: {ny}), "
                    f"control1: CGPoint(x: {x1}, y: {y1}), "
                    f"control2: CGPoint(x: {x2}, y: {y2}))"
                )
                cx, cy = x2, y2
                x, y = nx, ny

        elif cmd in "Qq":
            while i < len(t) and not t[i].isalpha():
                qx, qy = f(), f()
                nx, ny = f(), f()
                if cmd == "q":
                    qx += x; qy += y
                    nx += x; ny += y

                c1x = x + 2/3 * (qx - x)
                c1y = y + 2/3 * (qy - y)
                c2x = nx + 2/3 * (qx - nx)
                c2y = ny + 2/3 * (qy - ny)

                out.append(
                    f"p.addCurve(to: CGPoint(x: {nx}, y: {ny}), "
                    f"control1: CGPoint(x: {c1x}, y: {c1y}), "
                    f"control2: CGPoint(x: {c2x}, y: {c2y}))"
                )
                x, y = nx, ny

        elif cmd in "Tt":
            while i < len(t) and not t[i].isalpha():
                nx, ny = f(), f()
                if cmd == "t":
                    nx += x; ny += y

                # If previous wasn't Q/T, reflection is from current point (handled by reset above)
                qx = 2 * x - qx
                qy = 2 * y - qy

                c1x = x + 2/3 * (qx - x)
                c1y = y + 2/3 * (qy - y)
                c2x = nx + 2/3 * (qx - nx)
                c2y = ny + 2/3 * (qy - ny)

                out.append(
                    f"p.addCurve(to: CGPoint(x: {nx}, y: {ny}), "
                    f"control1: CGPoint(x: {c1x}, y: {c1y}), "
                    f"control2: CGPoint(x: {c2x}, y: {c2y}))"
                )
                x, y = nx, ny

        elif cmd in "Aa":
            while i < len(t) and not t[i].isalpha():
                rx, ry = f(), f()
                phi = f()
                large = int(f())
                sweep = int(f())
                nx, ny = f(), f()
                if cmd == "a":
                    nx += x; ny += y

                curves = arc_to_cubic(x, y, rx, ry, phi, large, sweep, nx, ny)
                if not curves:
                    # line fallback (or noop if same point)
                    if not (x == nx and y == ny):
                        out.append(f"p.addLine(to: CGPoint(x: {nx}, y: {ny}))")
                else:
                    for c1, c2, p in curves:
                        out.append(
                            f"p.addCurve(to: CGPoint(x: {p[0]}, y: {p[1]}), "
                            f"control1: CGPoint(x: {c1[0]}, y: {c1[1]}), "
                            f"control2: CGPoint(x: {c2[0]}, y: {c2[1]}))"
                        )
                x, y = nx, ny

        elif cmd in "Zz":
            out.append("p.closeSubpath()")
            x, y = sx, sy

        last = up

    return out

def extract_paths(svg):
    tree = ET.parse(svg)
    root = tree.getroot()
    ns = {"svg": "http://www.w3.org/2000/svg"}
    return [p.attrib["d"] for p in root.findall(".//svg:path", ns)]

def main():
    # Match your actual filenames: Tree_0.svg … Tree_7.svg (case-insensitive)
    files = sorted(
        f for f in os.listdir(SVG_DIR)
        if re.fullmatch(r"(?i)tree_[0-7]\.svg", f)
    )

    if len(files) != 8:
        raise RuntimeError(f"Expected 8 files Tree_0.svg…Tree_7.svg in {SVG_DIR}, found {len(files)}: {files}")

    lines = ["import SwiftUI", "", "enum TreePaths {", ""]

    for f in files:
        idx = re.search(r"(\d+)", f).group(1)
        lines.append(f"    static let tree{idx}: Path = Path {{ p in")
        for d in extract_paths(os.path.join(SVG_DIR, f)):
            for cmd in parse_path(d):
                lines.append(f"        {cmd}")
        lines.append("    }")
        lines.append("")

    lines.append("    static func path(for index: Int) -> Path? {")
    lines.append("        switch index {")
    for f in files:
        idx = re.search(r"(\d+)", f).group(1)
        lines.append(f"        case {idx}: return tree{idx}")
    lines.append("        default: return nil")
    lines.append("        }")
    lines.append("    }")

    lines.append("}")

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write("\n".join(lines))

    print(f"Generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
