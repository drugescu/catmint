#!/usr/bin/env python3
"""Exercise the compiled app. Connectivity/path oracles do not reuse its code."""
import argparse
from collections import deque
import hashlib
import os
from pathlib import Path
import random
import subprocess
import tempfile
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=Path(__file__).with_name("dungeon-lab"))
    parser.add_argument("--seeds", type=int, default=32)
    options = parser.parse_args()
    binary = options.binary.resolve()
    environment = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_RENDER_DRIVER="software", SDL_AUDIODRIVER="dummy")
    checks = 0
    with tempfile.TemporaryDirectory(prefix="catmint-dungeon-") as folder:
        work = Path(folder)

        def run(*args, ok=True):
            p = subprocess.run([str(binary), *map(str, args)], cwd=work, env=environment,
                               text=True, capture_output=True, timeout=30)
            assert "AddressSanitizer" not in p.stderr and "LeakSanitizer" not in p.stderr, p.stderr
            assert p.returncode == (0 if ok else 1), (args, p.returncode, p.stdout[-1000:], p.stderr[-2000:])
            return p.stdout

        def dump(*args, script=None):
            if script is not None:
                (work / "input.play").write_text(script)
                args = (*args, "--play", work / "input.play")
            text = run("--dump", *args)
            lines = text.splitlines()
            assert lines[0] == "DUNGEON-LAB 1"
            header = {}
            index = 1
            while lines[index] != "map":
                key, *values = lines[index].split()
                header[key] = list(map(int, values))
                index += 1
            w, h = header["size"]
            rows = lines[index + 1:index + 1 + h]
            assert lines[index + 1 + h] == "route"
            route = lines[index + 2 + h:index + 2 + h * 2]
            view = list(map(int, lines[-1].split()[1:]))
            assert len(rows) == len(route) == h and all(len(r) == w for r in rows + route)
            floor = {y * w + x for y, row in enumerate(rows) for x, c in enumerate(row) if c == "."}
            assert all(set(row) <= {".", "#"} for row in rows)
            assert all(set(row) <= {"0", "1"} for row in route)
            assert all(c == "#" for c in rows[0] + rows[-1])
            assert all(row[0] == row[-1] == "#" for row in rows)
            start, end, target = header["entrance"][0], header["exit"][0], header["target"][0]
            assert start in floor and end in floor and target in floor

            def adjacent(cell):
                x, y = cell % w, cell // w
                return [ny * w + nx for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                        if 0 <= nx < w and 0 <= ny < h and ny * w + nx in floor]

            distance = {start: 0}
            queue = deque([start])
            while queue:
                cell = queue.popleft()
                for nxt in adjacent(cell):
                    if nxt not in distance:
                        distance[nxt] = distance[cell] + 1
                        queue.append(nxt)
            assert set(distance) == floor, "disconnected dungeon"
            assert distance[end] == max(distance.values()), "exit is not farthest"
            assert header["floors"] == [len(floor)]
            assert header["distance"] == [distance[target]]
            actual = {y * w + x for y, row in enumerate(route) for x, c in enumerate(row) if c == "1"}
            assert actual <= floor and start in actual and target in actual
            assert len(actual) == distance[target] + 1
            # Distance must strictly decrease along the reconstructed path.
            walked = {target}
            cell = target
            while cell != start:
                previous = [n for n in adjacent(cell) if n in actual and distance[n] == distance[cell] - 1]
                assert len(previous) == 1
                cell = previous[0]
                walked.add(cell)
            assert walked == actual
            assert 2 <= header["rooms"][0] <= header["rooms"][1]
            return text, header, view

        rng = random.Random(3112026)
        seeds = [1, 2, 42, 2147483647] + [rng.randint(1, 2147483647) for _ in range(options.seeds)]
        for seed in seeds:
            for count in (6, 12, 20):
                _, header, _ = dump("--seed", seed, "--rooms", count)
                assert header["seed"] == [seed] and header["rooms"][1] == count
                checks += 1
        original, header, _ = dump("--seed", 42)
        assert hashlib.sha256(original.encode()).hexdigest() == "6daa0b25b167c5a207e9ac4f6ee436437d8af39ee50eb23c507fa4d023eca366", "v1 seed 42 changed"
        assert dump("--seed", 42)[0] == original, "same seed changed"
        assert dump("--seed", 42, script="key 110\nkey 112\n")[0] == original
        assert dump("--seed", 2147483647, script="key 110\n")[1]["seed"] == [1]
        assert dump("--seed", 1, script="key 112\n")[1]["seed"] == [2147483647]
        assert dump(script="key 115\ntext 1234\nkey 8\nkey 13\n")[1]["seed"] == [123]
        assert dump(script="key 115\ntext 0\nkey 13\nkey 27\n")[1]["seed"] == [42]
        assert dump(script="key 115\ntext 9999999999\nkey 13\nkey 27\n")[1]["seed"] == [42]
        assert dump("--rooms", 6, script="key 45\n")[1]["rooms"][1] == 6
        assert dump("--rooms", 20, script="key 61\n")[1]["rooms"][1] == 20
        assert dump(script="key 103\nkey 114\n")[2] == [0, 1, 0]
        # Click the entrance through exactly the same handler as a real mouse.
        entrance = header["entrance"][0]
        click = f"click {24 + (entrance % 61) * 14 + 7} {150 + (entrance // 61) * 14 + 7}\n"
        assert dump(script=click)[1]["distance"] == [0]
        assert dump(script="click 25 151\n")[1]["target"] == header["target"], "wall changed target"
        assert dump(script="click 950 320\n")[1]["seed"] == [43], "next button"

        exported = work / "a printable map.svg"
        run("--seed", 42, "--export", exported)
        before = exported.read_bytes()
        root = ET.fromstring(before)
        ns = {"s": "http://www.w3.org/2000/svg"}
        assert root.tag == "{http://www.w3.org/2000/svg}svg"
        assert "seed 42" in root.find("s:title", ns).text
        assert root.attrib["viewBox"] == "0 0 1260 840"
        # Reconstruct rock from the exported SVG's run rectangles, independently
        # of how the generator chose rooms and corridors.
        rock = set()
        group = root.find("s:g[@transform]", ns)
        for rect in group.findall("s:rect", ns):
            x, y = int(rect.attrib["x"]) // 20, int(rect.attrib["y"]) // 20
            width = int(rect.attrib["width"]) // 20
            rock.update(y * 61 + xx for xx in range(x, x + width))
        rows = original.split("map\n", 1)[1].split("\nroute\n", 1)[0].splitlines()
        assert rock == {y * 61 + x for y, row in enumerate(rows) for x, c in enumerate(row) if c == "#"}, "SVG does not match the map"
        (work / "select.play").write_text(click)
        run("--export", exported, "--play", work / "select.play")
        assert before == exported.read_bytes(), "inspection changed the export"
        # E in the UI controller also exports; missing directories fail cleanly.
        run("--headless", "--play", work / "select.play")
        (work / "export.play").write_text("key 101\n")
        run("--headless", "--play", work / "export.play")
        assert (work / "dungeon-42-12.svg").read_bytes() == before
        run("--export", work / "missing" / "map.svg", ok=False)
        run("--export", work, ok=False)
        for args in (("--seed", "-1"), ("--seed", "2147483648"), ("--seed", "1x"),
                     ("--rooms", "5"), ("--rooms", "21"), ("--seed",), ("--unknown",),
                     ("--dump", "--shot", "bad.bmp"), ("--export", ""), ("--play", "")):
            run(*args, ok=False)
        (work / "bad.play").write_text("silently ignore this\n")
        run("--headless", "--play", work / "bad.play", ok=False)
        (work / "bad.play").write_text("click -1 100\n")
        run("--headless", "--play", work / "bad.play", ok=False)
        run("--headless", "--play", work / "absent.play", ok=False)

        image = work / "screen.bmp"
        run("--shot", image)
        import struct
        data = image.read_bytes()
        assert data[:2] == b"BM" and struct.unpack_from("<ii", data, 18) == (1200, 760)
        offset = struct.unpack_from("<I", data, 10)[0]
        bits = struct.unpack_from("<H", data, 28)[0]
        assert bits in (24, 32)
        stride = ((1200 * bits + 31) // 32) * 4

        def pixel(x, y):
            at = offset + (759 - y) * stride + x * (bits // 8)
            return tuple(reversed(data[at:at + 3]))

        assert pixel(0, 759) == (15, 20, 29), "background not drawn"
        assert pixel(25, 151) == (26, 34, 37), "sealed border not drawn"
        (work / "route.play").write_text("key 114\n")
        run("--play", work / "route.play", "--shot", work / "route.bmp")
        assert image.read_bytes() != (work / "route.bmp").read_bytes(), "route toggle not rendered"
        print(f"Dungeon Lab: {checks} independently checked maps; input, SVG, refusals and rendering passed")


if __name__ == "__main__":
    main()
