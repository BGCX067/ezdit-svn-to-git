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

namespace eval ::fmeDebugger {
	variable wInfo
	array set wInfo ""
	
	variable varsCache
	array set varsCache [list local ""]
	
	variable watchpoints
	array set watchpoints ""
	
	variable varLocals
	array set varLocals ""
}

proc ::fmeDebugger::breakpoint_add {script pos} {
	set tree $::fmeDebugger::wInfo(tree)
	set parent $::fmeDebugger::wInfo(nodeBreakpoint)
	set item [$tree item create -parent $parent -button no]
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
#	$tree item lastchild $parent $item
	$tree item element configure $item 0 eImg -image [::crowImg::get_image breakpoint]
	$tree item element configure $item 0 eTxt -text $script
	$tree item element configure $item 1 eTxt -text $pos -data $pos
	return $item	
}

proc ::fmeDebugger::breakpoint_goto {script pos} {
	variable wInfo
	set tree $wInfo(tree)
	::fmeTabEditor::file_open $script
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::goto_pos $editor $pos
	return
}

proc ::fmeDebugger::breakpoint_load {} {
	set prjPath [::fmeProjectManager::get_project_path]
	if {$prjPath ne "" && [file exists $prjPath]} {
		set wp [file join $prjPath ".__meta__" "Debugger.rc"]
		foreach {bp} [lindex [::crowRC::param_get $wp Breakpoints] 0] {
			foreach {script pos} $bp {break}
			::crowDebugger::breakpoint_add $script $pos
		}
	}
}

proc ::fmeDebugger::breakpoint_refresh {name1 name2 op} {
	set tree $::fmeDebugger::wInfo(tree)	
	foreach item [$tree item children $::fmeDebugger::wInfo(nodeBreakpoint)] {
		$tree item delete $item
	}

	foreach {key val} [array get ::crowDebugger::breakpoints] {
		foreach {script pos} $key {break}
		set item [::fmeDebugger::breakpoint_add $script $pos]
	}
	::fmeDebugger::breakpoint_save
	return
}

proc ::fmeDebugger::breakpoint_save {} {
	set prjPath [::fmeProjectManager::get_project_path]
	if {$prjPath ne "" && [file exists $prjPath]} {
		set wp [file join $prjPath ".__meta__" "Debugger.rc"]
		::crowRC::param_set $wp Breakpoints [format "{%s}" [array names ::crowDebugger::breakpoints]]
	}
	return
}

proc ::fmeDebugger::init {path} {	
	variable wInfo
	
	set fmeMain [frame $path]	
	
	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief groove]
	set btnStart [menubutton $fmeBtn.btnStart -direction below -width 20 -height 20 \
		-image [::crowImg::get_image debugger_start] \
		-bd 1 -relief raised  -menu {}]
	$btnStart configure -menu [menu $btnStart.menu -postcommand ::fmeDebugger::start_menu_post -tearoff 0]
		
	set btnFreeGo [button $fmeBtn.btnFreeGo -width 20 -height 20 \
		-state disabled \
		-image [::crowImg::get_image debugger_free_go] \
		-command ::fmeDebugger::free_go]
	set btnPause [button $fmeBtn.btnPause -width 20 -height 20 \
		-state disabled \
		-image [::crowImg::get_image debugger_pause] \
		-command ::fmeDebugger::pause]
	set btnStep [button $fmeBtn.btnStep -width 20 -height 20 \
		-state disabled \
		-image [::crowImg::get_image debugger_step] \
		-command ::fmeDebugger::step]
	set btnStop [button $fmeBtn.btnStop -width 20 -height 20 \
		-state disabled \
		-image [::crowImg::get_image debugger_stop] \
		-command ::fmeDebugger::stop]
	set btnSettings [menubutton $fmeBtn.btnSettings -direction below -width 20 -height 20 \
		-image [::crowImg::get_image debugger_settings] \
		-bd 1 -relief raised  -menu {}]
	set m [menu $btnSettings.menu -tearoff 0]
	$btnSettings configure -menu $m
	$m add  radiobutton  -label [::msgcat::mc "Shallow"] \
		-variable ::crowDebugger::sysInfo(mode) -value "SHALLOW" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}
	$m add  radiobutton  -label [::msgcat::mc "Normal"] \
		-variable ::crowDebugger::sysInfo(mode) -value "NORMAL" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}
	$m add  radiobutton  -label [::msgcat::mc "Deep"] \
		-variable ::crowDebugger::sysInfo(mode) -value "DEEP" \
		-command {
			set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
			::crowRC::param_set $rc CrowTDE.DebugMode $::crowDebugger::sysInfo(mode)
		}		

	bind $btnStart <Enter> [list puts sbar msg [::msgcat::mc "Start Debugger"]]
	bind $btnFreeGo <Enter> [list puts sbar msg [::msgcat::mc "Free go"]]
	bind $btnPause <Enter> [list puts sbar msg [::msgcat::mc "Pause"]]
	bind $btnStep <Enter> [list puts sbar msg [::msgcat::mc "Step"]]
	bind $btnStop <Enter> [list puts sbar msg [::msgcat::mc "Stop debugging"]]	
	bind $btnSettings <Enter> [list puts sbar msg [::msgcat::mc "Debug level"]]	

	DynamicHelp::add $btnStart -text [::msgcat::mc "Start Debugger"]
	DynamicHelp::add $btnFreeGo -text [::msgcat::mc "Free go"]
	DynamicHelp::add $btnPause -text [::msgcat::mc "Pause"]
	DynamicHelp::add $btnStep -text [::msgcat::mc "Step"]
	DynamicHelp::add $btnStop -text [::msgcat::mc "Stop debugging"]
	DynamicHelp::add $btnSettings -text [::msgcat::mc "Debug level"]

	pack $btnStart -padx 2 -pady 1 -side left
	pack $btnFreeGo -padx 2 -pady 1 -side left
	pack $btnPause -padx 2 -pady 1 -side left
	pack $btnStep -padx 2 -pady 1 -side left
	pack $btnStop -padx 2 -pady 1 -side left
	pack $btnSettings -padx 2 -pady 1 -side left
	
	set wInfo(btnStart) $btnStart
	set wInfo(menuBtnStart) [$btnStart cget -menu]
	set wInfo(btnFreeGo) $btnFreeGo
	set wInfo(btnPause) $btnPause
	set wInfo(btnStep) $btnStep
	set wInfo(btnStop) $btnStop
	set wInfo(btnSettings) $btnSettings
	
	pack $fmeBtn -fill x -pady 2
	
	set fmePW [PanedWindow $fmeMain.pw -side right]
	$fmePW add -weight 1
	$fmePW add
	
	
	set sw [ScrolledWindow [$fmePW getframe 0].sw -bd 2 -relief groove]
	set tree [treectrl $sw.treeL \
		-showroot no \
		-linestyle dot \
		-selectmod browse \
		-showrootbutton no \
		-showbuttons yes \
		-showheader yes \
		-showlines no \
		-scrollmargin 16 \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50" \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-bd 1]

	$sw setwidget $tree
	set wInfo(tree) $tree
	pack $sw -expand 1 -fill both

	$tree column create -tag cName -expand yes -text "Name"
	$tree column create -tag cValue -expand yes -text "Value"
	$tree element create eImg image -height 24 -width 24
	$tree element create eTxt text -fill [list black {selected focus}] -justify left
	$tree element create eRect rect -open news -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn cName
	
	$tree style create sName
	$tree style elements sName {eRect eImg eTxt}
	$tree style layout sName eImg -padx {0 4} -expand ns
	$tree style layout sName eTxt -padx {0 4} -expand ns
	$tree style layout sName eRect -union {eImg eTxt} -iexpand news -ipadx 2

	
	$tree style create sValue
	$tree style elements sValue {eRect eTxt}
	$tree style layout sValue eTxt -padx {0 4} -expand ns
	$tree style layout sValue eRect -union {eTxt} -iexpand news -ipadx 2
	
	set item [$tree item create -button yes]
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
	$tree item lastchild 0 $item
	$tree item element configure $item 0 eImg \
		-image [list [::crowImg::get_image debug_owatchs] {open} [::crowImg::get_image debug_cwatchs] {}]
	$tree item element configure $item 0 eTxt -text [::msgcat::mc "Watch Variables"]
	$tree item element configure $item 1 eTxt -text "" -data ""
	set wInfo(nodeWatchpoint) $item 	
	
	set item [$tree item create -button yes]
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
	$tree item lastchild 0 $item
	$tree item element configure $item 0 eImg \
		-image [list [::crowImg::get_image debug_olocals] {open} [::crowImg::get_image debug_clocals] {}]
	$tree item element configure $item 0 eTxt -text [::msgcat::mc "Currently-Visible Variables"]
	$tree item element configure $item 1 eTxt -text "" -data ""
	set wInfo(nodeVars) $item 
	
	set item [$tree item create -button yes]
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
	$tree item lastchild 0 $item
	$tree item element configure $item 0 eImg \
		-image [list [::crowImg::get_image debug_oglobals] {open} [::crowImg::get_image debug_cglobals] {}]
	$tree item element configure $item 0 eTxt -text [::msgcat::mc "Breakpoints"]
	$tree item element configure $item 1 eTxt -text "" -data ""
	set wInfo(nodeBreakpoint) $item
	
	$tree notify bind $tree <ActiveItem> {
		set txt $::fmeDebugger::wInfo(txt)
		$txt configure -state normal
		$txt delete 1.0 end
		
		set data [%T item element cget %c 1 eTxt -data]
		$txt insert end $data
		$txt configure -state disabled
	}
	bind $tree <F2> {
		set tree %W
		set item [$tree selection get]
		if {$item ne ""} {
			set parent [$tree item parent $item]
			set nodeWatchpoint $::fmeDebugger::wInfo(nodeWatchpoint)
			set nodeVars $::fmeDebugger::wInfo(nodeVars)
			if {$parent eq $nodeWatchpoint} {
				::fmeDebugger::var_set "VAR" $item
			}
			if {[$tree item parent $parent] eq $nodeWatchpoint} {
				::fmeDebugger::var_set "ARRAY" $item
			}
			if {$parent eq $nodeVars} {
				::fmeDebugger::var_set "VAR" $item
			}
			if {[$tree item parent $parent] eq $nodeVars} {
				::fmeDebugger::var_set "ARRAY" $item
			}
		 }
	}

	bind $tree <Delete> {
		set tree %W
		set item [$tree selection get]
		if {$item ne ""} {
			set parent [$tree item parent $item]
			set nodeWatchpoint $::fmeDebugger::wInfo(nodeWatchpoint)
			set nodeBreakpoint $::fmeDebugger::wInfo(nodeBreakpoint)
			if {$parent eq $nodeWatchpoint} {
				::fmeDebugger::watchpoint_del $item
			}
			if {$parent eq $nodeBreakpoint} {
				set script [$tree item element cget $item 0 eTxt -text]
				set pos [$tree item element cget $item 1 eTxt -text]
				::crowDebugger::breakpoint_del $script $pos
			}
		 }
	}


	bind $tree <ButtonRelease-3> {::fmeDebugger::item_btn3_click %x %y %X %Y} 
	
	set sw2 [ScrolledWindow [$fmePW getframe 1].sw2 -bd 2 -relief groove]
	set txt [text $sw2.txt -bd 1 -relief groove -highlightthickness 0 -state disabled -height 1]
	$sw2 setwidget $txt
	set wInfo(txt) $txt
	pack $sw2 -expand 1 -fill both
		
	pack $fmePW -expand 1 -fill both

	set fmeInfo [frame $fmeMain.fmeInfo -bd 2 -relief groove]
	set lblScript [label $fmeInfo.lblScript -text [::msgcat::mc "Script:"] -anchor w -justify left]
	set txtScript [label $fmeInfo.txtScript -textvariable ::fmeDebugger::wInfo(txtScript,var) -anchor w -justify left]
#	set lblPos [label $fmeInfo.lblPos -text [::msgcat::mc "Position:"] -anchor w -justify left]
#	set txtPos [label $fmeInfo.txtPos -textvariable ::fmeDebugger::wInfo(txtPos,var) -anchor w -justify left]	
#	set lblLines [label $fmeInfo.lblLines -text [::msgcat::mc "Lines:"] -anchor w -justify left]
#	set txtLines [label $fmeInfo.txtLines -textvariable ::crowDebugger::loadProgress -anchor w -justify left]

	grid $lblScript $txtScript -sticky "news"
#	grid $lblPos $txtPos -sticky "news"
#	grid $lblLines $txtLines -sticky "news"
	grid columnconfigure $fmeInfo 1 -weight 1
	pack $fmeInfo -fill both -pady 1
	
	trace add variable ::crowDebugger::breakpoints array {::fmeDebugger::breakpoint_refresh}
	trace add variable ::crowDebugger::watchpoints write {::fmeDebugger::watchpoint_refresh}
	trace add variable ::crowDebugger::sysInfo(start) write {::fmeDebugger::refresh}
	trace add variable ::crowDebugger::sysInfo(currPos) write {::fmeDebugger::refresh}
	trace add variable ::crowDebugger::sysInfo(cmdlen) write {::fmeDebugger::refresh}
	trace add variable ::crowDebugger::sysInfo(locals) write {::fmeDebugger::refresh}

	return $fmeMain
}

proc ::fmeDebugger::item_btn3_click {posx posy posX posY} {
	variable wInfo
	set tree $wInfo(tree)
	set ninfo [$tree identify $posx $posy]
	if {$ninfo eq ""} {
		if {[winfo exists $tree.mWatch]} {destroy $tree.mWatch}
		set m [menu $tree.mWatch]
		$m add command -label [::msgcat::mc "Add Watch..."] \
			-command [list ::fmeDebugger::watchpoint_add]
		tk_popup $m $posX $posY	
		return
	}
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		$tree selection clear
		$tree selection add $itemId
		set parent [$tree item parent $itemId]
		set debugState disabled
		if {$::crowDebugger::sysInfo(start)} {
			set debugState normal
		}
		
	
		if {$parent eq $wInfo(nodeWatchpoint) || $itemId eq $wInfo(nodeWatchpoint)} {
			if {[winfo exists $tree.mWatch]} {destroy $tree.mWatch}
			set m [menu $tree.mWatch]

			$m add command -label [::msgcat::mc "Add Watch..."] \
				-command [list ::fmeDebugger::watchpoint_add]
			if {$parent eq $wInfo(nodeWatchpoint)} {
				$m add command -label [::msgcat::mc "Remove Watch"] \
					-accelerator "Del" \
					-command [list ::fmeDebugger::watchpoint_del $itemId]
				$m add separator
				$m add command -label [::msgcat::mc "Change Value..."] \
					-accelerator "F2" \
					-state $debugState \
					-command [list ::fmeDebugger::var_set "VAR" $itemId]
			}
			tk_popup $m $posX $posY
			return
		}

		if {[$tree item parent $parent] eq $wInfo(nodeWatchpoint)} {
			if {[winfo exists $tree.mWatch]} {destroy $tree.mWatch}
			set m [menu $tree.mWatch]

			$m add command -label [::msgcat::mc "Add Watch..."] \
				-command [list ::fmeDebugger::watchpoint_add]

			$m add command -label [::msgcat::mc "Change Value..."] \
				-accelerator "F2" \
				-state $debugState \
				-command [list ::fmeDebugger::var_set "ARRAY" $itemId]

			tk_popup $m $posX $posY
			return
		}

		if {$parent eq $wInfo(nodeBreakpoint)} {
			if {[winfo exists $tree.mBreakpoint]} {destroy $tree.mBreakpoint}
			set m [menu $tree.mBreakpoint]
			set script [$tree item element cget $itemId 0 eTxt -text]
			set pos [$tree item element cget $itemId 1 eTxt -text]
			
			$m add command -label [::msgcat::mc "View"] \
				-command [list ::fmeDebugger::breakpoint_goto $script $pos]
			$m add separator	
			$m add command -label [::msgcat::mc "Remove"] \
				-accelerator "Del" \
				-command [list ::crowDebugger::breakpoint_del $script $pos]
			
			tk_popup $m $posX $posY
			return			
		}		
		
		if {$parent eq $wInfo(nodeVars)} {
			if {[winfo exists $tree.mLocal]} {destroy $tree.mLocal}
			set m [menu $tree.mLocal]

			$m add command -label [::msgcat::mc "Change Value..."] \
				-accelerator "F2" \
				-state $debugState \
				-command [list ::fmeDebugger::var_set "VAR" $itemId]
			tk_popup $m $posX $posY
			return
		}
		
		if {[$tree item parent $parent] eq $wInfo(nodeVars)} {
			if {[winfo exists $tree.mLocal]} {destroy $tree.mLocal}
			set m [menu $tree.mLocal]

			$m add command -label [::msgcat::mc "Change Value..."] \
				-accelerator "F2" \
				-state $debugState \
				-command [list ::fmeDebugger::var_set "ARRAY" $itemId]
			tk_popup $m $posX $posY
			return			
		}
	}
	return
}

proc ::fmeDebugger::refresh {name1 name2 op} {
	set tree $::fmeDebugger::wInfo(tree)
	switch -exact -- $name2 {
		"start" {
			if {$::crowDebugger::sysInfo(start)} {
				# STARTED
				$::fmeDebugger::wInfo(btnStart) configure -state disabled
				$::fmeDebugger::wInfo(btnFreeGo) configure -state normal
				$::fmeDebugger::wInfo(btnPause) configure -state disabled
				$::fmeDebugger::wInfo(btnStep) configure -state normal
				$::fmeDebugger::wInfo(btnStop) configure -state normal
				$::fmeDebugger::wInfo(btnStop) configure -state normal
				$::fmeDebugger::wInfo(btnSettings) configure -state disabled
				::fmeTabEditor::file_open $::crowDebugger::sysInfo(script)
				::crowEditor::visibility [::fmeTabEditor::get_curr_editor]
				update
			} else {
				# STOPED
				$::fmeDebugger::wInfo(btnStart) configure -state normal
				$::fmeDebugger::wInfo(btnFreeGo) configure -state disabled
				$::fmeDebugger::wInfo(btnPause) configure -state disabled
				$::fmeDebugger::wInfo(btnStep) configure -state disabled
				$::fmeDebugger::wInfo(btnStop) configure -state disabled
				$::fmeDebugger::wInfo(btnSettings) configure -state normal			
			}
		}
		"currPos" {
			set fpath [::fmeTabEditor::get_curr_file]
			if {$fpath ne $::crowDebugger::sysInfo(script)} {
				::fmeTabEditor::file_open $::crowDebugger::sysInfo(script)
				update
			}
			set editor [::fmeTabEditor::get_curr_editor]
			set ::fmeDebugger::wInfo(txtScript,var) [file tail $::crowDebugger::sysInfo(script)]
			$::fmeDebugger::wInfo(btnStart) configure -state disabled
			$::fmeDebugger::wInfo(btnFreeGo) configure -state normal
			$::fmeDebugger::wInfo(btnPause) configure -state disabled
			$::fmeDebugger::wInfo(btnStep) configure -state normal
			$::fmeDebugger::wInfo(btnStop) configure -state normal
			$::fmeDebugger::wInfo(btnStop) configure -state normal
			$::fmeDebugger::wInfo(btnSettings) configure -state disabled			
#			set ::fmeDebugger::wInfo(txtPos,var) $::fmeStatusBar::vars(currpos)
			::fmeDebugger::text_update
			::crowEditor::goto_pos $editor $::crowDebugger::sysInfo(currPos)
		}
		"cmdlen" {}
		"locals" {
			array set oLocals $::fmeDebugger::varsCache(local)
			set ::fmeDebugger::varsCache(local) ""
			foreach {key vinfo} $::crowDebugger::sysInfo(locals) {
				foreach {type val} $vinfo {break}
				if {[info exists oLocals($key,$type)]} {
					set itemId $oLocals($key,$type)     ;# do not remove this
					::fmeDebugger::var_update $itemId $type $key $val
					unset oLocals($key,$type)
				} else { 
					set itemId [::fmeDebugger::var_add $::fmeDebugger::wInfo(nodeVars) $type $key $val]
				}
				lappend ::fmeDebugger::varsCache(local) $key,$type $itemId
			}
			foreach {key itemId} [array get oLocals] {$tree item delete $itemId}
			array unset oLocals
		}
		default {
			# do not thing
		}
	}
	foreach {key val} [array get ::fmeDebugger::wInfo node*] {
		$tree item sort  $val -increasing -column 0 -dictionary
	}
	array unset wCache
	array unset oCache
	
	return
}

#######################################
# public operations
#######################################

proc ::fmeDebugger::free_go {} {
	variable wInfo
	if {![catch {::crowDebugger::free_go}]} {
		$wInfo(btnStart) configure -state disabled
		$wInfo(btnFreeGo) configure -state disabled
		$wInfo(btnPause) configure -state normal
		$wInfo(btnStep) configure -state disabled
		$wInfo(btnStop) configure -state normal			
	}
	return
}

proc ::fmeDebugger::pause {} {
	variable wInfo
	if {![catch {::crowDebugger::pause}]} {
		$wInfo(btnStart) configure -state disabled
		$wInfo(btnFreeGo) configure -state normal
		$wInfo(btnPause) configure -state disabled
		$wInfo(btnStep) configure -state normal
		$wInfo(btnStop) configure -state normal	
	}
	::crowDebugger::pause
	return	
}

proc ::fmeDebugger::start {fpath} {
	::fmeTabMgr::page_raise [::msgcat::mc "Debug"]
	update
	
	::crowDebugger::start $fpath 
	
	return
}

proc ::fmeDebugger::step {} {
	::crowDebugger::step
	return	
}

proc ::fmeDebugger::stop {} {
	variable wInfo
	::crowDebugger::stop
	return
}

proc ::fmeDebugger::start_menu_post {} {
	variable wInfo
	set m $wInfo(menuBtnStart)
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
#	puts d-mainScript=$mainScript
#	puts d-prjState=$prjState
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

proc ::fmeDebugger::text_update {} {
	set tree $::fmeDebugger::wInfo(tree)
	if {[$tree selection count]} {
		set item [$tree selection get]
		set txt $::fmeDebugger::wInfo(txt)
		$txt configure -state normal
		$txt delete 1.0 end
		
		set data [$tree item element cget $item 1 eTxt -data]

		$txt insert end $data
		$txt configure -state disabled
	}
}

proc ::fmeDebugger::var_add {parent type name value} {
	set tree $::fmeDebugger::wInfo(tree)

	set item [$tree item create -parent $parent -button no]
	set img "variable"
	if {$type eq "ARRAY"} {
		$tree item configure $item -button yes
		$tree item collapse $item
		set img "array"
	}
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
#	$tree item lastchild $parent $item
	$tree item element configure $item 0 eImg -image [::crowImg::get_image $img]
	$tree item element configure $item 0 eTxt -text $name

	if {$type eq "VAR"} {
		if {[string length $value] > 20} {
			$tree item element configure $item 1 eTxt -text [string range $value 0 19]... -data $value
		} else {
			$tree item element configure $item 1 eTxt -text $value -data $value
		}
		return $item
	}
	$tree item element configure $item 1 eTxt -text "" -data $value
	foreach {key val} $value {
		::fmeDebugger::var_add $item "VAR" $key $val
	}
	return $item
}

proc ::fmeDebugger::var_set {type item} {
	variable wInfo
	set tree $wInfo(tree)
	
	set name [$tree item element cget $item 0 eTxt -text]
	set val [$tree item element cget $item 1 eTxt -data]
	set ret [::inputDlg::show $tree.set_variable [::msgcat::mc "Change value"] $val ]
	foreach {btn ret} $ret {break}
	if {$btn eq "CANCEL" || $btn eq "-1"} {return}
	if {$type eq "ARRAY"} {
		set parent [$tree item parent $item]
		set idata [$tree item element cget $parent 0 eTxt -text]
		set name ${idata}($name)
	}
	::crowDebugger::send_cmd [list set $name $ret]
	return
}

proc ::fmeDebugger::var_update {item type name value} {
	set tree $::fmeDebugger::wInfo(tree)
	set idata [$tree item element cget $item 1 eTxt -text]
	if {$idata eq $value} {return}

	if {$type eq "VAR"} {
		$tree item configure $item -button no
		if {[string length $value] > 20} {
			$tree item element configure $item 1 eTxt -text [string range $value 0 19]... -data $value
		} else {
			$tree item element configure $item 1 eTxt -text $value -data $value
		}
		$tree item element configure $item 0 eImg -image [::crowImg::get_image "variable"]
		foreach child [$tree item children $item] {$tree item delete $child}
		
		return
	}
	
	$tree item configure $item -button yes
	$tree item element configure $item 1 eTxt -text "" -data $value
	$tree item element configure $item 0 eImg -image [::crowImg::get_image "array"]
	foreach child [$tree item children $item] {$tree item delete $child}
	foreach {key val} $value {::fmeDebugger::var_add $item "VAR" $key $val}
	return	
	
}

proc ::fmeDebugger::watchpoint_add {{ret ""}} {
	variable wInfo
	variable sysInfo
	variable varsCache
	variable watchpoints
	
	set tree $wInfo(tree)
	
	if {$ret eq ""} {
		set ret [::inputDlg::show $tree.addWatch [::msgcat::mc "Add Watch"] "" ]
		foreach {btn ret} $ret {break}
		if {$btn eq "CANCEL" || $btn eq "-1" || [string trim $ret] eq ""} {return}
	}

	if {[info exists watchpoints($ret)]} {
		tk_messageBox -title [::msgcat::mc "Info"] -icon info \
			-message [::msgcat::mc "Watchpoint already exists!"] \
			-type ok
		return
	}
	
	
	set parent $wInfo(nodeWatchpoint)
	set item [$tree item create -parent $parent -button no]
	$tree item style set $item 0 sName
	$tree item style set $item 1 sValue
#	$tree item lastchild $parent $item
	$tree item element configure $item 0 eImg -image [::crowImg::get_image watchpoint]
	$tree item element configure $item 0 eTxt -text $ret
	$tree item element configure $item 1 eTxt -text "" -data ""
	set ::fmeDebugger::watchpoints($ret) $item
	
	::crowDebugger::watchpoint_add $ret
	::fmeDebugger::watchpoint_save
	return
}

proc ::fmeDebugger::watchpoint_del {item} {
	variable wInfo
	variable watchpoints
	set tree $wInfo(tree)
	set idata [$tree item element cget $item 0 eTxt -text]
	$tree item delete $item
	array unset watchpoints $idata
	::crowDebugger::watchpoint_del $idata
	::fmeDebugger::watchpoint_save
	return
}

proc ::fmeDebugger::watchpoint_load {} {
	set prjPath [::fmeProjectManager::get_project_path]
	if {$prjPath ne "" && [file exists $prjPath]} {
		set wp [file join $prjPath ".__meta__" "Debugger.rc"]
		foreach {key} [::crowRC::param_get $wp Watchpoints] {
			::fmeDebugger::watchpoint_add $key
		}
	}
}

proc ::fmeDebugger::watchpoint_refresh {name1 name2 op} {
	set tree $::fmeDebugger::wInfo(tree)
	if {[info exists ::fmeDebugger::watchpoints($name2)]} {
		set type ""
		set value ""
		foreach {type value} $::crowDebugger::watchpoints($name2) {break}
		if {$type eq ""} {return}
		::fmeDebugger::var_update $::fmeDebugger::watchpoints($name2) $type $name2 $value
		::fmeDebugger::text_update
	}
	return
}

proc ::fmeDebugger::watchpoint_save {} {
	variable watchpoints
	set prjPath [::fmeProjectManager::get_project_path]
	if {$prjPath ne "" && [file exists $prjPath]} {
		set wp [file join $prjPath ".__meta__" "Debugger.rc"]
		::crowRC::param_set $wp Watchpoints [array names watchpoints]
	}
	return
}

proc ::fmeDebugger::watchpoint_set {item} {
	variable wInfo
	set tree $wInfo(tree)
	set name [$tree item element cget $item 0 eTxt -text]
	set val [$tree item element cget $item 1 eTxt -text]
	set ret [::inputDlg::show $tree.set_variable [::msgcat::mc "Change value"] $val ]
	foreach {btn ret} $ret {break}
	if {$btn eq "CANCEL" || $btn eq "-1"} {return}
	::crowDebugger::send_cmd [list set $name $ret]
	return
}

