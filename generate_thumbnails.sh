#!/bin/bash

################################################################################
# SCRIPT: generate_thumbnails.sh
# DESCRIPTION: Automates portfolio thumbnail creation using ImageMagick (v6 or v7).
# 
# HOW TO USE:
# 1. Install ImageMagick: sudo apt update && sudo apt install imagemagick
# 2. Place screenshots in the 'raw_screenshots/' folder.
#    Expected names: supply_chain_raw.png, customer_raw.png, etc.
# 3. Make script executable: chmod +x generate_thumbnails.sh
# 4. Run: ./generate_thumbnails.sh
################################################################################

# 📁 Ensure directories exist
mkdir -p raw_screenshots
mkdir -p images/thumbnails

# 🔍 Detect ImageMagick Version (magick for v7+, convert for v6)
if command -v magick &> /dev/null; then
    IMG_TOOL="magick"
elif command -v convert &> /dev/null; then
    IMG_TOOL="convert"
else
    echo "❌ Error: ImageMagick is not installed."
    echo "👉 Run: sudo apt update && sudo apt install imagemagick"
    exit 1
fi

echo "🎨 Using $IMG_TOOL to process thumbnails..."

# 🛠️ Processing Logic:
# -resize 800x450^ : Ensures image covers the entire 16:9 area
# -gravity center  : Keeps the center of your dashboard as the focal point
# -extent 800x450   : Crops any overflow for perfect grid alignment
process_image() {
    local input=$1
    local output=$2
    $IMG_TOOL "$input" -resize 800x450^ -gravity center -extent 800x450 "$output"
    echo "✅ Created: $output"
}

# 🚀 Process specific files to match projects.yml
# (Only runs if the raw source file exists)

[ -f "raw_screenshots/supply_chain_raw.png" ] && \
    process_image "raw_screenshots/supply_chain_raw.png" "images/thumbnails/supply-chain.png"

[ -f "raw_screenshots/customer_raw.png" ] && \
    process_image "raw_screenshots/customer_raw.png" "images/thumbnails/customer-behaviour.png"

[ -f "raw_screenshots/workforce_raw.png" ] && \
    process_image "raw_screenshots/workforce_raw.png" "images/thumbnails/workforce.png"

[ -f "raw_screenshots/data_quality_raw.png" ] && \
    process_image "raw_screenshots/data_quality_raw.png" "images/thumbnails/data-quality.png"

echo "✨ Done! Refresh your Quarto preview to see the results."