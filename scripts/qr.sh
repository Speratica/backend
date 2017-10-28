#!/bin/fish

set random_folder /tmp/(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1)
mkdir -p $random_folder;
cd $random_folder

find . -iname '*.png' -delete

while read line;
    set base64_encoded (echo $line | base64)
    qrencode -v 4 -o (echo $line | cut -d, -f3-)-no-name.png -s 10 $base64_encoded
    convert (echo $line | cut -d, -f3-)-no-name.png -font Roboto -pointsize 27\
        label:(echo $line | cut -d, -f3- | sed s/,/\ /g) -gravity Center -append (echo $line | cut -d, -f3- | sed s/,/+/g)-name.png
    rm *-no-name.png
end;

# Concat the qr codes into a 4x5 grid
montage *.png -tile 4x5 -geometry +3+3 output.png

# Remove useless files
find . -iname '*-name.png' -and -not -iname '*.sh' -delete >/dev/null

find . -iname 'output*.png' -exec echo $random_folder/\{\} \; | sed 's/\.\///g'
