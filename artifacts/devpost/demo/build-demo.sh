#!/bin/zsh
set -euo pipefail

demo_dir="${0:A:h}"
repo_root="${demo_dir:h:h:h}"
slides_dir="$demo_dir/slides"
segments_dir="$demo_dir/segments"
phones_dir="$demo_dir/phones"
audio_dir="$demo_dir/audio"
preferred_generation_clip="$repo_root/artifacts/app-store/videos/new-app-from-scratch-final.mp4"
fallback_generation_clip="$repo_root/artifacts/app-store/videos/final-ai-generation-polished.mp4"

if [[ -f "$preferred_generation_clip" ]]; then
  generation_clip="$preferred_generation_clip"
else
  generation_clip="$fallback_generation_clip"
  print -u2 "note: using existing generation clip; record ${preferred_generation_clip:t} (26.0 seconds) for the final demo"
fi

mkdir -p "$slides_dir" "$segments_dir" "$phones_dir" "$audio_dir"

font_regular="/System/Library/Fonts/Helvetica.ttc"
font_bold="/System/Library/Fonts/HelveticaNeue.ttc"
icon="$repo_root/MakeYourIOS/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
shots="$repo_root/artifacts/app-store/screenshots/upload"

make_phone() {
  local source_image="$1"
  local height="$2"
  local output_image="$3"
  magick "$source_image" -resize "x${height}" \
    -bordercolor "#FFFFFF" -border 5 "$output_image"
}

make_phone "$shots/01-app-library.jpg" 900 "$phones_dir/library.png"
make_phone "$shots/03-rate-test-alert.jpg" 700 "$phones_dir/fx-alert.png"
make_phone "$shots/04-use-it-first.jpg" 820 "$phones_dir/pantry-home.png"
make_phone "$shots/05-use-it-first-record.jpg" 820 "$phones_dir/pantry-record.png"
make_phone "$shots/06-reviewed-ai-helper.jpg" 820 "$phones_dir/pantry-ai.png"

magick -size 1920x1080 gradient:"#090817-#442481" \
  \( "$icon" -resize 380x380 \) -geometry +130+335 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#8BE8FF" -pointsize 34 \
  -annotate +620+165 "OPENAI BUILD WEEK" \
  \( -size 1120x300 -background none -font "$font_bold" -fill white \
     -pointsize 88 caption:"Stop downloading another tiny app." \) \
  -geometry +620+225 -composite \
  \( -size 1080x150 -background none -font "$font_regular" -fill "#D8D3F3" \
     -pointsize 46 caption:"Make yours — a private native home for personal software." \) \
  -geometry +625+600 -composite \
  "$slides_dir/01-problem.png"

magick -size 1920x1080 gradient:"#0A1422-#223C71" \
  "$phones_dir/library.png" -geometry +155+90 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#6FE8FF" -pointsize 32 \
  -annotate +760+160 "ONE HOME. MANY PERSONAL APPS." \
  \( -size 1030x260 -background none -font "$font_bold" -fill white \
     -pointsize 72 caption:"Describe it. Generate it. Use it." \) \
  -geometry +760+225 -composite \
  \( -size 1000x230 -background none -font "$font_regular" -fill "#D4E4FF" \
     -pointsize 42 caption:"GPT-5.6   •   validated AppDocument   •   native SwiftUI runtime" \) \
  -geometry +765+560 -composite \
  "$slides_dir/02-library.png"

magick -size 1920x1080 gradient:"#07141D-#174E6E" \
  "$phones_dir/fx-alert.png" -geometry +1515+290 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#70D8FF" -pointsize 32 \
  -annotate +680+155 "GENERATED APP #1" \
  \( -size 760x220 -background none -font "$font_bold" -fill white \
     -pointsize 72 caption:"Live FX Watch" \) \
  -geometry +680+215 -composite \
  \( -size 780x330 -background none -font "$font_regular" -fill "#D6F2FF" \
     -pointsize 40 caption:"Choose a base currency. Add countries. Refresh reference rates. Test a threshold alert." \) \
  -geometry +685+440 -composite \
  "$slides_dir/03-fx.png"

magick -size 1920x1080 gradient:"#071C18-#1F6858" \
  "$phones_dir/pantry-home.png" -geometry +65+130 -composite \
  "$phones_dir/pantry-record.png" -geometry +455+130 -composite \
  "$phones_dir/pantry-ai.png" -geometry +845+130 -composite \
  -gravity NorthWest -font "$font_bold" -fill "#87FFD8" -pointsize 30 \
  -annotate +1250+170 "GENERATED APP #2" \
  \( -size 600x190 -background none -font "$font_bold" -fill white \
     -pointsize 68 caption:"Use It First" \) \
  -geometry +1250+225 -composite \
  \( -size 570x410 -background none -font "$font_regular" -fill "#D8FFF3" \
     -pointsize 38 caption:"Private photos\nPantry records\nUse-by dates\nLocal reminders\nReviewed text-only AI" \) \
  -geometry +1255+455 -composite \
  "$slides_dir/04-pantry.png"

magick -size 1920x1080 gradient:"#110A25-#4B2CB4" \
  -gravity NorthWest -font "$font_bold" -fill "#C8B8FF" -pointsize 32 \
  -annotate +120+160 "REAL iOS SIMULATOR — GPT-5.6" \
  \( -size 1000x260 -background none -font "$font_bold" -fill white \
     -pointsize 78 caption:"Build it. Open it. Use it." \) \
  -geometry +120+225 -composite \
  \( -size 950x270 -background none -font "$font_regular" -fill "#E3DEFF" \
     -pointsize 42 caption:"My Apps   •   blank canvas   •   prompt   •   validated native runtime" \) \
  -geometry +125+585 -composite \
  "$slides_dir/05-generation.png"

magick -size 1920x1080 gradient:"#0B0B17-#39206E" \
  -gravity NorthWest -font "$font_bold" -fill "#BDAEFF" -pointsize 34 \
  -annotate +110+95 "BUILT AND VERIFIED WITH CODEX" \
  \( -size 1150x190 -background none -font "$font_bold" -fill white \
     -pointsize 72 caption:"From product thesis to App Store build." \) \
  -geometry +110+155 -composite \
  -fill "#201A43" -stroke "#725CFF" -strokewidth 3 \
  -draw "roundrectangle 110,440 500,790 34,34 roundrectangle 545,440 935,790 34,34 roundrectangle 980,440 1370,790 34,34 roundrectangle 1415,440 1805,790 34,34" \
  \( -size 330x160 -background none -font "$font_bold" -fill white -stroke none -strokewidth 0 -pointsize 70 -gravity center caption:"43 / 43" \) -gravity NorthWest -geometry +140+485 -composite \
  \( -size 330x90 -background none -font "$font_regular" -fill "#D9D1FF" -stroke none -strokewidth 0 -pointsize 34 -gravity center caption:"tests passed" \) -gravity NorthWest -geometry +140+650 -composite \
  \( -size 330x160 -background none -font "$font_bold" -fill white -stroke none -strokewidth 0 -pointsize 70 -gravity center caption:"0" \) -gravity NorthWest -geometry +575+485 -composite \
  \( -size 330x90 -background none -font "$font_regular" -fill "#D9D1FF" -stroke none -strokewidth 0 -pointsize 34 -gravity center caption:"lint violations" \) -gravity NorthWest -geometry +575+650 -composite \
  \( -size 330x160 -background none -font "$font_bold" -fill white -stroke none -strokewidth 0 -pointsize 66 -gravity center caption:"REAL API" \) -gravity NorthWest -geometry +1010+485 -composite \
  \( -size 330x90 -background none -font "$font_regular" -fill "#D9D1FF" -stroke none -strokewidth 0 -pointsize 34 -gravity center caption:"generation tested" \) -gravity NorthWest -geometry +1010+650 -composite \
  \( -size 330x160 -background none -font "$font_bold" -fill white -stroke none -strokewidth 0 -pointsize 60 -gravity center caption:"BUILD 1" \) -gravity NorthWest -geometry +1445+485 -composite \
  \( -size 330x110 -background none -font "$font_regular" -fill "#D9D1FF" -stroke none -strokewidth 0 -pointsize 32 -gravity center caption:"uploaded to\nApp Store Connect" \) -gravity NorthWest -geometry +1445+635 -composite \
  "$slides_dir/07-codex.png"

magick -size 1920x1080 gradient:"#090817-#442481" \
  \( "$icon" -resize 310x310 \) -gravity North -geometry +0+125 -composite \
  \( -size 1500x170 -background none -font "$font_bold" -fill white \
     -pointsize 86 -gravity center caption:"Personal software should live and evolve." \) \
  -gravity North -geometry +0+500 -composite \
  \( -size 1300x130 -background none -font "$font_regular" -fill "#BFEAFF" \
     -pointsize 52 -gravity center caption:"Stop downloading another tiny app. Make yours." \) \
  -gravity North -geometry +0+730 -composite \
  "$slides_dir/08-close.png"

make_still_segment() {
  local slide="$1"
  local narration="$2"
  local output="$3"
  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate 30 -i "$slide" -i "$narration" \
    -map 0:v -map 1:a -c:v libx264 -preset medium -crf 18 -tune stillimage \
    -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -shortest \
    -movflags +faststart "$output"
}

make_still_segment "$slides_dir/01-problem.png" "$audio_dir/01-problem.mp3" "$segments_dir/01.mp4"
make_still_segment "$slides_dir/02-library.png" "$audio_dir/02-library.mp3" "$segments_dir/02.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -loop 1 -framerate 30 -i "$slides_dir/03-fx.png" \
  -i "$repo_root/artifacts/app-store/videos/live-fx-runtime-final.mp4" \
  -i "$audio_dir/03-fx.mp3" \
  -filter_complex "[1:v]setpts=0.75*PTS,scale=-2:900,fps=30,tpad=stop_mode=clone:stop_duration=8[phone];[0:v][phone]overlay=130:90:shortest=1[v]" \
  -map "[v]" -map 2:a -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -shortest \
  -movflags +faststart "$segments_dir/03.mp4"

make_still_segment "$slides_dir/04-pantry.png" "$audio_dir/04-pantry.mp3" "$segments_dir/04.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -loop 1 -framerate 30 -i "$slides_dir/05-generation.png" \
  -i "$generation_clip" \
  -i "$audio_dir/05-generation.mp3" \
  -filter_complex "[1:v]scale=-2:980,fps=30,tpad=stop_mode=clone:stop_duration=8[phone];[0:v][phone]overlay=1280:50:shortest=1[v]" \
  -map "[v]" -map 2:a -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -shortest \
  -movflags +faststart "$segments_dir/05.mp4"

make_still_segment "$slides_dir/07-codex.png" "$audio_dir/07-codex.mp3" "$segments_dir/07.mp4"
make_still_segment "$slides_dir/08-close.png" "$audio_dir/08-close.mp3" "$segments_dir/08.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/01.mp4" -i "$segments_dir/02.mp4" \
  -i "$segments_dir/03.mp4" -i "$segments_dir/04.mp4" \
  -i "$segments_dir/05.mp4" -i "$segments_dir/07.mp4" \
  -i "$segments_dir/08.mp4" \
  -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a][3:v][3:a][4:v][4:a][5:v][5:a][6:v][6:a]concat=n=7:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -pix_fmt yuv420p -movflags +faststart \
  "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"

ffprobe -v error -show_entries format=duration,size \
  -show_entries stream=codec_name,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 "$demo_dir/MakeYour-OpenAI-Build-Week-Demo.mp4"
