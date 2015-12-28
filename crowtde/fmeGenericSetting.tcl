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

namespace eval ::fmeGenericSetting {
	variable vars
	array set vars ""
}

proc ::fmeGenericSetting::get_frame {path} {
	variable vars
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	set vars(txtTcl) [::crowRC::param_get $rc CrowTDE.TclInterpreter]
#	if {$vars(txtTcl) eq ""} {
#		set vars(txtTcl) "tclsh"
#		if {$::tcl_platform(platform) eq "windows"} {set vars(txtTcl) "tclsh.exe"}
#		::crowRC::param_set $rc CrowTDE.TclInterpreter $vars(txtTcl)
#	}
	set vars(txtTk) [::crowRC::param_get $rc CrowTDE.TkInterpreter]
#	if {$vars(txtTk) eq ""} {
#		set vars(txtTk) "wish"
#		if {$::tcl_platform(platform) eq "windows"} {set vars(txtTk) "wish.exe"}
#		::crowRC::param_set $rc CrowTDE.TkInterpreter $vars(txtTk)
#	}	
	
	set fmeMain [frame $path]
	set lblTitle [label $fmeMain.lblTitle -text [::msgcat::mc "General Settings"] -bd 2 -relief groove]
	grid $lblTitle -row 0 -column 0 -columnspan 3 -sticky "we"
	
	set fmeSys [labelframe $fmeMain.fmeSys -text [::msgcat::mc "Interpreter"]]
	set lblTcl [label $fmeSys.lblTcl -text [::msgcat::mc "Tcl Interpreter:"] -anchor w -justify left] 
	set txtTcl [label $fmeSys.txtTcl -textvariable ::fmeGenericSetting::vars(txtTcl) \
		-anchor w -justify left -bg white -bd 2 -relief groove -width 30]
	set btnTcl [button $fmeSys.btnTcl -text [::msgcat::mc "Browse..."] -command {::fmeGenericSetting::sel_tcl}]
	set lblTk [label $fmeSys.lblTK -text [::msgcat::mc "Tk Interpreter:"] -anchor w -justify left] 
	set txtTk [label $fmeSys.txtTk -textvariable ::fmeGenericSetting::vars(txtTk) \
		-anchor w -justify left -bg white -bd 2 -relief groove -width 30]
	set btnTk [button $fmeSys.btnTk -text [::msgcat::mc "Browse..."] -command {::fmeGenericSetting::sel_tk}]
	grid $lblTcl $txtTcl $btnTcl -sticky "we" -padx 2 -pady 2
	grid $lblTk $txtTk $btnTk -sticky "we" -padx 2 -pady 2
	grid columnconfigure $fmeSys 1 -weight 1
	
	set vars(rdoBoot) [::crowRC::param_get $rc CrowTDE.StartPage]
	if {$vars(rdoBoot) eq ""} {
		set vars(rdoBoot) "DEFAULT"
		::crowRC::param_set $rc CrowTDE.StartPage $vars(rdoBoot)
	}
	set fmeBoot [labelframe $fmeMain.fmeBoot -text [::msgcat::mc "Startup"]]
	set rdoDefault [radiobutton $fmeBoot.rdoDefault -anchor w -justify left -command {::fmeGenericSetting::rdoBoot_click} \
		-value "DEFAULT" -variable ::fmeGenericSetting::vars(rdoBoot) -text [::msgcat::mc "Show startup page"]]
	set rdoLast [radiobutton $fmeBoot.rdoLast  -anchor w -justify left -command {::fmeGenericSetting::rdoBoot_click} \
		-value "LAST" -variable ::fmeGenericSetting::vars(rdoBoot) -text [::msgcat::mc "Open last edit project"]]
	set rdoNew [radiobutton $fmeBoot.rdoNew  -anchor w -justify left -command {::fmeGenericSetting::rdoBoot_click} \
		-value "NEW" -variable ::fmeGenericSetting::vars(rdoBoot) -text [::msgcat::mc "Create new project"]]
	set rdoNotthings [radiobutton $fmeBoot.rdoNottings -anchor w -justify left -command {::fmeGenericSetting::rdoBoot_click} \
		-value "NOTTINGS" -variable ::fmeGenericSetting::vars(rdoBoot) -text [::msgcat::mc "Do nothing"]]
	pack $rdoDefault $rdoLast $rdoNew $rdoNotthings -side top -expand 1 -fill x

	set fmeDebug [labelframe $fmeMain.fmeDebug -text [::msgcat::mc "Debug Level"]]
	set rdoShallow [radiobutton $fmeDebug.rdoShallow -anchor w -justify left -command {::fmeGenericSetting::rdoDebug_click} \
		-value "SHALLOW" -variable ::crowDebugger::sysInfo(mode) -text [::msgcat::mc "Shallow"]]
	set rdoNormal [radiobutton $fmeDebug.rdoNormal  -anchor w -justify left -command {::fmeGenericSetting::rdoDebug_click} \
		-value "NORMAL" -variable ::crowDebugger::sysInfo(mode) -text [::msgcat::mc "Normal"]]
	set rdoDeep [radiobutton $fmeDebug.rdoDeep  -anchor w -justify left -command {::fmeGenericSetting::rdoDebug_click} \
		-value "DEEP" -variable ::crowDebugger::sysInfo(mode) -text [::msgcat::mc "Deep"]]
	pack $rdoShallow $rdoNormal $rdoDeep -side top -expand 1 -fill x


	grid $fmeSys -row 1 -column 0 -columnspan 3 -sticky "we" -pady 2 
	grid $fmeBoot -row 2 -column 0 -columnspan 3 -sticky "we" -pady 2
	grid $fmeDebug -row 3 -column 0 -columnspan 3 -sticky "we" -pady 2
	
	grid columnconfigure $fmeMain 0 -weight 1
	grid rowconfigure $fmeMain 4 -weight 1
	
	return $path
}

proc ::fmeGenericSetting::rdoBoot_click {} {
	variable vars
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc CrowTDE.StartPage $vars(rdoBoot)
	return
}

proc ::fmeGenericSetting::rdoDebug_click {} {
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
	return
}

proc ::fmeGenericSetting::sel_tcl {} {
	variable vars
	set ret [tk_getOpenFile -filetypes [list [list "All" "*.*"] ] -title [::msgcat::mc "Choose Tcl interpreter"]]
	if {$ret eq "" || $ret eq "-1"} {return ""}
	set vars(txtTcl) $ret
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc CrowTDE.TclInterpreter $ret
}

proc ::fmeGenericSetting::sel_tk {} {
	variable vars
	set ret [tk_getOpenFile -filetypes [list [list "All" "*.*"] ] -title [::msgcat::mc "Choose Tk interpreter"]]
	if {$ret eq "" || $ret eq "-1"} {return ""}
	set vars(txtTk) $ret
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc CrowTDE.TkInterpreter $ret
	
}

