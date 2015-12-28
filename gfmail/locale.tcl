#!/bin/tclsh

encoding system utf-8

namespace eval ::locale {
	variable Priv
	array set Priv ""
}

proc ::locale::msg_find {dpath} {
	variable Priv
	set flist [glob -nocomplain -directory $dpath -types {f} -- "*.tcl"]
	foreach f $flist {parsing $f}
	set fd [open "src/locales/msg.new" r]
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
		#puts item=$item
		if {[string first "::msgcat::mcset" $item] == -1} {continue}
		if {[lindex $item 0] == "::msgcat::mcset"} {
			set arrA($ns,[lindex $item 2]) $item 
		}
	}
	set fd [open "src/locales/msg.new" w]
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
	foreach d [glob -nocomplain -directory $dpath -types {d} -- *] {
		if {[file tail $d] == "." || [file tail $d] == ".."} {continue}
		if {$dpath == "./src/loacls"} {continue}
		::locale::msg_find $d
	}
	
}

proc ::locale::msg_purge {dpath} {
	variable Priv
	
	set fd [open "src/locales/msg.new" r]
	set data [split [read $fd] "\n"]
	close $fd
	array set arr [list]
	set nslist [list]
	set ns ""
	foreach item $data {
		if {[string first "namespace eval" $item] == 0} {
			set item [string trim $item "{}"]
			set ns [lindex $item 2]
			set arr($ns,mlist) [list]
			if {[lsearch -exact $nslist $ns] == -1} {lappend nslist $ns}
			
			continue
		}
		if {$item == "\}"} {
			set ns "" 
			continue
		}
		if {$ns == ""} {continue}
		if {[lsearch -exact $arr($ns,mlist) $item] == -1} {
			lappend arr($ns,mlist) $item
		}
	}
	
	set fd [open "src/locales/msg.new" w]
	foreach ns $nslist {
		if {$arr($ns,mlist) == ""} {continue}
		puts $fd "namespace eval $ns \{"
		foreach {item} $arr($ns,mlist) {
			puts $fd $item
		}
		puts $fd "\}\n"
	}
	close $fd
	foreach d [glob -nocomplain -directory $dpath -types {d} -- *] {
		if {[file tail $d] == "." || [file tail $d] == ".."} {continue}
		::locale::msg_purge $d
	}
	
}

proc ::locale::msg_syn {fileA BLang fileB} {
	array set arrA ""
	set nsA ""
	array set arrB ""
	set nsB ""
		
	set fd [open $fileA r]
	fconfigure $fd -encoding utf-8
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
	fconfigure $fd -encoding utf-8
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
	fconfigure $fd -encoding utf-8
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

proc ::locale::parsing {fname} {
	
	set fd [open $fname r]
	set code [read $fd]
	close $fd
	set mlist [regexp -indices -all -inline -- {::msgcat::mc\s} $code]
	set name [file tail $fname]
	set fd [open "src/locales/msg.new" a]
	
	set idx [string first "namespace eval" $code]
	if {$idx == -1} {return}
	set idx1 [string first "::" $code $idx]
	set idx2 [string first " " $code $idx1]
	set ns [string trim [string range $code $idx1 $idx2]]

	puts $fd "# Script : $fname"
	puts $fd "namespace eval $ns \{"
	foreach item $mlist {
		foreach {idx1 idx2} $item {}
		
		set msg ""
		set i1 [expr $idx2 + 1]
		if {[string index $code $i1] != "\""} {continue}
		set i2 [expr $i1 + 1]
		set ch [string index $code $i2]
		while {$ch != "\""} {
			if {$ch == "\\"} {incr i2}
			if {$ch == "\""} {break}
			set ch [string index $code [incr i2]]
		}
		set msg [string range $code $i1 $i2]
		set out "\t::msgcat::mcset en_us "
		append out $msg
		append out " "
		append out $msg
		puts $fd $out
	}
	puts $fd "\}"
	puts $fd ""
	close $fd
}

foreach f [glob -nocomplain -directory "./src/locales" "*.new"] {file delete $f}

::locale::msg_find ./src
::locale::msg_purge ./src

set msgs [glob -nocomplain -directory "./src/locales" -- *.msg]
foreach msg $msgs {
	foreach {l e} [split [file tail $msg] "."] {}
	::locale::msg_syn "./src/locales/msg.new" $l $msg
}
puts "Finish!!"
exit

