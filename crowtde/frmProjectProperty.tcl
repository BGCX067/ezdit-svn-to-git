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

namespace eval ::frmProjectProperty {
	variable wInfo
	variable vars
	array set wInfo ""
	array set vars ""
}

proc ::frmProjectProperty::btnOk_click {} {
	variable vars
	::fmeProjectManager::set_project_mainScript $vars(cmbMainScript)
	::fmeProjectManager::set_project_interpreter $vars(cmbInterp)
	::frmProjectProperty::btnCancel_click
}
proc ::frmProjectProperty::btnInterp_click {} {
	variable vars
	set ret [tk_getOpenFile -filetypes [list [list "All" "*"] ] -title [::msgcat::mc "Interpreter"]]
	if {$ret eq ""} {return}
	set vars(cmbInterp) $ret	
}

proc ::frmProjectProperty::btnCancel_click {} {
	variable wInfo
	after idle [list destroy $::frmProjectProperty::wInfo(frmProjectProperty)]
	$wInfo(frmProjectProperty) enddialog ""
}

proc ::frmProjectProperty::cmbMainScript_values {prjPath dpath} {
	variable vars
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *]]
	#puts $flist
	foreach f $flist {
		if {[string range [file tail $f] 0 2] eq ".__"} {continue}
		set fname [string range $f [expr [string length $prjPath]+1] end]
		lappend vars(cmbMainScriptValues) $fname
	}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]
	#puts dlist=$dlist
	foreach d $dlist {
		if {[string range [file tail $d] 0 2] eq ".__"} {continue}
		::frmProjectProperty::cmbMainScript_values $prjPath $d
	}	
}

proc ::frmProjectProperty::show {path} {
	variable wInfo
	variable vars
		
	Dialog $path -title [::msgcat::mc "Project Properties"] -modal local
	set fmeMain [$path getframe]
	
	set prjPath [::fmeProjectManager::get_project_path]
	set prjName [file tail $prjPath]
	set prjDir [file dirname $prjPath]
	
	set vars(cmbMainScript) [::fmeProjectManager::get_project_mainScript]
	set vars(cmbInterp) [::fmeProjectManager::get_project_interpreter]
	set vars(cmbMainScriptValues) ""
	::frmProjectProperty::cmbMainScript_values $prjPath $prjPath
	
	set lblProjectName [label $fmeMain.lblProjectName -text [::msgcat::mc "Project Name:"] -anchor w -justify left]
	set txtProjectName [label $fmeMain.txtProjectName -text $prjName -relief groove -anchor w -justify left -bg white]
	set lblWorkspace [label $fmeMain.lblWorkspace -text [::msgcat::mc "Workspace:"] -anchor w -justify left]
	set txtWorkspace [label $fmeMain.txtWorkspace -text $prjDir -relief groove -anchor w -justify left -bg white]
	set lblMainScript [label $fmeMain.lblMainScript -text [::msgcat::mc "Default Script:"] -anchor w -justify left]
	set cmbMainScript [ComboBox $fmeMain.cmbMainScript -entrybg white \
		-textvariable ::frmProjectProperty::vars(cmbMainScript) \
		-values $vars(cmbMainScriptValues) \
		-highlightthickness 0 -relief groove]
	set lblInterp [label $fmeMain.lblInterp -text [::msgcat::mc "Interpreter:"] -anchor w -justify left]
	
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	set tclInterp [::crowRC::param_get $rc CrowTDE.TclInterpreter]
	set vals ""
	if {$tclInterp ne ""} {lappend vals $tclInterp}
	set tkInterp [::crowRC::param_get $rc CrowTDE.TkInterpreter]
	if {$tkInterp ne ""} {lappend vals $tkInterp}	
	set cmbInterp [ComboBox $fmeMain.cmbInterp -entrybg white \
		-textvariable ::frmProjectProperty::vars(cmbInterp) \
		-values $vals \
		-highlightthickness 0 -relief groove]
	
	set btnInterp [button $fmeMain.btnInterp -text [::msgcat::mc "Browse..."] -command {::frmProjectProperty::btnInterp_click}]
	
	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief sunken]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -command {::frmProjectProperty::btnOk_click}]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -command {::frmProjectProperty::btnCancel_click}]
	pack $btnOk -expand 1 -fill both -padx 2 -pady 2 -side left -padx 2 -pady 2
	pack $btnCancel -expand 1 -fill both -padx 2 -pady 2 -side left -padx 2 -pady 2
	
	grid $lblProjectName -row 0 -column 0 -sticky "we"
	grid $txtProjectName -row 0 -column 1 -sticky "we" -columnspan 2
	grid $lblWorkspace -row 1 -column 0 -sticky "we"
	grid $txtWorkspace -row 1 -column 1 -sticky "we" -columnspan 2
	grid $lblMainScript -row 2 -column 0 -sticky "we"
	grid $cmbMainScript -row 2 -column 1 -sticky "we" -columnspan 2
	grid $lblInterp -row 3 -column 0 -sticky "we"
	grid $cmbInterp -row 3 -column 1 -sticky "we"
	grid $btnInterp -row 3 -column 2 -sticky "we"
	grid $fmeBtn -row 4 -column 0 -sticky "news" -columnspan 3 -pady 3
	
	grid rowconfigure $fmeMain 4 -weight 1
	grid columnconfigure $fmeMain 1 -weight 1
	
	set wInfo(frmProjectProperty) $path
	
	$path draw

}

