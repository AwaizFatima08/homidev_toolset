#!/bin/bash
# lm-studio-gui.sh v1.1 (LG2, 9 Oct 2026) - one LM Studio at a time: stop the headless daemon, run the GUI (its engine then
# serves the API on 1234 too), and when the GUI closes bring the headless daemon + server back. Never kills by name pattern.
export PATH="$HOME/.lmstudio/bin:$PATH"
lms daemon down >/dev/null 2>&1 || true
( sleep 25; lms server start >/dev/null 2>&1 ) &      # keep port 1234 available while the GUI is open
"$HOME/Applications/LM-Studio.AppImage" "$@"
# GUI closed -> headless again, so the API and the receiver unload keep working
sleep 2; lms daemon up >/dev/null 2>&1; sleep 3; lms server start >/dev/null 2>&1
