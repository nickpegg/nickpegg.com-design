#!/bin/bash

# requires that imagemagick and wkhtmltopdf are installed

ORIGINAL="https://nickpegg.com"
WIDTH=1920
HEIGHT=1080

mkdir -p progress
git checkout master

wkhtmltoimage --width $WIDTH --height $HEIGHT $ORIGINAL progress/0000.png

count=0
commits=$(git log -- index.html | grep commit | grep -v initial | awk '{print $2}' | tac)

for commit in $(echo $commits | xargs); do
  git checkout "$commit"
  i=$((++count))
  wkhtmltoimage --width $WIDTH --height $HEIGHT index.html "progress/$(printf "%04d" "$count").png"
done

# Magical one-liner to remove duplicates
md5sum progress/* | \
  sort | \
  awk 'BEGIN{lasthash = ""} $1 == lasthash {print $2} {lasthash = $1}' | \
  xargs rm

# Add an artificial pause by copying the last file a few times
for i in $(seq $((count+1)) $((count+5))); do
  cp progress/$(printf "%04d" "$count").png progress/$(printf "%04d" "$i").png
done

echo "Creating GIF..."
convert -delay 100 progress/*png progress.gif

echo "Creating small GIF..."
convert -resize '500x500' progress.gif progress.small.gif

git checkout master
