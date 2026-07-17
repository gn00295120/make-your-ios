#!/bin/zsh
set -euo pipefail

demo_dir="${0:A:h}"
repo_root="${demo_dir:h:h:h}"
panels_dir="$demo_dir/panels"
slides_dir="$demo_dir/slides"
segments_dir="$demo_dir/segments"
audio_dir="$demo_dir/audio"

pages_clip="$repo_root/artifacts/app-store/videos/app-three-page-tour-final.mp4"
generation_clip="$repo_root/artifacts/app-store/videos/focus-checklist-generation-final.mp4"
complete_clip="$repo_root/artifacts/app-store/videos/focus-checklist-complete-task-final.mp4"
style_clip="$repo_root/artifacts/app-store/videos/focus-checklist-style-update-final.mp4"
switch_clip="$repo_root/artifacts/app-store/videos/multi-app-switching-final.mp4"
icon="$repo_root/MakeYourIOS/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

font_regular="/System/Library/Fonts/Supplemental/Arial.ttf"
font_bold="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

mkdir -p "$panels_dir" "$slides_dir" "$segments_dir" "$audio_dir"

for required_file in \
  "$pages_clip" \
  "$generation_clip" \
  "$complete_clip" \
  "$style_clip" \
  "$switch_clip" \
  "$icon" \
  "$audio_dir/demo-v5-01-pages.mp3" \
  "$audio_dir/demo-v5-02-create.mp3" \
  "$audio_dir/demo-v5-03-style.mp3" \
  "$audio_dir/demo-v5-04-switch.mp3" \
  "$audio_dir/demo-v5-05-codex.mp3" \
  "$audio_dir/demo-v5-06-close.mp3"; do
  [[ -f "$required_file" ]] || {
    print -u2 "missing required demo asset: $required_file"
    exit 1
  }
done

# Keep the real iPhone interaction dominant. Each overlay is deliberately small
# and only tells the viewer what to notice in the live app.
make_overlay() {
  local kicker="$1"
  local headline="$2"
  local detail="$3"
  local accent="$4"
  local output="$5"

  magick -size 1920x1080 xc:none \
    -fill "#070914E6" -stroke "${accent}99" -strokewidth 2 \
    -draw "roundrectangle 55,55 715,285 30,30" \
    -fill "$accent" -stroke none \
    -draw "roundrectangle 80,83 92,257 6,6" \
    -gravity NorthWest -font "$font_bold" -fill "$accent" -pointsize 22 \
    -annotate +118+106 "$kicker" \
    \( -size 560x72 -background none -font "$font_bold" -fill white \
       -pointsize 42 caption:"$headline" \) \
    -geometry +118+130 -composite \
    \( -size 560x56 -background none -font "$font_regular" -fill "#E4E6F6" \
       -pointsize 24 caption:"$detail" \) \
    -geometry +118+218 -composite \
    "$output"
}

make_overlay \
  "OPENAI BUILD WEEK" \
  "One app. Your tiny apps." \
  "My Apps  ·  Builder  ·  AI Key" \
  "#9C8CFF" \
  "$panels_dir/01-pages.png"

make_overlay \
  "NEW APP → GPT-5.6" \
  "One prompt. Working app." \
  "Real generation  ·  wait shortened" \
  "#57C9FF" \
  "$panels_dir/02-create.png"

make_overlay \
  "VERSION 2 → VERSION 3" \
  "Make it yours." \
  "New style  ·  new feature  ·  data preserved" \
  "#66E39C" \
  "$panels_dir/03-style.png"

make_overlay \
  "YOUR APP LIBRARY" \
  "Many apps. One home." \
  "Travel  ·  live rates  ·  private journal" \
  "#FFBC5E" \
  "$panels_dir/04-switch.png"

make_overlay \
  "BUILT WITH CODEX" \
  "The runtime behind the idea." \
  "Schema  ·  validator  ·  safety  ·  SwiftUI" \
  "#B29CFF" \
  "$panels_dir/05-codex.png"

make_overlay \
  "MAKE YOURS" \
  "One app. Your tiny apps." \
  "Built with GPT-5.6 + Codex" \
  "#9C8CFF" \
  "$panels_dir/06-close.png"

# The raw page tour moves faster than the narration. Hold each real page long
# enough for its spoken explanation, while preserving every original tap and
# navigation transition.
ffmpeg -y -hide_banner -loglevel error \
  -i "$pages_clip" \
  -filter_complex \
  "[0:v]split=4[myapps1][builder][key][myapps2];\
   [myapps1]trim=start=0:end=6.3,setpts=PTS-STARTPTS,fps=30,\
tpad=stop_mode=clone:stop_duration=2.1,trim=duration=8.4[v0];\
   [builder]trim=start=6.3:end=9.333,setpts=PTS-STARTPTS,fps=30,\
tpad=stop_mode=clone:stop_duration=0.067,trim=duration=3.1[v1];\
   [key]trim=start=9.333:end=13.367,setpts=PTS-STARTPTS,fps=30,\
tpad=stop_mode=clone:stop_duration=0.766,trim=duration=4.8[v2];\
   [myapps2]trim=start=13.367:end=14.633,setpts=PTS-STARTPTS,fps=30,\
tpad=stop_mode=clone:stop_duration=3.634,trim=duration=4.9[v3];\
   [v0][v1][v2][v3]concat=n=4:v=1:a=0,format=yuv420p[v]" \
  -map "[v]" -an -c:v libx264 -preset medium -crf 18 -r 30 \
  -pix_fmt yuv420p -movflags +faststart "$segments_dir/pages-timed-source.mp4"

# Join the real generation and the first real interaction into one continuous
# product beat. The short fade only bridges two independently captured takes.
ffmpeg -y -hide_banner -loglevel error \
  -i "$generation_clip" -i "$complete_clip" \
  -filter_complex \
  "[0:v]fps=30,format=yuv420p,setpts=PTS-STARTPTS[generation];\
   [1:v]fps=30,format=yuv420p,setpts=PTS-STARTPTS[complete];\
   [generation][complete]xfade=transition=fade:duration=0.2:offset=9.566[v]" \
  -map "[v]" -an -c:v libx264 -preset medium -crf 18 -r 30 \
  -pix_fmt yuv420p -movflags +faststart "$segments_dir/create-source.mp4"

# Reuse the final live My Apps frame behind the Codex credit and closing line so
# the demo never stops feeling like an actual product walkthrough.
ffmpeg -y -hide_banner -loglevel error \
  -i "$switch_clip" -ss 22.5 -t 0.9 -an \
  -vf "fps=30,format=yuv420p" -c:v libx264 -preset medium -crf 18 -r 30 \
  -pix_fmt yuv420p -movflags +faststart "$segments_dir/library-hold-source.mp4"

render_live_segment() {
  local source_video="$1"
  local panel="$2"
  local narration="$3"
  local duration="$4"
  local output="$5"

  ffmpeg -y -hide_banner -loglevel error \
    -i "$source_video" -loop 1 -framerate 30 -i "$panel" -i "$narration" \
    -filter_complex \
    "[0:v]split=2[background][phone];\
     [background]scale=1920:1080:force_original_aspect_ratio=increase,\
crop=1920:1080,gblur=sigma=36,eq=brightness=-0.40:saturation=0.72,fps=30,\
tpad=stop_mode=clone:stop_duration=12,trim=duration=${duration},setpts=PTS-STARTPTS[bg];\
     [phone]scale=-2:1040:flags=lanczos,fps=30,tpad=stop_mode=clone:stop_duration=12,\
trim=duration=${duration},setpts=PTS-STARTPTS[fg];\
     [bg][fg]overlay=760:20:shortest=1[scene];\
     [scene][1:v]overlay=0:0:shortest=1[v];\
     [2:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=12,\
atrim=duration=${duration},asetpts=PTS-STARTPTS[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t "$duration" \
    -movflags +faststart "$output"
}

render_live_segment \
  "$segments_dir/pages-timed-source.mp4" \
  "$panels_dir/01-pages.png" \
  "$audio_dir/demo-v5-01-pages.mp3" \
  "21.2" \
  "$segments_dir/01-pages.mp4"

render_live_segment \
  "$segments_dir/create-source.mp4" \
  "$panels_dir/02-create.png" \
  "$audio_dir/demo-v5-02-create.mp3" \
  "16.6" \
  "$segments_dir/02-create.mp4"

render_live_segment \
  "$style_clip" \
  "$panels_dir/03-style.png" \
  "$audio_dir/demo-v5-03-style.mp3" \
  "19.7" \
  "$segments_dir/03-style.mp4"

render_live_segment \
  "$switch_clip" \
  "$panels_dir/04-switch.png" \
  "$audio_dir/demo-v5-04-switch.mp3" \
  "23.3" \
  "$segments_dir/04-switch.mp4"

render_live_segment \
  "$segments_dir/library-hold-source.mp4" \
  "$panels_dir/05-codex.png" \
  "$audio_dir/demo-v5-05-codex.mp3" \
  "8.4" \
  "$segments_dir/05-codex.mp4"

render_live_segment \
  "$segments_dir/library-hold-source.mp4" \
  "$panels_dir/06-close.png" \
  "$audio_dir/demo-v5-06-close.mp3" \
  "7.1" \
  "$segments_dir/06-close.mp4"

# Six-frame dips separate chapters without hiding any interaction. Audio uses a
# matching equal-power dissolve, and every source is normalized to CFR 30 fps.
ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/01-pages.mp4" \
  -i "$segments_dir/02-create.mp4" \
  -i "$segments_dir/03-style.mp4" \
  -i "$segments_dir/04-switch.mp4" \
  -i "$segments_dir/05-codex.mp4" \
  -i "$segments_dir/06-close.mp4" \
  -filter_complex \
  "[0:v][1:v]xfade=transition=fadeblack:duration=0.2:offset=21.0[v01];\
   [v01][2:v]xfade=transition=fadeblack:duration=0.2:offset=37.4[v02];\
   [v02][3:v]xfade=transition=fadeblack:duration=0.2:offset=56.9[v03];\
   [v03][4:v]xfade=transition=fadeblack:duration=0.2:offset=80.0[v04];\
   [v04][5:v]xfade=transition=fadeblack:duration=0.2:offset=88.2,format=yuv420p[v];\
   [0:a][1:a]acrossfade=d=0.2:c1=tri:c2=tri[a01];\
   [a01][2:a]acrossfade=d=0.2:c1=tri:c2=tri[a02];\
   [a02][3:a]acrossfade=d=0.2:c1=tri:c2=tri[a03];\
   [a03][4:a]acrossfade=d=0.2:c1=tri:c2=tri[a04];\
   [a04][5:a]acrossfade=d=0.2:c1=tri:c2=tri[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 \
  -movflags +faststart "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"

# A real Version 3 screen anchors the thumbnail in the product rather than in a
# concept slide.
ffmpeg -y -hide_banner -loglevel error \
  -i "$style_clip" -ss 12 -frames:v 1 "$slides_dir/thumbnail-phone.png"

magick -size 1280x720 gradient:"#080916-#432781" \
  \( "$icon" -resize 150x150 \) -geometry +70+58 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#BFAFFF" -pointsize 26 \
  -annotate +70+260 "OPENAI BUILD WEEK" \
  \( -size 770x230 -background none -font "$font_bold" -fill white \
     -pointsize 66 caption:"BUILD YOUR OWN\nTINY APPS" \) \
  -geometry +70+305 -composite \
  -font "$font_bold" -fill "#72D7FF" -pointsize 42 \
  -annotate +73+645 "WITH GPT-5.6" \
  -fill "#15132CE8" -stroke "#9C8CFF" -strokewidth 3 \
  -draw "roundrectangle 930,35 1225,685 42,42" \
  \( "$slides_dir/thumbnail-phone.png" -resize 275x598 \) \
  -geometry +940+61 -composite \
  -quality 92 "$demo_dir/MakeYour-YouTube-Thumbnail.jpg"

ffprobe -v error \
  -show_entries format=duration,size \
  -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,sample_rate \
  -of default=noprint_wrappers=1 \
  "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"
