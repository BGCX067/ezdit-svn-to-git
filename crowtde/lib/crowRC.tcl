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

package provide crowRC 1.0

namespace eval ::crowRC {
}

proc ::crowRC::create {rcPath} {
	if {![file exists $rcPath]} {
		if {[catch {close [open $rcPath w]}]} {
			tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
				-message $rcPath[::msgcat::mc "Create fail!"]
			return
		}
	}
	return $rcPath
}

proc ::crowRC::param_save {rcPath buf} {
	#if {![file exists $rcPath]} {return}
	upvar $buf data
	set fd [open $rcPath w]
	foreach {key val} [array get data] {
		puts $fd "${key}:${val}"
	}
	close $fd
	return
}

proc ::crowRC::param_del {rcPath name} {
	if {![file exists $rcPath]} {return}
	array set buf ""
	::crowRC::param_get_all $rcPath buf
	array unset buf $name
	::crowRC::param_save $rcPath buf
	return
}

proc ::crowRC::param_get {rcPath name} {
	if {![file exists $rcPath]} {return}
	set ret ""
	set inBuf ""
	set fd [open $rcPath r]
	gets $fd inBuf
	while {![eof $fd]} {
		set idx [string first ":" $inBuf]
		if {$idx > 0} {
			set key [string range $inBuf 0 [expr $idx -1]]
			if {$key eq $name} {
				set val [string range $inBuf [expr $idx +1] end]
				if {$ret ne ""} {
					lappend ret $val
				} else {
					set ret $val
				}
			}
		}
		gets $fd inBuf
	}
	close $fd
	return $ret
}

proc ::crowRC::param_get_all {rcPath buf} {
	if {![file exists $rcPath]} {return}
	upvar $buf ret
	set inBuf ""
	set fd [open $rcPath r]
	gets $fd inBuf
	while {![eof $fd]} {
		set idx [string first ":" $inBuf]
		if {$idx > 0} {
			set key [string range $inBuf 0 [expr $idx -1]]
			set val [string range $inBuf [expr $idx +1] end]
			if {[info exists ret($key)]} {
				lappend ret($key) $val
			} else {
				set ret($key) $val
			}
		}
		gets $fd inBuf
	}
	close $fd
	return
}

proc ::crowRC::param_set {rcPath name val} {
	#if {![file exists $rcPath]} {return}
	array set buf ""
	::crowRC::param_get_all $rcPath buf
	array set buf [list $name $val]
	::crowRC::param_save $rcPath buf
	return	
}

