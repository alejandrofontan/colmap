#!/bin/bash

DIVISOR="10"

# Function to split key-value pairs and assign them to variables
max_rgb="50" # Default value. Can be overwritten "max_rgb:500"
matcher_type="exhaustive" # Default value. Options: exhaustive, sequential
use_gpu="1" # Default value.
verbose="0"

split_and_assign() {
  local input=$1
  local key=$(echo $input | cut -d':' -f1)
  local value=$(echo $input | cut -d':' -f2-)
  eval $key=$value
}

# Split the input string into individual components
for ((i=1; i<=$#; i++)); do
    split_and_assign "${!i}"
done

exp_id=$(printf "%05d" ${exp_id})

echo "Sequence Path: $sequence_path"
echo "Experiment Folder: $exp_folder"
echo "Experiment ID: $exp_id"
echo "Verbose: $verbose"
echo "max_rgb: $max_rgb"
echo "matcher_type: $matcher_type"
echo "use_gpu: $use_gpu"

# Calculate the minimum frames per second (fps) for downsampling
calibration_file="${sequence_path}/calibration.yaml"
fps=$(grep -oP '(?<=Camera\.fps:\s)-?\d+\.\d+' "$calibration_file")
min_fps=$(echo "scale=2; $fps / ${DIVISOR}" | bc)

exp_folder_colmap="${exp_folder}/colmap_${exp_id}"
rm -rf "$exp_folder_colmap"
mkdir "$exp_folder_colmap"

# Downsample RGB frames
rgb_ds_txt="${exp_folder_colmap}/rgb_ds.txt"
python Baselines/downsample_rgb_frames.py $sequence_path --rgb_ds_txt "${rgb_ds_txt}" --min_fps ${min_fps} -v --max_rgb ${max_rgb}

# Run COLMAP scripts for matching and mapping
pixi run -e colmap ./Baselines/colmap/colmap_matcher.sh $sequence_path $exp_folder $exp_id $matcher_type $use_gpu
pixi run -e colmap ./Baselines/colmap/colmap_mapper.sh $sequence_path $exp_folder $exp_id $verbose

# Convert COLMAP outputs to a format suitable for VSLAM-Lab
python Baselines/colmap/colmap_to_vslamlab.py $sequence_path $exp_folder $exp_id


