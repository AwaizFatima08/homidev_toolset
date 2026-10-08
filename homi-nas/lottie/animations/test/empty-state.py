#!/usr/bin/env python3
"""empty-state v1 - 'no entries yet': a clipboard with three faint lines; a pencil drifts up and down slowly; a small plus sign blinks. 4 s loop."""
import sys; sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[2]))
from homilottie import *

TEAL, LIGHT, GREY, DARK = rgb("#1FA893"), rgb("#E6F4F1"), rgb("#C9D3D9"), rgb("#5B6B73")
an = new_animation(4.0, 512, name="empty-state")
layer = an.add_layer(objects.ShapeLayer())

# clipboard body
b = layer.add_shape(objects.Group())
body = b.add_shape(objects.Rect())
body.position.value = Point(256, 280)
body.size.value = Point(260, 320)
body.rounded.value = 28
b.add_shape(objects.Fill(LIGHT))
b.add_shape(objects.Stroke(GREY, 6))

# clip at the top
c = layer.add_shape(objects.Group())
clip = c.add_shape(objects.Rect())
clip.position.value = Point(256, 124)
clip.size.value = Point(110, 44)
clip.rounded.value = 14
c.add_shape(objects.Fill(TEAL))

# three faint lines
for i, (y, w) in enumerate([(220, 160), (280, 130), (340, 100)]):
    l = layer.add_shape(objects.Group())
    line = l.add_shape(objects.Rect())
    line.position.value = Point(256 - (160 - w) / 2 - 20, y)
    line.size.value = Point(w, 14)
    line.rounded.value = 7
    l.add_shape(objects.Fill(GREY))
    l.transform.opacity.add_keyframe(0, 55, ease_inout())
    l.transform.opacity.add_keyframe(60 + i * 10, 30, ease_inout())
    l.transform.opacity.add_keyframe(120, 55)

# pencil: a rotated rounded bar with a teal tip, floating up and down
p = layer.add_shape(objects.Group())
bar = p.add_shape(objects.Rect())
bar.position.value = Point(0, 0)
bar.size.value = Point(26, 150)
bar.rounded.value = 8
p.add_shape(objects.Fill(DARK))
tip = layer.add_shape(objects.Group())
tp = tip.add_shape(path_from_points([(-13, 75), (13, 75), (0, 102)], closed=True))
tip.add_shape(objects.Fill(TEAL))
for grp in (p, tip):
    grp.transform.rotation.value = -35
    grp.transform.position.add_keyframe(0, Point(372, 300), ease_inout())
    grp.transform.position.add_keyframe(60, Point(372, 282), ease_inout())
    grp.transform.position.add_keyframe(120, Point(372, 300))

# blinking plus sign near the clip
plus = layer.add_shape(objects.Group())
plus.add_shape(path_from_points([(0, -22), (0, 22)]))
plus.add_shape(path_from_points([(-22, 0), (22, 0)]))
st = plus.add_shape(objects.Stroke(TEAL, 10))
st.line_cap = objects.LineCap.Round
plus.transform.position.value = Point(392, 150)
plus.transform.opacity.add_keyframe(0, 0, ease_inout())
plus.transform.opacity.add_keyframe(30, 100, ease_inout())
plus.transform.opacity.add_keyframe(90, 100, ease_inout())
plus.transform.opacity.add_keyframe(120, 0)

finish(an, "test", "empty-state",
       "Empty-state illustration 'no entries yet': clipboard with three faint lines, a pencil floating slowly, a small teal plus sign fading in and out. Calm 4 s loop. 512x512, 30 fps.",
       loop=True)
