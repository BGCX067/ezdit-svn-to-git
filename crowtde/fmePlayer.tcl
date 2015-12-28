##################################################################################
# Copyright (C) 2006-2007 Tai, Yuan-Liang                                        #
#                                                                                #
# This program is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by           #
# the Free Software Foundation; either version 2 of the License, or              #
# (at your option) any later version.                                            #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA   #
##################################################################################

namespace eval ::fmePlayer {
	variable sound
	array set sound [list dir "" state "stop" t0 0 t1 0 snd "" currFile ""]
	
	variable wInfo
	array set wInfo ""
	
	variable vars
	array set vars ""
}

proc ::fmePlayer::get_directory {} {
	variable sound
	return $sound(dir)
}

proc ::fmePlayer::get_frame {path} {
	variable wInfo
	variable vars
	
	set rc [file join $::env(HOME) ".CrowTDE" Player.rc]
	set ret [::crowRC::param_get $rc Player.IntiDirectory]
	
	if {$ret ne "" && [file exists $ret]} {::fmePlayer::set_directory $ret}
	
	set fmePlayer [frame $path -bd 2 -relief ridge]
	set btnPlay [button $fmePlayer.play -image [::crowImg::get_image run] -relief flat -command {::fmePlayer::play}]
	set btnPause [button $fmePlayer.pause -image [::crowImg::get_image pause] -relief flat -command {::fmePlayer::pause}]
	set btnStop [button $fmePlayer.stop -image [::crowImg::get_image stop] -relief flat -command {::fmePlayer::stop}]
	set sldBar [scale $fmePlayer.sldBar \
		-bd 1 \
		-highlightthickness 0 \
		-takefocus 0 \
		-relief flat \
		-sliderrelief flat \
		-sliderlength 6 \
		-orient h \
		-showvalue 0 -variable ::fmePlayer::vars(sldBar)]
	set btnSetting [button $fmePlayer.setting -image [::crowImg::get_image cfolder] -relief flat -command {::fmePlayer::set_directory ""}]
	set font10 [::crowFont::get_font smaller]
	set lblTitle [label $fmePlayer.title -textvariable ::fmePlayer::vars(title) \
		-font $font10 -relief groove \
		-wraplength 180 \
		-anchor w -justify left ]
	set lblGain [label $fmePlayer.gain -text [::msgcat::mc "Vol:"] -font $font10 -justify left -anchor w -relief groove]
	set sldGain [scale $lblGain.sldGain \
		-bd 1 \
		-length 145 \
		-from 0 -to 100	\
		-highlightthickness 0 \
		-takefocus 0 \
		-relief flat \
		-sliderrelief flat \
		-sliderlength 6 \
		-orient h \
		-showvalue 0 -variable ::fmePlayer::vars(sldGain) \
		-command {::fmePlayer::set_volume}]
	set vars(sldGain) [::snack::audio play_gain]
	pack $sldGain -side right
	
	grid $btnPlay -row 0 -column 0
	grid $btnPause -row 0 -column 1
	grid $btnStop -row 0 -column 2
	grid $sldBar -row 0 -column 3 -sticky "we"
	grid $btnSetting -row 0 -column 4
	grid $lblGain -row 1 -column 0 -columnspan 5 -sticky "we" -pady 2
	#grid $sldGain -row 1 -column 3 -columnspan 1 -sticky "we"
	grid $lblTitle -row 2 -column 0 -columnspan 5 -sticky "we" -pady 2
	
	grid rowconfigure $fmePlayer 0 -weight 1
	grid columnconfigure $fmePlayer 3 -weight 1
	
	set wInfo(sldBar) $sldBar
	set wInfo(sldGain) $sldGain
	set vars(title) [::msgcat::mc "MP3:"]
	foreach btn [list $btnPlay $btnPause $btnStop $btnSetting] {
		bind $btn <Enter> [list ::fmePlayer::mouse_enter %W]
		bind $btn <Leave> [list ::fmePlayer::mouse_leave %W]
	}
	bind $sldBar <ButtonPress-1> {::fmePlayer::sldBar_press}
	bind $sldBar <ButtonRelease-1> {::fmePlayer::sldBar_release}
	return $fmePlayer
}

proc ::fmePlayer::get_random {dpath} {
	set flist [glob -nocomplain -directory $dpath -types {f} -- "*.mp3" "*.MP3"]
	set flist [concat $flist [glob -nocomplain -directory $dpath -types {d} *]]
	if {[string trim $flist] eq ""} {return ""}
	set len [llength $flist]
	set idx [expr int(rand()*$len)]
	set item [lindex $flist $idx]
	if {[file isdirectory $item]} {return [::fmePlayer::get_random $item]}
	return $item
}

proc ::fmePlayer::mouse_leave {widget} {
	$widget configure -relief flat -bd 1
	return
}
 
proc ::fmePlayer::mouse_enter {widget} {
	$widget configure -relief raised -bd 1
	return
}



proc ::fmePlayer::pause {} {
	variable sound
	after cancel ::fmePlayer::timer
	if {$sound(state) ne "play"} {return}
	$sound(snd) pause
	set sound(state) "pause"	
	return
}

proc ::fmePlayer::play {} {
	variable vars
	variable wInfo
	variable sound
	if {![file exists $sound(dir)]} {set $sound(dir) [::fmePlayer::set_directory ""]}
	if {![file exists $sound(dir)]} {return}
	if {$sound(state) eq "pause"} {
		$sound(snd) play
		set sound(t0) [expr [clock scan now] - $sound(t1)]
		set sound(state) "play"
		::fmePlayer::timer
		return
	}
	if {$sound(state) eq "play"} {$sound(snd) stop}
	if {$sound(snd) eq ""} {
		set sound(snd) [snack::sound -buffersize [expr 1024*512]]
		snack::audio playLatency 1200
	}
	set sound(state) "stop"
	set cut 0
	set item ""
	while {$item eq ""} {
		set item [::fmePlayer::get_random $sound(dir)]
		incr cut
		if {$cut >5} {return}
	}
	if {![file exists $item]} {return}
	set sound(currFile) $item
	$sound(snd) configure -file $item
	set vars(title) [file tail $item]
	$sound(snd) play -start 0 -command {set ::fmePlayer::sound(state) "stop" ; after idle ::fmePlayer::play}
	set sound(t0) [clock scan now]
	set sinfo [$sound(snd) info]
	set start 0
	set end [$sound(snd) length -unit sec]
	$wInfo(sldBar) configure -from $start -to $end
	set vars(sldBar) 0
	set sound(state) "play"
	::fmePlayer::timer
}

proc ::fmePlayer::set_seek {pos} {
	variable sound
	variable vars	
	if {![snack::audio active]} {return}
	if {$sound(snd) eq "" || $sound(state) eq "stop"} {return}
	after cancel ::fmePlayer::timer
	set start [expr int($pos/[$sound(snd) length -unit sec]*[$sound(snd) length])]
	set sound(state) "stop"
	$sound(snd) stop
	$sound(snd) configure -file $sound(currFile)
	$sound(snd) play -start $start -command {set ::fmePlayer::sound(state) "stop" ; after idle ::fmePlayer::play}
	set sound(t0) [expr [clock scan now] - $pos]
	set sound(state) "play"
	::fmePlayer::timer
}

proc ::fmePlayer::set_directory {dpath} {
	variable sound
	if {$dpath eq ""} {
		set ret [tk_chooseDirectory -title [::msgcat::mc "MP3 Folder"] -mustexist 1]
		if {$ret eq "" || $ret eq "-1"} {return ""}
		set dpath $ret		
	}
	set sound(dir) $dpath
	set rc [file join $::env(HOME) ".CrowTDE" Player.rc]
	::crowRC::param_set $rc Player.IntiDirectory $dpath
	
	return $dpath
}

proc ::fmePlayer::set_volume {val} {
	variable vars
	::snack::audio play_gain $vars(sldGain)
	#::snack::mixer volume Vol  ::fmePlayer::vars(Vol)
	#::snack::mixer volume Pcm ::fmePlayer::vars(pcmL) ::fmePlayer::vars(pcmR)
	#set vars(pcmL) $val
	#set vars(pcmR) $val
	#set vars(Vol) $val
}

proc ::fmePlayer::sldBar_press {} {
	variable wInfo
	$wInfo(sldBar) configure -variable ""
}

proc ::fmePlayer::sldBar_release {} {
	variable vars	
	variable wInfo
	set pos [$wInfo(sldBar) get]
	if {$pos >= [$wInfo(sldBar) cget -to]} {set pos [expr [$wInfo(sldBar) cget -to]-1]}
	::fmePlayer::set_seek $pos
	$wInfo(sldBar) configure -variable ::fmePlayer::vars(sldBar)
}

proc ::fmePlayer::stop {} {
	variable sound
	variable vars
	after cancel ::fmePlayer::timer
	if {$sound(snd) ne ""} {$sound(snd) stop ; $sound(snd) destroy}
	set sound(snd) ""
	set sound(state) "stop"
	set vars(sldBar) 0
	return	
}

proc ::fmePlayer::timer {} {
	variable sound
	variable vars
	if {$sound(state) ne "play"} {return}
	if {![snack::audio active]} {return}
	set sound(t1) [expr [clock scan now] - $sound(t0)]
	set vars(sldBar) $sound(t1)
	after 500 ::fmePlayer::timer
	update
	return
}

