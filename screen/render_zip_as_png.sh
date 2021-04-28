#!/bin/bash

zip_pth=$1
out_pth=$2
fps=$3

#unzip into temp directory
unzip $zip_pth -d /tmp/render_norns_screencap

(
#go to inner directory
cd /tmp/render_norns_screencap/

#mogrify files in directory
mogrify -gamma 1.25 -filter point -resize 400% -gravity center -background black -extent 120% *.png 
)

#output assembled apng to destination
$(dirname $0)/apngasm $out_pth /tmp/render_norns_screencap/frame*.png 1 $fps

#delete temp directory
rm -r /tmp/render_norns_screencap