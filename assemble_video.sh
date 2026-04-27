#!/bin/bash

TS="$1"
MUSIC_FILE="$2"

echo "DEBUG: TS=${TS}"
echo "DEBUG: MUSIC_FILE=${MUSIC_FILE}"

# -------------------------
# VALIDATION
# -------------------------

if [ -z "$TS" ]; then
  echo "FATAL: Timestamp is empty"
  exit 1
fi

if [ ! -f /tmp/voice_${TS}.mp3 ]; then
  echo "FATAL: Voice file missing"
  exit 1
fi

if [ ! -f /tmp/subs_${TS}.vtt ]; then
  echo "FATAL: Subs file missing"
  exit 1
fi

if [ ! -f /tmp/download_${TS}.sh ]; then
  echo "FATAL: Download script missing"
  exit 1
fi

if [ ! -f /tmp/list_${TS}.txt ]; then
  echo "FATAL: Concat list missing"
  exit 1
fi

if [ ! -f "$MUSIC_FILE" ]; then
  echo "FATAL: Music file invalid: $MUSIC_FILE"
  exit 1
fi

echo "DEBUG: Voice exists: $(ls -la /tmp/voice_${TS}.mp3)"

# -------------------------
# DOWNLOAD CLIPS
# -------------------------

bash /tmp/download_${TS}.sh

CLIP_COUNT=$(ls /tmp/clip*_${TS}.mp4 2>/dev/null | wc -l)
echo "DEBUG: Downloaded ${CLIP_COUNT} clips"

if [ "$CLIP_COUNT" -lt "2" ]; then
  echo "FATAL: Only ${CLIP_COUNT} clips downloaded"
  exit 1
fi

# -------------------------
# NORMALIZE CLIPS (CRITICAL FIX)
# -------------------------

echo "DEBUG: Normalizing clips..."

rm -f /tmp/norm_clip*_${TS}.mp4

for f in /tmp/clip*_${TS}.mp4; do
  OUT="/tmp/norm_$(basename "$f")"

  ffmpeg -y -loglevel error -i "$f" \
    -vf "fps=25,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920" \
    -c:v libx264 -preset ultrafast -crf 28 \
    -an \
    "$OUT"

  if [ ! -f "$OUT" ]; then
    echo "FATAL: Failed to normalize $f"
    exit 1
  fi
done

# -------------------------
# BUILD NEW CONCAT LIST
# -------------------------

echo "DEBUG: Building normalized concat list..."

rm -f /tmp/list_${TS}.txt

for f in /tmp/norm_clip*_${TS}.mp4; do
  echo "file '$f'" >> /tmp/list_${TS}.txt
done

cat /tmp/list_${TS}.txt

# -------------------------
# GET VOICE DURATION
# -------------------------

VOICE_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 /tmp/voice_${TS}.mp3)

TOTAL_DURATION=$(echo "$VOICE_DURATION + 0.5" | bc)

echo "DEBUG: Voice duration = ${VOICE_DURATION}"
echo "DEBUG: Total duration = ${TOTAL_DURATION}"

# -------------------------
# CONCAT BACKGROUND VIDEO
# -------------------------

echo "DEBUG: Creating background video..."

ffmpeg -y -loglevel error \
  -f concat -safe 0 \
  -i /tmp/list_${TS}.txt \
  -c:v libx264 -preset ultrafast -crf 28 \
  -an \
  /tmp/bg_${TS}.mp4

if [ ! -f /tmp/bg_${TS}.mp4 ]; then
  echo "FATAL: Background video not created"
  exit 1
fi

echo "DEBUG: Background video ready"


# Fix subtitle overlaps
python3 /home/YOUR_USERNAME/fix_subs.py /tmp/subs_${TS}.vtt

# -------------------------
# FINAL VIDEO (SUBS + AUDIO)
# -------------------------

echo "DEBUG: Creating final video..."

ffmpeg -y -loglevel error \
  -i /tmp/bg_${TS}.mp4 \
  -i /tmp/voice_${TS}.mp3 \
  -i "$MUSIC_FILE" \
  -t ${TOTAL_DURATION} \
  -filter_complex "\
    [1:a]volume=1.3[voice]; \
    [2:a]volume=0.22[music]; \
    [voice][music]amix=inputs=2:duration=first:dropout_transition=2[aout]; \
    [0:v]subtitles=/tmp/subs_${TS}.vtt:force_style='Fontname=Arial,Fontsize=16,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=2,Shadow=1,Alignment=2,MarginV=60,MarginL=40,MarginR=40,WrapStyle=1'[vout]" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset ultrafast -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  /tmp/final_${TS}.mp4

if [ ! -f /tmp/final_${TS}.mp4 ]; then
  echo "FATAL: Final video not created"
  exit 1
fi

FINAL_SIZE=$(stat -c%s /tmp/final_${TS}.mp4)

echo "VIDEO_DONE"
echo "FINAL_SIZE=${FINAL_SIZE}"
