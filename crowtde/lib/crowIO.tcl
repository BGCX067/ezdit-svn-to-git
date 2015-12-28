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
package provide crowIO 1.0

package require msgcat

namespace eval ::crowIO {
	variable txtVar ""
	variable varName ""
	variable nonewline ""
	variable readCount ""
	variable channels
	array set ::crowIO::channels [list stdout ::tclPuts stderr ::tclPuts]
}

proc ::crowIO::init {} {
	if {[info commands ::tclPuts] eq ""} {
		rename ::puts ::tclPuts
		rename ::crowIO::puts ::puts

		rename ::gets ::tclGets
		rename ::read ::tclRead
		rename ::crowIO::gets ::gets
		rename ::crowIO::read ::read
	}
}

proc ::crowIO::puts {args} {
	if {[llength $args]==0} {
		error [::msgcat::mc "Wrong argument!"]
		return
	}
	if {[llength $args] == 1} {
		foreach cmd $::crowIO::channels(stdout) {
			set cmd [lindex $cmd 0]
			if {$cmd eq ""} {continue}
			eval $cmd $args
		}
		return
	}
	if {[lindex $args 0] eq "-nonewline"} {
		set arglist [lrange $args 1 end]
		set flag "-nonewline"
	} else {
		set arglist [lrange $args 0 end]
		set flag ""
	}
	if {[info exists ::crowIO::channels([lindex $arglist 0])]} {
		foreach cmd $::crowIO::channels([lindex $arglist 0]) {
			set cmd [lindex $cmd 0]
			if {$cmd eq ""} {continue}
			eval [concat $cmd $flag [lrange $arglist 1 end]]
		}
	} else {
		eval [concat ::tclPuts $flag $arglist]
	}
}

proc ::crowIO::register {ch handle} {
	if {![info exists ::crowIO::channels($ch)]} {
		set ::crowIO::channels($ch) ""
	}
	lappend ::crowIO::channels($ch) $handle
}

proc ::crowIO::unregister {ch} {
	if {[info exists ::crowIO::channels($ch)]} {
		set idx [lsearch -exact $::crowIO::channels($ch) ch]
		if {$idx >=0} {
			lset ::crowIO::channels($ch) $idx ""
		}
	}
}

proc ::crowIO::gets {fd args} {
	set varname [lindex $args 0]
	#puts fd=$fd
	#puts vname=$varname
	if {$fd ne "stdin"} {
		if {$varname ne ""} {
			upvar 1 $varname var
			return [::tclGets $fd var]
		}
		return [::tclGets $fd]
	}
	set path ".crowtde_tkgets"
	set ::crowIO::txtVar ""
	set ::crowIO::varName $varname 
	package require Tk
	package require BWidget
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "gets"] -modal local
	set fme [$path getframe]
	set txtInput [entry $fme.txt -textvariable ::crowIO::txtVar -relief groove]
	set btnOk [button $fme.btnOk -text [::msgcat::mc "Ok"] -command [list $path enddialog "ok"] -bd 1 -default active]
	set btnCancel [button $fme.btnCancel -text [::msgcat::mc "Cancel"] -command [list $path enddialog "cancel"] -bd 1]	
	grid $txtInput -row 0 -column 0 -columnspan 2 -sticky "we"
	grid $btnOk -row 1 -column 0 -padx 10 -pady 10
	grid $btnCancel -row 1 -column 1 -padx 10 -pady 10
	focus $txtInput	
	bind $txtInput <KeyRelease-Return> [list $path enddialog "ok"]
	set ret [$path draw]
	if {$ret eq "ok"} {
		upvar 1 $varname var
		set var $::crowIO::txtVar
		set len [string length $var]
	} else {
		upvar 1 $varname var
		set var ""
		set len [string length $var]
	}
	destroy $path
	return $len	
}

proc ::crowIO::read {args} {
	set item0 [lindex $args 0]
	set item1 [lindex $args 1]
	switch -exact -- [llength $args] {
		"1" {
			if {$item0 ne "stdin"} {return [::tclRead $item0]}
			set ::crowIO::nonewline 1	
			set ::crowIO::readCount ""			
		}
		"2" {
			if {$item0 eq "-nonewline"} {
				if {$item1 ne "stdin"} {return [::tclRead -nonewline $item1]}
				set ::crowIO::nonewline 1	
				set ::crowIO::readCount ""
			} else {
				if {$item0 ne "stdin"} {return [::tclRead $item0 $item1]}
				set ::crowIO::nonewline 0	
				set ::crowIO::readCount $item1
			}
		}
		default {
			error [::msgcat::mc "Wrong argument!"]
			return
		}
	}
	set path ".crowtde_tkgets"
	set ::crowIO::txtVar ""
	package require Tk
	package require BWidget	
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "read"] -modal local
	set fme [$path getframe]
	set txtInput [text $fme.txt -relief groove -bd 2 -width 30 -height 6]
	set btnOk [button $fme.btnOk -text [::msgcat::mc "Ok"] -command [list $path enddialog "ok"] -bd 1 -default active]
	set btnCancel [button $fme.btnCancel -text [::msgcat::mc "Cancel"] -command [list $path enddialog "cancel"] -bd 1]	
	grid $txtInput  - -sticky "news"
	grid $btnOk $btnCancel
	focus $txtInput	
	set ret [$path draw]
	if {[winfo exists $txtInput]} {
		set ::crowIO::txtVar [$txtInput get 1.0 end]
	}
	destroy $path
	if {$ret ne "ok"} {
		return ""
	}
	
	if {$::crowIO::nonewline == 1} {
		if {[string range $::crowIO::txtVar end-1 end] eq "\n\r"} {
			set ::crowIO::txtVar [string range $::crowIO::txtVar 0 end-2]
		} elseif {[string index $::crowIO::txtVar end] eq "\n"} {
			set ::crowIO::txtVar [string range $::crowIO::txtVar 0 end-1]
		} elseif {[string index $::crowIO::txtVar end] eq "\r"} {
			set ::crowIO::txtVar [string range $::crowIO::txtVar 0 end-1]
		}
	}
	if {$::crowIO::readCount ne ""} {
		incr ::crowIO::readCount -1
		set ::crowIO::txtVar [string range $::crowIO::txtVar 0 $::crowIO::readCount]
	}	
	return $::crowIO::txtVar
}


