#!/bin/bash

CACHE_DIR=".cache/vitube"
_nav_page=0
_nav_position=0

bind '"\C-w": kill-whole-line'
bind '"\e": "\C-w\C-d"'

mkdir -p ~/.config/vitube
mkdir -p $CACHE_DIR

_draw_flag=true
_draw_jobs=(
	"__draw_background"
	"__draw_text"
    "__draw_subscriptions"
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
    if test -f ~/$CACHE_DIR/newvideos; then
        tput cup 1 0
        local _begin=$(( $_nav_page*($(tput lines)-3)+1 ))
        local _end=$(( $_begin + $(tput lines) - 4 ))
        local _lcount=0
        while read -r line; do
            tput setab 0
            tput setaf 7
            # Highligh selected item
            if test $_lcount -eq $_nav_position ;then
                tput setab 7
                tput setaf 0
            fi
            echo "$line" |
            gawk -v lname=$(tput cols) '{ printf "%.*s\n", lname, $1 }' FS='\t'
            let _lcount++
        done <<< "$(sed -n "$_begin,$_end p" ~/$CACHE_DIR/newvideos)"
        
        # Clear empty lines
        tput setab 0
        tput setaf 7
        while test $_lcount -ne $(( $(tput lines)-3 ));do
            tput el
            echo
            let _lcount++
        done
    fi
}

_draw () { # Execute all draw jobs
	for i in "${!_draw_jobs[@]}"; do
		${_draw_jobs[$i]};
	done
}

__fetch_new_videos () { # Web scraping videos from channel
    _cache_file_name=$(echo $1 | grep -oP '\w+$') 
    
    curl --silent "$1/videos" | 
    gawk 'match($0, /yt-lockup-title.+title="([^"]+)".*href="([^"]+)".*Duration: (.*\.)/, a) {print a[1] "\t" a[2] "\t" a[3]}' > ~/${CACHE_DIR}/${_cache_file_name}
    #fi
    
    rm -f ~/${CACHE_DIR}/newvideos
    # generate new videos file
    for filename in ~/${CACHE_DIR}/*; do
        head -3 $filename >> ~/${CACHE_DIR}/newvideos
    done
}

__fetch_subscriptions () { # Read subscriptions from file
    while IFS= read -r _line; do
        __fetch_new_videos $_line
    done < ~/.config/vitube/subscriptions
}

__clear_subscriptions () {
    tput cup 1 0
    tput setab 0
    tput setaf 7
    local _line=0
    while test $_line -ne $(( $(tput lines) - 3 )); do
        tput el
        echo
        let _line++
    done
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
            __clear_subscriptions
            __draw_subscriptions
            ;;
        "up")
            if test $_nav_position -eq 0; then
                if test $_nav_page -ne 0; then
                    let _nav_page--
                    _nav_position=$(( $(tput lines)-4))
                    __clear_subscriptions
                fi
            else
                let _nav_position--
            fi
            __draw_subscriptions
            ;;
        "down")
            if test $_nav_position -eq $(( $(tput lines)-4 )) ; then
                _nav_position=0
                let _nav_page++
                __clear_subscriptions
            else
                let _nav_position++
            fi
            __draw_subscriptions
            ;;
        "play")
            local _video=$(( $_nav_page*($(tput lines)-3) + $_nav_position + 1 ))
            
            local _url=$(sed "$_video q;d" ~/${CACHE_DIR}/newvideos | 
                gawk '{ print "https://youtube.com"$2 }' FS='\t')
            
            mpv $_url &> /dev/null &
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
        "j")
            __execute_command "down"  
            ;;
        "k")
            __execute_command "up"
            ;;
		"q")
			__execute_command "quit"
			;;
        "r")
            __execute_command "reload"
            ;;
        "")
            __execute_command "play"
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
