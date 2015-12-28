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

namespace eval ::fmeToolbar {
	variable wInfo
	array set wInfo ""
	variable btnCounter 0
	variable vars
	array set vars [list case "-nocase" direct "-forwards" matching ""]
	variable procCache
	array set procCache ""
}

proc ::fmeToolbar::init {path appPath} {
	variable vars
	variable wInfo
	variable btnCounter
	set fmeToolbar [frame $path -bd 2 -relief groove]
	set wInfo(fmeToolbar) $fmeToolbar
	
	set sep [label $fmeToolbar.sep0 -bd 2 -relief groove]
	pack $sep -side left -fill y -padx 3 -pady 1
	bind $sep <ButtonRelease-1> {::crowTde::toolbar_collapse}
	bind $sep <Enter> {%W configure -bg #808080}
	bind $sep <Leave> {%W configure -bg [. cget -bg]}
	
	set wInfo(menuNew) [::fmeToolbar::menu_btn_new $fmeToolbar.btnNew "new" ::fmeToolbar::btnNew_click [::msgcat::mc "New"]]
	set wInfo(menuOpen) [::fmeToolbar::menu_btn_new $fmeToolbar.btnOpen "open" ::fmeToolbar::btnOpen_click [::msgcat::mc "Open"]]
	
	::fmeToolbar::btn_new $fmeToolbar.btnSave "save" {::fmeTabEditor::save_curr} [::msgcat::mc "Save"]
	::fmeToolbar::btn_new $fmeToolbar.btnSaveAll "save_all" {::fmeTabEditor::save_all} [::msgcat::mc "Save All"]

	::fmeToolbar::btn_new $fmeToolbar.btnPrint "printer" {::fmeTabEditor::curr_show_print} [::msgcat::mc "Print current editor..."]

	::fmeToolbar::btn_new $fmeToolbar.btnCut "cut" {::fmeTabEditor::curr_cut} [::msgcat::mc "Cut"]
	::fmeToolbar::btn_new $fmeToolbar.btnCopy "copy" {::fmeTabEditor::curr_copy} [::msgcat::mc "Copy"]
	::fmeToolbar::btn_new $fmeToolbar.btnPaste "paste" {::fmeTabEditor::curr_paste} [::msgcat::mc "Paste"]

	::fmeToolbar::btn_new $fmeToolbar.btnSearchInFiles "search_in_files" {::frmSearchInFiles::show .crowSearchInFiles} [::msgcat::mc "Search in files"]
	::fmeToolbar::btn_new $fmeToolbar.btnSearchFiles "search_files" {::frmSearchFiles::show .crowSearchFiles} [::msgcat::mc "Search files"]	
	
	::fmeToolbar::btn_new $fmeToolbar.btnUndo "undo" {::fmeTabEditor::curr_undo} [::msgcat::mc "Undo"]
	::fmeToolbar::btn_new $fmeToolbar.btnRedo "redo" {::fmeTabEditor::curr_redo} [::msgcat::mc "Redo"]
	
	set wInfo(menuDebuggerStart) [::fmeToolbar::menu_btn_new $fmeToolbar.btnDebuggerStart "debugger_start" {::fmeToolbar::btnDebuggerStart_click} [::msgcat::mc "Start Debugger"]]
	::fmeToolbar::btn_new $fmeToolbar.btnSyntaxCheck "syntax_check" {::fmeNagelfar::check [::fmeTabEditor::get_curr_file]} [::msgcat::mc "Syntax check..."]
	::fmeToolbar::btn_new $fmeToolbar.btnRunScript "run_script" {::fmeTabEditor::curr_eval} [::msgcat::mc "Run..."]
	::fmeToolbar::btn_new $fmeToolbar.btnRun "run_project" {::fmeProjectManager::project_run} [::msgcat::mc "Run Project..."]
	set wInfo(menuStopScript) [::fmeToolbar::menu_btn_new $fmeToolbar.btnStopScript "stop_script" {::fmeToolbar::btnStopScript_click} [::msgcat::mc "Stop"]]
		
	::fmeToolbar::btn_new $fmeToolbar.btnUnindent "unindent" {::fmeTabEditor::curr_remove_tab} [::msgcat::mc "Ident Selection"]
	::fmeToolbar::btn_new $fmeToolbar.btnIndent "indent" {::fmeTabEditor::curr_insert_tab} [::msgcat::mc "UnIdent Selection"]

	::fmeToolbar::btn_new $fmeToolbar.btnComment "comment" {::fmeTabEditor::curr_insert_comment} [::msgcat::mc "Add Block Comment"]
	::fmeToolbar::btn_new $fmeToolbar.btnUncomment "uncomment" {::fmeTabEditor::curr_remove_comment} [::msgcat::mc "Remove Block Comment"]	

	
	#<!--
	pack configure [::fmeToolbar::sep_new $fmeToolbar.sep$btnCounter] -side right
	if {[package versions snack] eq ""} {
		::fmeToolbar::frame_btn_new $fmeToolbar.btnPlayer "player" [frame .crowToolbarPlayer] [::msgcat::mc "MP3 Player"]	
		$fmeToolbar.btnPlayer configure -state disable
	} else {
		set wInfo(fmePlayer) [::fmePlayer::get_frame .crowToolbarPlayer]
		::fmeToolbar::frame_btn_new $fmeToolbar.btnPlayer "player" $wInfo(fmePlayer) [::msgcat::mc "MP3 Player"]			  
	}
	pack configure $fmeToolbar.btnPlayer -side right
	#-->
	
	#<!--
	#pack configure [::fmeToolbar::sep_new $fmeToolbar.sep$btnCounter] -side right	
	set wInfo(fmeFind) [::fmeToolbar::get_findFrame .crowToolbarFind]
	::fmeToolbar::frame_btn_new $fmeToolbar.btnFindConf "find_options" $wInfo(fmeFind) [::msgcat::mc "Find Options"]	
	::fmeToolbar::btn_new $fmeToolbar.btnFind "find2" {::fmeToolbar::btnFind_click} [::msgcat::mc "Find"]
	pack configure 	$fmeToolbar.btnFindConf -side right
	pack configure 	$fmeToolbar.btnFind -side right
	
	ComboBox $fmeToolbar.procList \
		-postcommand {::fmeToolbar::procList_refresh} \
		-values {} \
		-textvariable ::fmeToolbar::vars(currProc) \
		-autocomplete true \
		-modifycmd {::fmeToolbar::procList_change} \
		-entrybg white \
		-command {::fmeToolbar::btnFind_click} \
		-highlightthickness 0 -relief groove
	pack $fmeToolbar.procList -side right -fill y -padx 3	
	set wInfo(procList) $fmeToolbar.procList
	$fmeToolbar.procList bind <FocusIn> {::fmeToolbar::procList_refresh}
	$fmeToolbar.procList bind <Escape> {
		set editor [::fmeTabEditor::get_curr_editor]
		if {[winfo exists $editor]} {
			set txt [::crowEditor::get_text_widget $editor]
			after idle [list focus $txt]
		}
	} 
	#-->
	
	pack configure [::fmeToolbar::sep_new $fmeToolbar.sep$btnCounter] -side right -padx 2		
	#::fmeToolbar::btn_new $fmeToolbar.btnPause "pause" {}
	#::fmeToolbar::btn_new $fmeToolbar.btnStop  "stop" {}
	
	bind . <Escape> [list focus -force $fmeToolbar.procList]
	
	trace add variable ::crowEditor::wInfo(CrowEditor,sel) write ::fmeToolbar::editor_sel_change
	trace add variable ::crowNoteBook::wInfo(CrowNoteBook,pages) write ::fmeToolbar::editor_pages_change
	trace add variable ::fmeProjectManager::prjInfo(name) write ::fmeToolbar::project_change
	
	$wInfo(fmeToolbar).btnSave configure -state disabled
	$wInfo(fmeToolbar).btnSaveAll configure -state disabled
	$wInfo(fmeToolbar).btnCut configure -state disabled
	$wInfo(fmeToolbar).btnCopy configure -state disabled
	$wInfo(fmeToolbar).btnPaste configure -state disabled
	$wInfo(fmeToolbar).btnPrint configure -state disabled
	$wInfo(fmeToolbar).btnUndo configure -state disabled
	$wInfo(fmeToolbar).btnRedo configure -state disabled
	$wInfo(fmeToolbar).btnFind configure -state disabled
	$wInfo(fmeToolbar).btnFindConf configure -state disabled
	$wInfo(fmeToolbar).procList configure -state disabled
	$wInfo(fmeToolbar).btnIndent configure -state disabled
	$wInfo(fmeToolbar).btnUnindent configure -state disabled
	$wInfo(fmeToolbar).btnComment configure -state disabled
	$wInfo(fmeToolbar).btnUncomment configure -state disabled	
	$wInfo(fmeToolbar).btnSyntaxCheck configure -state disabled
	$wInfo(fmeToolbar).btnRun configure -state disabled
	$wInfo(fmeToolbar).btnRunScript configure -state disabled
	return $fmeToolbar
}

proc ::fmeToolbar::btn_new {path img cmd tooltip} {
	button $path -image [::crowImg::get_image $img] -bd 1 -relief flat -command $cmd -width 22  -compound center
	bind $path <Enter> [format {
				::fmeToolbar::mouse_enter %%W
				puts sbar msg {%s}
			} $tooltip]
	bind $path <Leave> {::fmeToolbar::mouse_leave %W}
	DynamicHelp::add $path -text $tooltip
	set ::fmeToolbar::wInfo($::fmeToolbar::btnCounter) $path
	incr ::fmeToolbar::btnCounter
	pack $path -side left -fill y -padx 1
	return
}

proc ::fmeToolbar::btn_toggle {btn widget width msg} {
	variable wInfo
	variable vars
#	puts "$btn $widget $width $msg"
	if {$vars($widget) == 1} {
		place forget $widget
		bind $btn <Configure> {}
		bind $btn <Enter> [format {
			::fmeToolbar::mouse_enter %%W
			puts sbar msg {%s}
		} $msg]
		bind $btn <Leave> {::fmeToolbar::mouse_leave %W}
		DynamicHelp::add $btn -text $msg
		$btn configure -bd 1 -relief flat
		set vars($widget) 0
		return		
	}
	bind $btn <Enter> {}
	bind $btn <Leave> {}
	$btn configure -bd 1 -relief sunken

	set x [expr [winfo x $btn] + [winfo width $btn] - [expr $width + 2]]
	set y [expr [winfo y $btn] + [winfo height $btn] +2]	
	
	place $widget -width $width -x $x -y $y
	
	set vars($widget) 1

	bind $btn <Configure> [list ::fmeToolbar::resize $btn $widget $width]
	raise $widget
	return
}

proc ::fmeToolbar::btnDebuggerStart_click {} {
	variable wInfo
	set m $wInfo(menuDebuggerStart)
	$m delete 0 end
	set prjPath [::fmeProjectManager::get_project_path]
	set fpath [::fmeTabEditor::get_curr_file]
	set prjState normal
	set editorState normal
	if {$prjPath eq ""} {set prjState disabled}
	if {$fpath eq ""} {set editorState disabled}

	$m add command -label [::msgcat::mc "Debug..."] \
		-compound left \
		-state $editorState \
		-command [list ::fmeDebugger::start $fpath]
		
	$m add separator

	set mainScript [::fmeProjectManager::property_get mainScript]
	set mainScript [file join [::fmeProjectManager::get_project_path] $mainScript]
	if {$mainScript eq $prjPath || ![file exists $mainScript]} {
		set prjState disabled
	}	
	if {$mainScript eq "" || ![file exists $mainScript]} {set prjState disabled}
	$m add command -label [::msgcat::mc "Debug Default Script..."] \
		-compound left \
		-state $prjState \
		-command [list ::fmeDebugger::start $mainScript]

	return
}

proc ::fmeToolbar::btnFind_click {} {
	variable vars
	variable procCache
	if {$vars(currProc) eq ""} {return}
	if {[info exists procCache($vars(currProc))]} {
		::fmeProcManager::goto_line [string trimleft $procCache($vars(currProc)) "0"]
	} else {
		set editor [::fmeTabEditor::get_curr_editor]
		if {$editor eq ""} {return}
		::crowEditor::find_keyword $editor $vars(currProc) $vars(case) $vars(direct) $vars(matching)
	}
}

#proc ::fmeToolbar::btnDebuggerStart_click {} {
#	variable wInfo
#	set m $wInfo(menuDebuggerStart)
#	$m delete 0 end
#	set prjPath [::fmeProjectManager::get_project_path]
#	set fpath [::fmeTabEditor::get_curr_file]
#	set prjState normal
#	set editorState normal
#	if {$prjPath eq ""} {set prjState disabled}
#	if {$fpath eq ""} {set editorState disabled}
#
#	$m add command -label [::msgcat::mc "Debug current file"] \
#		-compound left \
#		-state $editorState \
#		-command [list ::fmeDebugger::start $fpath]
#		
#	$m add separator
#
#	set mainScript [::fmeProjectManager::property_get mainScript]
#	if {$mainScript eq ""} {set prjState disabled}
#	$m add command -label [::msgcat::mc "Debug project"] \
#		-compound left \
#		-state $prjState \
#		-command [list ::fmeDebugger::start $mainScript]
#
#	return
#}

proc ::fmeToolbar::btnNew_click {} {
	variable wInfo
	$wInfo(menuNew) delete 0 end
	set prjPath [::fmeProjectManager::get_project_path]
	$wInfo(menuNew) add command -label [::msgcat::mc "Project..."] \
		-compound left \
		-command {::fmeProjectManager::project_new}
	$wInfo(menuNew) add separator
	set prjState normal
	if {$prjPath eq ""} {set prjState disabled}
	set templs [::crowTemplate::item_ls]
	foreach t $templs {
		array set templ $t
		if {$templ(image) eq ""} {
			$wInfo(menuNew) add command -label $templ(name) \
				-compound left \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]			
		} else {
			$wInfo(menuNew) add command -label $templ(name) \
				-compound left \
				-image [::crowImg::get_image $templ(image)] \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]
		}
	}
	$wInfo(menuNew) add separator

	$wInfo(menuNew) add command -label [::msgcat::mc "Folder..."] \
		-image [::crowImg::get_image new_folder] \
		-compound left \
		-state $prjState \
		-command {::fmeProjectManager::item_mkdir [::fmeProjectManager::get_curr_directory_item]}	
	return
}

proc ::fmeToolbar::btnOpen_click {} {
	variable wInfo
	$wInfo(menuOpen) delete 0 end
	$wInfo(menuOpen) add command -label [::msgcat::mc "File..."] \
		-compound left \
		-command {
			set ret [tk_getOpenFile -filetypes [list [list "All Types" "*.*"] ] -title [::msgcat::mc "Open File"]]
			if {$ret ne "" && $ret ne "-1" && [file exists $ret]} {
				::fmeProjectManager::file_open $ret
			}
		}
	$wInfo(menuOpen) add command -label [::msgcat::mc "Project..."] \
		-compound left \
		-command {::fmeProjectManager::project_open ""}		
}

proc ::fmeToolbar::btnStopScript_click {} {
	variable wInfo
	set m $wInfo(menuStopScript)
	$m delete 0 end
	foreach {fd pinfo} [array get ::crowExec::tblScript] {
		foreach {script id} $pinfo {break}
		$m add command -label [::msgcat::mc "Stop '%s'" [file tail $script]] -command [list ::crowExec::stop_script $fd]
	}
}

proc ::fmeToolbar::editor_sel_change {name1 name2 op} {
	variable wInfo
#	set editor [::fmeTabEditor::get_curr_editor]
#	set sel ""
#	if {$editor ne ""} {set sel [::crowEditor::get_sel_range $editor]}
	set state normal
	if {$::crowEditor::wInfo(CrowEditor,sel) eq ""} {set state disabled}
	$wInfo(fmeToolbar).btnCut configure -state $state
	$wInfo(fmeToolbar).btnCopy configure -state $state	
}

proc ::fmeToolbar::editor_pages_change {name1 name2 op} {
	variable wInfo
	set state normal
	if {$::crowNoteBook::wInfo(CrowNoteBook,pages) == 0} {set state disabled}
	$wInfo(fmeToolbar).btnSave configure -state $state
	$wInfo(fmeToolbar).btnSaveAll configure -state $state
	$wInfo(fmeToolbar).btnPaste configure -state $state
	$wInfo(fmeToolbar).btnPrint configure -state $state
	$wInfo(fmeToolbar).btnUndo configure -state $state
	$wInfo(fmeToolbar).btnRedo configure -state $state	
	$wInfo(fmeToolbar).btnFind configure -state $state
	$wInfo(fmeToolbar).btnFindConf configure -state $state
	$wInfo(fmeToolbar).procList configure -state $state
	$wInfo(fmeToolbar).btnIndent configure -state $state
	$wInfo(fmeToolbar).btnUnindent configure -state $state
	$wInfo(fmeToolbar).btnComment configure -state $state
	$wInfo(fmeToolbar).btnUncomment configure -state $state
	$wInfo(fmeToolbar).btnSyntaxCheck configure -state $state
	$wInfo(fmeToolbar).btnRunScript configure -state $state
}

proc ::fmeToolbar::frame_btn_new {path img frame tooltip} {
	variable vars
	button $path -image [::crowImg::get_image $img] -bd 1 -relief flat -width 22  -compound center \
		-command [list ::fmeToolbar::btn_toggle $path $frame 200 $tooltip]
	bind $path <Enter> [format {
				::fmeToolbar::mouse_enter %%W
				puts sbar msg {%s}
			} $tooltip]
	bind $path <Leave> {::fmeToolbar::mouse_leave %W}
	DynamicHelp::add $path -text $tooltip
	set ::fmeToolbar::wInfo($::fmeToolbar::btnCounter) $path
	incr ::fmeToolbar::btnCounter
	pack $path -side left -fill y -padx 1
	set vars($frame) 0
	return
}

proc ::fmeToolbar::get_findFrame {path} {
	variable vars
	variable wInfo
	set fme [frame $path -bd 2 -relief ridge]
	set font10 [::crowFont::get_font smaller]
	set chkCase [checkbutton $fme.chkCase -offvalue "-nocase" -onvalue "-exact" \
		-font $font10 \
		-variable ::fmeToolbar::vars(case) \
		-text [::msgcat::mc "Case Sensitive"] -anchor w -justify left]
	set chkDirect [checkbutton $fme.chkDirect -offvalue "-forwards" -onvalue "-backwards" \
		-font $font10 \
		-variable ::fmeToolbar::vars(direct) \
		-text [::msgcat::mc "Backward"] -anchor w -justify left]
	set chkRegexp [checkbutton $fme.chkRegexp -offvalue "" -onvalue "-regexp" \
		-font $font10 \
		-variable ::fmeToolbar::vars(matching) \
		-text [::msgcat::mc "Regular Expression"] -anchor w -justify left]
	pack $chkCase -side top -expand 1 -fill x
	pack $chkDirect -side top -expand 1 -fill x
	pack $chkRegexp -side top -expand 1 -fill x
	return $path
}

proc ::fmeToolbar::menu_btn_new {path img postcmd tooltip} {
	menubutton $path -image [::crowImg::get_image $img] -bd 1 -relief flat -menu {} -direction below -width 22  -compound center
	$path configure -menu [menu $path.menu -postcommand $postcmd -tearoff 0]
	bind $path <Enter> [format {
					::fmeToolbar::mouse_enter %%W
					puts sbar msg {%s}
				} $tooltip]
	bind $path <Leave> "::fmeToolbar::mouse_leave %W"
	DynamicHelp::add $path -text $tooltip
	set ::fmeToolbar::wInfo($::fmeToolbar::btnCounter) $path
	incr ::fmeToolbar::btnCounter
	pack $path -side left -fill y -padx 1
	return	$path.menu
}

proc ::fmeToolbar::mouse_enter {widget} {
	$widget configure -relief raised -bd 1
	return
}

proc ::fmeToolbar::mouse_leave {widget} {
	$widget configure -relief flat -bd 1
	return
}

proc ::fmeToolbar::procList_change {} {
	variable vars
	variable wInfo
	variable procCache
	set procList $wInfo(procList)
	::fmeProcManager::goto_line [string trimleft $procCache($vars(currProc)) "0"]
	return
}

proc ::fmeToolbar::procList_refresh {} {
	variable vars
	variable wInfo
	variable procCache
	set procList $wInfo(procList)
	array unset procCache 
	array set procCache [::fmeProcManager::get_procs]
	$procList configure -values [lsort -dictionary [array names procCache]]
	return
}

proc ::fmeToolbar::project_change {name1 name2 op} {
	variable wInfo
	set state normal
	if {$::fmeProjectManager::prjInfo(name) eq ""} {set state disabled}
	$wInfo(fmeToolbar).btnRun configure -state $state
}

proc ::fmeToolbar::resize {btn widget size} {
	set x [expr [winfo x $btn] + [winfo width $btn] - [expr $size +2]]
	set y [expr [winfo y $btn] + [winfo height $btn] +2]		
	place $widget -width $size -x $x -y $y
}

proc ::fmeToolbar::sep_new {path} {
	Separator $path -orient vertical
	set ::fmeToolbar::wInfo($::fmeToolbar::btnCounter) $path
	incr ::fmeToolbar::btnCounter
	pack $path -side left -fill y
	return $path
}


