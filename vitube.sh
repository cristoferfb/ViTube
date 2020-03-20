#!/bin/bash

CACHE_DIR=".cache/vitube"


bind '"\C-w": kill-whole-line'
bind '"\e": "\C-w\C-d"'

mkdir -p ~/.config/vitube
mkdir -p $CACHE_DIR

_draw_flag=true
_draw_jobs=(
	"__draw_background"
	"__draw_text"
)

__draw_background () { # Draw TUI background
	tput setab 0
	clear
	tput setab 7
	tput il 1
	tput cup "$(tput lines)" 0
	tput cuu1
	tput il 1
}

__draw_text () { # Draw TUI text
	local _help_text="q:Exit  j:Down  k:Up  r:Reload"
	local _status_text="--ViTube: "
	tput setaf 0
	tput cup 0 0
	printf "%.*s" "$(tput cols)" "$_help_text"
	tput cup "$(tput lines)" 0
	tput cuu1
	printf "%.*s" "$(tput cols)" "$_status_text"
}

__draw_subscriptions () {
   : 
}

_draw () { # Execute all draw jobs
	for i in "${!_draw_jobs[@]}"; do
		${_draw_jobs[$i]};
	done
}

__fetch_new_videos () { # Web scraping videos from channel
    _cache_file_name=$(echo $1 | grep -oP '\w+$') 
    
    if [ -f "~/${CACHE_DIR}/${_cache_file_name}" ]; then
        _last_video=$(head -n 1 "~/${CACHE_DIR}/$_cache_file_name") 
        #TODO only load new videos
    else
        curl --silent $1 | 
        gawk 'match($0, /yt-lockup-title.+title="([^"]+)".*href="([^"]+)".*Duration: (.*\.)/, a) {print "\"" a[1] "\"\t\"" a[2] "\"\t\"" a[3] "\""}' > ~/${CACHE_DIR}/${_cache_file_name}
    fi
}

__fetch_subscriptions () { # Read subscriptions from file
    while IFS= read -r _line; do
        __fetch_new_videos $_line
        #$(curl --silent $_line | grep yt-lockup-title) $_line
    done < ~/.config/vitube/subscriptions
}
__execute_command () {
	case "$1" in
		"add")
			echo "$2" >> ~/.config/vitube/subscriptions
			;;	
		"quit")
			tput reset
			exit 0
		    ;;
		"reload")
            __fetch_subscriptions
			;;
	esac
}

__command_mode () {
	local _command
	local _arg
	tput cup "$(tput lines)" 0
	tput setb 0
	tput setf 7
	read -erp ':' _command _arg
	_draw # TODO avoid to redraw all TUI after read
	__execute_command "$_command" "$_arg"
}

__read_key () {
	case "$1" in
		"q")
			__execute_command "quit"
			;;
        "r")
            __execute_command "reload"
            ;;
		":")
			__command_mode
			;;
	esac
}

_main_loop () {
	local _key
	if $_draw_flag; then
		_draw
		_draw_flag=false
	fi
	read -rsn 1 _key
	__read_key "$_key"
}

tput civis
while true; do _main_loop; done
