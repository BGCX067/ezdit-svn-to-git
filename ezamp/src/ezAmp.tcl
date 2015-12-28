#!/bin/sh
#\
exec wish "$0" ${1+"$@"}

# Copyright (C) 2009-2010 Tai, Yuan-Liang
#
#This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version. 
#
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. 
#
#You should have received a copy of the GNU General Public License along with this progra


namespace eval ::ezAmp {
	variable playList ""
	variable plIdx -1
	
	variable sInfo
	array set sInfo [list loop "noloop" state "STOP" snd "" file "" name "" tmpGain 50 gain 50 len 0 t0 0 t1 0 tE 0 tR 0]
	
	variable wInfo
	array set wInfo ""
	
	variable appPath ""
	
	variable rcDir ""
	
	variable os
}

proc ::ezAmp::argv_handler {args} {
	variable playList

	foreach item $args {
		if {[string range $item 0 6] == "file://"} {set item [string range $item 7 end]}
		if {![file exists $item]} {continue}
		if {[file isfile $item]} {
			if {[lsearch $playList $item] >= 0} {continue}
			set ext [string tolower [file extension $item]]
			if {[lsearch ".mp3 .wav" $ext] == -1} {return}
			lappend playList $item
			continue
		}
		if {[file isdirectory $item]} {
			::ezAmp::pl_add_dir_scan $item
			continue
		}		
	}
	
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save	
	
	return ""
}

proc ::ezAmp::dbus_init {} {
	if {[catch {package require dbus-tcl}]} {return	}
	dbus connect
		
	if {[llength $::argv] && ![catch {dbus call -dest org.got7.ezamp.dbus / org.got7.ezamp open {*}$::argv}]} {
		dbus close
		exit
	}
	
	dbus name -yield -replace org.got7.ezamp.dbus
	dbus filter add -interface org.got7.ezamp
	dbus method / open ::ezAmp::argv_handler
	
	return			
}

proc ::ezAmp::dde_init {} {
	package require dde
	if {[catch {[dde execute TclEval EzampService {_file_not_exists_}]}]} {
		dde servername -handler ::ezAmp::argv_handler EzampService
		return
	}
	if {[info exists ::argv] && $::argv != ""} {
		dde execute TclEval EzampService {*}$::argv
		exit
	}	
}

proc ::ezAmp::init {path} {
	variable appPath
	variable rcDir
	variable wInfo
	variable sInfo
	variable playList
	variable plIdx
	variable os
		
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	set appPath [file dirname $appPath]

	lappend ::auto_path [file join $appPath "lib"]

	set os [string tolower $::tcl_platform(os)]

	if {[string first "windows" $os] >= 0} {set os "windows"}	
	
	lappend ::auto_path [file join $appPath "lib_$os"]

	if {$os == "windows"} {::ezAmp::dde_init}
	if {$os == "linux"} {::ezAmp::dbus_init}

	set rcDir [file join $::env(HOME) .CrowAmp]
	if {![file exists $rcDir]} {file mkdir $rcDir}

	#if {$::tcl_version < 8.6} {package require img::png}
	
	package require crowImg
	package require snack
	package require tooltip
	package require autoscroll
	catch {package require img::png}
	
	if {![file exists [file join $rcDir logo.png]]} {
		file copy [file join $appPath "images" "logo.png"] [file join $rcDir logo.png]
	}
	
	::crowImg::init [file join $appPath "images"]
	
	set wInfo(dock,flag) 0
	if {$os == "windows"} {
		if {[catch {package require Winico}] == 0} {
			set wInfo(icon) [winico createfrom [file join $appPath "images" "ezamp.ico"]]
			winico taskbar add $wInfo(icon) -callback [list ::ezAmp::winico_cb %m] -text "ezAmp"
			source [file join $appPath lib theme.tcl]
			ttk::style theme use clam
			set wInfo(dock,flag) 1
		}
	}
	
	if {$os == "linux"} {
		if {![catch {package require tktray}]} {
			tktray::icon .dock \
			-image [::crowImg::get_image logo-24]
			set wInfo(dockwin) .dock
			set wInfo(dock,flag) 1
			.dock balloon "CrowAMP" 3
			bind .dock <Button-1> ::ezAmp::winico_toggle
			bind $wInfo(dockwin) <Enter> [list $wInfo(dockwin) balloon "CrowAMP Music Player" 1]
		}
		catch {snack::audio selectInput "/dev/dsp"}
	}

	wm iconphoto . [::crowImg::get_image logo]
	
	set sInfo(snd) [snack::sound -buffersize [expr 1024*512]]
	snack::audio playLatency 1200
	set sInfo(state) "STOP"	
	set sInfo(gain) [snack::audio play_gain]
	
	set sInfo(loop) [::ezAmp::snd_loop_get]
	
	set fmeMain [ttk::frame $path]
	
	set wInfo(lblName,var) "Music:"
	set wInfo(lblName) [ttk::label $fmeMain.lblName \
		-textvariable ::ezAmp::wInfo(lblName,var)]	
	
	#播放進度
	set fmePrg [ttk::frame $fmeMain.fmePrg -borderwidth 0 -relief ridge]

	set wInfo(sldBar) [ttk::scale $fmePrg.sldBar \
		-takefocus 0 \
		-orient h \
		-variable ::ezAmp::wInfo(sldBar,var)]
	
	pack $wInfo(sldBar) -fill x -padx 2 -side top
	bind $wInfo(sldBar) <ButtonPress-1> {set ::ezAmp::sInfo(state) "SEEK"}
	bind $wInfo(sldBar) <ButtonRelease-1> {::ezAmp::snd_seek}
	
	# 控制按鈕
	set fmeBtn [ttk::frame $fmeMain.fmeBtn]	
	foreach {btn tip} [list play "Play" prev "Previous" next "Next"] {
		pack [ttk::button $fmeBtn.$btn \
			-image [::crowImg::get_image $btn] \
			-command [list ::ezAmp::snd_$btn] \
			-style "Toolbutton"] -side left -padx 2
		::tooltip::tooltip $fmeBtn.$btn $tip
		set wInfo(btn[string totitle $btn]) $fmeBtn.$btn
	}

	set wInfo(btnLoop) [ttk::button $fmeBtn.loop \
		-image [::crowImg::get_image $sInfo(loop)] \
		-command [list ::ezAmp::snd_loop_toggle] \
		-style "Toolbutton"]
	::tooltip::tooltip $wInfo(btnLoop) "Loop"
	pack $wInfo(btnLoop) -side left -padx 2

	pack [ttk::scale $fmeBtn.sldGain \
		-from 0 \
		-variable ::ezAmp::sInfo(gain) \
		-to 100 \
		-takefocus 0 \
		-orient horizontal \
		-command {::ezAmp::vol_set}]		 -side right

	pack [ttk::button $fmeBtn.btnSound \
		-image [::crowImg::get_image sound] \
		-command [list ::ezAmp::vol_zero] \
		-style "Toolbutton"] -side right -padx 2
	::tooltip::tooltip $fmeBtn.btnSound "Silence"

	set wInfo(btnSound) $fmeBtn.btnSound

	# 播放清單
	set fmeList [ttk::frame $fmeMain.fmeList -borderwidth 2  -relief groove]
	set wInfo(lst) [listbox $fmeList.pl \
		-highlightthickness 0 \
		-bd 0 \
		-relief flat \
		-selectbackground "#c0c0c0" \
		-foreground "#505050" \
		-listvariable ::ezAmp::wInfo(lst,var)]
	set vs [ttk::scrollbar $fmeList.vs -command [list $wInfo(lst) yview] -orient vertical]
	set hs [ttk::scrollbar $fmeList.hs -command [list $wInfo(lst) xview] -orient horizontal]
	$wInfo(lst) configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
	::autoscroll::autoscroll $vs
	::autoscroll::autoscroll $hs	
	grid $fmeList.pl $vs -sticky "news"
	grid $hs - -sticky "we"
	grid rowconfigure $fmeList 0 -weight 1
	grid columnconfigure $fmeList 0 -weight 1
	
	bind $wInfo(lst) <Double-Button-1> [list ::ezAmp::pl_dclick]
	bind $wInfo(lst) <Delete> [list ::ezAmp::pl_del]
	bind $wInfo(lst) <Button-3> {::ezAmp::pl_menu_popup %x %y %X %Y}
	bind $wInfo(lst) <Visibility> {
		%W selection clear 0 end
		%W selection set $::ezAmp::plIdx	
	}
	
	#清單控制
	set fmeBtn2 [ttk::frame $fmeMain.fmeBtn2]
	pack [ttk::button $fmeBtn2.btnAddFile \
		-image [::crowImg::get_image add] \
		-command [list ::ezAmp::pl_add_dir] \
		-style "Toolbutton"] -side left	-padx 2 -pady 2
	::tooltip::tooltip $fmeBtn2.btnAddFile "Left-Click:Add Folder\nRight-Click:Add File"
	bind $fmeBtn2.btnAddFile <Button-3> {::ezAmp::pl_add_file}
	
	pack [ttk::button $fmeBtn2.btnDelFile \
		-image [::crowImg::get_image del] \
		-command [list ::ezAmp::pl_del] \
		-style "Toolbutton"] -side left	-padx 2 -pady 2
	::tooltip::tooltip $fmeBtn2.btnDelFile "Left-Click:Delete Item\nRight-Click:Clear Playlist"
	bind $fmeBtn2.btnDelFile <Button-3> {::ezAmp::pl_clear}	

	set wInfo(var,time) -1
	set wInfo(var,message) "00:00:00"
	
	pack [ttk::button $fmeBtn2.btnAddTime \
		-image [::crowImg::get_image time] \
		-style "Toolbutton" -command [namespace code {
				if {$wInfo(var,time) == -1} {set wInfo(var,time) [clock scan now]}
				set wInfo(var,time) [clock add $wInfo(var,time) 10 minute]	
		}]] -side right -padx 2 -pady 2
	::tooltip::tooltip $fmeBtn2.btnAddTime "Left-Click:+10 Minute\nRight-Click:-10 Minute"

	bind $fmeBtn2.btnAddTime <Button-3> {
		namespace eval ::ezAmp {
			variable wInfo
			if {$wInfo(var,time) != -1} {
				set wInfo(var,time) [clock add $wInfo(var,time) -10 minute]
				if {$wInfo(var,time) <= [clock scan now]} {set wInfo(var,time) -1}
			}
		}		
	}

	pack [ttk::label $fmeBtn2.lblAddTime \
		-textvariable ::ezAmp::wInfo(var,message)] -side right  -padx 2 -pady 2
	
	
	grid $wInfo(lblName)  -sticky "we" -pady 2 -padx 2		
	grid $fmeBtn  -sticky "we" -pady 2 -padx 2
	grid $fmePrg  -sticky "we"  -pady 2
	grid $fmeList  -sticky "news" -padx 2
	grid $fmeBtn2  -sticky "we" -padx 2

	grid columnconfigure $fmeMain 0 -weight 1
	grid rowconfigure $fmeMain 3 -weight 1
	
	::ezAmp::pl_lbox_load
	::ezAmp::snd_timer_start
	
	update
	#setup  tkdnd : linux
	if {$os == "linux" && ![catch {package require tkdnd 1.0}]} {
		package require uri::urn
		dnd bindtarget $wInfo(lst) "text/uri-list" <Drop> {
			set items [list]
			set args %D
			foreach item $args {
				 set item [uri::urn::unquote $item]
				 if {$::ezAmp::os == "linux"} {
					 set item [encoding convertfrom [encoding system] $item]
				}
				 lappend items $item
			}
			::ezAmp::argv_handler {*}$items
		}
	}
	
	if {$os == "windows" && ![catch {package require tkdnd 2.2}]} {
		tkdnd::drop_target register $wInfo(lst) "DND_Files"
		bind $wInfo(lst) <<Drop:DND_Files>> {catch {foreach item %D {::ezAmp::argv_handler $item}}}
	}
	
	wm protocol . WM_DELETE_WINDOW {
		catch {::ezAmp::snd_stop}
		catch {$::ezAmp::sInfo(snd) destroy}
		if {[info commands dbus] != ""} {catch {dbus close}}
		catch {destroy .dock}
		if {[info exists ::ezAmp::wInfo(icon)]} {catch {winico taskbar delete $::ezAmp::wInfo(icon)}}
		
		exit
	}
	
	return $fmeMain
}

proc ::ezAmp::initdir_get {} {
	variable rcDir
	set rc [file join $rcDir initdir]
	set dpath ""
	if {[file exists $rc]} {
		set fd [open $rc r]
		set dpath [read -nonewline $fd]
		close $fd
	}
	if {![file exists $dpath]} {set dpath ""}
	return $dpath
}

proc ::ezAmp::initdir_set {dpath} {
	variable rcDir
	set rc [file join $rcDir initdir]
	set fd [open $rc w]
	puts $fd $dpath
	close $fd
}

proc ::ezAmp::pl_add_dir {} {
	variable playList
	set initDir $::env(HOME)
	set ret [::ezAmp::initdir_get]
	if {$ret ne ""} {set initDir $ret}

	set dpath [tk_chooseDirectory -initialdir $initDir -title [::msgcat::mc "Add directory"] ]
	if {$dpath eq "" || $dpath == -1 } {return}
	::ezAmp::initdir_set $dpath
	::ezAmp::pl_add_dir_scan $dpath
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save
	return	
}

proc ::ezAmp::pl_add_dir_scan {dpath} {
	variable playList

	set flist [glob -nocomplain -directory $dpath -types {f} "*.mp3" "*.ogg" "*.wav" "*.MP3" "*.OGG" "*.WAV"]
	foreach f $flist {
		if {[lsearch $playList $f] >= 0} {continue}
		lappend playList $f
	}
	set dlist [glob -nocomplain -directory $dpath -types {d} *]
	foreach d $dlist {
		::ezAmp::pl_add_dir_scan $d
	}
	return
}

proc ::ezAmp::pl_add_file {} {
	variable playList
	
	set initDir $::env(HOME)
	set ret [::ezAmp::initdir_get]
	if {[file exists $ret]} {set initDir $ret}
	
	set types [list [list "MP3" {.mp3 .MP3}] [list "WAV" {.wav .WAV}] [list "ALL Files" *]]
	set items [tk_getOpenFile -initialdir $initDir -multiple 1 \
		-filetypes $types\
		-title [::msgcat::mc "Add file"] ]
	if {$items eq "" || $items == -1 } {return}
	 
	foreach item $items {
		if {[lsearch $playList $item] >= 0} {continue}
		lappend playList $item
	}
	
	::ezAmp::initdir_set [file dirname [lindex $items 0]]
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save
	return
}

proc ::ezAmp::pl_add_item {item} {
	variable playList

	set flag 0

	set item [string trim $item "{}"]
	set extName [string tolower [file extension $item]]
	if {[file exists $item]} {
		if {[file type $item] eq "file" && ($extName eq ".mp3" || $extName eq ".wav" || $extName eq ".ogg")} {
			lappend playList $item
			set flag 1
		} elseif {[file type $item] eq "directory"} {
			::ezAmp::pl_add_dir_scan $item
			set flag 1
		}
	}
	if {$flag} {
		::ezAmp::pl_lbox_update
		::ezAmp::pl_lbox_save
	}
}

proc ::ezAmp::pl_clear {} {
	variable playList

	set playList ""
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save
	return
}

proc ::ezAmp::pl_dclick {} {
	variable playList
	variable plIdx
	variable sInfo
	variable wInfo
	
	set lst $wInfo(lst)
	set idx [$lst curselection]

	if {$idx eq ""} {return}
	
	set f [lindex $playList $idx]
	if {![file exists $f]} {
		$lst delete $idx
		::ezAmp::pl_lbox_update
		::ezAmp::pl_lbox_save	
		return
	}
	set plIdx $idx
	set sInfo(file) $f
	::ezAmp::snd_start
	
	
	return
}

proc ::ezAmp::pl_del {} {
	variable playList
	variable wInfo
	
	set lst $wInfo(lst)
	foreach item [$lst curselection] {
		$lst delete $item
		set i 0
		set tmp $playList
		set playList [list]
		foreach t $tmp {
			if {$i == $item} {incr i ; continue}
			incr i
			lappend playList $t
			
		}
	}
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save		
	return
}

proc ::ezAmp::pl_lbox_load {} {
	variable playList
	variable rcDir
	
	set rc [file join $rcDir playlist]
	if {[file exists $rc]} {
		set playList ""
		set fd [open $rc r]
		set items [split [read -nonewline $fd] "\n"]
		close $fd
		foreach item $items {
			lappend playList $item
		}
		::ezAmp::pl_lbox_update
	}
	return
}

proc ::ezAmp::pl_menu_popup {x y X Y} {
	variable wInfo
	variable playList
	if {$playList eq ""} {return}
	
	set idx [$wInfo(lst) curselection]
	
	set f ""
	set state "normal"
	if {$idx == ""} {
		set state "disabled"
	} else {
		append f " (" [file tail [lindex $playList $idx]] ")"
	}

	set m $wInfo(lst).m
	if {[winfo exists $m]} {destroy $m}
	menu $m -tearoff 0

	$m add command -label [::msgcat::mc "Randomize"] \
		-command [list ::ezAmp::pl_random]	

	tk_popup $m $X $Y

}

proc ::ezAmp::pl_lbox_update {} {
	variable playList
	variable wInfo
	variable sInfo
	
	set wInfo(lst,var) ""

	foreach item $playList {
		lappend wInfo(lst,var) [file tail $item]
	}
	
	set len [$wInfo(lst) size]
	for {set i 0} {$i < $len} {incr i} {
		set fg "#505050"
		set f [lindex $playList $i]
		if {![file exists $f]} {set fg "#A0A0A0"}
		if {$f == $sInfo(file)} {set fg "#0069d2"}
		$wInfo(lst) itemconfigure $i -foreground $fg
	}	
	
	return
}

proc ::ezAmp::pl_lbox_save {} {
	variable playList
	variable rcDir
	
	set rc [file join $rcDir playlist]
	set fd [open $rc w]
	foreach item $playList {
		puts $fd $item
	}
	close $fd
	return
}

proc ::ezAmp::pl_random {} {
	variable playList
	
	set times [llength $playList]
	if {$times <= 1} {return}
	
	for {set i 0 } {$i < $times} {incr i} {
		set idx [expr int(rand()*$times)]
		set item [lindex $playList $idx]
		
		set idx2 0
		if {[expr rand()] >= 0.5} {
			set idx2 end
		}
		set item2 [lindex $playList $idx2]
		
		lset playList $idx $item2
		lset playList $idx2 $item
	}
	::ezAmp::pl_lbox_update
	::ezAmp::pl_lbox_save
	return
}

proc ::ezAmp::snd_end {} {
	variable sInfo
	variable wInfo
	variable plIdx
	variable playList
	
	#after cancel ::ezAmp::snd_timer_start
	$sInfo(snd) stop
	$wInfo(btnPlay) configure -image [::crowImg::get_image play] 
	set sInfo(state) "STOP"
	set wInfo(lblTE,var) "00:00"
	set wInfo(sldBar,var) 0

	if {$sInfo(loop) == "oneloop"} {
		::ezAmp::snd_start
		return
	}
	
	if {$plIdx >= [expr [llength $playList]-1] && $sInfo(loop) == "noloop"} {
		set wInfo(lblName,var) "Music:"
		return
	}	

	after idle ::ezAmp::snd_next
	return
}

proc ::ezAmp::snd_loop_get {} {
	variable sInfo
	variable rcDir
	
	set rc [file join $rcDir "loop"]
	if {![file exists $rc]} {return "noloop"}
	set fd [open $rc r]
	set data [string trim [read $fd]]
	close $fd
	if {$data == ""} {set data "noloop"}
	return $data
}

proc ::ezAmp::snd_loop_set {state} {
	variable sInfo
	variable rcDir
	
	set rc [file join $rcDir "loop"]
	set fd [open $rc w]
	puts -nonewline $fd $state
	close $fd
	return $state
}

proc ::ezAmp::snd_loop_toggle {} {
	variable sInfo
	variable rcDir
	variable wInfo
	
	set rc [file join $rcDir "loop"]
	if {![file exists $rc]} {::ezAmp::snd_loop_set "noloop"}
	
	if {$sInfo(loop) == "noloop"} {
		set sInfo(loop) "oneloop"
	} elseif {$sInfo(loop) == "oneloop"} {
		set sInfo(loop) "allloop"
	} else {
		set sInfo(loop) "noloop"
	}
	::ezAmp::snd_loop_set $sInfo(loop)
	$wInfo(btnLoop) configure -image [::crowImg::get_image $sInfo(loop)]	
}

proc ::ezAmp::snd_next {} {
	variable plIdx
	variable playList
	variable sInfo	
	variable wInfo
	
	if {$sInfo(snd) eq "" || [llength $playList] == 0} {return}
	
	
	incr plIdx
	if {$plIdx >= [llength $playList]} {set plIdx 0}
	set sInfo(file) [lindex $playList $plIdx]	
	
	while {[::ezAmp::snd_start] == 0} {
		incr plIdx
		if {$plIdx >= [llength $playList]} {
			set plIdx 0 
			$wInfo(btnPlay) configure -image [::crowImg::get_image play]
			break
		}
		set sInfo(file) [lindex $playList $plIdx]
	}
	
	return
}

proc ::ezAmp::snd_play {} {
	variable sInfo
	variable wInfo
	variable plIdx
	variable playList
	
	if {$sInfo(state) == "PLAY"} {
		set sInfo(state) "PAUSE"
		$sInfo(snd) pause
		$wInfo(btnPlay) configure -image [::crowImg::get_image play]
		return
	}
	
	if {$sInfo(state) == "PAUSE"} {
		set sInfo(state) "PLAY"
		$sInfo(snd) play
		$wInfo(lst) selection clear 0 end
		$wInfo(lst) selection set $plIdx		
		$wInfo(btnPlay) configure -image [::crowImg::get_image pause] 
		#::ezAmp::snd_timer_start
		return
	}
	
	if {$playList eq ""} {
		::ezAmp::pl_add_file
		set sInfo(file) [lindex $playList 0]
		set plIdx 0
	}
	
	if {$sInfo(file) eq "" || ![file exists $sInfo(file)]} {
		set idx 0
		foreach item $playList {
			if {[file exists $item]} {
				set sInfo(file) $item
				set plIdx $idx
				break
			}
			incr idx
		}
	}
	
	::ezAmp::snd_start
	return
}

proc ::ezAmp::snd_prev {} {
	variable plIdx
	variable playList
	variable sInfo	
	variable wInfo
	
	if {$sInfo(snd) eq "" || [llength $playList] == 0} {return}
	
	incr plIdx -1
	if {$plIdx < 0} {set plIdx [expr [llength $playList]-1]}
	set sInfo(file) [lindex $playList $plIdx]	
	if {$sInfo(file) eq "" || ![file exists $sInfo(file)]} {return}
	
	::ezAmp::snd_start
	return
}

proc ::ezAmp::snd_seek {} {
	variable wInfo
	variable sInfo 
	variable vars	
		
	if {![snack::audio active]} {
		set wInfo(sldBar,var) 0
		set sInfo(state) "STOP"
		return
	}

	set val [$wInfo(sldBar) get]
	set start [expr int( $val / $sInfo(len) * [$sInfo(snd) length] )]

	$sInfo(snd) stop
	$sInfo(snd) play -start $start -command {after 1500 ::ezAmp::snd_end}
	$wInfo(btnPlay) configure -image [::crowImg::get_image pause] 
	
	set sInfo(t0) $val
	
	$wInfo(sldBar) configure -variable ::ezAmp::wInfo(sldBar,var)
	
	set sInfo(state) "PLAY"
	return
}

proc ::ezAmp::snd_start {} {
	variable sInfo
	variable wInfo
	variable plIdx
	variable playList
	
	if {$sInfo(file) eq "" || ![file exists $sInfo(file)]} {return 0}
	
	::ezAmp::snd_stop
	$sInfo(snd) configure -file $sInfo(file) -rate [expr 44*1024]
	
	set sInfo(len) [$sInfo(snd) length -unit sec]
	set sInfo(name) [file tail $sInfo(file)]
	set sInfo(t0) 0
	set sInfo(t1) 0
	
	set sInfo(state) "PLAY"
	$sInfo(snd) play -command {after 1500 ::ezAmp::snd_end}
	$wInfo(btnPlay) configure -image [::crowImg::get_image pause]
	
	$wInfo(sldBar) configure -from 0 -to $sInfo(len)
	$wInfo(lst) selection clear 0 end
	$wInfo(lst) selection set $plIdx
	
	set len [$wInfo(lst) size]
	if {$plIdx >= $len } {set plIdx 0}
	for {set i 0} {$i < $len} {incr i} {
		set fg "#505050"
		set f [lindex $playList $i]
		if {![file exists $f]} {set fg "#A0A0A0"}
		$wInfo(lst) itemconfigure $i -foreground $fg
	}
	if {$plIdx < $len} {	$wInfo(lst) itemconfigure $plIdx -foreground #0069d2  }
	 
	
	return 1
}

proc ::ezAmp::snd_stop {} {
	variable sInfo
	variable wInfo
	
	$wInfo(btnPlay) configure -image [::crowImg::get_image play]
	if {$sInfo(state) eq "STOP"} {return}
	
	set sInfo(state) "STOP"
	$sInfo(snd) stop
	
	set sInfo(t0) 0
	set sInfo(t0) 0
	set wInfo(sldBar,var) 0
	set wInfo(lblTE,var) "00:00"
	
	return
}

proc ::ezAmp::snd_timer_start {} {
	variable sInfo
	variable wInfo
	variable os
	
	if {$wInfo(dock,flag) == 1 && [wm state .] == "iconic"} {wm withdraw .}
	
	if {$wInfo(var,time) == -1} {
		set wInfo(var,message) "00:00:00"
	} else {
		set now [clock scan now]

		if {$wInfo(var,time) >= $now} {
			set t1970 [clock scan "1977" -format "%Y"]
			set re [clock add [expr $t1970 + ($wInfo(var,time) - $now)]]
			set wInfo(var,message) [clock format $re -format "%H:%M:%S" ]
		} else {
			::ezAmp::snd_stop
			::ezAmp::vol_set 0
			if {$os == "windows"} {		exec shutdown -s -f }
			if {$os == "linux"} {exec shutdown -h now}
			if {$os == "darwin"} {}
			exit
		}		
	}

	if {![snack::audio active] || $sInfo(state) != "PLAY"} {
		after 250 ::ezAmp::snd_timer_start
		return
	}
	
	set sInfo(t1) [expr int([snack::audio elapsedTime])]
	set sInfo(tE) [expr int($sInfo(t1) + $sInfo(t0))] 
	set wInfo(lblTE,var) [clock format $sInfo(tE) -format "%M:%S"]
	set wInfo(sldBar,var) $sInfo(tE)
	set sInfo(tR) [expr int([expr $sInfo(len) - $sInfo(tE)])]
	
	set wInfo(lblName,var) "Music: $sInfo(name) ($wInfo(lblTE,var))"
	
	after 250 ::ezAmp::snd_timer_start
	update
	return	
}

proc ::ezAmp::vol_zero {} {
	variable wInfo
	variable sInfo

	set icon [::crowImg::get_image sound]
	set icon2 [$wInfo(btnSound) cget -image]
	if {$icon2 == $icon} {
		$wInfo(btnSound) configure -image [::crowImg::get_image nosound]
		set sInfo(tmpGain) [::snack::audio play_gain]
		::snack::audio play_gain 0
	} else {
		$wInfo(btnSound) configure -image [::crowImg::get_image sound]
		::snack::audio play_gain $sInfo(tmpGain) 
	}
}

proc ::ezAmp::vol_incr {} {
	variable sInfo
	set sInfo(gain)  [::snack::audio play_gain]
	incr sInfo(gain) 3
	::snack::audio play_gain $sInfo(gain)
}

proc ::ezAmp::vol_desc {} {
	variable sInfo
	set sInfo(gain)  [::snack::audio play_gain]
	incr sInfo(gain) -3
	::snack::audio play_gain $sInfo(gain)
}

proc ::ezAmp::vol_set {val} {
	variable sInfo
	set sInfo(gain)  [expr int($val)]
	::snack::audio play_gain $sInfo(gain)
}



proc ::ezAmp::winico_cb {btn} {
	variable wInfo
	
	if {$btn == "WM_MOUSEMOVE"} {
		winico taskbar modify $wInfo(icon) -text "Shutdown : $wInfo(var,message)" 
	}
	
	if {$btn != "WM_LBUTTONDOWN"} {return}
	
	::ezAmp::winico_toggle
}

proc ::ezAmp::winico_toggle {} {
	if {[wm state .] == "withdrawn"} {
		wm state . normal
	} else {
		wm state . withdrawn
	}
}

package require Tk

pack [::ezAmp::init .iplayer] -expand 1 -fill both

font configure TkDefaultFont -size 12

wm geometry . 400x300
wm title . "CrowAMP v2.2 (http://got7.org)"

::ezAmp::argv_handler {*}$::argv
