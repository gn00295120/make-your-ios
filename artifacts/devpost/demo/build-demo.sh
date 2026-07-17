#!/bin/zsh
set -euo pipefail

demo_dir="${0:A:h}"
repo_root="${demo_dir:h:h:h}"
panels_dir="$demo_dir/panels"
slides_dir="$demo_dir/slides"
segments_dir="$demo_dir/segments"
audio_dir="$demo_dir/audio"

key_clip="$repo_root/artifacts/app-store/videos/api-key-gpt56-runtime-final.mp4"
generation_clip="$repo_root/artifacts/app-store/videos/new-app-from-scratch-final.mp4"
fx_alert_clip="$repo_root/artifacts/app-store/videos/live-fx-alert-runtime-final.mp4"
pantry_clip="$repo_root/artifacts/app-store/videos/use-it-first-immersive-runtime-final.mp4"
icon="$repo_root/MakeYourIOS/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

font_regular="/System/Library/Fonts/Supplemental/Arial.ttf"
font_bold="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

mkdir -p "$panels_dir" "$slides_dir" "$segments_dir" "$audio_dir"

for required_file in \
  "$key_clip" \
  "$generation_clip" \
  "$fx_alert_clip" \
  "$pantry_clip" \
  "$icon" \
  "$audio_dir/demo-v3-01-key.mp3" \
  "$audio_dir/demo-v3-02-generate.mp3" \
  "$audio_dir/demo-v3-03-breadth.mp3" \
  "$audio_dir/demo-v3-04-codex.mp3" \
  "$audio_dir/demo-v3-05-close.mp3"; do
  [[ -f "$required_file" ]] || {
    print -u2 "missing required demo asset: $required_file"
    exit 1
  }
done

# The first frame states the product clearly: the user's own OpenAI key and
# GPT-5.6 turn MakeYour into an on-device factory for personal apps.
magick -size 1920x1080 xc:none \
  -fill "#080916DE" -stroke "#8D7BFF77" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  \( "$icon" -resize 124x124 \) -geometry +105+105 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#BEB2FF" -pointsize 28 \
  -annotate +105+285 "BRING YOUR OWN OPENAI KEY" \
  \( -size 930x260 -background none -font "$font_bold" -fill white \
     -pointsize 78 caption:"Your key.\nAny app." \) \
  -geometry +105+340 -composite \
  \( -size 900x210 -background none -font "$font_regular" -fill "#E2DEFF" \
     -pointsize 40 caption:"Select GPT-5.6. The key stays in iOS Keychain and requests go directly to OpenAI." \) \
  -geometry +110+655 -composite \
  -fill "#6F5CFF" -stroke none -draw "roundrectangle 105,900 485,970 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+945 "LIVE BYOK SETUP" \
  "$panels_dir/01-key.png"

magick -size 1920x1080 xc:none \
  -fill "#100820DE" -stroke "#AF94FF77" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  -gravity NorthWest -font "$font_bold" -fill "#C7B7FF" -pointsize 28 \
  -annotate +105+135 "REAL GPT-5.6 GENERATION" \
  \( -size 930x270 -background none -font "$font_bold" -fill white \
     -pointsize 74 caption:"Describe it.\nMakeYour builds it." \) \
  -geometry +105+210 -composite \
  \( -size 900x180 -background none -font "$font_regular" -fill "#E7E0FF" \
     -pointsize 40 caption:"Blank canvas → prompt → GPT-5.6 → validated native app" \) \
  -geometry +110+570 -composite \
  -fill "#1C1437" -stroke "#7E6AE8" -strokewidth 2 \
  -draw "roundrectangle 105,790 1010,875 26,26" \
  -font "$font_regular" -fill white -pointsize 31 \
  -annotate +145+844 "“Make a travel budget converter”" \
  -fill "#6F52DD" -stroke none -draw "roundrectangle 105,910 560,980 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+955 "ONE PROMPT → WORKING APP" \
  "$panels_dir/02-generate.png"

magick -size 1920x1080 xc:none \
  -fill "#06121DDE" -stroke "#5DD9FF77" -strokewidth 2 \
  -draw "roundrectangle 55,55 1160,1025 48,48" \
  -gravity NorthWest -font "$font_bold" -fill "#68DFFF" -pointsize 28 \
  -annotate +105+135 "NOT ONE CARD TEMPLATE" \
  \( -size 940x250 -background none -font "$font_bold" -fill white \
     -pointsize 69 caption:"Different apps.\nOne safe runtime." \) \
  -geometry +105+210 -composite \
  \( -size 900x350 -background none -font "$font_regular" -fill "#D6F3FF" \
     -pointsize 41 caption:"Live data · native alerts\nLocal records · photos\nReminders · reviewed AI\nA new prompt can change any app" \) \
  -geometry +110+520 -composite \
  -fill "#168BB4" -stroke none -draw "roundrectangle 105,910 620,980 35,35" \
  -font "$font_bold" -fill white -pointsize 27 -annotate +145+955 "GENERATED INSIDE MAKEYOUR" \
  "$panels_dir/03-breadth.png"

# A short breadth montage follows the complete generation flow. It is evidence
# that the runtime supports very different apps, not the video's main story.
ffmpeg -y -hide_banner -loglevel error \
  -i "$fx_alert_clip" -i "$pantry_clip" \
  -filter_complex \
  "[0:v]trim=start=0:end=3,setpts=PTS-STARTPTS,fps=30,scale=1320:2868:flags=lanczos,format=yuv420p[a];\
   [0:v]trim=start=5.7:end=8.7,setpts=PTS-STARTPTS,fps=30,scale=1320:2868:flags=lanczos,format=yuv420p[b];\
   [1:v]trim=start=9.2:end=13.5,setpts=PTS-STARTPTS,fps=30,scale=1320:2868:flags=lanczos,format=yuv420p[c];\
   [1:v]trim=start=22:end=25.2,setpts=PTS-STARTPTS,fps=30,scale=1320:2868:flags=lanczos,format=yuv420p[d];\
   [a][b][c][d]concat=n=4:v=1:a=0[v]" \
  -map "[v]" -c:v libx264 -preset medium -crf 19 -movflags +faststart \
  "$segments_dir/03-breadth-source.mp4"

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
tpad=stop_mode=clone:stop_duration=5,trim=duration=${duration},setpts=PTS-STARTPTS[bg];\
     [phone]scale=-2:1040:flags=lanczos,fps=30,tpad=stop_mode=clone:stop_duration=5,\
trim=duration=${duration},setpts=PTS-STARTPTS[fg];\
     [bg][fg]overlay=1320:20:shortest=1[scene];\
     [scene][1:v]overlay=0:0:shortest=1[v];\
     [2:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=5,\
atrim=duration=${duration},asetpts=PTS-STARTPTS[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t "$duration" \
    -movflags +faststart "$output"
}

render_live_segment \
  "$key_clip" \
  "$panels_dir/01-key.png" \
  "$audio_dir/demo-v3-01-key.mp3" \
  "8.1" \
  "$segments_dir/01-key.mp4"

render_live_segment \
  "$generation_clip" \
  "$panels_dir/02-generate.png" \
  "$audio_dir/demo-v3-02-generate.mp3" \
  "32.466667" \
  "$segments_dir/02-generate.mp4"

render_live_segment \
  "$segments_dir/03-breadth-source.mp4" \
  "$panels_dir/03-breadth.png" \
  "$audio_dir/demo-v3-03-breadth.mp3" \
  "13.5" \
  "$segments_dir/03-breadth.mp4"

magick -size 1920x1080 gradient:"#0A0B18-#342061" \
  -gravity NorthWest -font "$font_bold" -fill "#BFAFFF" -pointsize 32 \
  -annotate +110+95 "CODEX ACCELERATED THE BUILD" \
  \( -size 1600x170 -background none -font "$font_bold" -fill white \
     -pointsize 72 caption:"Architecture, native runtime, testing, and release." \) \
  -geometry +110+165 -composite \
  -fill "#1A1738" -stroke "#7664D8" -strokewidth 3 \
  -draw "roundrectangle 110,450 600,820 36,36 roundrectangle 715,450 1205,820 36,36 roundrectangle 1320,450 1810,820 36,36" \
  \( -size 420x155 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 76 -gravity center caption:"43 / 43" \) -gravity NorthWest -geometry +145+495 -composite \
  \( -size 420x100 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 36 -gravity center caption:"tests passed" \) -gravity NorthWest -geometry +145+670 -composite \
  \( -size 420x155 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 76 -gravity center caption:"ZERO" \) -gravity NorthWest -geometry +750+495 -composite \
  \( -size 420x100 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 36 -gravity center caption:"lint violations" \) -gravity NorthWest -geometry +750+670 -composite \
  \( -size 420x155 -background none -font "$font_bold" -fill white -stroke none \
     -pointsize 64 -gravity center caption:"BUILD 1" \) -gravity NorthWest -geometry +1355+495 -composite \
  \( -size 420x130 -background none -font "$font_regular" -fill "#DCD5FF" -stroke none \
     -pointsize 34 -gravity center caption:"submitted for\nApp Store review" \) -gravity NorthWest -geometry +1355+650 -composite \
  "$slides_dir/04-codex.png"

magick -size 1920x1080 gradient:"#090817-#442481" \
  \( "$icon" -resize 280x280 \) -gravity North -geometry +0+95 -composite \
  \( -size 1650x240 -background none -font "$font_bold" -fill white \
     -pointsize 86 -gravity center caption:"Your GPT-5.6. Your apps." \) \
  -gravity North -geometry +0+430 -composite \
  \( -size 1400x150 -background none -font "$font_regular" -fill "#BFEAFF" \
     -pointsize 50 -gravity center caption:"Make it, use it, and evolve it inside MakeYour." \) \
  -gravity North -geometry +0+730 -composite \
  "$slides_dir/05-close.png"

make_still_segment() {
  local slide="$1"
  local narration="$2"
  local duration="$3"
  local output="$4"

  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate 30 -i "$slide" -i "$narration" \
    -filter_complex \
    "[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=2,\
atrim=duration=${duration},asetpts=PTS-STARTPTS[a]" \
    -map 0:v -map "[a]" -c:v libx264 -preset medium -crf 18 -tune stillimage \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t "$duration" \
    -movflags +faststart "$output"
}

make_still_segment \
  "$slides_dir/04-codex.png" \
  "$audio_dir/demo-v3-04-codex.mp3" \
  "14.304" \
  "$segments_dir/04-codex.mp4"

make_still_segment \
  "$slides_dir/05-close.png" \
  "$audio_dir/demo-v3-05-close.mp3" \
  "6.552" \
  "$segments_dir/05-close.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/01-key.mp4" \
  -i "$segments_dir/02-generate.mp4" \
  -i "$segments_dir/03-breadth.mp4" \
  -i "$segments_dir/04-codex.mp4" \
  -i "$segments_dir/05-close.mp4" \
  -filter_complex \
  "[0:v][0:a][1:v][1:a][2:v][2:a][3:v][3:a][4:v][4:a]concat=n=5:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 \
  -movflags +faststart "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"

ffprobe -v error \
  -show_entries format=duration,size \
  -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,sample_rate \
  -of default=noprint_wrappers=1 \
  "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"
