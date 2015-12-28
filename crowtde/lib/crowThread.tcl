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

package provide crowThread 1.0
package require msgcat
package require Thread

namespace eval ::crowThread {
	variable appPath
	variable threadList ""
	variable masterThread [::thread::id]
}

proc ::crowThread::init {appPath} {
	set ::crowThread::appPath $appPath	
}

proc ::crowThread::create {} {
	variable threadList
	set tid [::thread::create -preserved]
	lappend threadList $tid
	return $tid
}

proc ::crowThread::run_script {shell script headHook bottomHook} {
	if {![file exists $shell]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Interpreter '%s' not exists" $shell]
		return
	}
	set tid [::crowThread::create]
	::thread::send $tid [list set ::crowTdeThread(parentId) [::thread::id]]
	::thread::send $tid [list set ::crowTdeThread(targetScriptPath) $script]	
	set fd [open $script r]
	::thread::send $tid [list set ::crowTdeThread(targetScript) [read $fd]]
	close $fd
	
	set fd [open [file join $::crowThread::appPath lib crowIO.tcl] r]
	::thread::send $tid [list set ::crowTdeThread(crowIOScript) [read $fd]]
	close $fd
	
	::thread::send $tid [list set ::crowTdeThread(shell) $shell]
	::thread::send $tid [list set ::crowTdeThread(appPath) $::crowThread::appPath]
	::thread::send $tid [list set ::crowTdeThread(headHook) $headHook]
	::thread::send $tid [list set ::crowTdeThread(bottomHook) $bottomHook]
	
	set msg [::msgcat::mc "Run %s ..." [file tail $script]]
	::thread::send $tid [list set ::crowTdeThread(headMsg) $msg]
	set msg  [::msgcat::mc "%s Finish" [file tail $script]]
	::thread::send $tid [list set ::crowTdeThread(bottomMsg) $msg]
	set bootCode {
		::thread::send $::crowTdeThread(parentId) [list puts $::crowTdeThread(headMsg)]
		# <!-- 
		# set fd [open [list | crxvt -e $::shellName] r+]
		# close $fd
		# -->
		set fd [open "| $::crowTdeThread(shell)" r+]
		fconfigure $fd -buffering none ;#-translation binary
		puts $fd $::crowTdeThread(crowIOScript)
		puts $fd "::crowIO::init"
		if {$::crowTdeThread(headHook) ne ""} {	puts $fd $::crowTdeThread(headHook)}
		puts $fd [list cd [file dirname $::crowTdeThread(targetScriptPath)]]
		puts $fd [list info script $::crowTdeThread(targetScriptPath)]
		puts $fd [list set ::crowtde_run_script_codes $::crowTdeThread(targetScript)]		
		set bodyHook "
			     if {\[catch {eval \$::crowtde_run_script_codes} msgErr]} {
				set ret \[lrange \[split \$errorInfo \\n] 0 end-2]
				foreach l \$ret {puts \$l}
			     }
			     if {\[info exists ::tk_library]} {catch {tkwait window .}}
			     exit
			  "
			  
		puts $fd $bodyHook
		flush $fd
		if {$::crowTdeThread(bottomHook) ne ""} {puts $fd $::crowTdeThread(bottomHook)}
		#::thread::send $::crowTdeThread(parentId) [list puts "loop start"]
		while {[catch {gets $fd msg} ret] == 0} {
			if {$ret == -1} {break}
			::thread::send $::crowTdeThread(parentId) [list puts $msg]
		}
		catch {close $fd}
		#::thread::send $::crowTdeThread(parentId) [list puts "loop end"]
		::thread::send $::crowTdeThread(parentId) [list puts "$crowTdeThread(bottomMsg)\n"]
		::thread::send -async $::crowTdeThread(parentId) [list after 1000 [list ::crowThread::release [::thread::id]]]
	}
	if {!$::crowTde::inVFS} {
		append bootCode "\n::thread::release"
	}
	::thread::send -async $tid [list eval $bootCode]
}

proc ::crowThread::release {tid} {
	#puts tid=[::crowThread::names]
	variable threadList
	set idx [lsearch -exact $threadList $tid]
	if {$idx >=0} {
		set idx2 [incr idx]
		if {$idx2 == [llength $threadList]} {
			set threadList [lrange $threadList 0 end-1]
		} else {
			set threadList [lreplace $threadList $idx $idx2 [lindex $threadList $idx2]]
		}
		if {[::thread::exists $tid]} {
			if {$::crowTde::inVFS} {
				catch [list ::thread::send $tid ::thread::exit]
			} else {
				::thread::release $tid
			}
		}
		
	}
	#puts tid=[::crowThread::names]
}

proc ::crowThread::run_ap {ap arglist headHook bottomHook} {
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
	
	foreach arg $arglist {
		lappend cmd $arg
	}
	puts [format "Run %s %s" [file tail $ap] $arglist]
	lappend cmd &
	if {$headHook ne ""} {eval $headHook}
	if {[catch {eval $cmd} ret]} {
		puts $ret
		return
	}
	if {$bottomHook ne ""} {eval $bottomHook}
	return
}

proc ::crowThread::names {} {
	variable threadList
	return $threadList
}

