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

namespace eval ::fmeMenuBar {
	variable appPath ""
	
	variable wInfo
	array set wInfo ""
	
	variable vars
	array set vars ""
}


proc ::fmeMenuBar::init {path appPath} {
	variable wInfo
	set ::fmeMenuBar::appPath $appPath
	set menubar [menu $path -bd 0 -relief groove -type menubar -postcommand ::fmeMenuBar::menubar_post]
	set wInfo(menubar) $menubar

	::fmeMenuBar::file_init
	::fmeMenuBar::edit_init
	::fmeMenuBar::project_init
	::fmeMenuBar::debug_init
	::fmeMenuBar::options_init
	::fmeMenuBar::windows_init
	#::fmeMenuBar::tools_init
	::fmeMenuBar::help_init
	#::fmeMenuBar::test_init
	$menubar add cascade -menu $wInfo(file) -label [::msgcat::mc "File"]
	$menubar add cascade -menu $wInfo(edit) -label [::msgcat::mc "Edit"] 
	$menubar add cascade -menu $wInfo(project) -label [::msgcat::mc "Project"] 
	$menubar add cascade -menu $wInfo(debug) -label [::msgcat::mc "Debug"] 
	$menubar add cascade -menu $wInfo(options) -label [::msgcat::mc "Options"] 
	#$menubar add cascade -menu $wInfo(tools) -label [::msgcat::mc "Tools(T)"] -underline 0	
	$menubar add cascade -menu $wInfo(windows) -label [::msgcat::mc "Window"] 
	$menubar add cascade -menu $wInfo(help) -label [::msgcat::mc "Help"] 
	#$menubar add cascade -menu $wInfo(test) -label [::msgcat::mc "Test(W)"] -underline 0
	#bind . <Alt-f> {tk_menuSetFocus $::fmeMenuBar::wInfo(file)}
	bind . <Control-w> {::fmeTabEditor::close_curr}
	bind . <F4> {::fmeTabEditor::curr_eval}
	bind . <F5> {::fmeProjectManager::project_run}
	bind . <F6> {
		set fpath [::fmeTabEditor::get_curr_file]
		if {$fpath ne "" && $::crowDebugger::sysInfo(start) == 0} {
			::fmeDebugger::start $fpath
		}		
	}
	bind . <F7> {
		set prjPath [::fmeProjectManager::get_project_path]
		if {$prjPath ne "" && $::crowDebugger::sysInfo(start) == 0} {
			set mainScript [::fmeProjectManager::property_get mainScript]
			set mainScript [file join [::fmeProjectManager::get_project_path] $mainScript]
			if {$mainScript ne $prjPath && [file exists $mainScript]} {  
				::fmeDebugger::start $mainScript
			} else {
				tk_messageBox -title [::msgcat::mc "error!"] \
					-icon error \
					-type ok \
					-message [::msgcat::mc "Default script not exists!"]
			}
		}
	}
	bind . <F8> {
		if {[$::fmeDebugger::wInfo(btnStep) cget -state] eq "normal"} {
			::fmeDebugger::step
		}
	}	
	bind . <Control-Left> {::fmeTabEditor::raise_prev}
	bind . <Control-Right> {::fmeTabEditor::raise_next}
	bind . <Alt-Right> {::fmeTabEditor::scroll_incr}
	bind . <Alt-Left> {::fmeTabEditor::scroll_desc}	
	return $menubar 
}
proc ::fmeMenuBar::menubar_post {} {}

proc ::fmeMenuBar::debug_init {} {
	variable wInfo
	set wInfo(debug) [menu $wInfo(menubar).debug  -postcommand ::fmeMenuBar::debug_post]
}

proc ::fmeMenuBar::debug_post {} {
	variable wInfo
	set m $wInfo(debug)
	$m delete 0 end	
	set editor [::fmeTabEditor::get_curr_editor]
	set editorState normal

	set prjPath [::fmeProjectManager::get_project_path]
	set fpath [::fmeTabEditor::get_curr_file]
	
	set prjState normal
	set mainScript ""
	
	if {$editor eq "" || $::crowDebugger::sysInfo(start)} {
		set editorState disabled
	}
	
	if {$prjPath eq "" || $::crowDebugger::sysInfo(start)} {
		set prjState disabled
	} else {
		set mainScript [::fmeProjectManager::property_get mainScript]
		set mainScript [file join [::fmeProjectManager::get_project_path] $mainScript]
		if {$mainScript eq $prjPath || ![file exists $mainScript]} {
			set prjState disabled
		}
	}
	
	$m add command -compound left -label [::msgcat::mc "Debug..."] \
		-image [::crowImg::get_image debugger_start] \
		-accelerator "F6" \
		-state $editorState \
		-command [list ::fmeDebugger::start $fpath]
	$m add command -compound left -label [::msgcat::mc "Debug Default Script..."] \
		-accelerator "F7" \
		-state $prjState \
		-command [list ::fmeDebugger::start $mainScript]
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Free Go"] \
		-state [$::fmeDebugger::wInfo(btnFreeGo) cget -state] \
		-command [list ::fmeDebugger::free_go]
	$m add command -compound left -label [::msgcat::mc "Pause"] \
		-state [$::fmeDebugger::wInfo(btnPause) cget -state]  \
		-command [list ::fmeDebugger::pause]
	$m add command -compound left -label [::msgcat::mc "Step"] \
		-accelerator "F8" \
		-state [$::fmeDebugger::wInfo(btnStep) cget -state]  \
		-command [list ::fmeDebugger::step]
	$m add command -compound left -label [::msgcat::mc "Stop"] \
		-state [$::fmeDebugger::wInfo(btnStop) cget -state]  \
		-command [list ::fmeDebugger::stop]		
	$m add separator
	set watchState disabled
	if {$prjPath ne ""} {set watchState normal}
	$m add command -compound left -label [::msgcat::mc "Add Watch..."] \
		-image [::crowImg::get_image add_watch] \
		-state $watchState  \
		-command [list ::fmeDebugger::watchpoint_add]
	$m add separator
	if {[winfo exists $m.subm]} {destroy $m.subm}
	set subm [menu $m.subm -tearoff 0]
	$subm add  radiobutton  -label [::msgcat::mc "Shallow"] \
		-variable ::crowDebugger::sysInfo(mode) -value "SHALLOW" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}
	$subm add  radiobutton  -label [::msgcat::mc "Normal"] \
		-variable ::crowDebugger::sysInfo(mode) -value "NORMAL" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}
	$subm add  radiobutton  -label [::msgcat::mc "Deep"] \
		-variable ::crowDebugger::sysInfo(mode) -value "DEEP" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}
	$m add cascade -label [::msgcat::mc "Debug level"] -menu $subm \
		-state [$::fmeDebugger::wInfo(btnSettings) cget -state]
}

proc ::fmeMenuBar::edit_init {} {
	variable wInfo
	set wInfo(edit) [menu $wInfo(menubar).edit  -postcommand ::fmeMenuBar::edit_post]
}

proc ::fmeMenuBar::edit_post {} {
	variable wInfo
	$wInfo(edit) delete 0 end	
	set editor [::fmeTabEditor::get_curr_editor]
	set editorState normal
	if {$editor eq ""} { set editorState disabled}
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Undo"] \
		-state $editorState \
		-accelerator "Ctrl+z" \
		-command [list catch [list ::crowEditor::undo $editor]]
		
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Redo"] \
		-state $editorState \
		-command  [list catch [list ::crowEditor::redo $editor]]
	$wInfo(edit) add separator
	
	set selState $editorState
	set sel ""
	if {$editor ne ""} {set sel [::crowEditor::get_sel_range $editor]}
	if {$sel eq ""} {set selState disabled}
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Cut"] \
		-state $selState \
		-accelerator "Ctrl+x" \
		-image [::crowImg::get_image cut] \
		-command [list ::crowEditor::cut $editor]
		
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Copy"] \
		-state $selState \
		-accelerator "Ctrl+c" \
		-image [::crowImg::get_image copy] \
		-command [list ::crowEditor::copy $editor]
		
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Paste"] \
		-state $editorState \
		-accelerator "Ctrl+v" \
		-image [::crowImg::get_image paste] \
		-command [list ::crowEditor::paste $editor]
		
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Delete"] \
		-state $selState \
		-image [::crowImg::get_image close] \
		-command [list ::crowEditor::cut $editor]
		
	$wInfo(edit) add separator
	
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Jump To..."] \
		-state $editorState \
		-accelerator "Ctrl+g" \
		-command [list ::crowEditor::show_goto $editor ""]
		 	
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Find/Replace..."] \
		-state $editorState \
		-accelerator "Ctrl+f" \
		-command [list ::crowEditor::show_find $editor]
		
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Search In Files..."] \
		-image [::crowImg::get_image search_in_files] \
		-command [list ::frmSearchInFiles::show .crowSearchInFiles]
	
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Search Files..."] \
		-image [::crowImg::get_image search_files] \
		-command [list ::frmSearchFiles::show .crowSearchFiles]
				
	$wInfo(edit) add separator
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Select All"] \
		-state $editorState \
		-accelerator "Ctrl+a" \
		-command [list ::crowEditor::sel_all $editor]

	$wInfo(edit) add separator
	$wInfo(edit) add cascade -compound left -label [::msgcat::mc "Insert Macro"] \
		-state $editorState \
		-menu [::crowMacro::get_menu $fmeMenuBar::wInfo(edit).macros "" [list ::crowEditor::insert_macro $editor]]
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Save Macro"] \
		-state $selState \
		-command [list ::crowEditor::save_macro $editor]	
	$wInfo(edit) add separator
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Add Block Comment"] \
		-state $editorState \
		-command [list ::crowEditor::insert_comment $editor]
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Remove Block Comment"] \
		-state $editorState \
		-command [list ::crowEditor::remove_comment $editor]

	$wInfo(edit) add separator
	$wInfo(edit) add command -compound left -label [::msgcat::mc "Indent Selection"] \
		-state $editorState \
		-accelerator "Ctrl+Period" \
		-command [list ::crowEditor::insert_tab $editor]
	$wInfo(edit) add command -compound left -label [::msgcat::mc "UnIndent Selection"] \
		-state $editorState \
		-accelerator "Ctrl+Comma" \
		-command [list ::crowEditor::remove_tab $editor]
}

proc ::fmeMenuBar::file_init {} {
	variable wInfo
	set wInfo(file) [menu $wInfo(menubar).file -postcommand ::fmeMenuBar::file_post]
	set wInfo(fileNew) [menu $wInfo(file).new -postcommand ::fmeMenuBar::fileNew_post]
	set wInfo(fileOpen) [menu $wInfo(file).open -postcommand ::fmeMenuBar::fileOpen_post]
	set wInfo(fileFileRecently) [menu $wInfo(file).menuFileFileRecently \
		-postcommand [list ::fmeMenuBar::fileFileRecently_post $wInfo(file).menuFileFileRecently]]
	set wInfo(fileProjectRecently) [menu $wInfo(file).menuFileProjectRecently \
		-postcommand [list ::fmeMenuBar::fileProjectRecently_post $wInfo(file).menuFileProjectRecently]]
		
	$wInfo(fileOpen) add command -label [::msgcat::mc "Open File..."] \
		-compound left \
		-command {
			set ret [tk_getOpenFile -filetypes [list [list "All" "*.*"] ] -title [::msgcat::mc "Open File"]]
			if {$ret ne "" && $ret ne "-1" && [file exists $ret]} {::fmeProjectManager::file_open $ret}
		}
	$wInfo(fileOpen) add command -label [::msgcat::mc "Open Project..."] \
		-compound left \
		-command {::fmeProjectManager::project_open ""}	
}

proc ::fmeMenuBar::file_post {} {
	variable wInfo
	$wInfo(file) delete 0 end
	set prjPath [::fmeProjectManager::get_project_path]
	set currEditFile [::fmeTabEditor::get_curr_file]
	set prjState normal
	set nbState normal
	if {$::crowNoteBook::wInfo(CrowNoteBook,pages) == 0} {set nbState disabled}
	if {$prjPath eq ""} {set prjState disabled}
	set editorState $nbState
	if {$currEditFile eq ""} {set editorState disabled}
	$wInfo(file) add cascade -label [::msgcat::mc "New"] \
		-compound left \
		-menu $wInfo(fileNew)
	$wInfo(file) add cascade -label [::msgcat::mc "Open"] \
		-compound left \
		-menu $wInfo(fileOpen)
	$wInfo(file) add separator
	$wInfo(file) add command -label [::msgcat::mc "Close"] \
		-state $editorState \
		-image [::crowImg::get_image close] \
		-compound left \
		-accelerator "Ctrl+w" \
		-command {::fmeTabEditor::close_curr}
	$wInfo(file) add command -label [::msgcat::mc "Close All"] \
		-state $nbState \
		-compound left \
		-command {::fmeTabEditor::close_all}		
	$wInfo(file) add separator	
	$wInfo(file) add command -label [::msgcat::mc "Save"] \
		-state $editorState \
		-compound left \
		-image [::crowImg::get_image save] \
		-accelerator "Ctrl+s" \
		-command {::fmeTabEditor::save_curr}
	$wInfo(file) add command -label [::msgcat::mc "Save As ..."] \
		-state $editorState \
		-compound left \
		-command {
			set ret [tk_getSaveFile -filetypes [list [list "All" "*.*"] ] -title [::msgcat::mc "Save As"]]
			if {$ret ne "" && $ret ne "-1"} {
				set editor [::fmeTabEditor::get_curr_editor]
				if {$editor ne ""} {
					set fd [open $ret w]
					puts $fd [::crowEditor::dump_text $editor]
					close $fd
					
					::crowEditor::set_no_save $editor
					::fmeTabEditor::file_close [::fmeTabEditor::get_curr_file]
					::fmeProjectManager::file_open $ret
				}
			}
		}		
	$wInfo(file) add command -label [::msgcat::mc "Save All"] \
		-state $editorState \
		-compound left \
		-command {::fmeTabEditor::save_all}
	$wInfo(file) add separator
	$wInfo(file) add command -label [::msgcat::mc "Open Project..."] \
		-compound left \
		-image [::crowImg::get_image ofolder] \
		-command {::fmeProjectManager::project_open ""}
	$wInfo(file) add command -label [::msgcat::mc "Close Project"] \
		-state $prjState \
		-compound left \
		-command {::fmeProjectManager::project_close}
	$wInfo(file) add separator
	$wInfo(file) add cascade -label [::msgcat::mc "Recent Files"] \
		-compound left \
		-menu $wInfo(fileFileRecently)
	$wInfo(file) add cascade -label [::msgcat::mc "Recent Projects"] \
		-compound left \
		-menu $wInfo(fileProjectRecently)

	$wInfo(file) add separator
	$wInfo(file) add command -label [::msgcat::mc "Print..."] \
		-state $editorState \
		-image [::crowImg::get_image printer] \
		-compound left \
		-command {::fmeTabEditor::curr_show_print}

	#$wInfo(file) add command -label [::msgcat::mc "Printer Setup*"] \
	#	-compound left \
	#	-command {}			
	$wInfo(file) add separator
	$wInfo(file) add command -label [::msgcat::mc "Import..."] \
		-state $prjState \
		-compound left \
		-command {::fmeProjectManager::item_import ""}
	$wInfo(file) add separator		
	$wInfo(file) add command -label [::msgcat::mc "Exit"] \
		-compound left \
		-image [::crowImg::get_image exit] \
		-accelerator "Ctrl+q" \
		-command {::crowTde::destroy}
}

proc ::fmeMenuBar::fileFileRecently_post {parent} {
	set hlist [::crowRecently::get_recently_files]
	$parent delete 0 end
	foreach item $hlist {	
		$parent add command -compound left -label $item \
			-command [list ::fmeProjectManager::file_open $item]
	}
}

proc ::fmeMenuBar::fileNew_post {} {
	variable wInfo
	$wInfo(fileNew) delete 0 end
	set prjPath [::fmeProjectManager::get_project_path]
	$wInfo(fileNew) add command -label [::msgcat::mc "Project..."] \
		-compound left \
		-command {::fmeProjectManager::project_new}
	$wInfo(fileNew) add separator
	set prjState normal
	if {$prjPath eq ""} {set prjState disabled}
	set templs [::crowTemplate::item_ls]
	foreach t $templs {
		array set templ $t
		if {$templ(image) eq ""} {
			$wInfo(fileNew) add command -label $templ(name) \
				-compound left \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]			
		} else {
			$wInfo(fileNew) add command -label $templ(name) \
				-compound left \
				-image [::crowImg::get_image $templ(image)] \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]
		}
		array unset templ
	}
	$wInfo(fileNew) add separator

	$wInfo(fileNew) add command -label [::msgcat::mc "Folder..."] \
		-compound left \
		-image [::crowImg::get_image new_folder] \
		-state $prjState \
		-command {
			::fmeProjectManager::item_mkdir [::fmeProjectManager::get_curr_directory_item]
		}		
	return
}
	
proc ::fmeMenuBar::fileOpen_post {} {}

proc ::fmeMenuBar::fileProjectRecently_post {parent} {
	set hlist [::crowRecently::get_recently_projects]
	$parent delete 0 end
	foreach item $hlist {	
		$parent add command -compound left -label $item \
			-command [list ::fmeProjectManager::project_open $item]
	}
}

proc ::fmeMenuBar::help_init {} {
	variable wInfo
	set ::fmeMenuBar::wInfo(help) [menu $::fmeMenuBar::wInfo(menubar).help]
	$wInfo(help) add command -compound left -label [::msgcat::mc "Help"] \
		-command {::fmeTabMgr::page_raise2 "pageDocView"}
	$wInfo(help) add separator
	$wInfo(help) add command -compound left -label [::msgcat::mc "About..."] \
		-command {::frmAbout::show .aboutCrowTDE}
#	$wInfo(help) add command -compound left -label [::msgcat::mc "Test"] \
#		-command {
#			puts "gogo"
#			interp alias slave ::frmAbout::show {} ::frmAbout::show .aboutCrowTDE
#			::tkcon::EvalSlave uplevel "#0" ::frmAbout::show
##			::tkcon::EvalSlave uplevel "#0" [list while {[incr i -1]} {continue}]
#			puts "done"
#		}
}

proc ::fmeMenuBar::options_init {} {
	variable wInfo
	set wInfo(options) [menu $wInfo(menubar).options -postcommand ::fmeMenuBar::options_post]
}

proc ::fmeMenuBar::options_set_color_enable_all {flag} {
	set editors [::fmeTabEditor::get_all_editor]
	foreach editor $editors {::crowEditor::set_color_state $editor $flag}
	set editor [::fmeTabEditor::get_curr_editor]
	after idle [list ::crowEditor::highlight_curr_view $editor]
}

proc ::fmeMenuBar::options_post {} {
	variable wInfo	
	set editor [::fmeTabEditor::get_curr_editor]
	
	$wInfo(options) delete 0 end
	
	#<- 
	if {[winfo exists $wInfo(options).menuSyntax] } {destroy $wInfo(options).menuSyntax}
	set menuSyntax [menu $wInfo(options).menuSyntax ]
	if {$editor ne ""} {
		set colorEnable [::crowEditor::get_color_state $editor]
		if {$colorEnable} {
			$menuSyntax add command -compound left -label [::msgcat::mc "Disabled Current Editor"] \
				-command [list ::crowEditor::set_color_state $editor 0] 
		} else {
			$menuSyntax add command -compound left -label [::msgcat::mc "Enabled Current Editor"] \
				-command [list ::crowEditor::set_color_state $editor 1]
		}
		$menuSyntax add separator
		$menuSyntax add command -compound left -label [::msgcat::mc "Diabled All"] \
			-command [list ::fmeMenuBar::options_set_color_enable_all 0] 
	$menuSyntax add command -compound left -label [::msgcat::mc "Enabled All"] \
			-command [list ::fmeMenuBar::options_set_color_enable_all 1] 
		
	$menuSyntax add separator
	}
	
	$menuSyntax add radiobutton -label [::msgcat::mc "Default Enabled"] \
		 -variable ::crowEditor::colorEnabled -value 1 -command [list ::crowEditor::set_color_default_state 1]
	$menuSyntax add radiobutton -label [::msgcat::mc "Default Disabled"] \
		 -variable ::crowEditor::colorEnabled -value 0 -command [list ::crowEditor::set_color_default_state 0]	
	$wInfo(options) add cascade -label [::msgcat::mc "Syntax Highlight"] -menu $menuSyntax
	$wInfo(options) add separator
	#->
	
	# <!--
	if {[winfo exists $wInfo(options).menuEditor] } {destroy $wInfo(options).menuEditor}
	set menuEditor [menu $wInfo(options).menuEditor ]
	set val [::crowEditor::get_lineBox_state]
	if {$val} {
			set cmd ::crowEditor::lineBox_hide
	} else {
			set cmd ::crowEditor::lineBox_show
	}
	$menuEditor add checkbutton -label [::msgcat::mc "Show Line Number"] \
		-variable ::crowEditor::showLineBox \
		-command $cmd
	set val [::crowEditor::get_synHelper_state]
	$menuEditor add checkbutton -label [::msgcat::mc "Show Syntax Helper"] \
		-variable ::crowEditor::synHelperEnabled \
		-command [list ::crowEditor::set_synHelper_state 	[expr !$val]]
	
	if {[winfo exists $menuEditor.mTabwidth] } {destroy $menuEditor.mTabwidth}
	set mTabwidth [menu $menuEditor.mTabwidth]
	set rc [file join $::env(HOME) ".CrowTDE" "CrowEditor.rc"]
	foreach w [list 4 6 8 10 12] {
		$mTabwidth add radiobutton -label $w -value $w -variable ::crowEditor::tabWidth \
			-command [list ::crowRC::param_set $::crowEditor::rc CrowEditor.TabWidth $w]
	}	
	$menuEditor add cascade -label [::msgcat::mc "Adjust Tab Width"] -menu $mTabwidth
		
	$wInfo(options) add cascade -label [::msgcat::mc "Editor Details"] -menu $menuEditor	
	#-->	
	
	if {[winfo exists $wInfo(options).menuToolbar] } {destroy $wInfo(options).menuToolbar}
	set menuToolbar [menu $wInfo(options).menuToolbar ]
	set val [::crowTde::get_toolbar_state]
	if {$val} {
		$menuToolbar add command -label [::msgcat::mc "Collapse Toolbar"] \
			-command {::crowTde::toolbar_collapse}
	} else {
		$menuToolbar add command -label [::msgcat::mc "Expand Toolbar"] \
			-command {::crowTde::toolbar_expand}
	}
	$wInfo(options) add cascade -label [::msgcat::mc "Toolbar Details"] -menu $menuToolbar

	if {[winfo exists $wInfo(options).menuProc] } {destroy $wInfo(options).menuProc}
	set menuProc [menu $wInfo(options).menuProc ]
	set val [::fmeProcManager::get_interval]
	$menuProc add command -label [::msgcat::mc "Refresh Interval (%s ms)" $val] \
		-command {::fmeProcManager::set_interval ""}
	$wInfo(options) add cascade -label [::msgcat::mc "Proc Details"] -menu $menuProc
	
	
	
	if {[winfo exists $wInfo(options).menuMP3] } {destroy $wInfo(options).menuMP3}
	set menuMP3 [menu $wInfo(options).menuMP3 ]
	set val [::fmePlayer::get_directory]
	$menuMP3 add command -label [::msgcat::mc "MP3 Directory - %s" $val] \
		-command {::fmePlayer::set_directory ""}
	if {[package versions snack] eq ""} {
		$wInfo(options) add cascade -label [::msgcat::mc "MP3 Player Details"] -state disabled
	} else {
		$wInfo(options) add cascade -label [::msgcat::mc "MP3 Player Details"] -menu $menuMP3
	}
	$wInfo(options) add separator	
	#$wInfo(options) add command -label [::msgcat::mc "File Relation"] -command {::frmSetting::show ".settings"}
	#$wInfo(options) add separator
	$wInfo(options) add command -compound left -label [::msgcat::mc "Settings..."] \
		-image [::crowImg::get_image settings] \
		-command {::frmSetting::show ".settings"}
	$wInfo(options) add separator
	
	
	if {[winfo exists $wInfo(options).menuLanguage] } {destroy $wInfo(options).menuLanguage}
	set menuLanguage [menu $wInfo(options).menuLanguage ]

	set tblLocale [file join $::crowTde::appPath locale list.txt]
	set fd [open $tblLocale r]
	set localeInfo [split [read $fd] "\n"]
	close $fd
	foreach item $localeInfo {
		set linfo [split $item ":"]
		if {[llength $linfo] != 2} {continue}
		foreach {locale language} $linfo {}
		$menuLanguage add radiobutton -label $language \
		 	-variable ::crowTde::locale -value $locale -command {
		 		tk_messageBox -type ok -title [::msgcat::mc "Locale"] \
		 			-message [::msgcat::mc "The settings will apply at restart CrowTDE!"]
		 }
	}

	$wInfo(options) add cascade -label [::msgcat::mc "Language"] -menu $menuLanguage
}

proc ::fmeMenuBar::project_init {} {
	variable wInfo
	set wInfo(project) [menu $wInfo(menubar).project -postcommand ::fmeMenuBar::project_post]
	set wInfo(projectTask) [menu $wInfo(menubar).task ]
	$wInfo(projectTask) add command -compound left -label [::msgcat::mc "Add Task"] \
		-accelerator "Insert" \
		-command {::fmeTask::task_add}
	$wInfo(projectTask) add command -compound left -label [::msgcat::mc "Delete Completed Tasks"] \
		-command {::fmeTask::task_del_completed}
	$wInfo(projectTask) add command -compound left -label [::msgcat::mc "Refresh"] \
		-command {::fmeTask::refresh}				
}

proc ::fmeMenuBar::project_post {} {
	variable wInfo
	$wInfo(project) delete 0 end
	set currPath [::fmeProjectManager::get_curr_file]
	set currItem [::fmeProjectManager::get_curr_item]
	set prjPath [::fmeProjectManager::get_project_path]
	
	set prjState normal
	if {$prjPath eq ""} { set prjState disabled}
	
	set fname ""
	if {$currPath ne ""} {
		append fname [string range $currPath [expr [string length $prjPath]+1] end]
	}
	set itemState normal
	if {$fname eq "" || [file isdirectory $currPath]} {set itemState disabled}
	
	set editorState normal
	if {[::fmeTabEditor::get_curr_editor] eq ""} {set editorState disabled}
	
	$wInfo(project) add command -compound left -label [::msgcat::mc "Run..."] \
		-state $itemState \
		-accelerator "F4" \
		-command {::fmeTabEditor::curr_eval}
		
	$wInfo(project) add command -compound left -label [::msgcat::mc "Run Default Script..."] \
		-state $prjState \
		-accelerator "F5" \
		-command {::fmeProjectManager::project_run}
#	$wInfo(project) add separator
	$wInfo(project) add command -compound left -label [::msgcat::mc "Syntax Check..."] \
		-state $itemState \
		-command {::fmeNagelfar::check [::fmeTabEditor::get_curr_file]}
	
	$wInfo(project) add separator
	if {$prjPath ne ""} {
		$wInfo(project) add command -compound left -label [::msgcat::mc "Build Project..." ] \
			-command [list ::fmeProjectManager::wrap_dir $prjPath]
	}
	if {[file isfile $currPath]} {
		set fpath [::fmeTabEditor::get_curr_file]
		if {$fpath ne "" && [file exists $fpath]} {
			$wInfo(project) add command -compound left -label [::msgcat::mc "Build ' %s ' ..." [file tail $fpath]] \
				-command [list ::crowSdx::wrap_file $fpath]
		} else {
			$wInfo(project) add command -compound left -label [::msgcat::mc "Build ..."] \
				-state disabled \
				-command {}			
		}
	} elseif {[file isdirectory $currPath] && $currPath ne $prjPath} {
		$wInfo(project) add command -compound left -label [::msgcat::mc "Build ' %s ' ..." $fname] \
			-command [list ::fmeProjectManager::wrap_dir $currPath]		
	} else {
		$wInfo(project) add command -compound left -label [::msgcat::mc "Build ..."] \
			-state disabled		
	}		
					
	#<!---
	$wInfo(project) add separator
	set templs [::crowTemplate::item_ls]
	foreach t $templs {
		array set templ $t
		if {$templ(image) eq ""} {
 			$wInfo(project) add command -label [::msgcat::mc "Add %s" $templ(name)] \
				-compound left \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]
			
		} else {
 			$wInfo(project) add command -label [::msgcat::mc "Add %s" $templ(name)] \
				-compound left \
				-image [::crowImg::get_image $templ(image)] \
				-state $prjState \
				-command [list ::fmeProjectManager::item_add [::fmeProjectManager::get_curr_directory_item] $templ(path)]
		}
		array unset templ
	}
	#-->
	
	#<!---
	$wInfo(project) add separator
	$wInfo(project) add command -compound left -label [::msgcat::mc "Set ' %s ' As Default Script" $fname] \
		-state $itemState \
		-command [list ::fmeProjectManager::set_project_mainScript $fname]
	#-->
	
	#<!--
	$wInfo(project) add separator
	set itemState normal
	if {$currItem eq ""} {set itemState disabled}
	if {$currPath eq $prjPath} {set itemState disabled}
	$wInfo(project) add command -compound left -label [::msgcat::mc "Delete ' %s '" $fname] \
		-image [::crowImg::get_image del] \
		-state $itemState \
		-command [list ::fmeProjectManager::item_del $currItem]
	#-->
	
	#<!--
	#$wInfo(project) add separator
	#$wInfo(project) add command -compound left -label [::msgcat::mc "freewrap*"] \
	#	-state $prjState \
	#	-command {}
	#$wInfo(project) add command -compound left -label [::msgcat::mc "Version Control*"] \
	#	-state $prjState \
	#	-command {}
	$wInfo(project) add separator
	$wInfo(project) add cascade -compound left -label [::msgcat::mc "Tasks"] \
		-state $prjState \
		-menu $wInfo(projectTask)
	$wInfo(project) add separator
	$wInfo(project) add command -compound left -label [::msgcat::mc "Properties..."] \
		-image [::crowImg::get_image project_properties] \
		-state $prjState \
		-command {::frmProjectProperty::show ".frmProjectProperty"}
	#-->
}

proc ::fmeMenuBar::tools_init {} {
	variable wInfo
	set wInfo(tools) [menu $wInfo(menubar).tools -postcommand ::fmeMenuBar::tools_post]
	$wInfo(tools) add command -compound left -label "Visual Regexp"\
		-command {exec "wish" [file join $::crowTde::appPath tools "visual_regexp.tcl"] &}	
	$wInfo(tools) add command -compound left -label "TkCon"\
		-command {exec "wish" [file join $::crowTde::appPath tools tkcon.tcl] &}	
}

proc ::fmeMenuBar::tools_post {} {
}

proc ::fmeMenuBar::windows_init {} {
	variable wInfo
	set wInfo(windows) [menu $wInfo(menubar).windows -postcommand ::fmeMenuBar::windows_post]
	set menuRaise [menu $wInfo(windows).raise ]
	set menuClose [menu $wInfo(windows).close ]
	$wInfo(windows) add command -label [::msgcat::mc "Next Page"] \
		-command {::fmeTabEditor::raise_next} -accelerator "Ctrl + Right"
	$wInfo(windows) add command -label [::msgcat::mc "Previous Page"] \
		-command {::fmeTabEditor::raise_prev} -accelerator "Ctrl + Left"
	$wInfo(windows) add separator
	$wInfo(windows) add cascade -label [::msgcat::mc "Raise"] -menu $menuRaise
	$wInfo(windows) add separator
	$wInfo(windows) add cascade -label [::msgcat::mc "Close"] -menu $menuClose
	$wInfo(windows) add separator
	$wInfo(windows) add command -compound left -label [::msgcat::mc "Close All"] \
		-command [list ::fmeTabEditor::close_all]
}

proc ::fmeMenuBar::windows_post {} {
	variable wInfo
	set editor [::fmeTabEditor::get_curr_editor]
	set editorState normal
	if {$editor eq ""} {set editorState disabled}
	#<!-- 
	$wInfo(windows) entryconfigure 0 -state $editorState 
	$wInfo(windows) entryconfigure 1 -state $editorState
	#-->
	set flist [::fmeTabEditor::get_all_file]
	set menuRaise $wInfo(windows).raise
	$menuRaise delete 0 end
	set dname [::fmeProjectManager::get_project_path]
	#puts dname=$dname	
	set lbl ""
	foreach item $flist {
		regsub $dname $item {} lbl
		set lbl [string trimleft $lbl "/"]
		$menuRaise add command -compound left -label $lbl \
			-command [list ::fmeTabEditor::file_raise $item]
		
	}
	set menuClose $wInfo(windows).close
	$menuClose delete 0 end
	foreach item $flist {
		regsub $dname $item {} lbl	
			set lbl [string trimleft $lbl "/"]
		$menuClose add command -compound left -label $lbl \
			-command [list ::fmeTabEditor::file_close $item]
		
	}
}


