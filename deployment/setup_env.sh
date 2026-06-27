#!/bin/bash

# Define the base directory
BASE_DIR=~/MoE

# Create the base directory if it doesn't exist
mkdir -p $BASE_DIR

# Create a virtual environment in the base directory
python3 -m venv $BASE_DIR/venv

# Activate the virtual environment
source $BASE_DIR/venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Deactivate the virtual environment
deactivate

