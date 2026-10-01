#!/usr/bin/env python3
"""idle.py [pad] - how much CPU an idle pad uses.

Starts pad with no input and leaves it, once for 1 second and once for 6, and
reads the CPU time the kernel charged each run (user plus system, from wait4).
Both runs pay for starting up -- building the font, creating the window -- so
the difference is what five idle seconds cost: the caret blinking twice a second
and nothing else. A loop that polled or redrew without cause would cost a large
part of the five seconds; this one costs a few thousandths of it.

Prints the figures and fails if the idle cost is over 0.25 s of the 5."""
import os
import signal
import subprocess
import sys
import time

here = os.path.dirname(os.path.abspath(__file__))
pad = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "pad")
env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_RENDER_DRIVER="software",
           SDL_AUDIODRIVER="dummy")


def cpu_after(seconds):
    p = subprocess.Popen([pad], env=env, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL)
    time.sleep(seconds)
    p.send_signal(signal.SIGTERM)
    _, _, usage = os.wait4(p.pid, 0)
    return usage.ru_utime + usage.ru_stime


short = cpu_after(1)
long_ = cpu_after(6)
idle = long_ - short
print("startup and 1 s: %.3f s of CPU; startup and 6 s: %.3f s; five idle seconds cost %.3f s"
      % (short, long_, idle))
if idle > 0.25:
    print("idle pad is using CPU: %.3f s in 5 s" % idle)
    sys.exit(1)
print("idle pad uses next to no CPU")
