#!/usr/bin/env python3
"""success-tick v1 - pill-reminder 'done' tick: teal circle pops in, white tick draws itself, settles. 1.2 s, plays once."""
import sys; sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[2]))
from homilottie import *

TEAL, WHITE = rgb("#1FA893"), rgb("#FFFFFF")
an = new_animation(1.2, 512, name="success-tick")
layer = an.add_layer(objects.ShapeLayer())

# circle: scale 0 -> 112 % -> 100 % (pop), opacity 0 -> 100
g = layer.add_shape(objects.Group())
circ = g.add_shape(objects.Ellipse())
circ.size.value = Point(300, 300)
g.add_shape(objects.Fill(TEAL))
g.transform.anchor_point.value = Point(0, 0)
g.transform.position.value = Point(256, 256)
g.transform.scale.add_keyframe(0, Point(0, 0), ease_out())
g.transform.scale.add_keyframe(10, Point(112, 112), ease_inout())
g.transform.scale.add_keyframe(16, Point(100, 100))
g.transform.opacity.add_keyframe(0, 0, ease_out())
g.transform.opacity.add_keyframe(6, 100)

# tick: stroke path drawn with a trim from 0 % to 100 % between frames 12 and 26
t = layer.add_shape(objects.Group())
t.add_shape(path_from_points([(176, 262), (234, 318), (344, 198)]))
trim = t.add_shape(objects.Trim())
trim.start.value = 0
trim.end.add_keyframe(12, 0, ease_out())
trim.end.add_keyframe(26, 100)
stroke = t.add_shape(objects.Stroke(WHITE, 28))
stroke.line_cap = objects.LineCap.Round
stroke.line_join = objects.LineJoin.Round

# tiny settle: whole tick group scales 100 -> 106 -> 100 at the end
t.transform.anchor_point.value = Point(256, 256)
t.transform.position.value = Point(256, 256)
t.transform.scale.add_keyframe(26, Point(100, 100), ease_inout())
t.transform.scale.add_keyframe(30, Point(106, 106), ease_inout())
t.transform.scale.add_keyframe(36, Point(100, 100))

finish(an, "test", "success-tick",
       "Pill-reminder 'done' tick: teal circle pops in (0-0.5 s), white tick draws itself (0.4-0.9 s), small settle. Plays once. 512x512, 30 fps, 1.2 s.",
       loop=False)
