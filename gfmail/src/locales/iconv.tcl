#!/usr/bin/tclsh

proc iconv {from to f} {
	variable Priv
	puts "convert file encoding $from -> $to " ; update
	set fd [open $f r]
	fconfigure $fd -translation binary -encoding $from
	set data [read $fd]
	close $fd
		
	set fd [open $f w]
	fconfigure $fd -translation binary -encoding $to
	puts -nonewline $fd $data
	close $fd
}

label .lblFrom -text "From:" -justify left -anchor w
entry .txtFrom -textvariable ::txtFrom
entry .txtTo -textvariable ::txtTo
label .lblTo -text "To:" -justify left -anchor w
label .lblFile -text "File:" -justify left -anchor w
entry .txtFile -textvariable ::txtFile
button .btnFile -text "choose" -command {
	set ans [tk_getOpenFile ]
	if {$ans != "" && $ans != -1} {
		set ::txtFile $ans
	}
}
button .btnConv -text "Conv" -command {
	iconv $::txtFrom $::txtTo $::txtFile
	tk_messageBox -title "Ok" -message "Ok" -type {ok}
}

set ::txtFrom big5
set ::txtTo utf-8

grid .lblFrom .txtFrom - -sticky "news"
grid .lblTo .txtTo -  -sticky "news"
grid .lblFile .txtFile .btnFile -sticky "news"
grid .btnConv - - -sticky "news"


