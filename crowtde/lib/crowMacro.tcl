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

package provide crowMacro 1.0
package require msgcat
package require treectrl

namespace eval ::crowMacro {
	variable macroFolder ""
	variable macroResult ""
	variable flag 0
	variable vars
	array set vars ""
	variable wInfo
	array set wInfo ""
}

proc ::crowMacro::init {macroFolder} {
	set ::crowMacro::macroFolder $macroFolder
}

proc ::crowMacro::get_menu {path dpath cb} {
	variable macroFolder

	if {$dpath eq ""} {set dpath $macroFolder}
	if {[winfo exists $path]} {destroy $path}
	set mMacro [menu $path -tearoff 0]
	$mMacro add command -label [::msgcat::mc "System Define"] -state disabled
	$mMacro add separator
	::crowMacro::mk_sys_menu $dpath $mMacro $cb
	
	set dpath [file join $::env(HOME) ".CrowTDE" "macro"]
	if {![file exists $dpath]} {return $path}
	set flist [glob -nocomplain -directory $dpath -types {d f} *]
	if {$flist eq ""} {return $path}
	
	$mMacro add separator
	$mMacro add command -label [::msgcat::mc "User Define"] -state disabled
	$mMacro add separator
	::crowMacro::mk_user_menu $dpath $mMacro $cb
	$mMacro add separator
	if {[winfo exists $mMacro.del_menu_crowtde_]} {destroy $mMacro.del_menu_crowtde_}
	set mDel [menu $mMacro.del_menu_crowtde_ -tearoff 0]
	::crowMacro::mk_user_del_menu $dpath $mDel
	$mMacro add command -label [::msgcat::mc "Operations"] -state disabled
	$mMacro add separator	
	$mMacro add cascade -label [::msgcat::mc "Delete"] -menu $mDel
	return $path
}

proc ::crowMacro::mk_sys_menu {dpath parent cb} {
	variable macroFolder	
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *.macro *.tm]]
	foreach f $flist {
		set fd [open $f r]
		set title [string range [gets $fd] 1 end]
		close $fd	
		$parent add command -label $title -command [list ::crowMacro::macro_exec $f $cb]
	}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]
	foreach d $dlist {
		if {[string index [file tail $d] 0] eq "."} {continue}
		set mName [string tolower [file tail $d]]
		if {[winfo exists $parent.$mName]} {destroy $parent.$mName}
		set mSub [menu $parent.$mName -tearoff 0]
		::crowMacro::mk_sys_menu $d $mSub $cb
		$parent add cascade -label [file tail $d] -menu $mSub
	}
}

proc ::crowMacro::mk_user_menu {dpath parent cb} {	
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *.macro *.tm]]
	foreach f $flist {
		set fd [open $f r]
		set title [string range [gets $fd] 1 end]
		close $fd	
		$parent add command -label $title -command [list ::crowMacro::macro_exec $f $cb]
	}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]
	foreach d $dlist {
		if {[string index [file tail $d] 0] eq "."} {continue}
		set mName [string tolower [file tail $d]]
		if {[winfo exists $parent.$mName]} {destroy $parent.$mName}
		set mSub [menu $parent.$mName -tearoff 0]
		::crowMacro::mk_user_menu $d $mSub $cb
		$parent add cascade -label [file tail $d] -menu $mSub
	}
	return	
}

proc ::crowMacro::mk_user_del_menu {dpath parent} {
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *.macro *.tm]]
	foreach f $flist {
		set fd [open $f r]
		set title [string range [gets $fd] 1 end]
		close $fd	
		$parent add command -label $title -command [list ::crowMacro::macro_del $f]
	}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]
	foreach d $dlist {
		if {[winfo exists $parent.[file tail $d]]} {destroy $parent.[file tail $d]}
		set mSub [menu $parent.[string tolower [file tail $d]] -tearoff 0]
		::crowMacro::mk_user_del_menu $d $mSub
		$parent add cascade -label [file tail $d] -menu $mSub
	}
	if {$flist eq "" && $dlist eq ""} {
		$parent add command -label [::msgcat::mc "--Delete This Folder--"] \
			-command [list file delete $dpath]
	}	
	return
}

proc ::crowMacro::macro_exec {fpath cb} {
	variable macroResult
	
	set fd [open $fpath r]
	set title [string range [gets $fd] 1 end]
	set macroResult [string trim [read $fd]]
	close $fd
	
	set cmd $cb
	lappend cmd $macroResult
	eval $cmd
	return
}

proc ::crowMacro::get_macro {} {
	variable macroResult
	return $macroResult
}

proc ::crowMacro::add {code} {
	variable vars
	variable wInfo
	set dpath [file join $::env(HOME) ".CrowTDE" "macro"]
	if {![file exists $dpath]} {file mkdir $dpath}

	set dlg [Dialog .dlgSaveMacro -modal local -title [::msgcat::mc "Save Macro"]]
	set fmeMain [$dlg getframe]
	set lblHelp [label $fmeMain.lblHelp -text [::msgcat::mc ""] -anchor w -justify left]
	set lblPath [label $fmeMain.lblPath -text [::msgcat::mc "Save Path:"] -anchor w -justify left]
	set txtPath [entry $fmeMain.txtPath -textvariable ::crowMacro::vars(txtPath) \
		-state disabled -disabledbackground white -disabledforeground black]
	set btnPath [button $fmeMain.btnPath -text [::msgcat::mc "Browse"] -command {::crowMacro::add_btnPath_click}]
	set lblName [label $fmeMain.lblName -text [::msgcat::mc "Macro Name:"] -anchor w -justify left]
	set txtName [entry $fmeMain.txtName]
	set lblCode [label $fmeMain.lblCode -text [::msgcat::mc "Codes:"] -anchor w -justify left] 
	set scroll [ScrolledWindow $fmeMain.scroll]
	set txtCode [text $fmeMain.txtCode -highlightthickness 0 -relief groove -bd 1]
	$txtCode insert end $code
	$scroll setwidget $txtCode
	set vars(txtPath) [file join {$HOME} "macro/"]

	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief sunken]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -command [list $dlg enddialog "OK"] -bd 1 -default active]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -command [list $dlg enddialog ""] -bd 1]	
	pack $btnOk -expand 1 -fill both -padx 2 -pady 2 -side left
	pack $btnCancel -expand 1 -fill both -padx 2 -pady 2 -side left	
	
	grid $lblPath $txtPath $btnPath -sticky "we"
	grid $lblName $txtName - -sticky "we"
	grid $lblCode - - -sticky "we"
	grid $scroll - - -sticky "news"
	grid $fmeBtn - - -sticky "we"
	
	grid rowconfigure $fmeMain 3 -weight 1
	grid columnconfigure $fmeMain 1 -weight 1
	
	set wInfo(dialog) $dlg
	set wInfo(txtPath) $txtPath
	set ret [$dlg draw]
	if {$ret eq "OK"} {
		set dpath [file join $::env(HOME) ".CrowTDE" [string range $vars(txtPath) 6 end]]
		set name [$txtName get]
		set code [$txtCode get 1.0 end]

		set id [clock format [clock scan today] -format "%Y%m%d%H%M%S"].macro
		set macro [file join $dpath $id]
		set fd [open $macro w]
		puts $fd "#$name"
		puts $fd $code
		close $fd
		
	}
	destroy $dlg
}

proc ::crowMacro::add_btnPath_click {} {
	variable vars
	variable wInfo
	set dpath [file join $::env(HOME) ".CrowTDE"]
	set initDir [regsub {\$HOME} $vars(txtPath) $dpath]
	set ret [::crowGetDir::show $wInfo(dialog).crowTDE_getdir_ $initDir]
	if {$ret eq ""} {return}
	$wInfo(txtPath) configure -state normal
	set vars(txtPath) \$HOME[string range $ret [string length $dpath] end]
	$wInfo(txtPath) configure -state disabled
}

proc ::crowMacro::macro_del {fpath} {
	set ans [tk_messageBox -icon info -type yesno \
		-title [::msgcat::mc "Delete"] -message [::msgcat::mc "Are you sure you want to delete macro?"] ]
	if {$ans ne "yes"} {return}
	file delete $fpath
	set flist [glob -nocomplain -directory [file dirname $fpath] -types {f d} *]
	#if {$flist eq ""} {file delete [file dirname $fpath]}
}
