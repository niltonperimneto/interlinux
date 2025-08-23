#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Your code goes here.
echo 'This is an example shell script'
echo 'Scripts here will run during build if specified in recipe.yml'

# Debugging: Log the files module paths
echo "Running files module..."
echo "Source paths:"
echo "usr, etc, system, home"

# Check if the source directories exist
for dir in usr etc system home; do
  if [[ ! -d "/tmp/$dir" ]]; then
    echo "Error: Source directory /tmp/$dir does not exist!" >&2
    exit 1
  fi
done

echo "All source directories exist. Proceeding with the build."
