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

package provide crowRecently 1.0

namespace eval ::crowRecently {
	variable rcPath ""
	variable rcSize 12	
}

proc ::crowRecently::init {} {
	variable rcPath
	set rcPath [file join $::env(HOME) ".CrowTDE" "Recently.rc"]
}

proc ::crowRecently::get_recently_projects {} {
	array set arrRecently [::crowRecently::read_rc]
	return $arrRecently(project)
}

proc ::crowRecently::get_recently_files {} {
	array set arrRecently [::crowRecently::read_rc]
	return $arrRecently(file)	
}

proc ::crowRecently::push_project {ppath} {
	variable rcSize
	array set arrRecently [::crowRecently::read_rc]
	if {$ppath eq [lindex $arrRecently(project) 0]} {return}
	set arrRecently(project) [lrange [linsert $arrRecently(project) 0 $ppath] 0 [expr $rcSize-1]]
	::crowRecently::save_rc [array get arrRecently]
}

proc ::crowRecently::push_file {fpath} {
	variable rcSize
	array set arrRecently [::crowRecently::read_rc]
	if {$fpath eq [lindex $arrRecently(file) 0]} {return}
	set arrRecently(file) [lrange [linsert $arrRecently(file) 0 $fpath] 0 [expr $rcSize-1]]
	::crowRecently::save_rc [array get arrRecently]	
}

proc ::crowRecently::read_rc {} {
	variable rcPath
	
	array set arrRecently [list project "" file ""]
	if {![file exists $rcPath]} {return [array get arrRecently]}
	set inBuf ""
	set fd [open $rcPath "r"]
	gets $fd inBuf
	while {![eof $fd]} {
		set idx [string first ":" $inBuf]
		if {$idx <0} {continue}
		set key [string range $inBuf 0 [expr $idx-1]]
		set val [string range $inBuf [expr $idx+1] end]
		if {[file exists $val]} {lappend arrRecently($key) $val}
		gets $fd inBuf
	}
	close $fd
	return [array get arrRecently]
}

proc ::crowRecently::save_rc {recently} {
	variable rcPath
	array set arrRecently $recently
	set fd [open $rcPath "w"]
	foreach item $arrRecently(project) {
		if {[file exists $item]} {puts $fd "project:$item"}
	}
	foreach item $arrRecently(file) {
		if {[file exists $item]} {puts $fd "file:$item"}
	}	
	close $fd
}

::crowRecently::init

