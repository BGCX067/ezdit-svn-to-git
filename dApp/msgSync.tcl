#!/bin/tclsh

encoding system utf-8

namespace eval ::msgSync {
	variable Priv
	array set Priv [list \
		msglist [list]
	]
}

proc ::msgSync::gettok {varName sidx} {
   
   upvar $varName data
   
   # skip space
   set idx1 $sidx
   set ch [string index $data $idx1]
   
   while {$ch == " "  || $ch == "\t"} {
      incr idx1
      set ch [string index $data $idx1]
   }
	set idx2 $idx1
 
	if {$ch == ""} {return [list "EOF" $idx1 $idx2]}
 
	if {$ch == "\n" || $ch == "\r"} {
		set ch2 [string index $data [expr $idx2 + 1 ]]
		if {$ch2 == "\n" || $ch2 == "\r"} {incr idx2}
		return [list "EOS" $idx1 $idx2]
	} 
   
	if {$ch == ";"} {return [list "EOS" $idx1 $idx2]}
    
	 set spaces [list "" " " "\t" "\n" "\r" ";"]
 
   while {1==1} {
	   
	   if {[lsearch -exact $spaces $ch] != -1} {return [list "TOK" $idx1 [incr idx2 -1]]}

		if {$ch == "\\"} {
			incr idx2
			set ch [string index $data [incr idx2]]
			continue
		}

	   if {$ch == "\["} {
	      set ch2 [string index $data [incr idx2]]
	      set nest 1
	      while {$ch2 != ""} {
	         if {$ch2 == "\["} {incr nest}
	         if {$ch2 == "\]"} {incr nest -1}
	         if {$ch2 == "\\"} {incr idx2}
	         if {$nest == 0} {break}
	         set ch2 [string index $data [incr idx2]]
	      }
	      if {$ch2 == ""} {return [list "TOK" $idx1 [incr idx2 -1]]}
	   }
	   
	   if {$ch == "\{"} {
	      set ch2 [string index $data [incr idx2]]
	      set nest 1
	      while {$ch2 != ""} {
	         
	         if {$ch2 == "\{"} {incr nest}
	         if {$ch2 == "\}"} {incr nest -1}
	         if {$ch2 == "\\"} {incr idx2}
	         if {$nest == 0} {break}       
		      set ch2 [string index $data [incr idx2]]
	      }
	     
	      if {$ch2 == ""} {return [list "TOK" $idx1 [incr idx2 -1]]}
	   }
	
	   if {$ch == "\""} {
	      set ch2 [string index $data [incr idx2]]
	      while {$ch2 != ""} {
	         if {$ch2 == "\""} {break}
	         if {$ch2 == "\\"} {incr idx2}       
	         set ch2 [string index $data [incr idx2]]
	      }
	      if {$ch2 == ""} {return [list "TOK" $idx1 [incr idx2 -1]]}
	   }
		set ch [string index $data [incr idx2]]
		
   }
   return [list "EOF" $idx1 $idx2]
}	

proc ::msgSync::msg_find {dpath {flag 0}} {
	# flag : 0  , do not include subdirectory
	variable Priv
	
	set flist [glob -nocomplain -directory $dpath -types {f} -- "*.tcl"]
	foreach f $flist {::msgSync::msg_parse $f}
	
	if {$flag == 0} {return}
	
	foreach d [glob -nocomplain -directory $dpath -types {d} -- *] {
		if {[file tail $d] == "." || [file tail $d] == ".."} {continue}
		::msgSync::msg_find $d $flag
	}
	
}

proc ::msgSync::msg_saveto {fpath} {
	variable Priv
	set fd [open $fpath w]
	foreach item $Priv(msglist) {
		if {[string first "{_DMSG_}" $item ] == 0} {
			puts $fd [string range $item 8 end]
			continue
		}
		if {[string first "{_SKIP_}" $item ] == 0} {
			#puts -nonewline $fd "\t#::msgcat::mcset en_us "
			#puts $fd [string range $item 8 end]
			continue
		}		
		puts -nonewline $fd  "\t::msgcat::mcset en_us "
		puts -nonewline $fd $item
		puts -nonewline $fd " "
		puts $fd $item
	}
	close $fd
}
 

proc ::msgSync::msg_parse {fpath} {
	variable Priv
	
	puts $fpath
	
	lappend Priv(msglist) "{_DMSG_}\n\t# $fpath"
	set fd2 [open $fpath r]
	while {![eof $fd2]} {
		gets $fd2 buf
		set buf [string trim $buf]
		if {[string index $buf 0] == "#"} {continue}
		set sIdx [string first "::msgcat::mc " $buf]
		if { $sIdx == -1} {continue}
		set eIdx $sIdx
		lassign [::msgSync::gettok buf $sIdx] type idx1 idx2
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		if {$type != "TOK"} {continue}
		set msg [string range $buf $idx1 $idx2]
		set msg [string trimright $msg "\]\}"]
		
		if {[lsearch -exact $Priv(msglist) $msg] >= 0} {
			lappend Priv(msglist) "{_SKIP_}$msg"
		} else {
			lappend Priv(msglist) [string trim $msg]
		}
	}
	close $fd2
}

proc ::msgSync::msg_syn {src dest locale} {

	set fd [open $dest r]
	while {![eof $fd]} {
		gets $fd buf
		set buf [string trim $buf]
		if {[string first "::msgcat::mcset" $buf] != 0} {continue}
		lassign [::msgSync::gettok buf 0] type idx1 idx2
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		set key [string trim [string range $buf $idx1 $idx2]]
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		set val [string trim [string range $buf $idx1 $idx2]]
		set nList($key) $val
	}
	close $fd
	
	set fd [open $src r]
	while {![eof $fd]} {
		gets $fd buf
		set buf [string trim $buf]
		if {[string first "::msgcat::mcset" $buf] != 0} {continue}
		lassign [::msgSync::gettok buf 0] type idx1 idx2
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		set key [string trim [string range $buf $idx1 $idx2]]
		lassign [::msgSync::gettok buf [incr idx2]] type idx1 idx2
		set val [string trim [string range $buf $idx1 $idx2]]
		
		if {![info exists nList($key)]} {continue}
		set oList($key) $val
	}
	close $fd
	
	
	foreach {key val} [array get nList] {
		if {[info exists oList($key)]} {continue}
		set aList($key) $val
	}
	
	set fd [open $src w]
	puts $fd "namespace eval :: {"

	foreach {key} [lsort -dictionary [array names aList]] {
		set val $aList($key)
		puts $fd "\t# New"
		puts -nonewline $fd  "\t::msgcat::mcset $locale "
		puts -nonewline $fd $key
		puts -nonewline $fd " "
		puts $fd $val
	}
	
	foreach {key} [lsort -dictionary [array names oList]] {
		set val $oList($key)
		puts -nonewline $fd  "\t::msgcat::mcset $locale "
		puts -nonewline $fd $key
		puts -nonewline $fd " "
		puts $fd $val
	}
	
	puts $fd "}"
	close $fd
	
}

proc ::msgSync::msg_start {} {
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	set appPath [file dirname $appPath]
	
	set appPath [file join $appPath src]
	
	::msgSync::msg_find $appPath

	set msgFile [file join $appPath locale msg.new]
	::msgSync::msg_saveto $msgFile
	
	foreach f [glob -nocomplain -directory [file join $appPath locale] -types {f} *.msg] {
		::msgSync::msg_syn $f $msgFile [file rootname [file tail $f]]
	}
	
	file delete ./src/locale/msg.new
	
	puts "Finish!!"
}

::msgSync::msg_start

