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


namespace eval ::frmNewProject {
	variable wInfo
	array set wInfo ""
	
	variable selTempl ""
	variable rcPath ""
	
	variable vars
	array set vars [list mainScript "" workspace "" interpreter "" name "Porject_01"]
	
	variable templNsList ""
	variable templInfo
	array set templInfo ""
}

proc ::frmNewProject::show {path } {
	variable wInfo
	variable vars
	variable rcPath
	
	Dialog $path -title [::msgcat::mc "New Project"] -modal local
	
	set fmeMain [$path getframe]
	set fmeTree [ScrolledWindow $fmeMain.fmeBody]
	set tree [treectrl $fmeTree.tree \
		-itemheight 64 \
		-height 210 \
		-showroot no \
		-showline no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader no \
		-scrollmargin 16 \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50"]
		
	set wInfo(tree) $tree

	$tree column create -tag colIcon
	$tree column create -tag colDescription -expand 1
	
	$tree element create imgIcon image -image [::crowImg::get_image cfolder] 
	$tree element create txtDescription text -fill [list #000080 {selected focus} #656565 ""] \
		-justify center -lines 5 -wrap word
#	$tree element create rectSel rect -fill [list #b4b5b6 {selected}]
	
	$tree style create styIcon
	$tree style elements styIcon {imgIcon}
	$tree style layout styIcon imgIcon -width 64 -height 64 -padx {5 0} -pady {5 0}
#	$tree style layout styIcon rectSel -union {imgIcon} -sticky "news" -pady {5 0}
	
	$tree style create styDescription
	$tree style elements styDescription {txtDescription}
	$tree style layout styDescription txtDescription -height 64 -padx {0 5} -pady {5 0} \
		-expand "news" -sticky "news"
#	$tree style layout styDescription rectSel -union {txtDescription} -padx {0 5} -pady {5 0} \
#		-iexpand "news" -sticky "news"
	
	
	$tree notify bind $tree <Selection> [list ::frmNewProject::item_click %S]
#	bind $tree <ButtonRelease-3> {::frmNewProject::show_description %x %y %X %Y}
	bind $tree <ButtonRelease-1> {
		if {[winfo exists $::frmNewProject::wInfo(frmMain).msg]} {destroy $::frmNewProject::wInfo(frmMain).msg}
	}

	#<!-- loading rc file
	set rcPath [file join $::env(HOME) ".CrowTDE" "CrowTDE.rc"]
	array set vars [list mainScript "" workspace "" interpreter "" name "Porject_01"]
	::crowRC::param_get_all $rcPath ::frmNewProject::vars
	if {$vars(workspace) eq ""} {set vars(workspace) $::env(HOME)}
	#-->
	
	#<!-- get not exists project name
	for {set i 1} {$i<10000} {incr i} {
		set id [string range "0000$i" end-4 end]
		if {[file exists [file join $vars(workspace) "TclProject$id"]]} {continue}
		set vars(name) "TclProject$id"
		break
	}
	#-->
	
	$fmeTree setwidget $wInfo(tree)
	set lblType [label $fmeMain.lblType -text [::msgcat::mc "Template:"] -anchor w -justify left]
	set lblProjectName [label $fmeMain.lblProjectName -text [::msgcat::mc "Project Name:"] -anchor w -justify left]
	set lblWorkspace [label $fmeMain.lblWorkspace -text [::msgcat::mc "Workspace:"] -anchor w -justify left]
	set lblInterp [label $fmeMain.lblInterp -text [::msgcat::mc "Interpreter:"] -anchor w -justify left]
	set lblMainScript [label $fmeMain.lblMainScript -text [::msgcat::mc "Default Script:"] -anchor w -justify left]
	set txtInterp [entry $fmeMain.txtInterp -textvariable ::frmNewProject::vars(interpreter) -takefocus 1]
	set txtProjectName [entry $fmeMain.txtProjectName -textvariable ::frmNewProject::vars(name) -takefocus 1]
	set txtWorkspace [entry $fmeMain.txtWorkspace -textvariable ::frmNewProject::vars(workspace) -takefocus 1]
	set txtMainScript [entry $fmeMain.txtMainScript -textvariable ::frmNewProject::vars(mainScript) -takefocus 1]
	set btnWorkspace [button $fmeMain.btnWorkspace -text [::msgcat::mc "Browse..."] \
		-command {::frmNewProject::btnWorkspace_click}]
	set btnInterp [button $fmeMain.btnInterp -text [::msgcat::mc "Browse..."] \
		-command {::frmNewProject::btnInterp_click}]

	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief groove]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Create"] \
		-command {::frmNewProject::btnOk_click}]

	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog ""]]
	pack $btnOk -expand 1  -fill both -side left -padx 2 -pady 2
	pack $btnCancel -expand 1  -fill both -side left -padx 2 -pady 2

	grid $lblType -row 0 -column 0 -sticky "we" -columnspan 5
	grid $fmeTree -row 1 -column 0 -sticky "news" -columnspan 5 -pady 2
	grid $lblProjectName -row 2 -column 0 -sticky "we" -pady 2
	grid $txtProjectName -row 2 -column 1 -sticky "we" -columnspan 4 -pady 2
	grid $lblWorkspace -row 3 -column 0 -sticky "we" -pady 2
	grid $txtWorkspace -row 3 -column 1 -sticky "we" -columnspan 3 -pady 2
	grid $btnWorkspace -row 3 -column 4 -sticky "we" -padx 2 -pady 2 
	grid $lblMainScript -row 4 -column 0 -sticky "we" -pady 2
	grid $txtMainScript -row 4 -column 1 -sticky "we" -pady 2
	grid $lblInterp -row 4 -column 2 -sticky "we" -pady 2
	grid $txtInterp -row 4 -column 3 -sticky "we" -pady 2
	grid $btnInterp -row 4 -column 4 -sticky "we" -padx 2 -pady 2
	grid $fmeBtn -row 5 -column 0 -sticky "we" -pady 2 -columnspan 5
	
	grid rowconfigure $fmeMain 1 -weight 1
	grid columnconfigure $fmeMain 3 -weight 1 
	
	::frmNewProject::load_template
	
	set wInfo(dialog) $path
	set wInfo(frmMain) $fmeMain
	wm resizable $path 1 1
	set ret [$path draw]
	
	destroy $path
	
	if {$ret eq "Ok"} {
		return [array get vars]
	} else {
		return ""
	}
}

proc ::frmNewProject::btnOk_click {} {
	variable vars
	variable wInfo
	variable selTempl
	variable templInfo
	
	set tree $wInfo(tree)
	
	set sel [$tree selection get]
	if {$sel eq ""} {
		tk_messageBox -type ok -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Please choose template first!"]
		return
	}
	
	set projectPath [file join $vars(workspace) $vars(name)]
	if {[file exists $projectPath]} {
		tk_messageBox -title [::msgcat::mc "Error"] -type ok -icon error \
			-message [::msgcat::mc "'%s' already exists." $projectPath]
		return
	}
	file mkdir $projectPath
		
	# on windows remove next line will raise error 
	grab release $wInfo(dialog)
	array set tInfo $templInfo($selTempl)
	source [file join $tInfo(path) init.tcl]
	if {[$tInfo(init) $projectPath] eq "1"} {
		set rcDir [file join $projectPath ".__meta__"]
		if {![file exists $rcDir]} {file mkdir $rcDir}
		set rc [file join $rcDir "project.rc"]
		::crowRC::param_set $rc interpreter $vars(interpreter)
		::crowRC::param_set $rc mainScript $vars(mainScript)
		$wInfo(dialog) enddialog "Ok"
	} else {
		file delete $projectPath
	}
	namespace delete $tInfo(namespace)
	array unset tInfo
	return
}

proc ::frmNewProject::btnWorkspace_click {} {
	variable vars
	variable rcPath
	variable wInfo
	set ret [tk_chooseDirectory -title [::msgcat::mc "Workspace"] -mustexist 1]
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(workspace) $ret
	::crowRC::param_set $rcPath "workspace" $ret
	return
}

proc ::frmNewProject::btnInterp_click {} {
	variable vars
	variable wInfo
	set ret [tk_getOpenFile -filetypes [list [list "All" "*.*"] ] -title [::msgcat::mc "Interpreter"]]
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(interpreter) $ret
	return
}

proc ::frmNewProject::load_template {} {
	variable wInfo
	variable selTempl
	variable templNsList
	variable templInfo
	
	
#	set templs [glob -nocomplain -directory [file join $::crowTde::appPath "templates" "project"] -type {d} *]
	
	foreach t [::crowTemplate::project_ls] {
		array set templ $t
		lappend templNsList $templ(namespace)
		set templInfo($templ(name)) $t
		::frmNewProject::item_add $templ(description) $templ(image) $templ(name)
	}
	set selTempl "Empty"
	return
}

proc ::frmNewProject::item_add {txt img data} {
	variable wInfo
	set tree $wInfo(tree)
	set item [$tree item create -button no]
	$tree item style set $item colIcon styIcon colDescription styDescription
	$tree item lastchild 0 $item
	$tree item element configure $item colIcon imgIcon -image [::crowImg::get_image $img]
	$tree item element configure $item colDescription txtDescription -text $txt -data $data
	return $item
}
 
proc ::frmNewProject::item_click {item} {	
	variable wInfo
	variable selTempl
	variable vars
	variable templInfo
	
	set tree $wInfo(tree)
	if {$item eq "" || [$tree item id $item] eq ""} {return}
	set selTempl [$tree item element cget $item colDescription txtDescription -data]
	array set tInfo $templInfo($selTempl)
	set vars(mainScript) $tInfo(mainScript)
	if {$tInfo(interpreter) ne ""} {
		set rc [file join $::env(HOME) ".CrowTDE" "CrowTDE.rc"]
		switch $tInfo(interpreter) {
			"__TCLSH__" {
				set vars(interpreter) [::crowRC::param_get $rc CrowTDE.TclInterpreter]
			}
			"__WISH__" {
				set vars(interpreter) [::crowRC::param_get $rc CrowTDE.TkInterpreter]
			}
			default {
				set vars(interpreter) $tInfo(interpreter)
			}
		}
	}
	array unset tInfo
	return
}
