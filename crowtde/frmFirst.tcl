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

namespace eval ::frmFirst {
	variable vars
	array set vars ""
	
	variable wInfo
	array set wInfo ""
}

proc ::frmFirst::btnTcl_click {} {
	variable vars
	if {$vars(txtTk) ne ""} {	
		set ret [tk_getOpenFile -filetypes [list [list "ALL" "*.*"] ] -title [::msgcat::mc "Open File"] -initialdir [file dirname $vars(txtTk)]]
	} else {
		set ret [tk_getOpenFile -filetypes [list [list "ALL" "*.*"] ] -title [::msgcat::mc "Open File"] ]
	}
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(txtTcl) $ret
}

proc ::frmFirst::btnTk_click {} {
	variable vars
	if {$vars(txtTcl) ne ""} {	
		set ret [tk_getOpenFile -filetypes [list [list "ALL" "*.*"] ] -title [::msgcat::mc "Open File"] -initialdir [file dirname $vars(txtTcl)]]
	} else {
		set ret [tk_getOpenFile -filetypes [list [list "ALL" "*.*"] ] -title [::msgcat::mc "Open File"] ]
	}
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(txtTk) $ret	
}

proc ::frmFirst::show {path} {
	variable wInfo
	variable vars
	
	set langs ""
	array set tblLang ""

	set tblLocale [file join $::crowTde::appPath locale list.txt]
	set fd [open $tblLocale r]
	set localeInfo [split [read $fd] "\n"]
	close $fd
	foreach item $localeInfo {
		set linfo [split $item ":"]
		if {[llength $linfo] != 2} {continue}
		foreach {locale language} $linfo {}
		lappend langs $language
		set tblLang($language) $locale
	}
	set vars(txtLang) [lindex $langs 0]
	
	toplevel $path 
	wm title $path [::msgcat::mc "Basic Settings"] 

	set fmeMain $path
	set lblMsg [label $fmeMain.lblMsg -bd 2 -relief groove -justify center -anchor center\
		-text [::msgcat::mc "You are first time running CrowTDE.%s Please configure your basic run-time environment." "\n"]]
	
	set lblLang [label $fmeMain.lblLang -anchor w -justify left -text [::msgcat::mc "Language:"]]
	set cmbLang [ComboBox $fmeMain.cmbLang -textvariable ::frmFirst::vars(txtLang) \
		-values $langs \
		-entrybg white \
		-bd 2 -relief groove \
		-highlightthickness 0]
		
	set lblTcl [label $fmeMain.lblTcl -anchor w -justify left -text [::msgcat::mc "Tcl Interpreter:"]]
	set txtTcl [label $fmeMain.txtTcl -anchor w -justify left -textvariable ::frmFirst::vars(txtTcl) \
		-bg white -bd 2 -relief groove -width 30]
	set btnTcl [button $fmeMain.btnTcl -text [::msgcat::mc "Browse..."] -command {::frmFirst::btnTcl_click}]
	set lblTk [label $fmeMain.lblTk -anchor w -justify left -text [::msgcat::mc "Tk Interpreter:"]]
	set txtTk [label $fmeMain.txtTk -anchor w -justify left -textvariable ::frmFirst::vars(txtTk) \
		-bg white -bd 2 -relief groove -width 30]
	set btnTk [button $fmeMain.btnTk -text [::msgcat::mc "Browse..."] -command {::frmFirst::btnTk_click}]	
	
	set btnOk [button $fmeMain.bntOK -text [::msgcat::mc "Ok"] -command [list after idle [list destroy $path]]]
	
	grid $lblMsg - - -padx 2 -pady 2 -sticky "we"
	grid $lblLang $cmbLang - -padx 2 -pady 2 -sticky "we"
	grid $lblTcl $txtTcl $btnTcl -padx 2 -pady 2 -sticky "we"
	grid $lblTk $txtTk $btnTk -padx 2 -pady 2 -sticky "we"
	grid $btnOk - - -padx 2 -pady 2 -sticky "we"
	
	set wInfo(dialog) $path
	wm resizable $path 0 0
	tkwait window $path	

	set rc [file join $::env(HOME) ".CrowTDE" "CrowTDE.rc"]
	::crowRC::param_set $rc locale $tblLang($vars(txtLang))
	::crowRC::param_set $rc CrowTDE.TclInterpreter $vars(txtTcl)
	::crowRC::param_set $rc CrowTDE.TkInterpreter $vars(txtTk)
	tk_messageBox -title [::msgcat::mc "Information"] -type ok -icon info \
		-message [::msgcat::mc "You can configure more details from 'Main Menu->Options->Settings' ."]
}
