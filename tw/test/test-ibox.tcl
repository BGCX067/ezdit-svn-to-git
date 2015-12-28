#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

lappend ::auto_path ../

if {$::tcl_version < 8.6} {
	package require img::png
}
package require ::tw::ibox

set ibox [::tw::ibox new]
$ibox add "a.png" "b.png"

set j 0
foreach i [$ibox names] {
	incr j
	button .btn$j -image [$ibox get $i] -text $i -compound bottom
	pack .btn$j -side left
}

puts [$ibox names]

