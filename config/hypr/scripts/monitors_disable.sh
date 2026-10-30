#!/bin/bash

main_monitor="DP-2"
secondary_monitors=("HDMI-A-1" "DP-1")

# Get status of secundary monitor
state=$(hyprctl monitors | grep -A 21 "${secondary_monitors[0]}" | grep disabled | awk '{print $NF}')

# Validate the status 
if [[ "$state" = "false" ]]; then
	# Move all windows to main monitor
	for window in $(hyprctl clients -j | jq -r '.[].address'); do
		hyprctl dispatch movetoworkspacesilent 3, address:$window
	done
	sleep 0.3


	# Disble secondary monitors
	for monitor in "${secondary_monitors[@]}"; do
		print $monitor
		hyprctl keyword monitor "$monitor, disable"
	done
else
	# Enable all monitors
	for monitor in "${secondary_monitors[@]}"; do
		hyprctl keyword monitor "$monitor, enable"
	done
	sleep 0.3
	# Configure the correct Hz to monitors
	hyprctl reload

fi
