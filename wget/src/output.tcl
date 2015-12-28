package require autoscroll
namespace eval ::output {
	variable Priv
	array set Priv [list]
	variable tagId 0

}

proc ::output::init {path} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set fme [ttk::frame $path]
	
	set txt [text $fme.txt -height 4 -relief groove -bd 1 -height 1]
	set vs [ttk::scrollbar $fme.vs -command [list $txt yview] -orient vertical]
	$txt configure -yscrollcommand [list $vs set]
	::autoscroll::autoscroll $vs
	
	set m [menu $txt.menu -tearoff 0]
	$m add command -compound left -label [::msgcat::mc "儲存訊息"] \
		-image [$ibox get empty] \
		-command [list ::output::save_output]
		
	$m add separator
	$m add command -compound left -label [::msgcat::mc "清除"] \
		-image [$ibox get empty] \
		-command [list ::output::clear_msg]

	bind $txt <<MenuPopup>> [list tk_popup $m %X %Y]

	$txt configure -state disabled
	
	
	set Priv(txt) $txt
	set Priv(menu) $m
	
	grid $txt $vs -sticky "news" -padx 2 -pady 2
	grid rowconfigure $fme 0 -weight 1
	grid columnconfigure $fme 0 -weight 1	
	
	return $path
}

proc ::output::clear_msg {} {
	variable Priv
	set txt $Priv(txt)
	$txt configure -state normal
	$txt delete 0.0 end
	$txt configure -state disabled
}

proc ::output::put_msg {msg {newline "\n"}} {
	variable Priv
	set txt $Priv(txt)
	
	$txt configure -state normal
	$txt insert end $msg$newline
	$txt see end
	$txt configure -state disabled
}

proc ::output::put_smsg {msg args} {
	variable Priv
	variable tagId
	set txt $Priv(txt)

	set tagName tag$tagId
	$txt configure -state normal
	set idx1 [$txt index end]
	$txt insert end "$msg\n"
	set idx2 [$txt index end]
	$txt tag add $tagName $idx1 $idx2
	
	array set opts [list \
		-size "" \
		-weight "" \
		-slant "" \
		-underline "" \
		-overstrike "" \
		-color "" \
		]

	set cmd "font create"
	foreach {key val} [array get opts] {
		if {$val == ""} {continue}
		if {$key == "-color"} {
			$Priv(txt) tag configure $tagName -foreground $val
			continue
		}
		lappend cmd $key $val
	}
	
	if {$cmd != "font create"} {
		$Priv(txt) tag configure $tagName -font [font create $conf]
	}
	
	$txt see end 
	$txt configure -state disabled
}

proc ::output::save_output {} {
	variable Priv
	set txt $Priv(txt)
	
	set ret [tk_getSaveFile -filetypes [list [list {All Type} {*.*}]] -title [::msgcat::mc "Save Output"]]
	if {$ret != "" && $ret != "-1"} {
		set fd [open $ret w]
		puts $fd [$txt get 0.0 end]
		close $fd
	}
}




