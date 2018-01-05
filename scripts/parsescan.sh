#!/bin/fish

command -v pnmtoplainpnm ^/dev/null >/dev/null; or alias pnmtoplainpnm="pnmtopnm -plain"

set left_elems 35
set total_v 43
set top_right_elems (echo $total_v-$left_elems | bc)
set total_b 17

# Work in a random directory in /tmp
set random_folder /tmp/(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1)
mkdir -p $random_folder;
cd $random_folder

# Save input image as a jpg, regardless of filetype
cat - >scan.jpg

# Detect filetype
set ft (identify scan.jpg | cut -d' ' -f2 | tr 'A-Z' 'a-z')

# Move file for it to have the correct extension
mv scan.jpg "scan.$ft"
convert "scan.$ft" -resize 620x877 scan.jpg
test "scan.$ft" = scan.jpg; or rm "scan.$ft"

# Check if the orientation is correct (if the qr code is in the top right corner)
set orientation_is_correct (convert scan.jpg -gravity NorthEast -crop 50%x50%+0+0 +repage jpg:- | zbarimg jpg:- -q | wc -l)

# If the orientation is incorrect, fix it
if test $orientation_is_correct -eq 0
    convert scan.jpg -rotate 180 scan_rotated.jpg
    rm scan.jpg
    mv scan_rotated.jpg scan.jpg
end

# Deskew image
convert scan.jpg -deskew 80% scan_deskewed.jpg
rm scan.jpg
mv scan_deskewed.jpg scan.jpg

# Get infos from QR code
zbarimg -q scan.jpg | cut -d: -f2- | base64 -d | sed 's/+/,/g'

# Extract the table part (discarding the QR and explanations part). Also resize to a predefined size to be able to use absolute offsets.
convert scan.jpg -crop 55%x100%+10+0 +repage -fuzz 20% -trim +repage tables.jpg

# Extract left column
# The left offset is at about 32% from the left border
set width (convert tables.jpg -format '%w' info:-)
set loffset (echo "0.31*$width" | bc -l | cut -d. -f1)
convert tables.jpg -crop 3%x100%+$loffset+0 -fuzz 20% -trim +repage -threshold 95% left.jpg

# For each element in the left column, return yes or no
set height (convert left.jpg -format '%h' info:-)
set percentage (echo 100/$left_elems | bc -l)

for i in (seq 1 $left_elems)
    set offset (echo "$height*($i-1)*$percentage/100" | bc -l | cut -d. -f1)
    set ones (convert left.jpg -crop 100%x$percentage%+0+$offset +repage pbm:- | pnmtoplainpnm | tail -n 21 | tr -d '\n' | sed s/0//g | wc -c)
    # TODO: use a treshold relative to part width and height.
    test "$ones" -gt 60; and echo "v$i yes"; or echo "v$i no"
end

# Remove residue file
rm left.jpg

# Extract the right column
# The left offset is at about 84% from the left border
set loffset (echo "0.84*$width" | bc -l | cut -d. -f1)
convert tables.jpg -crop 3%x100%+$loffset+0 -fuzz 20% -trim +repage -threshold 95% right.jpg

# Calculate an aproximation of a cell's height
set cellheight (echo "$height/$left_elems" | bc)

# Calculate a sensible height to cut at to get only the top right table
set cutline (echo "$top_right_elems*$cellheight+$cellheight" | bc)

# Cut into two parts
set rightwidth (convert right.jpg -format '%w' info:-)
convert right.jpg -crop $rightwidth'x'$cutline+0+0 +repage -fuzz 20% -trim +repage righttop.jpg
convert right.jpg -crop 100%x100%+0+$cutline +repage -fuzz 20% -trim +repage rightbot.jpg

# Remove residue file
rm right.jpg

for i in (seq 1 $top_right_elems)
    set offset (echo "($i-1)*$cellheight" | bc)
    set ones (convert righttop.jpg -crop $rightwidth'x'$cellheight+0+$offset +repage pbm:- | pnmtoplainpnm | tail -n 21 | tr -d '\n' | sed s/0//g | wc -c)
    set pos (echo $i+$left_elems | bc)
    test "$ones" -gt 60; and echo "v$pos yes"; or echo "v$pos no"
end

# Remove residue file
rm righttop.jpg

for i in (seq 1 $total_b)
    set offset (echo "($i-1)*$cellheight" | bc)
    set ones (convert rightbot.jpg -crop $rightwidth'x'$cellheight+0+$offset +repage pbm:- | pnmtoplainpnm | tail -n 21 | tr -d '\n' | sed s/0//g | wc -c)
    test "$ones" -gt 60; and echo "b$i yes"; or echo "b$i no"
end

# Remove residue files
rm rightbot.jpg tables.jpg scan.jpg
cd /tmp
rmdir $random_folder
