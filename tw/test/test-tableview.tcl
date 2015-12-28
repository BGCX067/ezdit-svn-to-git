#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

lappend ::auto_path ../

if {$::tcl_version < 8.6} {
	package require img::png
}
package require ::tw::ibox
package require ::tw::tableview

set tv [::tw::tableview new .tv -operation "check edit delete" -navigator 1]
pack .tv -expand 1 -fill both

$tv column_add tel -text "Tel" -itemstyle text

::oo::objdefine $tv method row_count {} {return 500}
::oo::objdefine $tv method fetch_rows {args} {
	my variable PRIV
		# -filter 
		# -offset
		# -count
		# -orderBy
		# -order	
	array set opts [list \
		-filter "" \
		-offset 0 \
		-count "" \
		-orderBy "" \
		-order "" \
	]
	array set opts $args
	if {$opts(-count) == ""} {set opts(-count) 500}
	set start $opts(-offset)
	set end [expr $opts(-offset) + $opts(-count) ]
	set inc 1
	if {$opts(-orderBy) != "" && $opts(-order) == "DESC"} {
		set start [expr $opts(-offset) + $opts(-count) ]
		set end $opts(-offset)
		set inc -1
	}
	
	if {$end > 500} {set end 501}
	
	for {set i $start} {$i < $end} {incr i $inc} {
		my item_add	tel "hello - $i" _CHECK_ CHECK
	}
	return 500
}

$tv navi_update
