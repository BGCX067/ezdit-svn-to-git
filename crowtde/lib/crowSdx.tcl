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

package provide crowSdx 1.0
package require BWidget
package require crowRC

namespace eval ::crowSdx {
	variable wInfo
	array set wInfo ""
	
	variable tools
	array set tools ""
}

proc ::crowSdx::chkRunTime_click {} {
	variable wInfo
	if {$wInfo(chkRunTime,var)} {
		$wInfo(btnRunTime) configure -state normal
		$wInfo(txtRunTime) configure -state normal
	} else {
		$wInfo(btnRunTime) configure -state disabled
		$wInfo(txtRunTime) configure -state disabled
	}
}

proc ::crowSdx::init {tclkit sdx} {
	variable tools
	set tools(tclkit) $tclkit
	set tools(sdx) $sdx
	if {$::tcl_platform(platform) eq "unix"} {
		catch {file attributes $tools(tclkit) -permissions "+x"}
		catch {file attributes $tools(sdx) -permissions "+x"}
	}
	return
}

proc ::crowSdx::get_open {var} {
	set ret [tk_getOpenFile -filetypes [list [list "ALL" "*"] ] -title [::msgcat::mc "Save As.."]]
	if {$ret eq "" || $ret eq "-1"} {return}
	set $var $ret
}


proc ::crowSdx::get_save {var} {
	set ret [tk_getSaveFile -filetypes [list [list "ALL" "*"] ] -title [::msgcat::mc "Save As.."]]
	if {$ret eq "" || $ret eq "-1"} {return}
	set $var $ret
}

proc ::crowSdx::wrap_dir {shell dpath} {
	variable wInfo
	variable tools
	
	set rc [file join $::env(HOME) ".CrowTDE" "CrowSDX.rc"]
	
	set dlg [Dialog .crowtde_sdx_ -title [::msgcat::mc "SDX"] -modal local]
	set fmeMain [$dlg getframe]
	set lblVFS [label $fmeMain.lblVFS -text [::msgcat::mc "VFS Directory:"] -anchor w -justify left ]
	set txtVFS [label $fmeMain.txtVFS -width 30 -textvariable ::crowSdx::wInfo(txtVFS,var) \
		-pady 3 -anchor w -justify left -bd 2 -relief groove -bg white]

	set wInfo(txtVFS,var) [file tail $dpath]
	
	set lblSaveTo [label $fmeMain.lblSaveTo -text [::msgcat::mc "Save to:"] -anchor w -justify left]
	set txtSaveTo [entry $fmeMain.txtSaveTo -width 30 -textvariable ::crowSdx::wInfo(txtSaveTo,var) \
		-disabledbackground [$txtVFS cget -bg] -disabledforeground black]
	set btnSaveTo [button $fmeMain.btnSaveTo -text [::msgcat::mc "Browse"] \
		-command {::crowSdx::get_save ::crowSdx::wInfo(txtSaveTo,var)}]
	set wInfo(txtSaveTo,var) [file rootname [file tail $dpath]].kit
	
	set fmeOptions [labelframe $fmeMain.fmeOptions -text [::msgcat::mc "Options"] -padx 3 -pady 2]
	set wInfo(chkNoComp,var) 0
	set wInfo(chkWritable,var) 0
	set wInfo(chkRunTime,var) 0
	
	set wInfo(txtRunTime,var) [::crowRC::param_get $rc runtime]
	if {$wInfo(txtRunTime,var) eq ""} {
		switch -exact -- $::tcl_platform(platform) {
			"unix" {
				set kit [lsort -decreasing [glob -nocomplain -directory [file join $::crowTde::appPath tools] -types {f} tclkit-*.bin]]			
			}
			"windows" {
				set kit [lsort -decreasing [glob -nocomplain -directory [file join $::crowTde::appPath tools] -types {f} tclkit-*.exe]]				
			}
		}
		set wInfo(txtRunTime,var) [lindex $kit 0]
#		if {$crowTde::inVFS} {
#			set wInfo(txtRunTime,var) [file join $::env(HOME) ".CrowTDE" tools [file tail $wInfo(txtRunTime,var)]]
#		}	
		
	}
	set chkNoComp [checkbutton $fmeOptions.chkNoComp -onvalue 1 -offvalue 0 -anchor w -justify left \
		-text [::msgcat::mc "Do not compress files added to starkit"] \
		-variable ::crowSdx::wInfo(chkNoComp,var)]
	set chkWritable [checkbutton $fmeOptions.chkWritable -onvalue 1 -offvalue 0 -anchor w -justify left \
		-text [::msgcat::mc "Writable"] \
		-variable ::crowSdx::wInfo(chkWritable,var)]			
	set chkRunTime [checkbutton $fmeOptions.chkRunTime -onvalue 1 -offvalue 0 -anchor w -justify left \
		-text [::msgcat::mc "include runtime"] \
		-variable ::crowSdx::wInfo(chkRunTime,var) \
		-command {::crowSdx::chkRunTime_click} ]
	set txtRunTime [entry $fmeOptions.txtRunTime -textvariable ::crowSdx::wInfo(txtRunTime,var) \
		-state disabled -highlightthickness 0]
	set btnRunTime [button $fmeOptions.btnRunTime -text [::msgcat::mc "Browse"] \
		-command {::crowSdx::get_open ::crowSdx::wInfo(txtRunTime,var)} -state disabled]
	grid $chkNoComp - -sticky "news" -pady 1 -padx 2
	grid $chkWritable - -sticky "news" -pady 1 -padx 2
	grid $chkRunTime - -sticky "news" -pady 1 -padx 2
	grid $txtRunTime $btnRunTime -sticky "news" -pady 1 -padx 2	
	grid columnconfigure $fmeOptions 0 -weight 1
	grid rowconfigure $fmeOptions 2 -weight 1
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -default active -width 8 -command [list $dlg enddialog "Ok"]]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -width 8 -command [list $dlg enddialog "Cancel"]]
	pack $btnOk $btnCancel -side left -expand 1 -pady 2

	grid $lblVFS $txtVFS - -sticky "news" -pady 4 -padx 2
	grid $lblSaveTo $txtSaveTo $btnSaveTo -sticky "news" -pady 1 -padx 2
	grid $fmeOptions - - -sticky "news" -pady 5 -padx 2
	grid $fmeBtn - - -sticky "news" -pady 1 -padx 2
	grid columnconfigure $fmeMain 1 -weight 1
	grid rowconfigure $fmeMain 4 -weight 1
	
	bind $txtSaveTo <KeyRelease-Return> [list $btnOk invoke]
	bind $txtRunTime <KeyRelease-Return> [list $btnOk invoke]
	
	set wInfo(txtRunTime) $txtRunTime
	set wInfo(btnRunTime) $btnRunTime
	
	set ret [$dlg draw]
	destroy $dlg
	if {$ret eq "Ok"} {
		set cmd [list exec $tools(tclkit) $tools(sdx) wrap $wInfo(txtSaveTo,var) -vfs $dpath]
		if {$wInfo(chkRunTime,var)} {
			if {![file exists $wInfo(txtRunTime,var)]} {
				tk_messageBox -title [::msgcat::mc "error"] -icon error -type "ok" \
					-message [::msgcat::mc "Starkit runtime not exists!" $wInfo(txtRunTime,var) ]
				return
			}
			lappend cmd -runtime $wInfo(txtRunTime,var)
			::crowRC::param_set $rc runtime $wInfo(txtRunTime,var)
		}
		if {$wInfo(chkNoComp,var)} {lappend cmd -nocomp}
		if {$wInfo(chkWritable,var)} {lappend cmd -writable}

		puts [::msgcat::mc "Building starkit ..."]
		set flag 1
		set t 0
		
		set fd [open [list | $shell] r+]
		fconfigure $fd -blocking 0 -buffering none
		
		puts $fd [format {
			cd {%s}
			if {[catch {%s} ret]} {
				puts $::errorInfo
			} else {
				puts $ret
			}
			cd {%s}
			exit
		} [file dirname $dpath] $cmd [pwd]]
		flush $fd		
		
		
		while {![eof $fd]} {
			after 500 ; update
			set flag [expr !$flag]
			if {$flag} {
				incr t
				puts [::msgcat::mc "%s Elapsed time ... %02s:%02s" "\t" [expr int($t/60)] [expr $t%60]]
			}
			set data [read -nonewline $fd]
			if {$data ne ""} {puts $data}
		}
		close $fd
	}
	return	
}

proc ::crowSdx::wrap_file {fpath} {
	variable wInfo
	variable tools
	
	set rc [file join $::env(HOME) ".CrowTDE" "CrowSDX.rc"]
	
	set dlg [Dialog .crowtde_sdx_ -title [::msgcat::mc "SDX"] -modal local]
	set fmeMain [$dlg getframe]
	set lblScript [label $fmeMain.lblScript -text [::msgcat::mc "Script:"] -anchor w -justify left ]
	set txtScript [label $fmeMain.txtScript -width 30 -textvariable ::crowSdx::wInfo(txtScript,var) \
		-pady 3 -anchor w -justify left -bd 2 -relief groove -bg white]
	set wInfo(txtScript,var) [file tail $fpath]
	
	set lblSaveTo [label $fmeMain.lblSaveTo -text [::msgcat::mc "Save to:"] -anchor w -justify left]
	set txtSaveTo [entry $fmeMain.txtSaveTo -width 30 -textvariable ::crowSdx::wInfo(txtSaveTo,var) \
		-disabledbackground [$txtScript cget -bg] -disabledforeground black]
	set btnSaveTo [button $fmeMain.btnSaveTo -text [::msgcat::mc "Browse"] \
		-command {::crowSdx::get_save ::crowSdx::wInfo(txtSaveTo,var)}]
	set wInfo(txtSaveTo,var) [file rootname [file tail $fpath]].kit
	
	set fmeRunTime [labelframe $fmeMain.runTime -text [::msgcat::mc "Options"] -padx 3 -pady 2]
	set wInfo(chkRunTime,var) 0	
	set wInfo(txtRunTime,var) [::crowRC::param_get $rc runtime]
	if {$wInfo(txtRunTime,var) eq ""} {
		switch -exact -- $::tcl_platform(platform) {
			"unix" {
				set kit [lsort -decreasing [glob -nocomplain -directory [file join $::crowTde::appPath tools] -types {f} tclkit-*.bin]]			
			}
			"windows" {
				set kit [lsort -decreasing [glob -nocomplain -directory [file join $::crowTde::appPath tools] -types {f} tclkit-*.exe]]				
			}
		}
		set wInfo(txtRunTime,var) [lindex $kit 0]
#		if {$crowTde::inVFS} {
#			set wInfo(txtRunTime,var) [file join $::env(HOME) ".CrowTDE" tools [file tail $wInfo(txtRunTime,var)]]
#		}	
		
	}	
	set chkRunTime [checkbutton $fmeRunTime.chkRunTime -onvalue 1 -offvalue 0 -anchor w -justify left \
		-text [::msgcat::mc "include runtime"] \
		-variable ::crowSdx::wInfo(chkRunTime,var) \
		-command {::crowSdx::chkRunTime_click} ]
	set txtRunTime [entry $fmeRunTime.txtRunTime -textvariable ::crowSdx::wInfo(txtRunTime,var) \
		-state disabled -highlightthickness 0]
	set btnRunTime [button $fmeRunTime.btnRunTime -text [::msgcat::mc "Browse"] \
		-command {::crowSdx::get_open ::crowSdx::wInfo(txtRunTime,var)} -state disabled]
	grid $chkRunTime - -sticky "news" -pady 1 -padx 2
	grid $txtRunTime $btnRunTime -sticky "news" -pady 1 -padx 2	
	grid columnconfigure $fmeRunTime 0 -weight 1
	grid rowconfigure $fmeRunTime 2 -weight 1
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -default active -width 8 -command [list $dlg enddialog "Ok"]]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -width 8 -command [list $dlg enddialog "Cancel"]]
	pack $btnOk $btnCancel -side left -expand 1 -pady 2

	grid $lblScript $txtScript - -sticky "news" -pady 4 -padx 2
	grid $lblSaveTo $txtSaveTo $btnSaveTo -sticky "news" -pady 1 -padx 2
	grid $fmeRunTime - - -sticky "news" -pady 5 -padx 2
	grid $fmeBtn - - -sticky "news" -pady 1 -padx 2
	grid columnconfigure $fmeMain 1 -weight 1
	grid rowconfigure $fmeMain 4 -weight 1
	
	set wInfo(txtRunTime) $txtRunTime
	set wInfo(btnRunTime) $btnRunTime

	bind $txtSaveTo <KeyRelease-Return> [list $btnOk invoke]
	bind $txtRunTime <KeyRelease-Return> [list $btnOk invoke]
	
	set ret [$dlg draw]
	destroy $dlg
	if {$ret eq "Ok"} {
		set oPwd [pwd]
		cd [file dirname $fpath]
		set kitname [file rootname [file tail $fpath]].kit
		if {$wInfo(chkRunTime,var)} {
			if {![file exists $wInfo(txtRunTime,var)]} {
				tk_messageBox -title [::msgcat::mc "error"] -icon error -type "ok" \
					-message [::msgcat::mc "Starkit runtime not exists!" $wInfo(txtRunTime,var) ]
				return
			}
			puts [list exec $tools(tclkit) $tools(sdx) qwrap [file tail $fpath] -runtime $wInfo(txtRunTime,var)]
			set ret ""
			if {[catch {eval [list exec $tools(tclkit) $tools(sdx) qwrap [file tail $fpath] -runtime $wInfo(txtRunTime,var)]} ret]} {
				puts $ret
				cd $oPwd
				return
			}
			set kitname [file rootname $kitname]
			::crowRC::param_set $rc runtime $wInfo(txtRunTime,var)
			
		} else {
			puts [list exec $tools(tclkit) $tools(sdx) qwrap [file tail $fpath]]
			set ret ""
			if {[catch {eval [list exec $tools(tclkit) $tools(sdx) qwrap [file tail $fpath]]} ret]} {
				puts $ret
				cd $oPwd
				return
			}
		}
		puts [::msgcat::mc "Move '%s' -> '%s'" $kitname $wInfo(txtSaveTo,var)]
		file rename -force $kitname $wInfo(txtSaveTo,var)
		puts [::msgcat::mc "Size = %s (KB)" [expr int([file size $wInfo(txtSaveTo,var)]/1024)]]
		puts [::msgcat::mc "Finish."]
		cd $oPwd
	}
	
	
}


#::crowSdx::init [file normalize "../tools/tclkit.bin"] [file normalize "../tools/sdx.kit"]
#::crowSdx::wrap_dir "/home/dai"
