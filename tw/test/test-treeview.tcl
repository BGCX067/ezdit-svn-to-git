#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

lappend ::auto_path ../

if {$::tcl_version < 8.6} {
	package require img::png
}
package require ::tw::treeview

package require autoscroll
set tv [::tw::treeview new .tv  \
	-columns [list name] \
	-autoscroll 1 \
	-scrollbar both \
	-show {headings tree}]
pack [$tv frame] -expand 1 -fill both

$tv frame configure -borderwidth 2 -relief groove
$tv treeview heading #0 -text "root"
$tv treeview heading name -text "name"
$tv treeview insert {} end -text "saf567567" 
$tv treeview insert {} end -text "saf123123" 

