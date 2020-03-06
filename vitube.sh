#!/bin/bash

mkdir -p ~/.config/vitube

_draw_flag=true
_draw_jobs=(
	"__draw_background"
	"__draw_text"
)

__draw_background () { # Draw TUI background
	tput setb 0
	clear
	tput setb 7
	tput il 1
	tput cup "$(tput lines)" 0
	tput cuu1
	tput il 1
}

__draw_text () { # Draw TUI text
	local _help_text="q:Exit  j:Down  k:Up  r:Reload"
	local _status_text="--ViTube: "
	tput setf 0
	tput cup 0 0
	printf "%.*s" "$(tput cols)" "$_help_text"
	tput cup "$(tput lines)" 0
	tput cuu1
	printf "%.*s" "$(tput cols)" "$_status_text"
}

_draw () { # Execute all draw jobs
	for i in "${!_draw_jobs[@]}"; do
		${_draw_jobs[$i]};
	done
}

_main_loop () {
	local _command
	if $_draw_flag; then
		_draw
		_draw_flag=false
	fi
	read -rsn 1 _command
	if [ "$_command" = "q" ]; then 
		return 1
	fi
}

tput civis
while true; do _main_loop || break; done
tput reset
exit 0
