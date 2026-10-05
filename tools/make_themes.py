#!/usr/bin/env python3
"""make_themes.py [--check | --ratios]

Writes lib/themes.cmm: every colour theme the editor offers, from the table below.

    make_themes.py            write lib/themes.cmm
    make_themes.py --check    exit 1 if lib/themes.cmm is not what the table says
                              (test.sh runs this)
    make_themes.py --ratios   print the contrast figures that test 86_themes
                              expects, computed here, in Python, by a WCAG
                              implementation that shares nothing with the one in
                              lib/theme.cmm -- so the test compares two
                              independent calculations on thirteen real palettes.

A theme is twelve colours for twelve jobs (see lib/theme.cmm). The community
themes are the palettes their authors published, each role taken from the role
the author gave it; where the editor needs a shade the author's palette has no
name for (the current-line band, the selection, a panel) it is blended from the
palette's own colours and marked "derived". They are not re-fitted to the
Catmint contrast rule: a Solarized that passed 7:1 would not be Solarized. The
figures are measured instead (--ratios) and the test holds each one.

Sources, fetched 2026-10-02:
  Dracula        https://github.com/dracula/dracula-theme   (palette: README)
  Nord           https://www.nordtheme.com/docs/colors-and-palettes
                 (comment: nord3 brightened, #616e88, as nord-vim has it)
  Solarized      https://ethanschoonover.com/solarized/
  Gruvbox        https://github.com/morhetz/gruvbox  (colors/gruvbox.vim)
  Tokyo Night    https://github.com/folke/tokyonight.nvim  (night)
  One Dark       https://github.com/atom/one-dark-syntax  (styles/colors.less;
                 the greys as One Dark Pro has them: #5c6370, #21252b)
  Catppuccin     https://github.com/catppuccin/catppuccin  (Mocha, Latte)
  Monokai        https://github.com/microsoft/vscode  (extensions/theme-monokai)
Popularity, which decided the set: One Dark Pro, Dracula Official, Monokai Pro
and Tokyo Night lead the VS Code marketplace; Nord, Gruvbox, Solarized and
Catppuccin are the ones people name next.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "lib", "themes.cmm")

ROLES = ("ground line panel selection text dim comment accent keyword "
         "string number error").split()

# name: (is dark, the theme "dark and light" goes to, the twelve colours)
# Where the editor needs a shade the author's palette does not name, it is
# blended from the palette's own colours -- computed, not chosen by eye:
#   Dracula line            #282a36 blended 46% toward #44475a (the author's own
#                           line highlight is #44475a at 46% opacity)
#   Catppuccin Mocha line   base #1e1e2e blended 40% toward surface0 #313244
#   Nord panel              nord0 #2e3440 darkened to 85%
#   Solarized Dark panel    base03 #002b36 darkened to 78%
#   Solarized Dark select   base02 #073642 blended 30% toward base01 #586e75
#   Solarized Light select  base2 #eee8d5 blended 20% toward base1 #93a1a1
# Every other colour is one the palette names (Tokyo Night's line, panel and
# selection are bg_highlight, bg_dark and bg_visual; One Dark's line and panel
# are One Dark Pro's #2c313c and #21252b).
THEMES = [
    ("Catmint Dark", 1, "Catmint Light",
     "1e2229 252a33 232830 3a4864 dfe1e6 8993a0 8993a0 e8b04a cca8ef 9ec68a e3ac7b e87880"),
    ("Catmint Light", 0, "Catmint Dark",
     "faf8f3 f0ede5 f3f0e9 cedbf3 262a32 626a76 626a76 a86808 67329a 245a1c 7f3a09 b22834"),
    ("Dracula", 1, "Catmint Light",
     "282a36 353747 21222c 44475a f8f8f2 6272a4 6272a4 bd93f9 ff79c6 f1fa8c bd93f9 ff5555"),
    ("Nord", 1, "Catmint Light",
     "2e3440 3b4252 272c36 434c5e d8dee9 616e88 616e88 88c0d0 81a1c1 a3be8c b48ead bf616a"),
    ("Solarized Dark", 1, "Solarized Light",
     "002b36 073642 00222a 1f4751 839496 586e75 586e75 268bd2 859900 2aa198 d33682 dc322f"),
    ("Solarized Light", 0, "Solarized Dark",
     "fdf6e3 eee8d5 eee8d5 dcdacb 657b83 93a1a1 93a1a1 268bd2 859900 2aa198 d33682 dc322f"),
    ("Gruvbox Dark", 1, "Gruvbox Light",
     "282828 3c3836 1d2021 504945 ebdbb2 928374 928374 fabd2f fb4934 b8bb26 d3869b fb4934"),
    ("Gruvbox Light", 0, "Gruvbox Dark",
     "fbf1c7 ebdbb2 f2e5bc d5c4a1 3c3836 7c6f64 928374 b57614 9d0006 79740e 8f3f71 9d0006"),
    ("Tokyo Night", 1, "Catmint Light",
     "1a1b26 292e42 16161e 283457 c0caf5 565f89 565f89 7aa2f7 bb9af7 9ece6a ff9e64 f7768e"),
    ("One Dark", 1, "Catmint Light",
     "282c34 2c313c 21252b 3e4451 abb2bf 5c6370 5c6370 61afef c678dd 98c379 d19a66 e06c75"),
    ("Catppuccin Mocha", 1, "Catppuccin Latte",
     "1e1e2e 262637 181825 45475a cdd6f4 7f849c 7f849c 89b4fa cba6f7 a6e3a1 fab387 f38ba8"),
    ("Catppuccin Latte", 0, "Catppuccin Mocha",
     "eff1f5 e6e9ef dce0e8 bcc0cc 4c4f69 7c7f93 7c7f93 1e66f5 8839ef 40a02b fe640b d20f39"),
    ("Monokai", 1, "Catmint Light",
     "272822 3e3d32 1e1f1c 49483e f8f8f2 88846f 88846f a6e22e f92672 e6db74 ae81ff f92672"),
]


def colours(spec):
    values = spec.split()
    assert len(values) == len(ROLES), spec
    return dict(zip(ROLES, values))


def _linear(channel):
    c = channel / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _luminance(hexcolour):
    r, g, b = (int(hexcolour[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * _linear(r) + 0.7152 * _linear(g) + 0.0722 * _linear(b)


def contrast(a, b):
    la, lb = _luminance(a), _luminance(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


def tenths(x):
    n = int(math.floor(x * 10 + 0.5))
    return "%d.%d" % (n // 10, n % 10)


def render():
    names = [t[0] for t in THEMES]
    for _, _, pair, _ in THEMES:
        assert pair in names, "pair %s is not a theme" % pair
    out = []
    out.append("# Generated by tools/make_themes.py -- do not edit.")
    out.append("#")
    out.append("# Every colour theme the editor offers. The community themes are the palettes")
    out.append("# their authors published, with the roles the authors gave the colours; the")
    out.append("# table, the sources and the reasons are in tools/make_themes.py. Their")
    out.append("# contrast is whatever the author chose, measured by test 86_themes and not")
    out.append("# bent to the Catmint rule. test.sh fails if this file and the table disagree.")
    out.append("")
    out.append("using theme")
    out.append("")
    out.append("class Themes")
    out.append("  # All of them, in the order they are offered.")
    out.append("  static def List all:")
    out.append("    List list = new List()")
    for name, dark, pair, spec in THEMES:
        c = colours(spec)
        args = ", ".join('"%s"' % c[r] for r in ROLES)
        out.append('    list.append(Theme.make("%s", %d, "%s", %s))' % (name, dark, pair, args))
    out.append("    return list")
    out.append("  end")
    out.append("")
    out.append("  # The theme with this name, or null.")
    out.append("  static def Theme named(String name):")
    out.append("    List list = Themes.all()")
    out.append("    Int i = 0")
    out.append("    while i < list.len():")
    out.append("      Theme t = list.get(i)")
    out.append("      if t.name.equals(name):")
    out.append("        return t")
    out.append("      end")
    out.append("      i = i + 1")
    out.append("    end")
    out.append("    return null")
    out.append("  end")
    out.append("")
    out.append("  # The names, in the order they are offered.")
    out.append("  static def List names:")
    out.append("    List list = Themes.all()")
    out.append("    List result = new List()")
    out.append("    Int i = 0")
    out.append("    while i < list.len():")
    out.append("      Theme t = list.get(i)")
    out.append("      result.append(t.name)")
    out.append("      i = i + 1")
    out.append("    end")
    out.append("    return result")
    out.append("  end")
    out.append("")
    out.append("  # Where \"toggle dark and light\" goes from this theme.")
    out.append("  static def Theme pairOf(Theme t):")
    out.append("    Theme other = Themes.named(t.pair)")
    out.append("    if other == null:")
    out.append("      return t")
    out.append("    end")
    out.append("    return other")
    out.append("  end")
    out.append("end")
    return "\n".join(out) + "\n"


def ratios():
    """The lines test 86_themes expects, one for each theme."""
    lines = ["%d themes" % len(THEMES)]
    for name, dark, pair, spec in THEMES:
        c = colours(spec)
        g = c["ground"]
        lines.append("%s: text %s dim %s keyword %s string %s number %s accent %s error %s" % (
            name, tenths(contrast(c["text"], g)), tenths(contrast(c["dim"], g)),
            tenths(contrast(c["keyword"], g)), tenths(contrast(c["string"], g)),
            tenths(contrast(c["number"], g)), tenths(contrast(c["accent"], g)),
            tenths(contrast(c["error"], g))))
        lines.append("  %s" % " ".join(c[r] for r in ROLES))
    return "\n".join(lines) + "\n"


def main():
    if "--ratios" in sys.argv[1:]:
        sys.stdout.write(ratios())
        return
    text = render()
    if "--check" in sys.argv[1:]:
        try:
            current = open(OUTPUT).read()
        except FileNotFoundError:
            current = None
        if current != text:
            raise SystemExit("make_themes: lib/themes.cmm is out of date with "
                             "tools/make_themes.py; run tools/make_themes.py")
        print("themes match their table (%d)" % len(THEMES))
    else:
        with open(OUTPUT, "w") as f:
            f.write(text)


main()
