#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

proc tok {varName sIdx} {
	upvar $varName data
	set idx1 $sIdx
	   
	# skip space
	set idx1 $sIdx
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
		
	set chars $SYNDB(_CHARS_)
	array set bracket [list "\(" "\)" "\[" "\]" "\{" "\}"]
	 while {1==1} {
		 
		if {[string first $ch $chars] <= 0} {return [list "TOK" $idx1 [incr idx2 -1] $ch]}

		if {$ch == "\""} {
			set ch2 [string index $data [incr idx2]]
			while {$ch2 != ""} {
				if {$ch2 == "\""} {break}
				if {$ch2 == "\\"} {incr idx2}       
				set ch2 [string index $data [incr idx2]]
			}
			if {$ch2 == ""} {return [list "TOK" $idx1 [incr idx2 -1]]}
		}		 
	 
		if {[string first $ch "\(\[\}"] >= 0} {
			set end $bracket($ch)
			set ch2 [string index $data [incr idx2]]
			set nest 1
			while {$ch2 != ""} {
				if {$ch2 == $end} {incr nest}
				if {$ch2 == $end} {incr nest -1}
				if {$ch2 == "\\"} {incr idx2}
				if {$nest == 0} {break}
				set ch2 [string index $data [incr idx2]]
			}
			if {$ch2 == ""} {return [list "TOK" $idx1 [incr idx2 -1]]}
		}
		
		 set ch [string index $data [incr idx2]]
	 
	 }
	 return [list "EOF" $idx1 $idx2]
}

set buf {
	abc 
	ee
void t1(void *data){
	while(1){
		printf("t1\n");
		Tcl_Sleep(1000);
		break;
	}
	Tcl_FinalizeThread() ;
}
}

lassign [tok buf 0] type idx1 idx2 ch
while {$type != "EOF"} {
	puts [list $type [string range $buf $idx1 $idx2] $ch]
	lassign [tok buf [incr idx2 2]] type idx1 idx2 ch
}

