#!/bin/bash

declare -a _draw_jobs
_draw_jobs[0]="__draw_tui" 

__draw_tui () {
	tput setb 0
	clear
}

_draw () {
	for i in "${!_draw_jobs[@]}"; do
		${_draw_jobs[$i]};
	done
}


_draw_flag=true
while true; do
	if $_draw_flag; then
		_draw
		_draw_flag=false
	fi

	read -rsn 1 _command
	
	if [ "$_command" = "q" ]; then 
		break
	fi
done


tput reset
