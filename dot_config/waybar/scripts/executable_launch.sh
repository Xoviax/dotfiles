#!/bin/bash

# Kill any existing waybar processes
pkill waybar

# Wait a bit for processes to die
sleep 0.5

# Launch waybar
waybar &