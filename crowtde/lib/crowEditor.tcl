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

package provide crowEditor 1.0

package require msgcat
package require Tk
package require crowImg
package require crowFont
package require crowRC
package require crowMacro

namespace eval ::crowEditor {
	variable prePos 0.0
	
	variable synHelper
	array set synHelper ""
	variable synHelperEnabled 1

	variable colorEnabled 1

	variable wInfo
	array set wInfo ""

	variable synInterp ""
	variable afterId 0
	
	variable colorTbl
	array set colorTbl [list TCLCMD "#804040" TCLARG "#6a5acd" TKCMD "#2E8B57" TKARG "#6a5acd" DIGIT "Red" VARIABLE "#008080" COMMENT "#0000ff" STRING "#ff00ff" ]

	variable defaultColorTbl
	array set defaultColorTbl [array get colorTbl]
	
	variable rc ""
	
	variable showLineBox 1
	
	variable tabWidth 4
	
	variable breakpointTbl
	array set breakpointTbl ""
}

proc ::crowEditor::init {tclparser crowSyntax} {
	variable rc
	variable colorTbl
	variable colorEnabled
	variable synHelperEnabled
	variable tabWidth
	variable synInterp
	
	bind Text <Control-a> {}
	bind Text <Control-f> {}	
	bind Text <Control-g> {}	
	bind Text <Control-p> {}	
	bind Text <Control-y> {}
	bind Text <Control-z> {}
	bind Text <Control-r> {}
	event delete <<Undo>>
	event delete <<Redo>>
	if {$::tcl_platform(platform) eq "unix"} {
		bind Text <Control-v> {}
		bind Text <<Paste>> {}
	}
	set synInterp [interp create]
	interp alias $synInterp ::crowEditor::highlight_cb {} ::crowEditor::highlight_cb
	interp alias $synInterp puts {} puts

	$synInterp eval [list set ::auto_path $::auto_path]
	$synInterp eval [list package require crowSyntax]
	$synInterp eval [list ::crowSyntax::init]
	
	set rc [file join $::env(HOME) ".CrowTDE" "CrowEditor.rc"]
	array set params ""
	::crowRC::param_get_all $rc params
	foreach item [array names colorTbl] {
		if {[info exists params(CrowEditor.Color.$item)]} {
			set colorTbl($item) $params(CrowEditor.Color.$item)
		}
	}
	if {[info exists params(CrowEditor.Color.Enabled)]} {
		set colorEnabled $params(CrowEditor.Color.Enabled)
	}
	if {[info exists params(CrowEditor.SyntaxHelper.Enabled)]} {
		set synHelperEnabled $params(CrowEditor.SyntaxHelper.Enabled)
	}
	if {[info exists params(CrowEditor.TabWidth)]} {
		set tabWidth $params(CrowEditor.TabWidth)
	}	
	array unset params
	return
}

proc ::crowEditor::add_trace_modified {widget cb} {
	set ::crowEditor::wInfo($widget,modified_cb) $cb
}

proc ::crowEditor::breakpoint_add {widget lineno pos} {
	set editor $::crowEditor::wInfo($widget,editor)
	set fpath $::crowEditor::wInfo($widget,file)
	set lineBox $::crowEditor::wInfo($widget,lineBox)
	set lineno $lineno.0
	$lineBox tag remove CMDSTART [$lineBox index "$lineno linestart"] [$lineBox index "$lineno lineend"] 
	$lineBox tag add BREAKPOINT [$lineBox index "$lineno linestart"] [$lineBox index "$lineno lineend"]
	::crowDebugger::breakpoint_add $fpath $pos
	return
}

proc ::crowEditor::breakpoint_del {widget lineno pos} {
	set editor $::crowEditor::wInfo($widget,editor)
	set fpath $::crowEditor::wInfo($widget,file)
	set lineBox $::crowEditor::wInfo($widget,lineBox)
	set lineno $lineno.0
	$lineBox tag add CMDSTART [$lineBox index "$lineno linestart"] [$lineBox index "$lineno lineend"] 
	$lineBox tag remove BREAKPOINT [$lineBox index "$lineno linestart"] [$lineBox index "$lineno lineend"]
	::crowDebugger::breakpoint_del $fpath $pos
	return
}

proc ::crowEditor::breakpoint_load {widget} {
	variable wInfo
	variable wVars
	set editor $wInfo($widget,editor)
	set fpath $wInfo($widget,file)

	set rc [file join $::env(HOME) ".CrowTDE" "debug" "cache.tbl"]
	if {[file exists $rc]} {
		set inBuf ""
		set cinfo ""
		set fd [open $rc r]
		set script ""
		while {![eof $fd]} {
			gets $fd inBuf
			foreach {cut script} $inBuf {break}
			if {$script eq $fpath} {
				set cinfo [file join $::env(HOME) ".CrowTDE" "debug" "$cut.info"]
				break
			}
		}
		close $fd
		set data ""
		if {$cinfo ne "" && [file exists $cinfo]} {
			set fd [open $cinfo r]
			set data [read -nonewline $fd]
			close $fd
		}
		set bps ""
		set prjPath [::fmeProjectManager::get_project_path]
		if {$prjPath ne "" && [file exists $prjPath]} {
			set wp [file join $prjPath ".__meta__" "Debugger.rc"]
			foreach {bp} [lindex [::crowRC::param_get $wp Breakpoints] 0] {
				set script ""
				foreach {script pos} $bp {break}
				if {$script eq $fpath} {lappend bps $pos}
			}
		}
		::crowEditor::barakpoint_set $widget $data $bps
	}	
}

proc ::crowEditor::barakpoint_set {widget bplist bps} {
	variable wInfo
	variable breakpointTbl
	set maxLine $wInfo($widget,maxLine)
	set editor $wInfo($widget,editor)
	set lineBox $wInfo($widget,lineBox)
	$lineBox delete 1.0 end
	set currLine 0
	
	$lineBox configure -state normal

	array unset breakpointTbl *
	set bplist2 $bplist
	set bplist ""
	foreach bp $bplist2 {
		set lineno [expr int([$editor index $bp])]
		lappend bplist $lineno
		set breakpointTbl($lineno) $bp
	}
	set bps2 $bps
	set bps ""
	foreach {bp} $bps2 {
		lappend bps [expr int([$editor index $bp])]
	}

	
	if {$maxLine > $currLine} {
		for {set i $currLine} {$i < $maxLine} {incr i} {
			set j [expr $i +1]
			set lineno [string range "00000$j" "end-4" end]
			if {[lsearch -exact $bps $j]>=0} {
				$lineBox insert end $lineno BREAKPOINT
				# coler lineno
			} elseif {[lsearch -exact $bplist $j]>=0} {
				$lineBox insert end $lineno CMDSTART	
			} else {
				$lineBox insert end $lineno
			}
			$lineBox insert end "\n"
		}
	}
#	$lineBox configure -state disabled
	return	
}

proc ::crowEditor::cut_word {widget} {	
	::crowEditor::sel_word $widget
	set ret [::crowEditor::get_sel_range $widget]
	::crowEditor::cut $widget
	return $ret
}

proc ::crowEditor::cut_line {widget} {	
	::crowEditor::sel_line $widget
	set ret [::crowEditor::get_sel_range $widget]
	::crowEditor::cut $widget
	return $ret
}

proc ::crowEditor::cut {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set ret [::crowEditor::get_sel_range $widget]
	tk_textCut $editor
	::crowEditor::update_ch_flag $widget
	after idle [list ::crowEditor::highlight_curr_pos $widget]
	return $ret
}

proc ::crowEditor::copy_line {widget} {
	::crowEditor::sel_line $widget
	set ret [::crowEditor::get_sel_range $widget]
	::crowEditor::copy $widget
	return $ret	
}

proc ::crowEditor::copy {widget} {	
	set editor $::crowEditor::wInfo($widget,editor)
	tk_textCopy $editor
	return [::crowEditor::get_sel_range $widget]
}

proc ::crowEditor::crowEditor {path args} {
	variable colorEnabled
	variable colorTbl
	variable showLineBox
	variable tabWidth
	
	set fmeEditor [frame $path -bd 2 -relief groove]

	set hs [scrollbar $fmeEditor.hs -orient horizontal]
	set vs [scrollbar $fmeEditor.vs -orient vertical]
	set line [text $fmeEditor.line -width 5 -wrap none \
		-bd 0 -relief ridge -spacing3 2 -spacing1 1 \
		-state disabled -highlightthickness 0 -fg "#666666" -bg "#e3e4e5" ]
#	button .btn -bg "#e4e4e4"
	$line tag configure CMDSTART -background "#cfcfcf"
	$line tag bind CMDSTART <Button-1> [format {
		set widget "%s"
		set line [expr int([%%W index "@%%x,%%y linestart"])]
		set pos ""
		foreach {key pos} [array get ::crowEditor::breakpointTbl $line] {break}
		if {$pos ne ""} {
			::crowEditor::breakpoint_add $widget $line $pos
#			set m "%%W.mBreakpoint"
#			if {[winfo exists $m]} {destroy $m}
#			menu $m
#			$m add command -label [::msgcat::mc "Set Breakpoint"] \
#				-command [list ::crowEditor::breakpoint_add $widget $line $pos]
#			tk_popup $m %%X %%Y
		}
	} $fmeEditor]
	$line tag configure BREAKPOINT -background "#cfcfcf" -foreground "red"
	$line tag bind BREAKPOINT <Button-1> [format {
		set widget "%s"
		set line [expr int([%%W index "@%%x,%%y linestart"])]
		set pos ""
		foreach {key pos} [array get ::crowEditor::breakpointTbl $line] {break}
		if {$pos ne ""} {		
			::crowEditor::breakpoint_del $widget $line $pos
#			set m "%%W.mBreakpoint"
#			if {[winfo exists $m]} {destroy $m}
#			menu $m
#			$m add command -label [::msgcat::mc "Unset Breakpoint"] \
#				-command [list ::crowEditor::breakpoint_del $widget $line $pos]
#			tk_popup $m %%X %%Y
		}
	} $fmeEditor]
	
	
	set editor [text $fmeEditor.editor -wrap none -undo 1 \
		-relief flat -bd 0 -bg white -spacing3 2 \
		-spacing1 1 -highlightthickness 0 ]
	set f [$editor cget -font]
	if {$f ne ""} {
		$editor configure -tabs [list [expr [font measure $f " "]*$tabWidth] left]
	}
		
	set ::crowEditor::wInfo($fmeEditor,editor) $editor
	set ::crowEditor::wInfo($fmeEditor,lineBox) $line
	set sensor [label $editor.sensor]
	
	$hs configure -command "$editor xview"
	$vs configure -command [list ::crowEditor::vscrollcmd $fmeEditor]
	$editor configure  -yscrollcommand [list ::crowEditor::editor_vsset $fmeEditor $editor $vs] -xscrollcommand "$hs set"
	bind $line <FocusIn> [list focus -force $editor]
	bind $line <MouseWheel> [list ::crowEditor::linebox_vsset $fmeEditor $line $vs] 
	bind $editor <Visibility> [list ::crowEditor::visibility $fmeEditor]
	
	# <!-- 
	set ::crowEditor::wInfo($fmeEditor,currPos) "0.0"
	set ::crowEditor::wInfo($fmeEditor,maxLine) "0"
	set ::crowEditor::wInfo($fmeEditor,file) ""
	set ::crowEditor::wInfo($fmeEditor,mtime) ""
	set ::crowEditor::wInfo($fmeEditor,msgbar) ""	
	set ::crowEditor::wInfo($fmeEditor,colorEnabled) $colorEnabled
	set ::crowEditor::wInfo($fmeEditor,modified) 0
	set ::crowEditor::wInfo($fmeEditor,lastModify) [clock seconds]
	set ::crowEditor::wInfo($fmeEditor,modified_cb) ""
	
	trace add variable ::crowEditor::wInfo($fmeEditor,modified) write [list ::crowEditor::trace_modified $fmeEditor]
	trace add variable ::crowEditor::wInfo($fmeEditor,maxLine) write [list ::crowEditor::trace_maxline $fmeEditor]
	trace add variable ::crowEditor::wInfo($fmeEditor,currPos) write [list ::crowEditor::trace_currpos $fmeEditor]
	# ->
	
	foreach {tag} [list TCLARG TKARG TCLCMD  TKCMD  DIGIT  VARIABLE  COMMENT  STRING  ] {
		$editor tag configure $tag -foreground $colorTbl($tag)
		$editor tag raise $tag	
	}

	
	$editor tag configure __MASK__ -background "#c5e0e0"
	$editor tag lower __MASK__
	
	$editor tag configure sel -background "#e4e5e6" -foreground black -relief groove -borderwidth 2

	$editor tag configure FIND -background #ddccdd -foreground black -borderwidth 0 -relief ridge
	if {$showLineBox} {
		grid $line   -row 0 -column 0  -rowspan 2 -sticky "ns"
		grid $editor -row 0 -column 1  -sticky "news"
	} else {
		grid $editor -row 0 -column 0 -columnspan 2  -sticky "news"		
	}
	grid $vs -row 0 -column 2 -rowspan 2 -sticky "ns"
	grid $hs -row 2 -column 0 -columnspan 3 -sticky "we"
	grid rowconfigure $fmeEditor 0 -weight 1
	grid columnconfigure $fmeEditor 1 -weight 1
	
	bind $editor <Control-a> [list ::crowEditor::sel_all $fmeEditor]
	bind $editor <Control-k> [list ::crowEditor::cut_line $fmeEditor]
	bind $editor <Control-l> [list ::crowEditor::sel_line $fmeEditor]	
	if {$::tcl_platform(platform) eq "unix"} {
		bind $editor <Control-v> [list ::crowEditor::paste $fmeEditor]
	}
	bind $editor <Control-v> +[list ::crowEditor::after_paste $fmeEditor]
	bind $editor <Control-y> [list ::crowEditor::copy_line $fmeEditor]
	bind $editor <Control-p> [list ::crowEditor::paste_line $fmeEditor]
	
	bind $editor <Control-period> [list ::crowEditor::insert_tab $fmeEditor]
	bind $editor <Control-comma> [list ::crowEditor::remove_tab $fmeEditor]
	
	bind $editor <Control-f> [list ::crowEditor::show_find $fmeEditor]
	bind $editor <Control-g> [list ::crowEditor::show_goto $fmeEditor ""]
	bind $editor <Control-s> [list ::crowEditor::save $fmeEditor]
	bind $editor <Control-z> [list ::crowEditor::undo $fmeEditor]
	bind $editor <Control-z> +[list after idle [list ::crowEditor::highlight_curr_view $fmeEditor]]
	
	bind $editor <KeyRelease> [list ::crowEditor::key_release $fmeEditor %k %K]
	bind $editor <KeyPress>   [list ::crowEditor::key_press $fmeEditor %k %K]
	bind $editor <Destroy> 	  [list ::crowEditor::cleanup $fmeEditor]
	bind $editor <FocusIn> [list ::crowEditor::focus_in $fmeEditor]
	bind $editor <FocusOut> {
		if {[info exists ::crowEditor::synHelper(fmeMain)] && [winfo exists $::crowEditor::synHelper(fmeMain)]} {
			after idle [list after 100 [list destroy $::crowEditor::synHelper(fmeMain)]]
		}
	}
	bind $sensor <Destroy> [list ::crowEditor::before_unload $fmeEditor]

	bind $editor <ButtonRelease-1> [list ::crowEditor::btn_release $fmeEditor]
	bind $editor <ButtonRelease-3> [list ::crowEditor::post_menu $fmeEditor %x %y %X %Y]

	$editor edit reset 	
	return $fmeEditor
	
}

proc ::crowEditor::dump_text {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	return [$editor get 1.0 end]
}

proc ::crowEditor::find_keyword {widget keywork case direct matching} {
	variable wInfo
	set editor $wInfo($widget,editor)
	if {$keywork eq ""} {return}
	set currIdx [$editor index insert]
	set matchLen 0
	if {$matching  eq ""} {
		set idx [$editor search $case $direct -count matchLen -- $keywork insert]
	} else {
		set idx [$editor search $case $direct $matching -count matchLen -- $keywork insert]
	}
	if {$direct eq "-forwards"} {
		set oft "+ 1 c"
	} else {
		set oft "- 1 c"
	}
	if {$idx eq $currIdx} {
		if {$matching  eq ""} {
			set idx [$editor search $case $direct -- $keywork "insert $oft"]
		} else {
			set idx [$editor search $case $direct $matching -- $keywork "insert $oft"]
		}	
	}

	$editor tag remove FIND 1.0 end
	if {$idx ne ""} {
		::crowEditor::goto_pos $widget $idx
		$editor tag add FIND $idx "$idx + $matchLen c"		
	} else {
		tk_messageBox -title [::msgcat::mc "Find"] -type ok -icon info \
			-message [::msgcat::mc "String Not Found"]		
	}
}

proc ::crowEditor::get_ch_flag {widget} {
	# get modified ?
	set editor $::crowEditor::wInfo($widget,editor)
	return [$editor edit modified]
}

proc ::crowEditor::get_color_state {widget} {
	# get syntax highlight state ?
	return $::crowEditor::wInfo($widget,colorEnabled)
}

proc ::crowEditor::get_file {widget} {
	return $::crowEditor::wInfo($widget,file)
}

proc ::crowEditor::get_lastModify {widget} {
	return $::crowEditor::wInfo($widget,lastModify)
}

proc ::crowEditor::get_frame {path} {
	variable colorTbl
	set fmeMain [frame $path]
	set lblTitle [label $fmeMain.lblTitle -text [::msgcat::mc "Editor Settings"] -bd 2 -relief groove]
	grid $lblTitle -row 0 -column 0  -sticky "we"
	
	set fmeHighlight [labelframe $fmeMain.fmeHighlight -text [::msgcat::mc "Syntax Highlight"]]
	set rdoEnabled [radiobutton $fmeHighlight.rdoEnabled -anchor w -justify left\
		-value 1 -variable ::crowEditor::colorEnabled -text [::msgcat::mc "Default enabled"] \
		-command [list ::crowEditor::set_color_default_state 1] ]
	set rdoDisabled [radiobutton $fmeHighlight.rdoDisabled  -anchor w -justify left\
		-value 0 -variable ::crowEditor::colorEnabled -text [::msgcat::mc "Default disabled"] \
		-command [list ::crowEditor::set_color_default_state 0] ]
	pack $rdoEnabled $rdoDisabled -side top -expand 1 -fill x
	
	set fmeColor [labelframe $fmeMain.fmeColor -text [::msgcat::mc "Colors"]]
	set textMap [list \
		TCLCMD [::msgcat::mc "Tcl Command:"] \
		TCLARG [::msgcat::mc "Tcl Argument:"] \
		TKCMD [::msgcat::mc "Tk Command:"] \
		TKARG [::msgcat::mc "Tk Argument:"] \
		DIGIT [::msgcat::mc "Numerical:"] \
		VARIABLE [::msgcat::mc "Variable:"] \
		COMMENT [::msgcat::mc "Comment:"] \
		STRING [::msgcat::mc "String:"] ]
	set flag 0
	set row 0
	set col 0
	foreach {cmd title} $textMap {
		grid [label $fmeColor.lbl$cmd -text $title -anchor w -justify left] -sticky "we" -pady 5 -padx 1 -row $row -column $col
		incr col
		grid [button $fmeColor.btn$cmd -bg $colorTbl($cmd) -width 6 -command [list ::crowEditor::set_color $cmd $title $fmeColor.btn$cmd]] \
		     -sticky "we" -pady 5 -padx 5  -row $row -column $col
		incr col
		set flag [expr !$flag]
		if {!$flag} {incr row ; set col 0}
		
	}
	set fmeBtn [frame $fmeColor.fmeBtn ]
	set btnReset [button $fmeBtn.btnReset -text [::msgcat::mc "Reset"] \
		-command [subst {
			array set ::crowEditor::colorTbl \[array get ::crowEditor::defaultColorTbl]
			foreach item \[array names ::crowEditor::colorTbl] {
				::crowRC::param_set \$::crowEditor::rc CrowEditor.Color.\$item \$::crowEditor::colorTbl(\$item)
				$fmeColor.btn\$item configure -bg \$::crowEditor::colorTbl(\$item)
			}
		}] ]
	pack $btnReset -side right -padx 5
	
	grid $fmeBtn -column 0 -columnspan 5 -sticky "we" -pady 5
	
	grid columnconfigure $fmeColor 4 -weight 1
	grid rowconfigure $fmeColor 6 -weight 1
	
	set fmeTabWidth [labelframe $fmeMain.fmeTabWidth -text [::msgcat::mc "Tab width"]]
	foreach w [list 4 6 8 10 12] {
		radiobutton $fmeTabWidth.rdo$w -text $w -value $w -variable ::crowEditor::tabWidth -width 5 -anchor w\
			-command [list ::crowRC::param_set $::crowEditor::rc CrowEditor.TabWidth $w]
		pack $fmeTabWidth.rdo$w -side left
	}
#	grid $fmeTabWidth.rdo4 $fmeTabWidth.rdo6 $fmeTabWidth.rdo8 -sticky "news"
#	grid $fmeTabWidth.rdo10 $fmeTabWidth.rdo12 - -sticky "news"
#	grid columnconfigure $fmeTabWidth 2 -weight 1
	
	grid $fmeHighlight -row 1 -column 0 -sticky "we"
	grid $fmeColor -row 2 -column 0  -sticky "we"
	grid $fmeTabWidth -row 3 -column 0  -sticky "we"
	grid columnconfigure $fmeMain 0 -weight 1
	grid rowconfigure $fmeMain 4 -weight 1
	
	return $path
}

proc ::crowEditor::get_synHelper_state {} {
	variable synHelperEnabled
	return $synHelperEnabled
}

proc ::crowEditor::get_lineBox_state {} {
	variable showLineBox
	return $showLineBox
}

proc ::crowEditor::get_sel_range {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	return [$editor tag range sel]
}

proc ::crowEditor::get_text_widget {widget} {
	variable wInfo
	if {![winfo exists $wInfo($widget,editor)]} {return ""}
	return $wInfo($widget,editor)
}

proc ::crowEditor::goto_line {widget line} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {$line eq "start"} {set line 1}
	$editor mark set insert $line.0
	::crowEditor::btn_release $widget
	$editor tag add __MASK__ $line.0 "$line.0 lineend"
	$editor see $line.0
}

proc ::crowEditor::goto_pos {widget pos} {
	variable wInfo
	set editor $wInfo($widget,editor)
	$editor mark set insert $pos
	::crowEditor::btn_release $widget
	$editor tag add __MASK__ "$pos linestart" "$pos lineend"
	$editor see $pos
}

proc ::crowEditor::insert_comment {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		set sIdx [$editor index "insert linestart"]
		set eIdx [$editor index "insert lineend"]
	} else {
		set sIdx [$editor index [concat [lindex $sel 0] " " "linestart"]]
		set eIdx [$editor index [concat [lindex $sel 1] " " "lineend"]]
	}
	set data "#[$editor get $sIdx $eIdx]"
	::crowEditor::insert_text $widget $sIdx $eIdx [regsub -all "\n" $data "\n#"]
	if {$sel ne ""} {$editor tag add sel $sIdx $eIdx}
	return	
}

proc ::crowEditor::insert_macro {widget macro} {
	set editor $::crowEditor::wInfo($widget,editor)
	set dlen [string length $macro]
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		::crowEditor::insert_text $widget [$editor index insert] "" $macro
	} else {
		::crowEditor::insert_text $widget [lindex $sel 0] [lindex $sel 1] $macro
	}
}

proc ::crowEditor::insert_tab {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		set sIdx [$editor index "insert linestart"]
		set eIdx [$editor index "insert lineend"]
	} else {
		set sIdx [$editor index [concat [lindex $sel 0] " " "linestart"]]
		set eIdx [$editor index [concat [lindex $sel 1] " " "lineend"]]
	}
	set data "\t[$editor get $sIdx $eIdx]"
	::crowEditor::insert_text $widget $sIdx $eIdx [regsub -all "\n" $data "\n\t"]
	if {$sel ne ""} {$editor tag add sel $sIdx $eIdx}
	return	
}

proc ::crowEditor::insert_text {widget sIdx eIdx data} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {$sIdx ne "" && $eIdx ne ""} {$editor delete $sIdx $eIdx}
	set dlen [string length $data]
	set currIdx $sIdx
	if {$currIdx eq ""} {set currIdx [$editor index "insert"]}
	$editor insert $currIdx $data
	
	set ::crowEditor::wInfo($widget,currPos) [$editor index "insert"]	
	set ::crowEditor::wInfo($widget,maxLine) [expr [lindex [split [$editor index end] "."] 0] -1]
	::crowEditor::goto_pos $widget $::crowEditor::wInfo($widget,currPos)
	::crowEditor::update_ch_flag $widget
	after idle [list ::crowEditor::highlight_range $widget $currIdx [list $currIdx + $dlen chars]]
}

proc ::crowEditor::load {widget fname} {
	if {[string tolower [file extension $fname]] ne ".tcl"} {
		set ::crowEditor::wInfo($widget,colorEnabled) 0
	}
		
	set editor $::crowEditor::wInfo($widget,editor)
	set fd [open $fname "r"]
	$editor insert end [read -nonewline $fd]
	close $fd
	::crowEditor::reset_undo $widget
	
	set ::crowEditor::wInfo($widget,file) $fname
	set ::crowEditor::wInfo($widget,mtime) [file mtime $fname]
	
	::crowEditor::set_ch_flag $widget 0
	::crowEditor::goto_pos $widget 1.0
	return $fname
}

proc ::crowEditor::lineBox_hide {} {
	variable wInfo
	variable showLineBox
	set showLineBox 0
	foreach key [array names wInfo *,editor] {
		set widget [lindex [split $key ","] 0]
		grid forget $wInfo($widget,lineBox)
		grid $wInfo($widget,editor) -row 0 -column 0 -columnspan 2 -sticky "news"
	}
}

proc ::crowEditor::lineBox_show {} {
	variable wInfo
	variable showLineBox
	set showLineBox 1
	foreach key [array names wInfo *,editor] {
		set widget [lindex [split $key ","] 0]		
		grid $wInfo($widget,lineBox)  -row 0 -column 0  -rowspan 2 -sticky "ns"
		grid $wInfo($widget,editor) -row 0 -column 1  -sticky "news"
	}
}

proc ::crowEditor::paste {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {[catch {set data [clipboard get]}]} {return}
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		::crowEditor::insert_text $widget [$editor index insert] "" $data
	} else {
		::crowEditor::insert_text $widget [lindex $sel 0] [lindex $sel 1] $data
	}
}

proc ::crowEditor::paste_line {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {[catch {set data [clipboard get]}]} {return}
	if {[$editor index "insert +1l lineend"] eq [$editor index "end lineend"]} {
		::crowEditor::insert_text $widget [$editor index "insert +1l linestart"] [$editor index "insert +1l linestart"] "\n$data\n"
	} else {
		::crowEditor::insert_text $widget [$editor index "insert +1l linestart"] [$editor index "insert +1l linestart"] "$data\n"
	}
}

proc ::crowEditor::redo {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {[catch {$editor edit redo}] == 0} {
		::crowEditor::update_ch_flag $widget
		after idle [list ::crowEditor::highlight_curr_view $widget]
	}
	
}

proc ::crowEditor::remove_comment {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		set sIdx [$editor index "insert linestart"]
		set eIdx [$editor index "insert lineend"]
	} else {
		set sIdx [$editor index [concat [lindex $sel 0] " " "linestart"]]
		set eIdx [$editor index [concat [lindex $sel 1] " " "lineend"]]
	}
	set data [$editor get $sIdx $eIdx]
	set idx ""
	set subIdx ""
	set startIdx 0
	while {[regexp -indices -line -start $startIdx -- {^\s*(#).*$} $data idx subIdx]} {
		set subIdx [lindex $subIdx 0]
		set data [string replace $data $subIdx $subIdx ""]
		set startIdx [lindex $idx 1]
	}
	::crowEditor::insert_text $widget $sIdx $eIdx $data
	if {$sel ne ""} {$editor tag add sel $sIdx $eIdx}
	return	
}

proc ::crowEditor::remove_tab {widget} {
	variable tabWidth
	set editor $::crowEditor::wInfo($widget,editor)
	set sel [$editor tag range sel]
	if {$sel eq ""} {
		set sIdx [$editor index "insert linestart"]
		set eIdx [$editor index "insert lineend"]
	} else {
		set sIdx [$editor index [concat [lindex $sel 0] " " "linestart"]]
		set eIdx [$editor index [concat [lindex $sel 1] " " "lineend"]]
	}
	set data [split [$editor get $sIdx $eIdx] "\n"]
	set data2 ""
	foreach item $data {
		if {[regexp -indices -- {^\s*(\t{1})} $item idx subIdx]} {
			set subIdx [lindex $subIdx 0]
			set tmp [string replace $item $subIdx $subIdx ""]
		} else {
			set tmp [regsub [format {^\s{0,%d}} $tabWidth] $item ""]
		}
		append data2 "$tmp\n"
	}

	::crowEditor::insert_text $widget $sIdx $eIdx [string range $data2 0 end-1]
	if {$sel ne ""} {$editor tag add sel $sIdx $eIdx}
	return		
}

proc ::crowEditor::reset_undo {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor edit reset
}

proc ::crowEditor::save {widget} {
	if {$::crowEditor::wInfo($widget,file) eq ""} {
		set ::crowEditor::wInfo($widget,file) [tk_getSaveFile -filetypes [list [list {Tcl Scripts} {.tcl}] [list {All Files} {*}] ] \
			-title [::msgcat::mc "Save file!"]]
	}
	if {$::crowEditor::wInfo($widget,file) eq ""} {return}
	set fd [open $::crowEditor::wInfo($widget,file) w]
	puts -nonewline $fd [::crowEditor::dump_text $widget]
	close $fd
	set ::crowEditor::wInfo($widget,mtime) [file mtime $::crowEditor::wInfo($widget,file)]
	::crowEditor::set_ch_flag $widget 0
	puts sbar msg [::msgcat::mc "Save success"]
	return
}

proc ::crowEditor::sel_all {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor tag delete sel
	$editor tag add sel 1.0 end
	::crowEditor::update_sel_range $widget
	#::crowEditor::trigger_event $editor SELECTION_CHANGE_EVENT
}

proc ::crowEditor::set_ch_flag {widget flag} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor edit modified $flag
	::crowEditor::update_ch_flag $widget
}

proc ::crowEditor::set_color_state {widget flag} {
	#Enabled/Disabled syntax highlight
	set ::crowEditor::wInfo($widget,colorEnabled) $flag
	after idle [list ::crowEditor::highlight_curr_view $widget]
}

proc ::crowEditor::set_color_default_state {flag} {
	variable rc
	variable colorEnabled
	set colorEnabled $flag	
	::crowRC::param_set $rc CrowEditor.Color.Enabled $flag
	return
}

proc ::crowEditor::set_font {widget font} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor configure -font $font
	return
}

proc ::crowEditor::set_no_save {widget} {
	::crowEditor::set_ch_flag $widget 0
	return
}

proc ::crowEditor::set_synHelper_state {flag} {
	variable rc
	variable synHelperEnabled
	set synHelperEnabled $flag	
	::crowRC::param_set $rc CrowEditor.SyntaxHelper.Enabled $flag	
}
	
proc ::crowEditor::sel_line {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor tag delete sel
	$editor tag add sel [$editor index "insert linestart"] [$editor index "insert lineend"]
	::crowEditor::update_sel_range $widget
}

proc ::crowEditor::sel_word {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	$editor tag delete sel
	$editor tag add sel [$editor index "insert wordstart"] [$editor index "insert wordend"]
	::crowEditor::update_sel_range $widget
}

proc ::crowEditor::show_goto {widget line} {
	if {$line ne ""} {
		::crowEditor::goto_line $widget $line
		return
	}
	set ret [::inputDlg::show $widget.tmpInputDlg [::msgcat::mc "Jump To"] "1"]
	foreach {btn ret} $ret {break}
	if {$btn eq "CANCEL" || $btn eq "-1" || ![string is integer $ret] eq ""} {return}	
	::crowEditor::goto_line $widget $ret
	return
}

proc ::crowEditor::show_find {widget} {
	variable wInfo
	variable wVars
	set editor $wInfo($widget,editor)

	#if {[winfo exists $widget.winFind]} {destroy $widget.winFind}
	if {[winfo exists .winFind]} {destroy $.winFind}
	set win [Dialog .winFind -title [::msgcat::mc "Find And Replace"] -modal none]
	set fme [$win getframe]
	set lblFind [label $fme.lblFind -text [::msgcat::mc "Find"] -anchor w -justify left]
	set txtFind [entry $fme.txtFind -textvariable ::crowEditor::wVars(keyword) -width 40 -takefocus 1]
	set lblReplace [label $fme.lblReplace -text [::msgcat::mc "Replace"] -anchor w -justify left]
	set txtReplace [entry $fme.txtReplace -textvariable ::crowEditor::wVars(replace) -width 40 -takefocus 1]
	set chkDirect [checkbutton $fme.chkDirect -variable ::crowEditor::wVars(direct) \
		-text [::msgcat::mc "Backward"] -anchor w -onvalue 0 -offvalue 1]
	set chkMatchAa [checkbutton $fme.chkMatchAa -variable ::crowEditor::wVars(matchAa) \
		-text [::msgcat::mc "Case Sensitive"] -anchor w -onvalue 1 -offvalue 0]
	set chkMatchRegexp [checkbutton $fme.chkMatchRegexp -variable ::crowEditor::wVars(matchRegexp) \
		-text [::msgcat::mc "Regular expression"] -anchor w -onvalue 1 -offvalue 0]		
	set btnFind [button $fme.btnFind -text [::msgcat::mc "Find Next"] -default active \
		-command [list ::crowEditor::find ""]] 
	set btnReplace [button $fme.btnReplace -text [::msgcat::mc "Replace"] \
		-command [list ::crowEditor::replace ""]]
	set btnReplaceAll [button $fme.btnReplaceAll -text [::msgcat::mc "Repalce All"] \
		-command [list ::crowEditor::replaceAll ""]]
	set btnExit [button $fme.btnExit -text [::msgcat::mc "Exit"] -command [list destroy $win]]
	
	grid $lblFind -row 0 -column 0 -sticky "we" -padx 2 -pady 2
	grid $txtFind -row 0 -column 1 -sticky "we" -padx 2 -pady 2
	grid $btnFind -row 0 -column 2 -sticky "we" -padx 2 -pady 4
	
	grid $lblReplace -row 1 -column 0 -sticky "we" -padx 2 -pady 2
	grid $txtReplace -row 1 -column 1 -sticky "we" -padx 2 -pady 2
	grid $btnReplace -row 1 -column 2 -sticky "we" -padx 2 -pady 4

	grid $chkMatchAa -row 2 -column 0 -columnspan 2 -sticky "we" -padx 2 -pady 2
	grid $btnReplaceAll -row 2 -column 2 -sticky "we" -padx 2 -pady 4	
	
	grid $chkDirect -row 3 -column 0 -columnspan 2 -sticky "we" -padx 2 -pady 2
	grid $btnExit -row 3 -column 2 -sticky "we" -padx 2 -pady 4	

	grid $chkMatchRegexp -row 4 -column 0 -columnspan 2 -sticky "we"	

	set wVars(prevFind) "insert"
	set wVars(matchAa) 0
	set wVars(matchRegexp) 0
	set wVars(direct) 1
	
	focus $txtFind
	bind $txtFind <KeyRelease-Return> [list ::crowEditor::find ""]
	$win draw
}

proc ::crowEditor::undo {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {[catch {$editor edit undo}] == 0} {
		::crowEditor::update_ch_flag $widget
		after idle [list ::crowEditor::highlight_curr_view $widget]
	}
}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::crowEditor::after_paste {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	if {[catch {set data [clipboard get]}]} {return}
	after idle [list ::crowEditor::highlight_range $widget insert [list insert - [string length $data] chars]]
}

proc ::crowEditor::before_unload {widget} {
	# check file exists ?
	
	if {$::crowEditor::wInfo($widget,file) eq ""} {return}
	set fname [file tail $::crowEditor::wInfo($widget,file)]
	if {![file exists $::crowEditor::wInfo($widget,file)]} {
		set ans [tk_messageBox -icon info -type yesno \
			-title [::msgcat::mc "Warring!"] \
			-message [::msgcat::mc "'%s' has been deleted from the file system. Save ?" $fname] ]
		if {$ans eq "yes"} {
			set fd [open $::crowEditor::wInfo($widget,file) w]
			puts -nonewline $fd [::crowEditor::dump_text $widget]
			close $fd
		}
		return	
	}
	# check modified ?
	if {[::crowEditor::get_ch_flag $widget]} {
		set ans [tk_messageBox -icon info -type yesno \
			-title [::msgcat::mc "Save File"] \
			-message [::msgcat::mc "'%s' has been modified. Save changes ?" $fname]]	
		if {$ans eq "yes"} {
			set fd [open $::crowEditor::wInfo($widget,file) w]
			puts -nonewline $fd [::crowEditor::dump_text $widget]
			close $fd
		}
	}
}

proc ::crowEditor::btn_release {widget} {
	::crowEditor::syntax_helper_hide $widget
	set editor $::crowEditor::wInfo($widget,editor)
	$editor tag remove __MASK__ 1.0 end
	if {[$editor tag range sel] eq ""} {
		$editor tag add __MASK__ [$editor index "insert linestart"] [$editor index "insert lineend+1c"]
	}
	
	set ::crowEditor::wInfo($widget,currPos) [$editor index "insert"]
	set ::crowEditor::wInfo($widget,maxLine) [expr [lindex [split [$editor index end] "."] 0] -1] 
	::crowEditor::update_sel_range $widget
	
}

proc ::crowEditor::cleanup {widget} {
	variable wInfo
	variable wVars
	set wInfo(CrowEditor,sel) ""
	set ::crowEditor::wInfo(CrowEditor,current) ""
	array unset wInfo $widget,*
	return
}

proc ::crowEditor::clear_color {widget sIdx eIdx} {
	set editor $::crowEditor::wInfo($widget,editor)
	set tags [$editor tag names]
	foreach tag $tags {$editor tag remove $tag $sIdx $eIdx}
}

proc ::crowEditor::editor_vsset {widget sender vs args} {
	::crowEditor::syntax_helper_hide $widget
	eval [concat $vs set $args]
	set yview [$sender yview]
	$::crowEditor::wInfo($widget,lineBox) yview moveto [lindex $yview 0]
	::crowEditor::highlight_curr_view $widget
	return
}

proc ::crowEditor::hscrollcmd {widget args} {
	::crowEditor::syntax_helper_hide $widget
	set editor $::crowEditor::wInfo($widget,editor)
	set lineBox $::crowEditor::wInfo($widget,lineBox)
	eval [concat $editor xview $args]
	eval [concat $lineBox xview $args]
	return
}

proc ::crowEditor::vscrollcmd {widget args} {
	::crowEditor::syntax_helper_hide $widget
	set editor $::crowEditor::wInfo($widget,editor)
	set lineBox $::crowEditor::wInfo($widget,lineBox)
	eval [concat $editor yview $args]
	eval [concat $lineBox yview $args]
	::crowEditor::highlight_curr_view $widget
	return
}

proc ::crowEditor::find {widget} {
	variable wInfo
	variable wVars
	if {![winfo exists $widget]} {set widget $wInfo(CrowEditor,current)}
	if {![winfo exists $widget]} {return}
	set editor $wInfo($widget,editor)
	if {$wVars(keyword) eq ""} {return}

	set arg ""
	if {$wVars(direct)} {
		append arg "-forwards"
	} else {
		append arg "-backwards"
	}

	if {$wVars(matchRegexp)} {
		append arg " -regexp"
	} else {
		append arg " -exact"
	}
	
	if {$wVars(matchAa) == 0} {
		append arg " -nocase"
	}
		
	set matchLen 0
	set idx [eval "$editor search $arg -count matchLen -- {$wVars(keyword)} {$wVars(prevFind)}"]
	
	if {$wVars(direct)} {
		set wVars(prevFind) "$idx +1 chars"
	} else {
		set wVars(prevFind) "$idx -1 chars"
	}
	
	$editor tag remove FIND 1.0 end
	if {$idx ne ""} {
		::crowEditor::goto_pos $widget $idx
		$editor tag add FIND $idx "$idx + $matchLen c"
	} else {
		if {$wVars(direct)} {
			set wVars(prevFind) 1.0
		} else {
			set wVars(prevFind) end
		}
		tk_messageBox -type ok -icon info \
			-title [::msgcat::mc "Find"] -message [::msgcat::mc "String Not Found"]
	}
}

proc ::crowEditor::focus_in {widget} {
	if {$::crowEditor::wInfo($widget,file) eq ""} {return}
	bind $::crowEditor::wInfo($widget,editor) <FocusIn> {}
	set f [$::crowEditor::wInfo($widget,editor) cget -font]
	if {$f ne ""} {
		$::crowEditor::wInfo($widget,editor) configure -tabs [list [expr [font measure $f " "]*$::crowEditor::tabWidth ] left]
	}
	
	set fname [file tail $::crowEditor::wInfo($widget,file)]
	#<!-- check exists ?
	if {![file exists $::crowEditor::wInfo($widget,file)]} {
		set ans [tk_messageBox -icon info -type yesno \
			-title [::msgcat::mc "Warring!"] \
			-message [::msgcat::mc "'%s' has been delete from the file system. Save it?" $fname]]
		if {$ans eq "yes"} {
			set fd [open $::crowEditor::wInfo($widget,file) w]
			puts -nonewline $fd [::crowEditor::dump_text $widget]
			close $fd
			set ::crowEditor::wInfo($widget,mtime) [file mtime $::crowEditor::wInfo($widget,file)]
		} 
		return
	}
	#-->
	
	#<!-- check modified ?
	if {[file mtime $::crowEditor::wInfo($widget,file)] ne $::crowEditor::wInfo($widget,mtime)} {
		# Don't touch next line
		set ::crowEditor::wInfo($widget,mtime) [file mtime $::crowEditor::wInfo($widget,file)] 
		set ans [tk_messageBox -icon info -type yesno \
			-title [::msgcat::mc "Information!"] \
			-message [::msgcat::mc "'%s' has been modified. Reload file ?" $fname]]
		if {$ans eq "yes"} {
			$::crowEditor::wInfo($widget,editor) delete 1.0 end
			::crowEditor::load $widget $::crowEditor::wInfo($widget,file)
			::crowEditor::highlight_curr_view $widget
		}
		#set ::crowEditor::wInfo($widget,mtime) [file mtime $::crowEditor::wInfo($widget,file)]
	}
	#-->
	bind $::crowEditor::wInfo($widget,editor) <FocusIn> [list ::crowEditor::focus_in $widget]
}

proc ::crowEditor::highlight_cb {editor type keyword idx1 idx2} {
	if {![winfo exists $editor]} {
		::crowEditor::highlight_stop
		return
	}
	switch -exact -- $type {
		"STRING" {
			if {[$editor get $idx1] eq "\"" && [$editor get "$idx2 -1 c"] eq "\""} {
				$editor tag add $type $idx1 $idx2
			}
		}
		"COMMENT" {
			if {[$editor get $idx1] eq "\#"} {
				$editor tag add $type $idx1 $idx2
			}
		}
		"CLEAR" {
			$editor tag remove "STRING" $idx1 $idx2
			$editor tag remove "COMMENT" $idx1 $idx2
			$editor tag remove "VARIABLE" $idx1 $idx2
			$editor tag remove "TCLARG" $idx1 $idx2
			$editor tag remove "TKARG" $idx1 $idx2
			$editor tag remove "DIGIT" $idx1 $idx2
			$editor tag remove "TCLCMD" $idx1 $idx2
			$editor tag remove "TKCMD" $idx1 $idx2
		}
		"PROC" {}
		"VARIABLE" -
		"TCLARG" -
		"TKARG" -
		"DIGIT" -
		"TCLCMD" -
		"TKCMD" {
			if {[$editor get $idx1 $idx2] eq $keyword} {
				$editor tag add $type $idx1 $idx2
			}
		}
		default {return}	
	}	
}

proc ::crowEditor::highlight_curr_pos {widget} {
	variable wInfo
	variable colorTbl
	if {![winfo exists $widget]} {return}
	set editor $wInfo($widget,editor)
	if {$wInfo($widget,colorEnabled) ==0} {
		foreach tag [array names colorTbl] {$editor tag remove $tag 1.0 end}
		return		
	}

	set idx1 [lindex [split [$editor index "insert"] "."] 0]
	set idx2 $idx1

	set startline 1.0
	for {set i [expr $idx1-1]} {$i > 1} {incr i -1} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set startline [incr i].0
			break
		}
	}

	set endidx [lindex [split [$editor index end] "."] 0]
	set endline end
	for {set i $idx2} {$i < $endidx} {incr i} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set endline [incr i].end
			break
		}
	}

	set data [$editor get $startline $endline]
	if {[string trim $data] eq ""} {return}
	::crowEditor::highlight_start $editor data [expr [lindex [split $startline "."] 0] -1]
}

proc ::crowEditor::highlight_curr_view {widget} {
	variable wInfo
	variable colorTbl
	if {![winfo exists $widget]} {return}	
	set editor $wInfo($widget,editor)
	if {$wInfo($widget,colorEnabled) ==0} {
		foreach tag [array names colorTbl] {$editor tag remove $tag 1.0 end}
		return
	}

	set idx1 [lindex [split [$editor index "@0,0"] "."] 0]
	set idx2 [lindex [split [$editor index "@[winfo width $editor],[winfo height $editor]"] "."] 0]
	
	set startline 1.0
	for {set i [expr $idx1-1]} {$i > 1} {incr i -1} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set startline [incr i].0
			break
		}
	}

	set endidx [lindex [split [$editor index end] "."] 0]
	set endline end
	for {set i $idx2} {$i < $endidx} {incr i} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set endline [incr i].end
			break
		}
	}
	set data [$editor get $startline $endline]
	if {[string trim $data] eq ""} {return}
	::crowEditor::highlight_start $editor data [expr [lindex [split $startline "."] 0] -1]
}

proc ::crowEditor::highlight_range {widget idx1 idx2} {
	variable wInfo
	variable colorTbl
	if {![winfo exists $widget]} {return}	
	set editor $wInfo($widget,editor)
	if {$wInfo($widget,colorEnabled) ==0} {
		foreach tag [array names colorTbl] {$editor tag remove $tag 1.0 end}
		return	
	}
	
	set idx1 [lindex [split [$editor index $idx1] "."] 0]
	set idx2 [lindex [split [$editor index $idx2] "."] 0]
	
	set startline 1.0
	for {set i [expr $idx1-1]} {$i > 1} {incr i -1} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set startline [incr i].0 
			break
		}
	}

	set endidx [lindex [split [$editor index end] "."] 0]
	set endline end
	for {set i $idx2} {$i < $endidx} {incr i} {
		if {[$editor get [list $i.end -1 chars]] ne "\\"} {
			set endline [incr i].end
			break
		}
	}
	set data [$editor get $startline $endline]
	if {[string trim $data] eq ""} {return}
	::crowEditor::highlight_start $editor data [expr [lindex [split $startline "."] 0] -1]
}

proc ::crowEditor::linebox_vsset {widget sender vs args} {
	::crowEditor::syntax_helper_hide $widget
	set editor $::crowEditor::wInfo($widget,editor)
	set yview [$sender yview]
	$::crowEditor::wInfo($widget,editor) yview moveto [lindex $yview 0]
	::crowEditor::highlight_curr_view $widget
	return
}

proc ::crowEditor::highlight_start {editor data lineno} {
	variable afterId
	variable synInterp
	upvar $data hldata
	$synInterp eval [list set ::crowSyntax::taskQueue [list $editor $hldata $lineno]]
	after cancel $afterId
	set afterId [after 50 [list $synInterp eval [list ::crowSyntax::parser_start]]]
	return
}

proc ::crowEditor::highlight_stop {} {
	variable synInterp
	$synInterp eval {set ::crowSyntax::::taskAbort 1}
	return
}

proc ::crowEditor::key_release {widget keycode keymap} {
	variable synHelper
	variable synHelperEnabled
	variable wInfo
	set editor $wInfo($widget,editor)
	set helper ""

	if {[info exists synHelper(fmeMain)]} {
		set helper $synHelper(fmeMain)
	}
	if {$helper ne "" && [winfo exists $helper]} {
		set currIdx [$editor index "insert"]
		set data [$editor get $synHelper(anchor) $currIdx]
		
		if {$keymap eq "Tab"} {
			if {($data ne "$synHelper(sel)\t") && ($synHelper(sel) ne "")} {
				set txt $synHelper(sel)
				switch -exact -- [string index $txt 0] {
					"!" {
						set txt [eval ::crowSyntax::[string range $txt 1 end]]
					}
				}
				::crowEditor::insert_text $widget $synHelper(anchor) $currIdx $txt
			}
			unset synHelper(fmeMain)
			after idle [list destroy $helper]
			return
		} else {
			foreach {l1 x1} [split $synHelper(anchor) "."] {}
			foreach {l2 x2} [split $currIdx "."] {}
			if {($l1 == $l2) && ($x2 >= $x1) && [regexp {\s+} $data]==0} {
				::crowEditor::syntax_helper_show $widget $synHelper(type) $synHelper(cmd) $data
			} else {
				unset synHelper(fmeMain)
				after idle [list destroy $helper]
				return
			}
		}
	}	
	if {[string length $keymap] > 1 && [string first $keymap "Control_L Shift_L Alt_L Shift_R Control_R Alt_R Caps_Lock Escape Insert"] >= 0} {
		::crowEditor::update_sel_range $widget
		return
	}

	$editor tag remove __MASK__ 1.0 end
	$editor tag add __MASK__ [$editor index "insert linestart"] [$editor index "insert lineend+1c"]

	set wInfo($widget,currPos) [$editor index "insert"]	

	if {[string length $keymap] > 1 && [string first $keymap  "Up Down Left Right Prior Next"] >= 0} {
		return
	}
	if {$keymap eq "Return"} {
		#<!-- apdding space
		set preword(line) [$editor get "insert -1 line linestart" "insert -1 line lineend"]
		set padding ""
		#find previous line prefix space
		if {[regexp {^\s+} $preword(line) sp]} {set padding $sp}
		# auto indent
		if {[string index [string trim $preword(line)] end] eq "\{"} {append padding "\t"}
		$editor insert insert $padding
		#-->
	} else {
		after idle [list ::crowEditor::highlight_curr_pos $widget]
	}

	::crowEditor::update_ch_flag $widget
	set wInfo($widget,maxLine) [expr [lindex [split [$editor index end] "."] 0] -1]
	
	if {$synHelperEnabled && [$editor get "insert -1 c"] eq "-"} {
		set synHelper(anchor) [$editor index "insert -1 c"]
		set sIdx [$editor index "insert linestart"]
		for {set i [lindex [split $synHelper(anchor) "."] 0]} {$i > 1} {incr i -1} {
			set ch [$editor get "$i.0 -1 line lineend -1 c"]
			if {$ch ne "\\"} {
				set sIdx $i.0
				break
			}
			
		}
		set data [$editor get $sIdx $synHelper(anchor)]
		#puts data=$data
		foreach cmdType {TKCMD TCLCMD} {
			set tag [$editor tag nextrange $cmdType $sIdx $synHelper(anchor)]
			set tags ""
			while {$tag ne ""} {
				if {$tags eq ""} {
					set tags $tag
				} else {
					set tags [concat $tags $tag]
				}
				set tag [$editor tag nextrange $cmdType [lindex $tag 1] $synHelper(anchor)]
			}
			switch -exact -- [llength $tags] {
				0 {continue}
				default {
					set len [string length $data]
					set cut 0
					set cut2 0
					for {set i 1} {$i<$len} {incr i} {
						set ch [$editor get "$synHelper(anchor) -$i c"]
						set tag [$editor tag names "$synHelper(anchor) -$i c"]
						if {($cut == 0) && ($cut2 == 0) && [lsearch $tag $cmdType] >= 0} {
							set tag [$editor tag nextrange $cmdType "$synHelper(anchor) -$i c wordstart" $synHelper(anchor)]
							foreach {idx1 idx2} $tag {}
							::crowEditor::syntax_helper_show $widget $cmdType [$editor get $idx1 $idx2] ""
		
							return
						}
						if {$ch eq "\]"} {incr cut}
						if {$ch eq "\["} {incr cut -1 ; if {$cut < 0} {break}}
						if {$ch eq "\}"} {incr cut2}
						if {$ch eq "\{"} {incr cut2 -1 ; if {$cut2 < 0} {break}}
					}
				}
			}
		}
	}
	if {$synHelperEnabled && $keymap eq "space"} {
		set tag [$editor tag nextrange TCLCMD "insert -2 c wordstart" "insert"]
		if {$tag ne ""} {
			foreach {idx1 idx2} $tag {}
			set synHelper(anchor) [$editor index insert]
			::crowEditor::syntax_helper_show $widget TCLCMD [$editor get $idx1 $idx2] ""
			return
		}
		set tag [$editor tag nextrange TKCMD "insert -2 c wordstart" "insert"]
		if {$tag ne ""} {
			foreach {idx1 idx2} $tag {}
			set synHelper(anchor) [$editor index insert]
			::crowEditor::syntax_helper_show $widget TKCMD [$editor get $idx1 $idx2] ""
			return
		}		
		set tag [$editor tag nextrange TCLARG "insert -2 c wordstart -1 c" "insert"]
		if {$tag ne ""} {
			foreach {idx1 idx2} $tag {}
			set synHelper(anchor) [$editor index insert]
			::crowEditor::syntax_helper_show $widget TCLARG [$editor get $idx1 $idx2] ""
			return
		}
		set tag [$editor tag nextrange TKARG "insert -2 c wordstart -1 c" "insert"]
		if {$tag ne ""} {
			foreach {idx1 idx2} $tag {}
			set synHelper(anchor) [$editor index insert]
			::crowEditor::syntax_helper_show $widget TKARG [$editor get $idx1 $idx2] ""
			return
		}		
	}
}

proc ::crowEditor::key_press {widget keycode keymap} {
	variable synHelper
	variable synHelperEnabled
	variable prePos
	variable wInfo
	
	set editor $wInfo($widget,editor)
	if {[info exists synHelper(fmeMain)]} {
		if {[winfo exists $synHelper(fmeMain)] && ($keymap eq "Up" || $keymap eq "Down")} {			
			set idx [$synHelper(lbox) curselection]
			if {$idx eq ""} {
				set idx 0
			} else {
				if {$keymap eq "Up"} {
					incr idx -1
				} else {
					incr idx 1
				}
				
			}
			$synHelper(lbox) selection clear 0 end
			$synHelper(lbox) selection set $idx
			$synHelper(lbox) see $idx
			focus $synHelper(lbox)
			after idle [format {
				set editor %s
				set pos %s
				$editor mark set insert $pos
				$editor tag add __MASK__ "$pos linestart" "$pos lineend"
				$editor see $pos
			} $editor $wInfo($widget,currPos)]
			return
		}
	}	

	if {$keymap eq "Return" || $keymap eq "Space"} {
		set prePos [$editor index insert]
	}

	# auto unindent
	# 221 = \}
	if {$keymap eq "braceright"} {
		if {[string trim [$editor get "insert linestart" "insert lineend"]] eq ""} {
			::crowEditor::remove_tab $widget
		}
	}	
	
}

proc ::crowEditor::post_menu {widget x y X Y} {
	::crowEditor::syntax_helper_hide $widget
	set editor $::crowEditor::wInfo($widget,editor)
		
	if {[winfo exists $editor.pMenu ]} {destroy $editor.pMenu}
	set m [menu $editor.pMenu -tearoff 0]
	
	set sel [::crowEditor::get_sel_range $widget]
	
	
	if {$sel eq ""} {
		#$m add command -compound left -label [::msgcat::mc "Cut word"] \
		#	-command [list ::crowEditor::cut_word $::crowEditor::wInfo($widget,editor)]
		$m add command -compound left -label [::msgcat::mc "Cut Line"] \
			-accelerator "Ctrl+k" \
			-command [list ::crowEditor::cut_line $widget]
	} else {
		$m add command -compound left -label [::msgcat::mc "Cut"] \
			-accelerator "Ctrl+x" \
			-command [list ::crowEditor::cut $widget]
	}	
	$m add separator
	
	if {$sel ne ""} {
		$m add command -compound left -label [::msgcat::mc "Copy"] \
			-accelerator "Ctrl+c" \
			-image [::crowImg::get_image copy] \
			-command [list ::crowEditor::copy $widget]
	}
	$m add command -compound left -label [::msgcat::mc "Paste"] \
			-accelerator "Ctrl+v" \
			-image [::crowImg::get_image paste] \
			-command [list ::crowEditor::paste $widget]
	if {$sel ne ""} {
		$m add command -compound left -label [::msgcat::mc "Delete"] \
			-image [::crowImg::get_image close] \
			-command [list ::crowEditor::cut $widget]
	}
	$m add separator
	if {$sel eq ""} {
		#$m add command -compound left -label [::msgcat::mc "Select word"] \
		#	-command [list ::crowEditor::sel_word $::crowEditor::wInfo($widget,editor)]
		$m add command -compound left -label [::msgcat::mc "Select Line"] \
			-accelerator "Ctrl+l" \
			-command [list ::crowEditor::sel_line $widget]
	}
	$m add command -compound left -label [::msgcat::mc "Select All"] \
		-accelerator "Ctrl+a" \
		-command [list ::crowEditor::sel_all $widget]
	
	$m add separator

	$m add cascade -compound left -label [::msgcat::mc "Insert Macro"] \
		-menu [::crowMacro::get_menu $m.macros "" [list ::crowEditor::insert_macro $widget]]
	if {$sel ne ""} {
		$m add command -compound left -label [::msgcat::mc "Save Macro"] \
			-command [list ::crowEditor::save_macro $widget]
	}	
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Undo"] \
		-accelerator "Ctrl+z" \
		-command [list catch "$::crowEditor::wInfo($widget,editor) edit undo"]
	$m add command -compound left -label [::msgcat::mc "Redo"] \
		-command [list catch "$::crowEditor::wInfo($widget,editor) edit redo"]
			
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Add Block Comment"] \
		-command [list ::crowEditor::insert_comment $widget]
	$m add command -compound left -label [::msgcat::mc "Remove Block Comment"] \
		-command [list ::crowEditor::remove_comment $widget]
		
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Indent Selection"] \
		-accelerator "Ctrl+Period" \
		-command [list ::crowEditor::insert_tab $widget]
	$m add command -compound left -label [::msgcat::mc "Unindent Selection"] \
		-accelerator "Ctrl+Comma" \
		-command [list ::crowEditor::remove_tab $widget]
	
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Jump To..."] \
		-accelerator "Ctrl+g" \
		-command [list ::crowEditor::show_goto $widget ""] 	
	$m add command -compound left -label [::msgcat::mc "Find/Replace..."] \
		-accelerator "Ctrl+f" \
		-image [::crowImg::get_image find] \
		-command [list ::crowEditor::show_find $widget]

	$m add separator	
	$m add command -compound left -label [::msgcat::mc "Save"] \
		-accelerator "Ctrl+s" \
		-image [::crowImg::get_image save] \
		-command [list ::crowEditor::save $widget]
	
	::crowEditor::goto_pos $widget [$editor index "@$x,$y"]
	tk_popup $m $X $Y	
	return
}

proc ::crowEditor::replace {widget} {
	variable wInfo
	variable wVars
	if {![winfo exists $widget]} {set widget $wInfo(CrowEditor,current)}
	if {![winfo exists $widget]} {return}
	set editor $wInfo($widget,editor)
	
	if {$wVars(keyword) eq ""} {return}
	set ranges [$editor tag ranges FIND]
	if {$ranges ne ""} {
		::crowEditor::insert_text $widget [lindex $ranges 0] [lindex $ranges 1] $wVars(replace)
	}
}

proc ::crowEditor::replaceAll {widget} {
	variable wInfo
	variable wVars
	if {![winfo exists $widget]} {set widget $wInfo(CrowEditor,current)}
	if {![winfo exists $widget]} {return}
	set editor $wInfo($widget,editor)

	if {$wVars(keyword) eq ""} {return}
	set cut 0
	set rcut 0
	set arg ""
	set idx "1.0"
	
	if {$::crowEditor::wVars(direct)} {
		set wVars(prevFind) "1.0"
		append arg "-forwards"
		set endidx end
	} else {
		set wVars(prevFind) "end"
		append arg "-backwards"
		set endidx 1.0
	}

	if {$wVars(matchRegexp)} {
		append arg " -regexp"
	} else {
		append arg " -exact"
	}
	
	if {$wVars(matchAa) == 0} {
		append arg " -nocase"
	}

	set matchLen 0
	set idx [eval "$editor search $arg -count matchLen -- {$wVars(keyword)} {$wVars(prevFind)} $endidx"]
	while {$idx ne ""} {
		incr rcut
		 ::crowEditor::insert_text $widget $idx "$idx + $matchLen c" $wVars(replace)
		if {$::crowEditor::wVars(direct)} {
			set wVars(prevFind) [concat $idx + [string length $wVars(replace)] c]
		} else {
			set wVars(prevFind) [concat $idx - [string length $wVars(replace)] c]
		}
		set matchLen 0
		set idx [eval "$editor search $arg -count matchLen -- {$wVars(keyword)} {$wVars(prevFind)} $endidx"]
	}
	tk_messageBox -title [::msgcat::mc "Information"] -type ok -icon info \
		-message [concat [::msgcat::mc "Replace"] $rcut [::msgcat::mc "Items"]]
}

proc ::crowEditor::save_macro {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set sel [::crowEditor::get_sel_range $widget]
	if {$sel eq ""} {return}
	::crowMacro::add [$editor get [lindex $sel 0] [lindex $sel 1]]
	return
}

proc ::crowEditor::syntax_helper_hide {widget} {
	variable synHelper
	set editor $::crowEditor::wInfo($widget,editor)
	if {[info exists synHelper(fmeMain)] && [winfo exists $synHelper(fmeMain)]} {
		destroy $synHelper(fmeMain)
	}
}

proc ::crowEditor::syntax_helper_show {widget type cmd arg} {
	variable synHelper
	set editor $::crowEditor::wInfo($widget,editor)
	set currIdx [$editor index insert]
	set endIdx [$editor index "insert lineend"]
	foreach {x y w h b} [$editor dlineinfo $currIdx] {}
	set pos ""
	set idx 1.0
	set i [expr $x + [lindex [split $currIdx "."] 1]* 2]
	set w [expr [winfo width $editor] + 30]
	while {$idx != $endIdx} {
		set idx [$editor index @$i,$y]
		if { $idx eq $currIdx} {
			set pos [list $i [expr $y+$h]]
			break
		}		
		incr i 3
		if {$i > $w} {return}
	}
	if {$pos eq ""} {return}
	set fmeHelper $editor.synHelper
	if {![winfo exists $fmeHelper]} {
		set synHelper(items) ""
		switch -exact $type {
			"TKCMD" {
				set synHelper(items) [::crowSyntax::get_tk_args $cmd]
			}
			"TCLCMD" {
				set synHelper(items) [::crowSyntax::get_tcl_args $cmd]
			}
			"TCLARG" -
			"TKARG" {
				set synHelper(items) [::crowSyntax::get_arg_values $cmd]
			}			
		}

		if {$synHelper(items) eq ""} {return}
		frame $fmeHelper -bd 1 -relief solid -cursor left_ptr -background white
		set synHelper(cmd) $cmd
		set synHelper(type) $type
		set lblCmd [label $fmeHelper.lblCmd -text $cmd -bd 2 -relief groove \
			-font [::crowFont::get_font small]]
		set lblX [label $lblCmd.lblX -text x -bd 1 -relief flat -width 2]
		set sw [ScrolledWindow $fmeHelper.sw]
		set lbox [listbox $sw.lbox -selectmode browse -relief flat -bd 4 \
			-font [::crowFont::get_font small] \
			-highlightthickness 0 \
			-bg white]
		$sw setwidget $lbox
		set ch [$editor get "insert -1 c"]
		set flag 0
		set tmp ""
		foreach item $synHelper(items) {
			if {$ch eq "-"} {
				if {[string index $item 0] ne "-"} {continue}
				$lbox insert end $item
				lappend tmp $item
				set flag 1
			} else {
				if {[string index $item 0] eq "-"} {continue}
				$lbox insert end $item
				lappend tmp $item
				set flag 1
			}
		}
		set synHelper(items) $tmp
		if {!$flag} {
			destroy $fmeHelper
			return
		}
		pack $lblX -side right
		pack $lblCmd -fill x -side top -padx 1 -pady 1
		pack $sw -expand 1 -fill both
		$lbox selection clear 0 end
		set synHelper(sel) ""
		bind $lblX <Enter> {%W configure -bd 1 -relief raised}
		bind $lblX <Leave> {%W configure -bd 1 -relief flat}
		bind $lblX <Button-1> [list destroy $fmeHelper]
		bind $lbox <Double-Button-1> [list after idle [list ::crowEditor::synHelper_dclick $widget]]
		bind $lbox <Key-Tab> [list after idle [list ::crowEditor::synHelper_dclick $widget]]
		set synHelper(lbox) $lbox
	} else {
		set idx [lsearch -glob $synHelper(items) $arg*]
		set synHelper(sel) [lindex $synHelper(items) $idx]
		$synHelper(lbox) selection clear 0 end
		if {$idx >= 0} {
			$synHelper(lbox) selection set $idx
			$synHelper(lbox) see $idx
		} else {
			$synHelper(lbox) see 0
		}
	}
	foreach {x y} $pos {}
	set h [winfo height $editor]
	set w [winfo width $editor]
	if {$y > ($h - 200)} {incr y -220}
	if {$x > ($w - 180)} {incr x -190}
	set synHelper(fmeMain) $fmeHelper
	place $fmeHelper -x $x -y $y -height 200 -width 180
}

proc ::crowEditor::set_color {type title btn} {
	variable colorTbl
	variable rc
	set color [tk_chooseColor -title $title -initialcolor $colorTbl($type)]
	if {$color eq "" || $color eq "-1"} {return}
	set colorTbl($type) $color
	::crowRC::param_set $rc CrowEditor.Color.$type $color
	$btn configure -bg $color
}

proc ::crowEditor::synHelper_dclick {widget args} {
	variable synHelper
	variable wInfo
	set idx [$synHelper(lbox) curselection]
	if {$idx eq ""} {return}
	set item [lindex $synHelper(items) $idx]
	
	destroy $synHelper(fmeMain)
	unset synHelper(fmeMain)
	
	switch -exact -- [string index $item 0] {
		"!" {
			set item [eval ::crowSyntax::[string range $item 1 end]] 
		}
	}
	set editor $wInfo($widget,editor)
	::crowEditor::insert_text $widget $synHelper(anchor) [$editor index "insert"] $item
	focus $editor
	return
}

proc ::crowEditor::trace_currpos {widget name1 name2 op} {
	set editor $::crowEditor::wInfo($widget,editor)
	puts sbar currpos $::crowEditor::wInfo($widget,currPos)
	return
}

proc ::crowEditor::trace_maxline {widget name1 name2 op} {
	set maxLine $::crowEditor::wInfo($widget,maxLine)
	set editor $::crowEditor::wInfo($widget,editor)
	set lineBox $::crowEditor::wInfo($widget,lineBox)
	set currLine [expr [lindex [split [$lineBox index end] "."] 0] -2]
	$lineBox configure -state normal

	if {$maxLine > $currLine} {
		for {set i $currLine} {$i < $maxLine} {incr i} {
			$lineBox insert end [string range "00000[expr $i+1]" "end-4" end]\n
		}
	} elseif {$currLine > $maxLine} {
		$lineBox delete "[expr $maxLine+1].0" end
		$lineBox insert end "\n"
		after idle [list ::crowEditor::highlight_curr_view $widget]
	}
	
#	$lineBox configure -state disabled
	$lineBox yview moveto [lindex [$editor yview] 0]
	puts sbar maxline $maxLine
	return
}

proc ::crowEditor::trace_modified {widget name1 name2 op} {
	set cmd $::crowEditor::wInfo($widget,modified_cb)
	if {$cmd eq ""} {return}
	eval [concat $cmd $::crowEditor::wInfo($widget,modified)]
	return
}

proc ::crowEditor::update_ch_flag {widget} {
	set editor $::crowEditor::wInfo($widget,editor)
	set ::crowEditor::wInfo($widget,modified) [$editor edit modified]
	set ::crowEditor::wInfo($widget,lastModify) [clock seconds]
	return
}

proc ::crowEditor::update_sel_range {widget} {
	variable wInfo
	set wInfo(CrowEditor,sel) [::crowEditor::get_sel_range $widget]
	return
}

proc ::crowEditor::visibility {widget} {
	variable wInfo
	variable wVars
	set wInfo(CrowEditor,current) $widget
	set wVars(prevFind) "1.0"
	set editor $wInfo($widget,editor)
	set fpath $wInfo($widget,file)
	$editor tag remove FIND 1.0 end
	::crowEditor::goto_pos $widget $wInfo($widget,currPos)
	after idle [list ::crowEditor::highlight_curr_view $widget]
	
	::crowEditor::breakpoint_load $widget
	
	
	focus $editor
		
}


