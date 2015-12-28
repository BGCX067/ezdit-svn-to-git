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
package provide crowDebugger 1.0

namespace eval ::crowDebugger {
	variable EOF
	variable EOS
	variable EOS2
	variable cacheSize 100
	variable cachePath ""
	variable debugScript ""
	variable debugCacheScript ""
	variable cachePos ""
	
	variable breakpoints
	array set breakpoints ""
	
	variable watchpoints
	array set watchpoints ""	
	
	variable tid ""
	variable debugServer crowDebuggerServer_[pid]
	variable debugClient crowDebuggerClient_[pid]
	variable loadProgress 0
	variable sysInfo
	array set sysInfo [list start 0 currPos "" cmdlen "" locals "" script "" level "" mode "NORMAL" debugBaseDir ""]
}

proc ::crowDebugger::gen_info {fpath {server ""}} {
	variable EOF
	variable EOS
	variable EOS2
	variable cacheSize
	variable cachePath
	variable debugScript
	variable debugCacheScript
	variable loadProgress
	variable cachePos
	variable debugServer
	if {$server ne ""} {set debugServer $server}

	set EOF [geteof]
	set EOS [geteos]
	set EOS2 [geteos]_2

	set cachePath [file join $::env(HOME) ".CrowTDE" debug]
	if {![file exists $cachePath]} {file mkdir $cachePath}

	set id ""
	set cacheTbl [file join $cachePath "cache.tbl"]
	set data ""
	if {[file exists $cacheTbl]} {
		set fd [open $cacheTbl r]
		set data [split [read -nonewline $fd] "\n"]
		close $fd
		
		set idx [lsearch -glob $data *$fpath]
		if {$idx >= 0} {
			foreach {oid script} [lindex $data $idx] {break}
			set id $oid
			set cpath [file join $cachePath "$id.cache"]
			set cinfo [file join $cachePath "$id.info"]		
		}
	}

	if {$id eq ""} {
		set id [expr abs([clock clicks])]
		set cpath [file join $cachePath "$id.cache"]
		set cinfo [file join $cachePath "$id.info"]
		while {[file exists $cpath]} {
			set id [expr abs([clock clicks])]
			set cpath [file join $cachePath "$id.cache"]
			set cinfo [file join $cachePath "$id.info"]
		}
		set data [linsert $data 0 [list $id $fpath]]
	}
	
	set fd [open $cacheTbl w]
	set i 0
	foreach line $data {
		incr i
		if {$i <= $cacheSize} {
			puts $fd $line
		} else {
			foreach {oid script} $line {break}
			catch {file delete -force [file join $cachePath $oid.cache]}
			catch {file delete -force [file join $cachePath $oid.info]}
		}
	}
	close $fd	
	
	set fd [open $fpath r]
	set data [read -nonewline $fd]
	close $fd	
	
	set debugScript $fpath
	set debugCacheScript $cpath
	puts -nonewline [::msgcat::mc "Loading '%s' ..." $fpath]
	set fd [open $cpath w]
	puts $fd [list info script $fpath]
	set loadProgress 0
	set cachePos ""
	if {[catch {::crowDebugger::parsing $fd data 0 0}]} {
		puts $::errorInfo
		puts [::msgcat::mc "...abort"]
	} else {
		puts [::msgcat::mc "...ok"]
		set fd2 [open $cinfo w]
		puts -nonewline $fd2 $cachePos
		close $fd2
	}
	set cachePos ""
	close $fd
	
	return $cpath
}

proc ::crowDebugger::handle_default {fd code startPos len} {
	variable debugServer
	variable debugScript
	variable cachePos
	
	set tok0 [lindex $code 0 end]
	if {$tok0 eq ""} {return}
	if {[string index $tok0 0] eq "#"} {return}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	foreach part $code {
		if {[string trim $part] eq ""} {continue}
		foreach {line idx len tok} $part {break}
		puts -nonewline $fd $tok
		puts -nonewline $fd " "
	}
	puts $fd ""

}

proc ::crowDebugger::handle_for {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	foreach {cmd init exp inc body} $code {break}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	puts -nonewline $fd [lindex $cmd end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $init end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $exp end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $inc end]
	puts -nonewline $fd " "		
	foreach {line idx len tok} $body {break}
	switch -exact -- [string index $tok 0] {
		\x7b {
			if {[string first "\n" $tok] < 0} {
				puts $fd $tok
			} else {
				puts $fd "{"
				::crowDebugger::parsing $fd tok [expr $line - 1] 0
				puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
				lappend cachePos $startPos
				puts $fd "}"
			}
		}
		\x5b -
		\" -
		default {
			puts $fd $tok
		}
	}
}

proc ::crowDebugger::handle_foreach {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	foreach {cmd varlist itemlist body} $code {break}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	puts -nonewline $fd [lindex $cmd end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $varlist end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $itemlist end]
	puts -nonewline $fd " "	
	foreach {line idx len tok} $body {break}
	switch -exact -- [string index $tok 0] {
		\x7b {
			if {[string first "\n" $tok] < 0} {
				puts $fd $tok
			} else {
				puts $fd "{"
				::crowDebugger::parsing $fd tok [expr $line - 1] 0
				puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
				lappend cachePos $startPos
				puts $fd "}"
			}
		}
		\x5b -
		\" -
		default {
			puts $fd $tok
		}
	}
}

proc ::crowDebugger::handle_if {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	set itemLen [llength $code]
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	for {set i 0} {$i < $itemLen} {incr i} {
		foreach {line idx tlen tok} [lindex $code $i] {break}
		switch -exact -- $tok {
			"if" -
			"elseif" {
				puts -nonewline $fd $tok
				puts -nonewline $fd " "
				incr i
				foreach {line idx tlen tok} [lindex $code $i] {break}
				puts -nonewline $fd $tok
				puts -nonewline $fd " "
			}
			"else" -
			"then" {
				puts -nonewline $fd $tok
				puts -nonewline $fd " "
			}
			default {
				switch -exact -- [string index $tok 0] {
					\x7b {
						if {[string first "\n" $tok] < 0} {
							puts $fd $tok
							continue
						}						
						puts $fd "{"
						::crowDebugger::parsing $fd tok [expr $line - 1] 0 "$startPos + $len c" 0
						puts -nonewline $fd "} "
					}
					\x5b -
					\" -
					default {
						puts -nonewline $fd $tok
					}
				}				
			}
		}
	}
	puts $fd ""
}

proc ::crowDebugger::handle_namespace {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	switch -exact -- [lindex $code 1 end] {
		eval {
			puts -nonewline $fd [lindex $code 0 end]
			puts -nonewline $fd " "
			puts -nonewline $fd [lindex $code 1 end]
			puts -nonewline $fd " "
			puts -nonewline $fd [lindex $code 2 end]
			puts -nonewline $fd " "
			foreach body [lrange $code 3 end] {
				foreach {line idx tlen tok} $body {break}

				switch -exact -- [string index $tok 0] {
					\x7b {
						if {[string first "\n" $tok] < 0} {
							puts -nonewline $fd $tok
							puts -nonewline $fd " "
						} else {
							puts $fd "{"
							::crowDebugger::parsing $fd tok [expr $line - 1] 0 -1 0
							puts -nonewline $fd "} "
							lappend cachePos "$startPos + $len c"
						}
					}
					\x5b -
					\" -
					default {
						puts -nonewline $fd $tok
						puts -nonewline $fd " "
					}
				}
			}
			puts $fd ""
		}
		default {
			foreach part $code {
				puts -nonewline $fd [lindex $part end]
				puts -nonewline $fd " "
			}
			puts $fd ""
		}
	}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript "$startPos + $len c" $len]
}

proc ::crowDebugger::handle_proc {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	foreach {cmd name arglist body} $code {break}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	puts -nonewline $fd [lindex $cmd end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $name end] 
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $arglist end]
	puts -nonewline $fd " "
	foreach {line idx tlen tok} $body {break}
	switch -exact -- [string index $tok 0] {
		\x7b {
			if {[string first "\n" $tok] < 0} {
				puts $fd $tok
			} else {
				puts $fd "{"
				::crowDebugger::parsing $fd tok [expr $line - 1] 0 -1 0
				puts $fd "}"
				puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript "$startPos + $len c" $len]
				lappend cachePos "$startPos + $len c"
			}
		}
		\x5b -
		\" -
		default {
			puts $fd $tok
		}
	}
}

proc ::crowDebugger::handle_while {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	
	foreach {cmd exp body} $code {break}
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	puts -nonewline $fd [lindex $cmd end]
	puts -nonewline $fd " "
	puts -nonewline $fd [lindex $exp end]
	puts -nonewline $fd " "
	foreach {line idx tlen tok} $body {break}
	switch -exact -- [string index $tok 0] {
		\x7b {
			if {[string first "\n" $tok] < 0} {
				puts $fd $tok
			} else {			
				puts $fd "{"
				::crowDebugger::parsing $fd tok [expr $line - 1] 0
				puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
				lappend cachePos $startPos
				puts $fd "}"
			}
		}
		\x5b -
		\" -
		default {
			puts $fd $tok
		}
	}
}

proc ::crowDebugger::handle_switch {fd code startPos len} {
	variable debugServer
	variable cachePos
	variable debugScript
	variable EOF
	variable EOS
	variable EOS2	
	set arglen [llength $code]
	
	puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
	lappend cachePos $startPos
	puts -nonewline $fd "switch "
	for {set i 1} {$i < $arglen} {incr i} {
		foreach {line idx tlen tok} [lindex $code $i] {break}
		
		if {$tok eq "--"} {
			puts -nonewline $fd $tok
			puts -nonewline $fd " "
			incr i
			foreach {line idx tlen tok} [lindex $code $i] {break}
			puts -nonewline $fd $tok
			puts -nonewline $fd " "
			incr i
			break
		}
		if {[string first "-" $tok] < 0} {
			puts -nonewline $fd $tok
			puts -nonewline $fd " "			 
			incr i 
			break 
		}
		puts -nonewline $fd $tok
		puts -nonewline $fd " " 
	}
	
	if {($arglen - $i) > 1} {
		for {set i $i} {$i < $arglen} {incr i} {
			foreach {line idx tlen tok} [lindex $code $i] {break}
			puts -nonewline $fd $tok
			puts -nonewline $fd " "			
			incr i
			foreach {line idx tlen tok} [lindex $code $i] {break}
			switch -exact -- [string index $tok 0] {
				\x7b {
					if {[string first "\n" $tok] < 0} {
						puts -nonewline $fd $tok
						puts -nonewline $fd " "
					} else {			
						puts $fd "{"
						::crowDebugger::parsing $fd tok [expr $line - 1] 0
						puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $startPos $len]
						lappend cachePos $startPos
						puts -nonewline $fd "} "
					}
				}
				\x5b -
				\" -
				default {
					puts -nonewline $fd $tok
					puts -nonewline $fd " "
				}
			}
		}
	} else {
		foreach {line idx tlen tok} [lindex $code $i] {break}
		set tp [new_Tclparser $tok [expr $line - 1]]
		while {[set tok [$tp gettok]] ne $EOF} {
			if {$tok eq $EOS || $tok eq $EOS2} {continue}
			puts -nonewline $fd $tok
			puts -nonewline $fd " "
			set tok [$tp gettok]
			switch -exact -- [string index $tok 0] {
				\x7b {
					if {[string first "\n" $tok] < 0} {
						puts -nonewline $fd $tok
						puts -nonewline $fd " "
					} else {			
						puts $fd "{"
						set line2 [$tp getlineno]
						::crowDebugger::parsing $fd tok $line2 0
						puts -nonewline $fd "} "
					}
				}
				\x5b -
				\" -
				default {
					puts -nonewline $fd $tok
					puts -nonewline $fd " "
				}
			}			
		}
		delete_Tclparser $tp
		puts $fd ""
		puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript "$startPos + $len c" $len]
		lappend cachePos "$startPos + $len c"
		return
	}
	puts $fd ""
	return
}

proc ::crowDebugger::parsing {fd data startline startpc {endPos ""} {endLen 0} } {
	variable EOF
	variable EOS
	variable EOS2
	variable loadProgress
	variable debugServer
	variable debugScript
	
	upvar $data code

	set idx0 -$startpc
	set lineno $startline
	set lineno2 $lineno
	set currCmd ""
	set idx2 $startpc
	set tp [new_Tclparser $code $startline]
	while {[set tok [$tp gettok]] ne $EOF} {
		if {$tok eq $EOS || $tok eq $EOS2} {
			set pc2 [$tp getpc]
			if {[string trim $currCmd] ne ""} {
				set handler ::crowDebugger::handle_default
				foreach {line idx len data} [lindex $currCmd 0] {break}
				if {[info proc ::crowDebugger::handle_$data] ne ""} {
					set handler ::crowDebugger::handle_$data
				}
				$handler $fd $currCmd $anchor1 [expr $pc2 - $pc1]
			}
			set idx0 [expr [$tp getpc] + 1]
			set lineno [expr [$tp getlineno] + 1]			
			set currCmd ""
			set loadProgress $lineno	
			continue
		}

		if {$lineno ne [$tp getlineno]} {set idx0 [expr [$tp getpc2] + 1]}
		set lineno [$tp getlineno]
		set lineno2 [expr $lineno +1]
		set idx2 [expr [$tp getpc] - $idx0]
		set dlen [string length $tok]
		set idx1 [expr $idx2 - $dlen]
		set ch [string index $tok 0]
		if {$currCmd eq ""} {
			set pc1 [expr [$tp getpc] - $dlen]
			set anchor1 $lineno2.$idx1
		}
		lappend currCmd [list $lineno2 $idx1 $dlen $tok]
		if {$ch eq "\""} {incr idx2}
	}
	
	if {[string trim $currCmd] ne ""} {
		set handler ::crowDebugger::handle_default
		set pc2 [$tp getpc]
		set handler ::crowDebugger::handle_default
		foreach {line idx len data} [lindex $currCmd 0] {break}
		if {[info proc ::crowDebugger::handle_$data] ne ""} {
			set handler ::crowDebugger::handle_$data
		}
		$handler $fd $currCmd $anchor1 [expr $pc2 - $pc1]
	}
	
	if {$endPos eq "-1"} {
		set loadProgress $lineno2
		delete_Tclparser $tp
		return
	}
	
	if {$endPos ne ""} {
		puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript $endPos $endLen]
		if {[string first "+" $endPos]<0} {
			lappend cachePos $endPos
		} else {
			lappend cachePos $endPos
		}
	} else {
		puts $fd [list ::crowDebugger_${debugServer}::check_break_point $debugScript [expr [$tp getlineno]+1].0 0]
		lappend cachePos [expr [$tp getlineno]+1].0
	}
	set loadProgress $lineno2
	delete_Tclparser $tp
	return	

}

proc ::crowDebugger::recv {} {
	variable tid
	if {$tid eq ""} {return}
	if {![eof $tid]} {
		if {[set data [read -nonewline $tid]] ne ""} {puts $data}
	} else {
		catch {close $tid}
		set tid ""
		set ::crowDebugger::sysInfo(start) 0
	}
}

#############################################
#           public operations               #
#############################################

proc ::crowDebugger::breakpoint_add {script pos} {
	variable debugServer
	variable breakpoints
	
	array set breakpoints [list [list $script $pos] 1]

	if {[::crowDebugger::state]} {
		::crowDebugger::send  [format {
			set debugServer "%s"
			set script "%s"
			set pos "%s"
			set ::crowDebugger_${debugServer}::breakpoints([list $script $pos]) 1
		} $debugServer $script $pos]
	}
	array exists breakpoints				;# don't remove this
	return
}

proc ::crowDebugger::breakpoint_del {script pos} {
	variable debugServer
	variable breakpoints
	if {[::crowDebugger::state]} {
		::crowDebugger::send  [format {
			set debugServer "%s"
			set script "%s"
			set pos "%s"			
			unset ::crowDebugger_${debugServer}::breakpoints([list $script $pos])
		} $debugServer $script $pos]
	}
	array unset breakpoints [list $script $pos]
	
	array exists breakpoints			;# don't remove this
	return
}

proc ::crowDebugger::free_go {} {
	variable tid
	variable sysInfo
	variable debugServer
	variable debugClient	
	if {![::crowDebugger::state]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debugger has not started!"]
		return
	}
	
	::crowDebugger::send [format {
		set debugServer "%s"
		set ::crowDebugger_${debugServer}::step 0 
		set ::crowDebugger_${debugServer}::signal 1
	} $debugServer]
	return	
}

proc ::crowDebugger::pause {} {
	variable tid
	variable sysInfo
	variable debugServer
	variable debugClient	
	if {![::crowDebugger::state]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debugger has not started!"]
		return
	}
	
	::crowDebugger::send [format {
		set debugServer "%s"
		set ::crowDebugger_${debugServer}::step 1
	} $debugServer]
		
	return
}

proc ::crowDebugger::send {data} {
	variable debugServer
	switch  -exact -- $::tcl_platform(platform) {
		"unix" {
			::send -async -- $debugServer $data
		}
		"windows" {
			dde execute -async TclEval $debugServer $data 
		}
		default {
			# others platform
		}
	}
	return
}

proc ::crowDebugger::send_cmd {cmd} {
	variable tid
	variable sysInfo
	variable debugServer
	variable debugClient	
	if {![::crowDebugger::state]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debugger has not started!"]
		return
	}
	
	::crowDebugger::send [format {
		set debugServer "%s"
		uplevel "#%s" [list eval {%s}]
		set ::crowDebugger_${debugServer}::signal 0 
	} $debugServer $sysInfo(level) $cmd]
		
	return	
}

proc ::crowDebugger::start {fpath} {
	variable tid
	variable debugServer
	variable debugClient
	variable sysInfo
	variable cachePath
	variable breakpoints
	variable watchpoints
	
	if {[::crowDebugger::state]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debugger already running!"]
		return
	}

	if {$fpath eq "" || ![file exists $fpath]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debug script is not specified or not exists.!"]	
		return
	}
	
	set tp [::fmeProjectManager::get_project_interpreter]
	if {![file exists $tp]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Interpreter is not specified or not exists!" $tp]	
		return
	}
	
	set sysInfo(debugBaseDir) ""
	if {$sysInfo(mode) eq "NORMAL"} {
		set sysInfo(debugBaseDir) [file normalize [file dirname $fpath]]
	}
	
	set cachePath [file join $::env(HOME) ".CrowTDE" debug]
	if {![file exists $cachePath]} {file mkdir $cachePath}	
#	foreach f [glob -nocomplain -directory $cachePath *] {file delete $f}
	
	set srcPath $fpath
	set fpath [::crowDebugger::gen_info $fpath]
	set tmpfile [file join $::env(HOME) .CrowTDE tmpfile.debug.[pid]]
	set tid [open $tmpfile w]
	
	puts $tid [format {
		namespace eval ::crowDebugger_%s {
			variable signal ""
			variable stop 0
			variable sysInfo
			array set sysInfo [list script ""]
			variable step 1
			variable breakpoints
			array set breakpoints ""
			
			variable watchpoints
			array set watchpoints ""
			
			variable varLocals 
			array set varLocals ""
		}
	} $debugServer $srcPath]
	

	switch  -exact -- $::tcl_platform(platform) {
		"unix" {
			tk appname $debugClient
			puts $tid [list package require Tk]
			puts $tid [list tk appname $debugServer]
			puts $tid [format {
				proc ::crowDebugger_%s::notify {script} {
					variable sysInfo
					variable varLocals
					variable watchpoints
					set debugClient {%s}
					set level [expr [info level] -2]
					# don't touch below order (currPos cmdlen locals)
					send -async -- $debugClient [format {
							set ::crowDebugger::sysInfo(script) [list %%s]
							set ::crowDebugger::sysInfo(currPos) [list %%s]
							set ::crowDebugger::sysInfo(level) [list %%s]
							set ::crowDebugger::sysInfo(cmdlen) [list %%s]
							set ::crowDebugger::sysInfo(locals) [list %%s]
							array set ::crowDebugger::watchpoints {%%s}
						} $script $sysInfo(currPos) $level $sysInfo(cmdlen) [array get varLocals] [array get watchpoints]]
				}
			} $debugServer $debugClient]			
		}
		"windows" {
			dde servername $debugClient
			puts $tid [list package require dde]
			puts $tid [list dde servername $debugServer]
			puts $tid [format {
				proc ::crowDebugger_%s::notify {script} {
					variable sysInfo
					variable varLocals
					variable watchpoints
					set debugClient {%s}
					set level [expr [info level] -2]
					# don't touch below order (currPos cmdlen globals namespaces locals)
					dde execute -async TclEval $debugClient [format {
							set ::crowDebugger::sysInfo(script) [list %%s]
							set ::crowDebugger::sysInfo(currPos) [list %%s]
							set ::crowDebugger::sysInfo(level) [list %%s]
							set ::crowDebugger::sysInfo(cmdlen) [list %%s]
							set ::crowDebugger::sysInfo(locals) [list %%s]
							array set ::crowDebugger::watchpoints {%%s}
						} $script $sysInfo(currPos) $level $sysInfo(cmdlen) [array get varLocals] [array get watchpoints]]
				}
			} $debugServer $debugClient]
		}
		default {
			# others platform
		}
	}

	puts $tid [format {	
		proc ::crowDebugger_%s::check_break_point {script startPos len} {
			variable sysInfo
			variable breakpoints
			variable watchpoints
			variable varLocals
			variable stop
			variable step
			set debugServer {%s}
			
#			puts d-wps=[array get watchpoints]
			if {$step || [info exists ::crowDebugger_${debugServer}::breakpoints([list $script $startPos])]} {
#				set step 1
				set sysInfo(currPos) $startPos
				set sysInfo(cmdlen) $len
				
				set ::crowDebugger_${debugServer}::signal 0
				while {![set ::crowDebugger_${debugServer}::signal]} {
					array unset varLocals *
					foreach var [uplevel [list info vars]] {
						upvar $var v
						if {[array exists v]} {
							set varLocals($var) [list ARRAY [array get v]]
						} else {
							if {[info exists v]} {set varLocals($var) [list VAR $v]}
						}
					}
	#				puts d-loclas=[uplevel [list info vars]]
	#				puts d-vars=[array get varLocals]
	#				puts d-ws=[array get watchpoints]
					foreach {name val} [array get watchpoints] {
	#					puts d-name=$name
	#					puts d-vars=[uplevel [list info vars $name]]
						set var [uplevel [list info vars $name]]
						if {$var eq ""} {continue}
						if {[uplevel [list array exists $var]]} {
							set watchpoints($name) [list ARRAY [uplevel [list array get $var]]]
						} else {
	#						puts d-cmd=[list info exists $var]
	#						puts d-exists=[info exists $var]
							if {[uplevel [list info exists $var]]} {
	#							puts d-var=[set $var]
								set watchpoints($name) [list VAR [uplevel [list set $var]]]
							}
						}
					}
	
	#				update
					
					::crowDebugger_${debugServer}::notify $script
					vwait ::crowDebugger_${debugServer}::signal
				}
			}
			if {$stop} {
				catch {tk appname ""}
				exit
			}
			return
		} 
	} $debugServer $debugServer]

	puts $tid [format {	
		proc crow_source {args} {
			set mode {%s}
			set debugBaseDir {%s}
			if {[string first "-rsrc" $args] > 0} {
				return [uplevel [list eval [linsert $args 0 source_TCL]]]
			} else {
				set fpath [lindex $args 0]
				if {$mode eq "NORMAL" && [string first $debugBaseDir $fpath] < 0} {
					return [uplevel [list source_TCL $fpath]]
				}
				set cpath [::crowDebugger::gen_info $fpath {%s}]
				set oScript [info script]
				set ret [uplevel [list source_TCL $cpath]]
				info script $oScript
				return $ret
			}
		}
	} $sysInfo(mode) $sysInfo(debugBaseDir) $debugServer]
	
	puts $tid [list array unset ::crowDebugger_${debugServer}::breakpoints *]

	foreach {b val} [array get breakpoints] {
		puts $tid [list set ::crowDebugger_${debugServer}::breakpoints($b) $val]
	}
	
	foreach {w val} [array get watchpoints] {
		puts $tid [list set ::crowDebugger_${debugServer}::watchpoints($w) $val]
	}	
	
	puts $tid [format {
		lappend ::auto_path {%s}
		lappend ::auto_path {%s}
		package require crowIO
		package require Tclparser
		package require crowDebugger
		set debugMode {%s}
		set deubgSymbolFile {%s}
		cd [file dirname {%s}]
		file delete {%s}	
		
		::crowIO::init
		
		switch -exact -- $debugMode {
			"NORMAL" -
			"DEEP" {
				rename source source_TCL
				rename crow_source source
				if {[catch {source_TCL $deubgSymbolFile}]} {puts $::errorInfo}
			}
			default {
				if {[catch {source $deubgSymbolFile}]} {puts $::errorInfo}
			}
		}
	} [file join $::env(HOME) .CrowTDE lib] 	[file join $::crowTde::appPath lib] $sysInfo(mode) $fpath $srcPath $tmpfile]
	close $tid
	
	set tid [open [list | $tp $tmpfile] r+]

	fconfigure $tid -blocking 0 -buffering line
	fileevent $tid readable ::crowDebugger::recv
	
	flush $tid

	vwait ::crowDebugger::sysInfo(currPos)
	set sysInfo(start) 1
	puts [::msgcat::mc "Start Debugger...ok"]
	
	return
}

proc ::crowDebugger::state {} {
	variable debugServer
	switch  -exact -- $::tcl_platform(platform) {
		"unix" {
			if {[catch {::send -async -- $debugServer ""}]} {return 0}
			return 1
		}
		"windows" {
			if {[dde services TclEval $debugServer] eq ""} {return 0}
			 return 1
		}
		default {
			# others platform
		}
	}
	return	
}

proc ::crowDebugger::step {} {
	variable tid
	variable sysInfo
	variable debugServer
	variable debugClient	
	if {![::crowDebugger::state]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -type ok \
			-message [::msgcat::mc "Debugger has not started!"]
		return
	}
	
	::crowDebugger::send [format {
		set debugServer "%s"
		set ::crowDebugger_${debugServer}::step 1 
		set ::crowDebugger_${debugServer}::signal 1
	} $debugServer]
		
	return
}

proc ::crowDebugger::stop {} {
	variable tid
	variable debugServer
	variable debugClient	
	variable sysInfo
	
	if {$sysInfo(start) == 0} {return}
	catch {
		::crowDebugger::send [format {
			set debugServer "%s"
			tk appname ""
			update
			set ::crowDebugger_${debugServer}::step 0
			set ::crowDebugger_${debugServer}::stop 1
			set ::crowDebugger_${debugServer}::signal 1
			after idle exit
		} $debugServer]
	}
	update
	
	switch -exact -- $::tcl_platform(platform) {
		"unix" {
			after idle [list catch {exec kill -9 [pid $tid]}]
		}
		"windows" {
			catch {::twapi::end_process [pid $tid] -force}
		}
		default {}
	}
	
	set sysInfo(start) 0
	puts [::msgcat::mc "Stop Debugger....ok"]

	return
}

proc ::crowDebugger::watchpoint_add {name} {
	variable debugServer
	variable watchpoints
	
	array set watchpoints [list $name ""]
	if {[::crowDebugger::state]} {
		::crowDebugger::send  [list set ::crowDebugger_${debugServer}::watchpoints($name) ""]
	}
	return
}

proc ::crowDebugger::watchpoint_del {name} {
	variable debugServer
	variable watchpoints
	if {[::crowDebugger::state]} {
		::crowDebugger::send  [list catch [list unset ::crowDebugger_${debugServer}::watchpoints($name)]]
	}
	array unset watchpoints $name
	return
}
