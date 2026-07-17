#!/bin/zsh
set -euo pipefail

demo_dir="${0:A:h}"
repo_root="${demo_dir:h:h:h}"
panels_dir="$demo_dir/panels"
slides_dir="$demo_dir/slides"
segments_dir="$demo_dir/segments"
audio_dir="$demo_dir/audio"

key_clip="$repo_root/artifacts/app-store/videos/api-key-gpt56-runtime-final.mp4"
travel_clip="$repo_root/artifacts/app-store/videos/new-app-from-scratch-final.mp4"
focus_clip="$repo_root/artifacts/app-store/videos/focus-checklist-generation-final.mp4"
evolve_clip="$repo_root/artifacts/app-store/videos/focus-checklist-evolve-final.mp4"
icon="$repo_root/MakeYourIOS/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

font_regular="/System/Library/Fonts/Supplemental/Arial.ttf"
font_bold="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

mkdir -p "$panels_dir" "$slides_dir" "$segments_dir" "$audio_dir"

for required_file in \
  "$key_clip" \
  "$travel_clip" \
  "$focus_clip" \
  "$evolve_clip" \
  "$icon" \
  "$audio_dir/demo-v4-01-core.mp3" \
  "$audio_dir/demo-v4-02-travel.mp3" \
  "$audio_dir/demo-v4-03-focus.mp3" \
  "$audio_dir/demo-v4-04-evolve.mp3" \
  "$audio_dir/demo-v4-05-codex.mp3" \
  "$audio_dir/demo-v4-06-close.mp3"; do
  [[ -f "$required_file" ]] || {
    print -u2 "missing required demo asset: $required_file"
    exit 1
  }
done

# Each live segment keeps the real Simulator full height on the right. The left
# panel explains why the operation matters without covering the generated app.
magick -size 1920x1080 xc:none \
  -fill "#080916E8" -stroke "#8D7BFF88" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  \( "$icon" -resize 124x124 \) -geometry +105+105 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#BEB2FF" -pointsize 28 \
  -annotate +105+285 "OPENAI BUILD WEEK" \
  \( -size 930x260 -background none -font "$font_bold" -fill white \
     -pointsize 76 caption:"GPT-5.6 makes\nyour tiny apps." \) \
  -geometry +105+340 -composite \
  \( -size 900x220 -background none -font "$font_regular" -fill "#E2DEFF" \
     -pointsize 39 caption:"Bring your own OpenAI API key. Describe a tool. Use it immediately inside one trusted iPhone app." \) \
  -geometry +110+650 -composite \
  -fill "#6F5CFF" -stroke none -draw "roundrectangle 105,900 560,970 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+945 "LIVE GPT-5.6 + BYOK" \
  "$panels_dir/01-key.png"

magick -size 1920x1080 xc:none \
  -fill "#100820E8" -stroke "#AF94FF88" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  -gravity NorthWest -font "$font_bold" -fill "#C7B7FF" -pointsize 28 \
  -annotate +105+135 "PROMPT 01 · FROM IDEA TO APP" \
  \( -size 930x300 -background none -font "$font_bold" -fill white \
     -pointsize 67 caption:"“Make a travel\nbudget converter.”" \) \
  -geometry +105+210 -composite \
  \( -size 900x210 -background none -font "$font_regular" -fill "#E7E0FF" \
     -pointsize 39 caption:"GPT-5.6 → validated AppDocument → native SwiftUI runtime" \) \
  -geometry +110+610 -composite \
  -fill "#6F52DD" -stroke none -draw "roundrectangle 105,900 685,970 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+945 "ONE SENTENCE → WORKING APP" \
  "$panels_dir/02-generate.png"

magick -size 1920x1080 xc:none \
  -fill "#07131AE8" -stroke "#55D7C888" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  -gravity NorthWest -font "$font_bold" -fill "#61E2D1" -pointsize 28 \
  -annotate +105+135 "PROMPT 02 · A DIFFERENT TINY APP" \
  \( -size 930x270 -background none -font "$font_bold" -fill white \
     -pointsize 72 caption:"Daily focus,\nbuilt on demand." \) \
  -geometry +105+210 -composite \
  \( -size 900x240 -background none -font "$font_regular" -fill "#D6F8F3" \
     -pointsize 40 caption:"Three tasks · local reminders\nPersistent data · native actions" \) \
  -geometry +110+590 -composite \
  -fill "#168F83" -stroke none -draw "roundrectangle 105,900 635,970 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+945 "REAL GPT-5.6 GENERATION" \
  "$panels_dir/03-breadth.png"

magick -size 1920x1080 xc:none \
  -fill "#07160FE8" -stroke "#5EE29388" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  -gravity NorthWest -font "$font_bold" -fill "#73E9A4" -pointsize 28 \
  -annotate +105+135 "SAME APP · NEXT VERSION" \
  \( -size 930x270 -background none -font "$font_bold" -fill white \
     -pointsize 76 caption:"Change it.\nDon’t rebuild it." \) \
  -geometry +105+210 -composite \
  \( -size 900x260 -background none -font "$font_regular" -fill "#DAF8E7" \
     -pointsize 40 caption:"Version 2 → Version 3\nNew style + evening reflection\nCompleted task preserved" \) \
  -geometry +110+570 -composite \
  -fill "#168F55" -stroke none -draw "roundrectangle 105,900 535,970 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+945 "ONE MORE PROMPT" \
  "$panels_dir/04-evolve.png"

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
crop=1920:1080,gblur=sigma=32,eq=brightness=-0.43:saturation=0.78,fps=30,\
tpad=stop_mode=clone:stop_duration=10,trim=duration=${duration},setpts=PTS-STARTPTS[bg];\
     [phone]scale=-2:1040:flags=lanczos,fps=30,tpad=stop_mode=clone:stop_duration=10,\
trim=duration=${duration},setpts=PTS-STARTPTS[fg];\
     [bg][fg]overlay=1320:20:shortest=1[scene];\
     [scene][1:v]overlay=0:0:shortest=1[v];\
     [2:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=8,\
atrim=duration=${duration},asetpts=PTS-STARTPTS[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t "$duration" \
    -movflags +faststart "$output"
}

render_live_segment \
  "$key_clip" \
  "$panels_dir/01-key.png" \
  "$audio_dir/demo-v4-01-core.mp3" \
  "13.5" \
  "$segments_dir/01-core.mp4"

render_live_segment \
  "$travel_clip" \
  "$panels_dir/02-generate.png" \
  "$audio_dir/demo-v4-02-travel.mp3" \
  "18.5" \
  "$segments_dir/02-travel.mp4"

render_live_segment \
  "$focus_clip" \
  "$panels_dir/03-breadth.png" \
  "$audio_dir/demo-v4-03-focus.mp3" \
  "11.4" \
  "$segments_dir/03-focus.mp4"

render_live_segment \
  "$evolve_clip" \
  "$panels_dir/04-evolve.png" \
  "$audio_dir/demo-v4-04-evolve.mp3" \
  "16.5" \
  "$segments_dir/04-evolve.mp4"

magick -size 1920x1080 gradient:"#0A0B18-#342061" \
  -gravity NorthWest -font "$font_bold" -fill "#BFAFFF" -pointsize 32 \
  -annotate +110+95 "CODEX ACCELERATED EVERY LAYER" \
  \( -size 1660x185 -background none -font "$font_bold" -fill white \
     -pointsize 70 caption:"From product thesis to a shippable iOS app." \) \
  -geometry +110+165 -composite \
  -fill "#1A1738" -stroke "#7664D8" -strokewidth 3 \
  -draw "roundrectangle 110,450 600,820 36,36 roundrectangle 715,450 1205,820 36,36 roundrectangle 1320,450 1810,820 36,36" \
  \( -size 420x130 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 50 -gravity center caption:"SCHEMA" \) -gravity NorthWest -geometry +145+495 -composite \
  \( -size 420x145 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 32 -gravity center caption:"Structured output\n+ validator" \) -gravity NorthWest -geometry +145+640 -composite \
  \( -size 420x130 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 50 -gravity center caption:"RUNTIME" \) -gravity NorthWest -geometry +750+495 -composite \
  \( -size 420x145 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 32 -gravity center caption:"Native SwiftUI\n+ safety boundary" \) -gravity NorthWest -geometry +750+640 -composite \
  \( -size 420x130 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 50 -gravity center caption:"TEST + SHIP" \) -gravity NorthWest -geometry +1355+495 -composite \
  \( -size 420x145 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 32 -gravity center caption:"43 tests\n+ App Store build" \) -gravity NorthWest -geometry +1355+640 -composite \
  "$slides_dir/05-codex.png"

magick -size 1920x1080 gradient:"#090817-#442481" \
  \( "$icon" -resize 280x280 \) -gravity North -geometry +0+80 -composite \
  \( -size 1650x220 -background none -font "$font_bold" -fill white \
     -pointsize 92 -gravity center caption:"Make yours." \) \
  -gravity North -geometry +0+420 -composite \
  \( -size 1500x190 -background none -font "$font_regular" -fill "#C8EDFF" \
     -pointsize 49 -gravity center caption:"Build it once. Evolve it whenever life changes." \) \
  -gravity North -geometry +0+680 -composite \
  -gravity South -font "$font_bold" -fill "#BFAFFF" -pointsize 27 \
  -annotate +0+75 "OPENAI BUILD WEEK · GPT-5.6 + CODEX" \
  "$slides_dir/06-close.png"

make_still_segment() {
  local slide="$1"
  local narration="$2"
  local duration="$3"
  local output="$4"

  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate 30 -i "$slide" -i "$narration" \
    -filter_complex \
    "[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=4,\
atrim=duration=${duration},asetpts=PTS-STARTPTS[a]" \
    -map 0:v -map "[a]" -c:v libx264 -preset medium -crf 18 -tune stillimage \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t "$duration" \
    -movflags +faststart "$output"
}

make_still_segment \
  "$slides_dir/05-codex.png" \
  "$audio_dir/demo-v4-05-codex.mp3" \
  "9.2" \
  "$segments_dir/05-codex.mp4"

make_still_segment \
  "$slides_dir/06-close.png" \
  "$audio_dir/demo-v4-06-close.mp3" \
  "7.2" \
  "$segments_dir/06-close.mp4"

# Six-frame dips keep text-heavy panels from overlapping while the audio uses a
# matching dissolve. Every interaction inside each source clip remains intact.
ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/01-core.mp4" \
  -i "$segments_dir/02-travel.mp4" \
  -i "$segments_dir/03-focus.mp4" \
  -i "$segments_dir/04-evolve.mp4" \
  -i "$segments_dir/05-codex.mp4" \
  -i "$segments_dir/06-close.mp4" \
  -filter_complex \
  "[0:v][1:v]xfade=transition=fadeblack:duration=0.2:offset=13.3[v01];\
   [v01][2:v]xfade=transition=fadeblack:duration=0.2:offset=31.6[v02];\
   [v02][3:v]xfade=transition=fadeblack:duration=0.2:offset=42.8[v03];\
   [v03][4:v]xfade=transition=fadeblack:duration=0.2:offset=59.1[v04];\
   [v04][5:v]xfade=transition=fadeblack:duration=0.2:offset=68.1,format=yuv420p[v];\
   [0:a][1:a]acrossfade=d=0.2:c1=tri:c2=tri[a01];\
   [a01][2:a]acrossfade=d=0.2:c1=tri:c2=tri[a02];\
   [a02][3:a]acrossfade=d=0.2:c1=tri:c2=tri[a03];\
   [a03][4:a]acrossfade=d=0.2:c1=tri:c2=tri[a04];\
   [a04][5:a]acrossfade=d=0.2:c1=tri:c2=tri[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 \
  -movflags +faststart "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -ss 7 -i "$focus_clip" -frames:v 1 "$slides_dir/thumbnail-phone.png"

magick -size 1280x720 gradient:"#080916-#432781" \
  \( "$icon" -resize 190x190 \) -geometry +75+70 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#BFAFFF" -pointsize 28 \
  -annotate +75+320 "OPENAI BUILD WEEK" \
  \( -size 830x260 -background none -font "$font_bold" -fill white \
     -pointsize 68 caption:"BUILD ANY TINY APP\nWITH GPT-5.6" \) \
  -geometry +75+370 -composite \
  -fill "#17142F" -stroke "#8D7BFF" -strokewidth 3 \
  -draw "roundrectangle 965,70 1210,650 42,42" \
  \( "$slides_dir/thumbnail-phone.png" -resize 225x490 \) -geometry +975+115 -composite \
  -quality 92 "$demo_dir/MakeYour-YouTube-Thumbnail.jpg"

ffprobe -v error \
  -show_entries format=duration,size \
  -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,sample_rate \
  -of default=noprint_wrappers=1 \
  "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"
