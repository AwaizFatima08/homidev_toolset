#!/usr/bin/env python3
"""heartbeat-loader v1 - calm loading indicator: teal heart beats twice (lub-dub) per 1.6 s loop, soft ring expands on the beat."""
import sys; sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[2]))
from homilottie import *

TEAL, RING = rgb("#1FA893"), rgb("#7FD6C8")
an = new_animation(1.6, 512, name="heartbeat-loader")
layer = an.add_layer(objects.ShapeLayer())


def add_heart(group, s=150):
    """Classic heart = a diamond (square turned 45 degrees) plus two circles on its upper edges. ~210 px wide.
    Screen coordinates: y grows downward, the tip is at the bottom."""
    half = s / 2
    group.add_shape(path_from_points([(0, -half), (half, 0), (0, half + 20), (-half, 0)], closed=True))
    r = half * 0.72
    for cx in (-half / 2, half / 2):
        c = group.add_shape(objects.Ellipse())
        c.position.value = Point(cx, -half / 2)
        c.size.value = Point(2 * r, 2 * r)


# expanding ring behind the heart (stroke only), fades out as it grows
r = layer.add_shape(objects.Group())
ring = r.add_shape(objects.Ellipse())
ring.size.value = Point(260, 260)
rs = r.add_shape(objects.Stroke(RING, 10))
r.transform.position.value = Point(256, 262)
r.transform.scale.add_keyframe(0, Point(90, 90), ease_out())
r.transform.scale.add_keyframe(30, Point(135, 135))
r.transform.scale.add_keyframe(48, Point(90, 90))
r.transform.opacity.add_keyframe(0, 60, ease_out())
r.transform.opacity.add_keyframe(30, 0)
r.transform.opacity.add_keyframe(47, 0)
r.transform.opacity.add_keyframe(48, 60)

# heart: lub (frames 0-8), dub (10-18), rest until 48
h = layer.add_shape(objects.Group())
add_heart(h)
h.add_shape(objects.Fill(TEAL))
h.transform.position.value = Point(256, 262)
sc = h.transform.scale
for f, v, e in [(0, 100, ease_out()), (4, 112, ease_inout()), (8, 100, ease_out()), (10, 100, ease_out()),
                (14, 108, ease_inout()), (18, 100, ease_inout()), (48, 100, None)]:
    sc.add_keyframe(f, Point(v, v), e) if e else sc.add_keyframe(f, Point(v, v))

finish(an, "test", "heartbeat-loader",
       "Loading indicator: teal heart beats lub-dub once per 1.6 s with a soft ring that expands and fades on the beat. Seamless loop. 512x512, 30 fps.",
       loop=True)
