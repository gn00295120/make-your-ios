#!/bin/zsh
set -euo pipefail

demo_dir="${0:A:h}"
repo_root="${demo_dir:h:h:h}"
panels_dir="$demo_dir/panels"
slides_dir="$demo_dir/slides"
segments_dir="$demo_dir/segments"
audio_dir="$demo_dir/audio"

trip_pilot_generation="$demo_dir/TripPilot-Full-Generation-2026-07-19.mp4"
trip_pilot_runtime="$demo_dir/TripPilot-Currency-Runtime-2026-07-19.mp4"
trip_pilot_audio="$audio_dir/demo-v6-02-trip-pilot.mp3"
style_clip="$repo_root/artifacts/app-store/videos/focus-checklist-style-update-final.mp4"
style_audio="$audio_dir/demo-v5-03-style.mp3"
icon="$repo_root/MakeYourIOS/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
final_video="$demo_dir/MakeYour-OpenAI-Build-Week-Demo-v2.mp4"
final_thumbnail="$demo_dir/MakeYour-YouTube-Thumbnail-v2.jpg"

font_regular="/System/Library/Fonts/Supplemental/Arial.ttf"
font_bold="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

mkdir -p "$panels_dir" "$slides_dir" "$segments_dir" "$audio_dir"

for required_file in \
  "$trip_pilot_generation" \
  "$trip_pilot_runtime" \
  "$trip_pilot_audio" \
  "$style_clip" \
  "$style_audio" \
  "$icon"; do
  [[ -f "$required_file" ]] || {
    print -u2 "missing required demo asset: $required_file"
    exit 1
  }
done

# Rebuild the five unchanged chapters from their original, real Simulator
# sources. The v2 edit replaces only the creation chapter.
"$demo_dir/build-demo.sh" >/tmp/makeyour-demo-v1-build.log

magick -size 1920x1080 xc:none \
  -fill "#070914E6" -stroke "#57C9FF99" -strokewidth 2 \
  -draw "roundrectangle 55,55 715,285 30,30" \
  -fill "#57C9FF" -stroke none \
  -draw "roundrectangle 80,83 92,257 6,6" \
  -gravity NorthWest -font "$font_bold" -fill "#57C9FF" -pointsize 22 \
  -annotate +118+106 "REAL GPT-5.6 RUN" \
  \( -size 560x72 -background none -font "$font_bold" -fill white \
     -pointsize 42 caption:"Invalid → repaired → live" \) \
  -geometry +118+130 -composite \
  \( -size 560x56 -background none -font "$font_regular" -fill "#E4E6F6" \
     -pointsize 24 caption:"Prompt preserved  ·  wait accelerated" \) \
  -geometry +118+218 -composite \
  "$panels_dir/02-trip-pilot.png"

# Preserve all meaningful state transitions from the real 3:30 generation run:
# prompt, initial composition, validator-triggered repair, capability review,
# runtime open, and the separately recorded persisted currency interaction.
# Only the two model-wait intervals are accelerated.
ffmpeg -y -hide_banner -loglevel error \
  -i "$trip_pilot_generation" -i "$trip_pilot_runtime" \
  -filter_complex \
  "[0:v]split=4[prompt][compose][repair][finish];\
   [prompt]trim=start=14:end=21,setpts=PTS-STARTPTS,fps=30,format=yuv420p[p];\
   [compose]trim=start=21:end=119,setpts=(PTS-STARTPTS)/14,fps=30,format=yuv420p[c];\
   [repair]trim=start=119:end=202,setpts=(PTS-STARTPTS)/12,fps=30,format=yuv420p[r];\
   [finish]trim=start=202:end=210.7,setpts=PTS-STARTPTS,fps=30,format=yuv420p[f];\
   [p][c][r][f]concat=n=4:v=1:a=0,settb=1/30[generation];\
   [1:v]trim=start=18:end=27,setpts=PTS-STARTPTS,fps=30,settb=1/30,format=yuv420p[runtime];\
   [generation][runtime]xfade=transition=fade:duration=0.35:offset=29.266667[v]" \
  -map "[v]" -an -c:v libx264 -preset medium -crf 18 -r 30 \
  -pix_fmt yuv420p -movflags +faststart "$segments_dir/trip-pilot-source.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/trip-pilot-source.mp4" \
  -loop 1 -framerate 30 -i "$panels_dir/02-trip-pilot.png" \
  -i "$trip_pilot_audio" \
  -filter_complex \
  "[0:v]split=2[background][phone];\
   [background]scale=1920:1080:force_original_aspect_ratio=increase,\
crop=1920:1080,gblur=sigma=36,eq=brightness=-0.40:saturation=0.72,fps=30,\
tpad=stop_mode=clone:stop_duration=12,trim=duration=45.7,setpts=PTS-STARTPTS[bg];\
   [phone]scale=-2:1040:flags=lanczos,fps=30,tpad=stop_mode=clone:stop_duration=12,\
trim=duration=45.7,setpts=PTS-STARTPTS[fg];\
   [bg][fg]overlay=760:20:shortest=1[scene];\
   [scene][1:v]overlay=0:0:shortest=1[v];\
   [2:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=12,\
atrim=duration=45.7,asetpts=PTS-STARTPTS[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t 45.7 \
  -movflags +faststart "$segments_dir/02-trip-pilot.mp4"

# The historical style capture contains two black frames at its internal app
# handoff. Replace that dip with a direct four-tenth-second dissolve between the
# last clean frame before the handoff and the first clean frame after it.
ffmpeg -y -hide_banner -loglevel error \
  -i "$style_clip" \
  -filter_complex \
  "[0:v]split=2[before][after];\
   [before]trim=start=0:end=3.2,setpts=PTS-STARTPTS,fps=30,settb=1/30,format=yuv420p[b];\
   [after]trim=start=3.6,setpts=PTS-STARTPTS,fps=30,settb=1/30,format=yuv420p[a];\
   [b][a]xfade=transition=fade:duration=0.4:offset=2.8[v]" \
  -map "[v]" -an -c:v libx264 -preset medium -crf 18 -r 30 \
  -pix_fmt yuv420p -movflags +faststart "$segments_dir/style-no-flash-source.mp4"

ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/style-no-flash-source.mp4" \
  -loop 1 -framerate 30 -i "$panels_dir/03-style.png" \
  -i "$style_audio" \
  -filter_complex \
  "[0:v]split=2[background][phone];\
   [background]scale=1920:1080:force_original_aspect_ratio=increase,\
crop=1920:1080,gblur=sigma=36,eq=brightness=-0.40:saturation=0.72,fps=30,\
tpad=stop_mode=clone:stop_duration=12,trim=duration=19.9,setpts=PTS-STARTPTS[bg];\
   [phone]scale=-2:1040:flags=lanczos,fps=30,tpad=stop_mode=clone:stop_duration=12,\
trim=duration=19.9,setpts=PTS-STARTPTS[fg];\
   [bg][fg]overlay=760:20:shortest=1[scene];\
   [scene][1:v]overlay=0:0:shortest=1[v];\
   [2:a]loudnorm=I=-16:TP=-1.5:LRA=11,apad=pad_dur=12,\
atrim=duration=19.9,asetpts=PTS-STARTPTS[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 -t 19.9 \
  -movflags +faststart "$segments_dir/03-style-v2.mp4"

# The replacement chapter is 28.9 seconds longer than the original creation
# chapter. Twelve-frame cross-dissolves keep every transition free of flashes.
ffmpeg -y -hide_banner -loglevel error \
  -i "$segments_dir/01-pages.mp4" \
  -i "$segments_dir/02-trip-pilot.mp4" \
  -i "$segments_dir/03-style-v2.mp4" \
  -i "$segments_dir/04-switch.mp4" \
  -i "$segments_dir/05-codex.mp4" \
  -i "$segments_dir/06-close.mp4" \
  -filter_complex \
  "[0:v][1:v]xfade=transition=fade:duration=0.4:offset=21.0[v01];\
   [v01][2:v]xfade=transition=fade:duration=0.4:offset=66.3[v02];\
   [v02][3:v]xfade=transition=fade:duration=0.4:offset=85.8[v03];\
   [v03][4:v]xfade=transition=fade:duration=0.4:offset=108.9[v04];\
   [v04][5:v]xfade=transition=fade:duration=0.4:offset=117.1,format=yuv420p[v];\
   [0:a][1:a]acrossfade=d=0.4:c1=tri:c2=tri[a01];\
   [a01][2:a]acrossfade=d=0.4:c1=tri:c2=tri[a02];\
   [a02][3:a]acrossfade=d=0.4:c1=tri:c2=tri[a03];\
   [a03][4:a]acrossfade=d=0.4:c1=tri:c2=tri[a04];\
   [a04][5:a]acrossfade=d=0.4:c1=tri:c2=tri[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k -ar 48000 -pix_fmt yuv420p -r 30 \
  -movflags +faststart "$final_video"

ffmpeg -y -hide_banner -loglevel error \
  -i "$trip_pilot_runtime" -ss 24 -frames:v 1 \
  "$slides_dir/thumbnail-trip-pilot.png"

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
  \( "$slides_dir/thumbnail-trip-pilot.png" -resize 275x598 \) \
  -geometry +940+61 -composite \
  -quality 92 "$final_thumbnail"

duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$final_video")
awk -v duration="$duration" 'BEGIN { exit !(duration < 180) }'

# Decode every output frame and audio packet before considering the edit done.
ffmpeg -v error -i "$final_video" -f null -

ffprobe -v error \
  -show_entries format=duration,size \
  -show_entries stream=codec_name,codec_type,width,height,r_frame_rate,pix_fmt,sample_rate,channels \
  -of default=noprint_wrappers=1 \
  "$final_video"
