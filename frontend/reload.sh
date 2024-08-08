#!/bin/bash

lastid=$(xdotool getactivewindow)
id=$(xdotool search --onlyvisible --name Chrome)
# echo $id
xdotool windowfocus --sync $id
xdotool key ctrl+r
# 最後にフォーカスを戻す
xdotool windowfocus --sync $lastid
