proc find_msg {dpath} {
	set flist [glob -nocomplain -directory $dpath -types {f} -- "*.tcl"]
	foreach f $flist {parsing $f}
	set fd [open "msg.new" r]
	set data [split [read $fd] "\n"]
	close $fd
	array set arrA ""
	set nsA ""
	foreach item $data {
		if {$item eq "\}"} {continue}
		if {[string range $item 0 8] eq "namespace"} {
			set ns [lindex [string trim $item "\{"] 2]
			lappend nsA $ns
			continue
		}
		puts item=$item
		if {[lindex $item 0] eq "::msgcat::mcset"} {
			set arrA($ns,[lindex $item 2]) $item 
		}
	}
	set fd [open msg.new w]
		foreach ns [lsort $nsA] {
			puts $fd "namespace eval $ns \{"
			set keys [lsort [array names arrA "$ns,*"]]
			foreach key $keys {
				if {$key eq ""} {continue}
				puts $fd $arrA($key)
			}
			puts $fd "\}\n"
		}
	close $fd
}

proc parsing {fname} {
	set fd [open $fname r]
	set code [read $fd]
	close $fd
	set mlist [regexp -indices -all -inline -- {::msgcat::mc\s+[^\[\]]+\"} $code]
	#set mlist [regexp -all -inline -- {::msgcat::mc\s+[^\[\]]+\"} $code]
	#puts $mlist
	#return
	set name [file tail $fname]
	set fd [open "msg.new" a]
	set ns [file rootname $name]
	set ns "svnWrapper"
	puts $fd "# Script : $fname"
	puts $fd "namespace eval ::$ns {"
	foreach item $mlist {
		foreach {idx1 idx2} $item {}
		set msg [string range $code $idx1 $idx2]
		puts msg=$msg
		set msg \"[lindex $msg 1]\"
		set out "\t::msgcat::mcset en_us "
		append out $msg
		append out " "
		append out $msg
		puts $fd $out
	}
	puts $fd "}"
	puts $fd ""
	close $fd
}
find_msg ./
exit
