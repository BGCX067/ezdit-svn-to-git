#!/usr/bin/tclsh
     
proc del_svn {dpath} {
	if {[file exists [file join $dpath ".svn"]]} {
		puts [format "\t delete %s" [file join $dpath ".svn"]]
		file delete -force [file join $dpath ".svn"]
	}
	if {[file exists [file join $dpath ".__meta__"]]} {
		puts [format "\t delete %s" [file join $dpath ".__meta__"]]
		file delete -force [file join $dpath ".__meta__"]
	}

	set flist [glob -nocomplain -directory $dpath -types {d hidden} *]
	foreach item $flist {
		set ftail [file tail $item]
		if {$ftail == "." || $ftail == ".."} {continue}
		del_svn $item
	}
	
	set flist [glob -nocomplain -directory $dpath -types {d} *]
	foreach item $flist {
		set ftail [file tail $item]
		if {$ftail == "." || $ftail == ".."} {continue}
		del_svn $item
	}	
}

set appPath [file normalize [info script]]
if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
set appPath [file dirname $appPath]

del_svn $appPath

exit
