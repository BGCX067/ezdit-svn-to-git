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

package provide crowSyntax 1.0
package require Tclparser

namespace eval ::crowSyntax {
	variable currTok ""
	variable currCmd ""
	
	variable taskQueue ""
	variable taskAbort 0
	
	variable EOF
	variable EOS
	variable EOS2
	
	variable tclKeywords
	array set tclKeywords ""

	variable tkKeywords
	array set tkKeywords ""
	
	variable currEditor ""
	
	variable argValues
	array set argValues ""
	
}

proc ::crowSyntax::init {} {
	::crowSyntax::load_tcl_keyword
	::crowSyntax::load_tk_keyword
}

proc ::crowSyntax::parser_start {} {
	variable currCmd
	variable currTok
	variable EOF
	variable EOS
	variable EOS2
	variable currEditor
	variable taskQueue
	variable taskAbort
		
	set currCmd ""
	set currTok ""
	set EOF [geteof]
	set EOS [geteos]
	set EOS2 "[geteos]_2"
	
	if {$taskQueue eq ""} {return}
	foreach {currEditor data lineno} $taskQueue {break}
	set taskQueue ""
	set taskAbort 0
	::crowSyntax::parsing data $lineno 0
	set taskAbort 1
	set currEditor ""
}

proc ::crowSyntax::parsing {data startline startpc} {
	variable currTok
	variable taskAbort
	variable EOF
	variable EOS
	variable EOS2
	variable currEditor
	variable tclKeywords
	variable tkKeywords
	upvar $data code

	set idx0 -$startpc
	set lineno $startline
	set currCmd ""
	set tp [new_Tclparser $code $startline]
	while {[set tok [$tp gettok]] ne $EOF} {
		if {$taskAbort} {
			after idle ::crowSyntax::parser_start
			break
		}
		if {$tok eq $EOS2} {continue}
		if {$tok eq $EOS} {
			set idx0 [expr [$tp getpc] + 1]
			set lineno [expr [$tp getlineno] + 1]
			set currCmd ""
			continue
		}

		if {$lineno ne [$tp getlineno]} {set idx0 [expr [$tp getpc2] + 1]}
		set lineno [$tp getlineno]
		set lineno2 [expr $lineno +1]
		set idx2 [expr [$tp getpc] - $idx0]
		set idx1 [expr $idx2 - [string length $tok]]
		set ch [string index $tok 0]		

		if {$ch eq "\""} {
			set s1 $lineno2.[incr idx1]
			incr idx2
			set s2 "$s1+[expr $idx2-$idx1]c"
			::crowEditor::highlight_cb $currEditor STRING STRING $s1 $s2
			continue
		}
		
		if {($ch eq "\{" || $ch eq "\[") && ($idx2 > $idx1 + 3 )} {
			#set currCmd ""
			if {$ch eq "\{"} {incr idx1}
			::crowSyntax::parsing tok $lineno [incr idx1]
			continue
		}
			
		::crowEditor::highlight_cb $currEditor CLEAR CLEAR $lineno2.$idx1 $lineno2.$idx2

		if {$ch eq "#"} {
			set currCmd ""
			set dlen [string length $tok]
			::crowEditor::highlight_cb $currEditor COMMENT COMMENT $lineno2.$idx1 "$lineno2.$idx1+${dlen}c"
			continue
		}
		
		if {$currCmd ne ""} {
			if {[info exists tclKeywords($currCmd)] && [lsearch -sorted -dictionary -increasing -exact $tclKeywords($currCmd) $tok] != -1} {
				::crowEditor::highlight_cb $currEditor TCLARG $tok $lineno2.$idx1 $lineno2.$idx2
				continue
			}
			if {[info exists tkKeywords($currCmd)]} {
				if {[lsearch -sorted -dictionary -increasing -exact $tkKeywords($currCmd) $tok] != -1} {
					::crowEditor::highlight_cb $currEditor TKARG $tok $lineno2.$idx1 $lineno2.$idx2
					continue
				}
			}
		}
		if {[info exists tclKeywords($tok)]} {
			::crowEditor::highlight_cb $currEditor TCLCMD $tok $lineno2.$idx1 $lineno2.$idx2
			set currCmd $tok
			continue
		}
		if {[info exists tkKeywords($tok)]} {
			::crowEditor::highlight_cb $currEditor TKCMD $tok $lineno2.$idx1 $lineno2.$idx2
			set currCmd $tok
			continue
		}
		
		if {[string is double $tok]} {
			::crowEditor::highlight_cb $currEditor DIGIT $tok $lineno2.$idx1 $lineno2.$idx2
			continue
		}		
		#set currCmd ""	
		if {[string first "\[" $tok] > 0 } {
			set strlen [string length $tok]
			set sidx 0
			set cut 0
			for {set i 0} {$i<$strlen} {incr i} {
				set c [string index $tok $i]
				if {$c eq "\\"} {incr i ; continue}
				if {$sidx >0} {
					if {$c eq "\["} {incr cut ; continue}
					if {$c eq "\]"} {
						if {[incr cut -1] == 0 } {
							set tok [string range $tok $sidx $i]
							::crowSyntax::parsing tok $lineno [expr $idx1 + $sidx +1]
							set sidx 0
						}
					}
					continue
				} else {
					if {$c eq "\["} {
						set sidx $i
						incr cut
						continue
					}
				}
			}
		}

		if {[string first "\$" $tok] >= 0} {
			set vars [regexp -indices -all -inline -- {\$\{?\:{0,2}[a-zA-Z0-9_]+\}?} $tok]
			foreach {idx} $vars {
				set oft1 [lindex $idx 0]
				set oft2 [lindex $idx 1]
				set var [string range $tok $oft1 $oft2]
				set oft1 [expr $idx1 + $oft1]
				set oft2 [expr $idx1 + $oft2 + 1]
				::crowEditor::highlight_cb $currEditor VARIABLE $var $lineno2.$oft1 $lineno2.$oft2
			}
		}
	}
	delete_Tclparser $tp
}


proc ::crowSyntax::chooseColor {} {
	set c [tk_chooseColor]
	if {$c eq ""} {return}
	return "\"$c\""
}

proc ::crowSyntax::chooseCursor {} {
	variable argValues
	variable vars
	
	set win [toplevel .crowSyntax_chooseCursor ]
	set fmeMain [frame $win.fmeMain ]
	set sv [scrollbar $fmeMain.sv -command [list $fmeMain.lbox yview]]
	set lbox [listbox $fmeMain.lbox -background white -bd 2 -relief groove \
		-yscrollcommand [list $sv set] ]
	foreach item [list X_cursor arrow based_arrow_down based_arrow_up boat bogosity bottom_left_corner \
			 bottom_right_corner bottom_side bottom_tee box_spiral center_ptr circle clock \
			 coffee_mug cross cross_reverse crosshair diamond_cross dot dotbox double_arrow \
			 draft_large draft_small draped_box exchange fleur gobbler gumby hand1 hand2 heart \
			 icon iron_cross left_ptr left_side left_tee leftbutton ll_angle lr_angle man \
			 middlebutton mouse pencil pirate plus question_arrow right_ptr right_side right_tee \
			 rightbutton rtl_logo sailboat sb_down_arrow sb_h_double_arrow sb_left_arrow \
			 sb_right_arrow sb_up_arrow sb_v_double_arrow shuttle sizing spider spraycan star \
			 target tcross top_left_arrow top_left_corner top_right_corner top_side top_tee trek \
			 ul_angle umbrella ur_angle watch xterm] {
		$lbox insert end $item
	}
	bind $lbox <Button-1> {
		set sel [%W curselection]
		if {$sel ne ""} {
			%W configure -cursor [%W get $sel]
			set ::crowSyntax::vars(chooseCursorSel) [%W get $sel]
		}
	}
	set vars(chooseCursor) $win
	set vars(chooseCursorFlag) "Cancel"
	set vars(chooseCursorSel) ""
	set fmeBtn [frame $fmeMain.fmeBtn]
	button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -command {
		set ::crowSyntax::vars(chooseCursorFlag) "Ok"
		destroy $::crowSyntax::vars(chooseCursor)
	}
	button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -command [list destroy $win]
	pack $fmeBtn.btnOk $fmeBtn.btnCancel -side left -expand 1 -ipadx 3 -ipady 3
	
	grid $lbox -row 0 -column 0 -sticky "news"
	grid $sv -row 0 -column 1 -sticky "ns"
	grid $fmeBtn -row 1 -column 0 -columnspan 2 -sticky "we"
	
	grid rowconfigure $fmeMain 0 -weight 1
	grid columnconfigure $fmeMain 0 -weight 1
	
	pack $fmeMain -expand 1 -fill both
	
	update
	set geometry [split [lindex [split [wm geometry $win] "+"] 0] "x"]
	set w [lindex $geometry end-1]
	set h [lindex $geometry end]
	set x [expr {([winfo screenwidth .]/2 - $w/2)}]
	set y [expr {([winfo screenheight .]/2 - $h/2)}]
	wm geometry $win +$x+$y
	wm resizable $win 0 0	
	
	tkwait window $win
	if {$vars(chooseCursorFlag) eq "Ok"} {
		set ret "\"$vars(chooseCursorSel)\""
	} else {
		set ret ""
	}
	destroy $win
	return $ret
}

proc ::crowSyntax::load_tcl_keyword {} {
	variable tclKeywords
	variable argValues
	array set tclKeywords [list \
		after [list cancel idle info] \
		append "" \
		array [list anymore donesearch exists get names nextelement set size startsearch statistics unset] \
		auto_execok "" \
		auto_load "" \
		auto_mkindex "" \
		auto_mkindex_old "" \
		auto_qualify "" \
		auto_reset "" \
		bgerror "" \
		binary [list format scan] \
		break "" \
		catch "" \
		cd "" \
		clock [list clicks format scan seconds] \
		close "" \
		concat "" \
		continue "" \
		dde [list eval execute poke request servername services] \
		encoding [list convertfrom convertto names system] \
		eof "" \
		error "" \
		eval "" \
		exec "" \
		expr "" \
		else "" \
		elseif "" \
		fblocked "" \
		fconfigure [list -blocking -buffering -buffersize -encoding -eofchar -translation] \
		fcopy [list -size -command] \
		file [list atime attributes channels copy delete dirname executable exists extension isdirectory \
			isfile join link lstat mkdir mtime nativename normalize owned pathtype readable readlink \
			rename rootname separator size split stat system tail type volumes writable] \
		fileevent [list readable writable] \
		filename "" \
		flush "" \
		for "" \
		foreach "" \
		format "" \
		gets "" \
		glob [list -directory -join -nocomplain -path -tails -types] \
		global "" \
		history [list add change clear event info keep nextid redo] \
		http "" \
		if "" \
		info [list args body cmdcount commands complete default exists functions globals hostname level \
			library loaded locals nameofexecutable patchlevel proc script sharedlibextension \
			tclversion vars] \
		incr "" \
		interp [list alias create delete eval exists expose hide hidden invokehidden issafe marktrusted \
			recursionlimit share slaves target transfer] \
		lappend "" \
		lindex "" \
		linsert "" \
		list "" \
		llength "" \
		load "" \
		lrange "" \
		lreplace "" \
		lsearch [list -all -ascii -decreasing -dictionary -exact -glob -increasing -inline -integer -not \
			-real -regexp -sorted -start] \
		lset "" \
		lsort [list -ascii -dictionary -integer -real -command -increasing -decreasing -index -unique] \
		memory [list active break_on_malloc info init onexit tag trace trace_on_at_malloc validate] \
		msgcat ""\
		namespace [list children code current delete eval exists export forget import inscope origin \
			parent qualifiers tail which] \
		open "" \
		package parray  pid pkg pkg_mkIndex proc puts pwd \
		package [list forget ifneeded names present provide require unknow vcompare versions vsatisfies] \
		parray "" \
		pid "" \
		pkg [list -name -version -load -source] \
		pkg_mkIndex [list -direct -lazy -load -verbose] \
		proc "" \
		puts [list -nonewline] \
		pwd "" \
		re_syntax "" \
		read [list -nonewline] \
		regexp [list -about -expanded -indices -line -linestop -lineanchor -nocase -all -inline -start] \
		registry [list broadcase delete get keys set type values] \
		regsub [list -all -expanded -line -linestop -lineanchor -nocase -start] \
		rename "" \
		resource [list close delete files list open read types write] \
		return [list -code -errorinfo -errorcode] \
		scan "" \
		seek [list start current end] \
		set "" \
		socket [list -server -myaddr -myport -anync -error -sockname -peername] \
		source [list -rsrc -rsrcid] \
		split "" \
		string [list bytelength compare first index is last length map match \
			range repeat replace tolower \
			totitle toupper trim trimleft trimright wordend wordstart] \
		subst [list -nobackslashes -nocommands -novariables] \
		switch [list -exact -glob -regexp] \
		trace [list add remove info variable vdelete vinfo] \
		tcl_endOfWord "" \
		tcl_findLibrary "" \
		tcl_startOfNextWord "" \
		tcl_startOfPreviousWord "" \
		tcl_wordBreakAfter "" \
		tcl_wordBreakBefore "" \
		tcltest "" \
		tclvars "" \
		tell "" \
		time "" \
		unknown "" \
		unset "" \
		update "" \
		uplevel "" \
		upvar "" \
		variable "" \
		vwait "" \
		while "" \
	]
	foreach key [array names tclKeywords] {
		set tclKeywords($key) [lsort -dictionary -increasing $tclKeywords($key)]
	}
	array set argValues [list \
		require [lsort -dictionary -increasing [package names]] \
	]
	
	return	
}

proc ::crowSyntax::load_tk_keyword {} {
	variable tkKeywords
	variable argValues
	array set tkKeywords [list \
		bell [list -displayof -nice] \
		bind "" \
		bindtags "" \
		bitmap [list -background -data -file -foreground -maskdata -maskfile ]  \
		button [list -text -command -relief -default -borderwidth -bd -state -height -textvariable -width \
			-activebackground -activeforeground -anchor -background -bg -bitmap -compound \
			-cursor -disabledforeground -font -foreground -fg -highlightbackground -highlightcolor \
			-highlightthickness -image -justify -padx -pady -repeatdelay -repeatinterval \
			-takefocus -underline -wraplength -overrelief] \
		canvas [list -closeenough -confine -height -scrollregion -width \
			-xscrollincrement -yscrollincrement -background -bg -borderwidth -bd \
			-cursor -highlightbackground -highlightcolor -highlightthickness -insertbackground \
			-insertborderwidth -insertofftime -insertontime -insertwidth -relief -selectbackground \
			-selectborderwidth -selectforeground -state -takefocus -xscrollcommand -yscrollcommand] \
		checkbutton [list -command -height -indicatoron -offrelief -offvalue -onvalue \
			-overrelief -selectcolor -selectimage -state -variable -width -activebackground -activeforeground \
			-anchor -background -bg -bitmap -borderwidth -bd -compound -cursor -disabledforeground -font \
			-foreground -fg -highlightbackground -highlightcolor -highlightthickness -image -justify -padx -pady \
			-relief -takefocus -text -textvariable -underline -wraplength] \
		clipboard [list clear append get] \
		console [list eval hidden show title] \
		destroy "" \
		entry [list -disabledbackground -disabledforeground -invalidcommand -invcmd \
			-readonlybackground -show -state -validate -validatecommand -vcmd -width -background -bg -borderwidth \
			-bd -cursor -exportselection -font -foreground -fg -highlightbackground -highlightcolor -highlightthickness \
			-insertbackground -insertborderwidth -insertofftime -insertontime -insertwidth -justify -relief -selectbackground \
			-selectborderwidth -selectforeground -takefocus -textvariable -xscrollcommand] \
		event [list -above -borderwidth -button -count -delta -detail -focus -height -keycode \
			-keysym -mode -override -place -root -rootx -rooty -sendevent -serial -state \
			-subwindow -time -warp -width -when -x -y ] \
		focus [list -displayof -force -lastfor ] \
		font [list actual -displayof configure create delete families measure metrics names \
			-family -size -weight -slant -underline -overstrike ] \
		frame [list -background -class -colormap -container -height -visual -width -borderwidth -bd -cursor -highlightbackground \
			-highlightcolor -highlightthickness -padx -pady -relief -takefocus] \
		grab [list -global current release set status] \
		grid [list bbox columnconfigure configure -column -columnspan -in -ipadx -ipady \
			-padx -pady -row -rowspan -sticky forget info location propagate rowconfigure \
			remove size slaves -weight] \
		image [list create delete height inuse type types width photo bitmap] \
		label [list -height -state -width -activebackground -activeforeground -anchor -background -bg -bitmap -borderwidth -bd \
			-compound -cursor -disabledforeground -font -foreground -fg -highlightbackground -highlightcolor -highlightthickness \
			-image -justify -padx -pady -relief -takefocus -text -textvariable -underline -wraplength] \
		labelframe [list -background -class -colormap -container -height -labelanchor -labelwidget -visual -width -borderwidth \
				-bd -cursor -font -foreground -fg -highlightbackground -highlightcolor -highlightthickness -padx \
				-pady -relief -takefocus -text] \
		listbox [list -activestyle -height -listvariable -selectmode -width -background -bg -borderwidth \
				-bd -cursor -disabledforeground -exportselection -font -foreground -highlightbackground \
				-highlightcolor -highlightthickness -relief -selectbackground -selectborderwidth -selectforeground \
				-setgrid -state -takefocus -xscrollcommand -yscrollcommand] \
		loadTk "" \
		lower "" \
		menu [list -postcommand -tearoff -tearoffcommand -title -type -activebackground \
			-activeforeground -accelerator -background -bitmap -columnbreak -command -compound \
			-font -foreground -hidemargin -image -indicatoron -label -menu -offvalue -onvalue \
			-selectcolor -selectimage -state -underline -value -variable -activeborderwidth \
			-bg -borderwidth -bd -cursor -disabledforeground -relief -takefocus] \
		menubutton [list -direction -height -indicatoron -menu -state -width -activebackground -activeforeground -anchor \
				-background -bg -bitmap -borderwidth -bd -compound -cursor -disabledforeground -font -foreground \
				-fg -highlightbackground -highlightcolor -highlightthickness -image -justify -padx -pady -relief \
				-takefocus -text -textvariable -underline -wraplength] \
		message [list -aspect -justify -width -anchor -background -bg -borderwidth -bd -cursor -font -foreground -fg \
			-highlightbackground -highlightcolor -highlightthickness -padx -pady -relief -takefocus -text -textvariable ] \
		option [list add clear get readfile ] \
		options [list -activebackground -activeborderwidth -activeforeground -anchor -background -bg -bitmap -borderwidth \
		  -bd -compound -cursor -disabledforeground -exportselection -font -foreground -fg -highlightbackground \
		  -highlightcolor -highlightthickness -image -insertbackground -insertborderwidth -insertofftime -insertontime \
		  -insertwidth -jump -justify -orient -padx -pady -relief -repeatdelay -repeatinterval -selectbackground \
		  -selectborderwidth -selectforeground -setgrid -takefocus -text -textvariable -troughcolor -underline -wraplength \
		  -xscrollcommand -yscrollcommand ] \
		pack [list slave configure -after -anchor -before -expand -fill -in -ipadx -ipady \
			-padx -pady -side forget info propagate slaves] \
		panedwindow [list -handlepad -handlesize -opaqueresize -sashcursor -sashpad -sashrelief \
				-sashwidth -showhandle -background -bg -borderwidth -bd -cursor -height -orient -relief -width ] \
		photo [list -data -format -file -gamma -height -palette -width ] \
		place [list configure -anchor -bordermode -height -in -relheight -relwidth \
			-relx -rely -width -x -y forget info slaves ] \
		radiobutton [list -command -height -indicatoron -selectcolor -offrelief -overrelief \
				-selectimage -state -value -variable -width -activebackground -activeforeground -anchor -background \
				-bg  -bitmap -borderwidth -bd -compound -cursor -disabledforeground -font -foreground -fg -highlightbackground \
				-highlightcolor -highlightthickness -image -justify -padx -pady -relief -takefocus -text -textvariable \
				-underline -wraplength] \
		raise "" \
		scale [list -bigincrement -command -digits -from -label -length -resolution -showvalue \
			-sliderlength -sliderrelief -state -tickinterval -to -variable -widt -activebackground -background -bg \
			-borderwidth -bd -cursor -font -foreground -fg -highlightbackground -highlightcolor -highlightthickness \
			-orient -relief -repeatdelay -repeatinterval -takefocus -troughcolor] \
		scrollbar [list -activerelief -command -elementborderwidth -width -activebackground -background -bg -borderwidth -bd \
				-cursor -highlightbackground -highlightcolor -highlightthickness -jump -orient -relief -repeatdelay \
				-repeatinterval -takefocus -troughcolor] \
		selection [list clear get handle own -displayof -selection -type -format -command ] \
		send [list -async -displayof] \
		spinbox [list -buttonbackground -buttoncursor -buttondownrelief -buttonuprelief -command \
			-disabledbackground -disabledforeground -format -from -invalidcommand -invcmd \
			-increment -readonlybackground -state -to -validate -validatecommand -vcmd -values -width \
			-activebackground -background -bg -borderwidth -bd -cursor -exportselection -font -foreground -fg \
			-highlightbackground -highlightcolor -highlightthickness -insertbackground -insertborderwidth -insertofftime \
			-insertontime -insertwidth -justify -relief -repeatdelay -repeatinterval -selectbackground -selectborderwidth \
			-selectforeground -takefocus -textvariable -xscrollcommand] \
		text [list -autoseparators -height -maxundo -spacing1 -spacing2 -spacing3 -state -tabs -undo \
			-width -wrap -background -bgstipple -borderwidth -elide -fgstipple -font -foreground \
			-justify -lmargin1 -lmargin2 -offset -overstrike -rmargin -underline -align -create \
			-stretch -window -image -name -bg -bd -cursor -exportselection -fg -highlightbackground \
			-highlightcolor -highlightthickness -insertbackground -insertborderwidth -insertofftime \
			-insertontime -insertwidth -padx -pady -relief -selectbackground -selectborderwidth \
			-selectforeground -setgrid -takefocus -xscrollcommand -yscrollcommand ] \
		tk [list tk appname caret window scaling -displayof useinputmethods windowingsystem ] \
		tk_setPalette "" \
		tk_setPalette [list name] \
		tk_bisque "" \
		tk_chooseColor [list -initialcolor -parent -title] \
		tk_chooseDirectory [list -initialdir -parent -title -mustexist ] \
		tk_dialog "" \
		tk_focusFollowsMouse "" \
		tk_focusNext "" \
		tk_focusPrev "" \
		tk_getOpenFile [list -defaultextension -filetypes -initialdir -initialfile -multiple -message \
				-parent -title ] \
		tk_menuSetFocus "" \
		tk_messageBox [list -default -icon -message -parent -title -type ] \
		tk_optionMenu "" \
		tk_popup "" \
		tk_textCopy "" \
		tk_textCut "" \
		tk_textPaste "" \
		tkerror "" \
		tkwait [list variable visibility window ] \
		toplevel [list -background -class -colormap -container -height -menu -screen -use -visual -width \
				-borderwidth -bd -cursor -highlightbackground -highlightcolor -highlightthickness \
				-padx -pady -relief -takefocus] \
		winfo [list atom atomname cells children class colormapfull containing depth exists \
			fpixels geometry height id interps ismapped manager name parent pathname pixels pointerx \
			pointerxy pointery reqheight reqwidth rgb rootx rooty screen screencells screendepth \
 			screenheight screenmmheight screenmmwidth screenvisual screenwidth server toplevel  \
 			visual visualid visualsavailable vrootheight vrootwidth vrootx vrooty width x y ] \
 		wm [list aspect attributes client colormapwindows command deiconify \
			focusmodel frame geometry grid group iconbitmap iconify iconmask iconname iconposition \
			iconwindow maxsize minsize overrideredirect positionfrom protocol resizable sizefrom \
			stackorder state title transient withdraw] \
	]
	foreach key [array names tkKeywords] {
		set tkKeywords($key) [lsort -dictionary -increasing $tkKeywords($key)]
	}
	
	array set argValues [list \
		-activebackground "!chooseColor" \
		-activeborderwidth ""\
		-activeforeground "!chooseColor" \
		-anchor [list n ne e se s sw w nw center] \
		-background "!chooseColor" \
		-bg "!chooseColor" \
		-bitmap [list error gray75 gray50 gray25 gray12 hourglass info questhead question \
				warning document stationery edition application accessory folder pfolder \
				trash floppy ramdisk cdrom preferences querydoc stop note caution ] \
		-borderwidth "" \
		-bd "" \
		-compound [list none bottom top left right center] \
		-cursor "!chooseCursor" \
		-disabledforeground  "!chooseColor" \
		-exportselection [list yes no] \
		-foreground "!chooseColor" \
		-fg "!chooseColor" \
		-highlightbackground "!chooseColor" \
		-highlightcolor "!chooseColor" \
		-highlightthickness [list true false] \
		-image "" \
		-insertbackground "!chooseColor" \
		-insertborderwidth "" \
		-insertofftime "" \
		-insertontime "" \
		-insertwidth "" \
		-jump [list true false] \
		-justify [list left center right] \
		-orient [list horizontal vertical] \
		-padx "" \
		-pady "" \
		-relief [list raised sunken flat ridge solid groove] \
		-repeatdelay "" \
		-repeatinterval "" \
		-selectbackground "!chooseColor" \
		-selectborderwidth "" \
		-selectforeground  "!chooseColor" \
		-setgrid [list true flase] \
		-takefocus [list true flase] \
		-troughcolor "!chooseColor" \
		-underline "" \
		-wraplength  "" \
		-xscrollcommand "" \
		-yscrollcommand "" \
	]
	return	
}

proc ::crowSyntax::get_arg_values {arg} {
	variable argValues
	if {![info exists argValues($arg)]} {return}
	return $argValues($arg)
}

proc ::crowSyntax::get_tcl_args {cmd} {
	variable tclKeywords
	if {![info exists tclKeywords($cmd)]} {return}
	return $tclKeywords($cmd)
}

proc ::crowSyntax::get_tk_args {cmd} {
	variable tkKeywords
	if {![info exists tkKeywords($cmd)]} {return}
	return $tkKeywords($cmd)
}
