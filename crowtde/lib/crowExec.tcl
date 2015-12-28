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

package provide crowExec 1.0
package require msgcat

namespace eval ::crowExec {
	variable tblScript
	array set tblScript ""
}

proc ::crowExec::recv {fd} {
	variable tblScript
	if {![eof $fd]} {
		if {[set data [read -nonewline $fd]] ne ""} {puts $data}
	} else {
		catch {close $fd}
		foreach {script} $tblScript($fd) {break}
		puts [::msgcat::mc "%s...Exit" [file tail $script]]
		unset tblScript($fd)
	}
}
proc ::crowExec::run_script {shell script} {
	variable tblScript
	if {![file exists $shell]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Interpreter '%s' not exists" $shell]
		return
	}

	set tmpfile [file join $::env(HOME) .CrowTDE tmpfile.crowExec.[pid]]
	set fd [open $tmpfile w]
	puts $fd [list info script $script]
	
	puts $fd [list lappend ::auto_path [file join $::env(HOME) .CrowTDE lib]]
	puts $fd [list lappend ::auto_path [file join $::crowTde::appPath lib]]
	puts $fd [list package require crowIO]

	puts $fd [list ::crowIO::init]
	puts $fd [format { 
				if {[catch [list source {%s}] ret]} {puts $errorInfo} 
	} $script]	
	close $fd
		
	puts [::msgcat::mc "Run %s..." [file tail $script]]
	set opwd [pwd]
	cd [file dirname $script]
	set fd [open [list | $shell $tmpfile] r+]
	set tblScript($fd) $script
	fconfigure $fd -blocking 0 -buffering none
	fileevent $fd readable [list ::crowExec::recv $fd] 
	cd $opwd
	after 5000 [list file delete $tmpfile]
	return
}

proc ::crowExec::stop_script {fd} {
	variable tblScript
	switch -exact -- $::tcl_platform(platform) {
		"unix" {
			catch {exec kill -9 [pid $fd]}
			# kill pid
		}
		"windows" {
			catch {::twapi::end_process [pid $fd] -force}
		}
		default {
			# others platform
		}
	}	
	
}

proc ::crowExec::run_ap {ap arglist} {
	set prog $ap
	if {$ap eq "EXEC"} {set prog [lindex $arglist 0]}
	if {![file executable $prog]} {
		set ans [tk_messageBox -icon warning \
			-message [::msgcat::mc "You may not permission to execuate this file! Execuate force?"] \
			-title [::msgcat::mc "Permission denied"] \
			-type "yesno"]
		if {$ans eq "no"} {return}
	}
	
	if {$ap eq "EXEC"} {
		set cmd "exec"
	} else {
		set cmd [list exec $ap]
	}		
	
	foreach arg $arglist {lappend cmd $arg}
	puts [format "Run %s %s" [file tail $ap] $arglist]
	lappend cmd &
	if {[catch {eval $cmd} ret]} {puts $ret}
	return
}
