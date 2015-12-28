#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

package require msgcat
lappend ::auto_path ../

if {$::tcl_version < 8.6} {
	package require img::png
}
package require ::tw::dialog

# test dialog
#set dlg [::tw::dialog new ".t" \
#	-title "Dialog" \
#	-buttons [list 1 ok 2 cancel] \
#	-cancel 1 \
#	-grab global \
#	]
#puts [$dlg show]
#$dlg destroy

#test messagebox
set dlg [::tw::dialog::msgbox new ".t" \
	-title "Message Box" \
	-message "this is message" \
	-detail "this is detail" \
	-buttons [list 1 ok 2 cancel] \
	-cancel 1 \
	-icon [image create photo -file a.png] \
	]
puts [$dlg show]
$dlg destroy

#test inputbox
#set dlg [::tw::dialog::inputbox new ".t" \
#	-title "Inputbox Box" \
#	-message "this is message" \
#	-detail "this is detail" \
#	-buttons [list 1 ok 2 cancel] \
#	-cancel 1 \
#	-icon [image create photo -file a.png] \
#	-value "default value" \
#	]
#puts [$dlg show]
#puts [$dlg data]
#$dlg destroy


#test fontbox
#set dlg [::tw::dialog::fontbox new ".t" \
#	-title "Fontbox Box" \
#	-buttons [list 1 ok 2 cancel] \
#	-cancel 1 \
#	-size 12 \
#	-family "Times" \
#	]
#puts [$dlg show]
#puts [$dlg data]
#$dlg destroy
