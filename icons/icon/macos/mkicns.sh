#!/bin/bash

mkdir -p icons.iconset

sizes=(16 32 128 256 512)
for size in "${sizes[@]}"; do
    sips -z $size $size logo.png --out icons.iconset/icon_${size}x${size}.png
    sips -z $((size*2)) $((size*2)) logo.png --out icons.iconset/icon_${size}x${size}@2x.png
done

sips -z 1024 1024 logo.png --out icons.iconset/icon_1024x1024.png

iconutil -c icns icons.iconset -o appZhome.icns  # ‌:ml-citation{ref="1,2" data="citationList"}

rm -rf icons.iconset

