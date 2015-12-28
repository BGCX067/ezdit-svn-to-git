proc synmsg {fileA BLang fileB} {
	array set arrA ""
	set nsA ""
	array set arrB ""
	set nsB ""
		
	set fd [open $fileA r]
	set data [split [read $fd] "\n"]
	close $fd
	foreach item  $data {
		if {[string trim $item] eq ""} {continue}
		if {[string range $item 0 8] eq "namespace"} {
			set ns [lindex [string trim $item "\{"] 2]
			lappend nsA $ns
			continue		
		}
		if {[lindex $item 0] eq "::msgcat::mcset"} {
			set arrA($ns,[lindex $item 2]) [lrange $item 2 end]
		}
	}
	
	set fd [open $fileB r]
	set data [split [read $fd] "\n"]
	close $fd	
	foreach item $data {
		if {[string range $item 0 8] eq "namespace"} {
			set ns [lindex [string trim $item "\{"] 2]
			lappend nsB $ns
			continue		
		}
		if {[lindex $item 0] eq "::msgcat::mcset"} {
			set arrB($ns,[lindex $item 2]) $item
		}
	}
	
	set nsA [lsort $nsA]
	set fd [open $fileB.new w]
	foreach ns $nsA {
		puts $fd "namespace eval $ns \{"
		foreach item [lsort [array names arrA "$ns,*"]] {
			if {[info exists arrB($item)]} {
				puts $fd $arrB($item)
			} else {
				foreach {src dest} $arrA($item) {}
				if {$src eq ""} {continue}
				puts $fd "\t# New"
				puts $fd "\t::msgcat::mcset $BLang  \"$src\" \"$dest\""
			}
		}
		puts $fd "\}\n"

	}
	close $fd	


}

set msgs [glob -nocomplain -directory "./" -tails -- *.msg]
foreach msg $msgs {
	foreach {l e} [split $msg "."] {}
	synmsg "msg.new" $l $msg
}

