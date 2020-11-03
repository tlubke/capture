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

convert -delay 4 -dispose previous -loop 0 /tmp/render_norns_screencap/*.png $out_pth

#delete temp directory
rm -r /tmp/render_norns_screencap