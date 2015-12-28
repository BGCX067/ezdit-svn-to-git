#!/usr/bin/tclsh

namespace eval ::build {
	variable Priv
	array set Priv [list \
		appName "GFMail" \
		srcDir "src" \
	]
	set Priv(vfsDir) "$Priv(srcDir).vfs"
	set Priv(win32Target) "$Priv(appName).exe"
	set Priv(linuxTarget) "$Priv(appName).bin"
	set Priv(darwinTarget) "$Priv(appName).mac" 
}

proc ::build::del_svn {dpath} {
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

proc ::build::init {} {
	variable Priv

	catch {file delete -force $Priv(vfsDir)}
	catch {file delete -force [file join release lib_win32]}
	catch {file delete -force [file join release lib_linux]}
	catch {file delete -force [file join release lib_darwin]}
	puts -nonewline "Copy $Priv(srcDir) to $Priv(vfsDir)...." ; update
	file copy -force src $Priv(vfsDir)
	puts "ok"	
	puts "Delete svn directory ...." ;	update
	::build::del_svn $Priv(vfsDir)
	
	file rename -force [file join $Priv(vfsDir) lib_darwin] [file join release lib_darwin]
	file rename -force [file join $Priv(vfsDir) lib_linux] [file join release lib_linux]
	file rename -force [file join $Priv(vfsDir) lib_win32] [file join release lib_win32]
}

proc ::build::wrap {target} {
	variable Priv
	
	puts -nonewline "Wrap $target starpack...." ; update
	
	set tclkit [file join tools "tclkit"]
	set sdx [file join tools "sdx.kit"]
	set chmod 1
	set runtime [file join tools "tclkit-$target"]
	
	set os [string tolower $::tcl_platform(os)]
	if {[string first "darwin" $os] >= 0 } {
		file copy -force [file join tools "tclkit-darwin"] $tclkit
	} elseif {[string first "windows" $os] >= 0} {
		append tclkit ".exe"
		file copy -force [file join tools "tclkit-win32"] $tclkit
		set chmod 0
	} else {
		file copy -force [file join tools "tclkit-linux"] $tclkit
	}
	
	if {$chmod} {exec chmod +x $tclkit }
	file rename -force [file join release lib_$target] [file join $Priv(vfsDir) lib_$target]
	exec $tclkit $sdx wrap [file join release $Priv(${target}Target)] -vfs $Priv(vfsDir) -runtime $runtime
	puts "ok"
	file delete -force [file join $Priv(vfsDir) lib_$target]
}

proc ::build::big5_to_utf8 {dir from to args} {
	variable Priv
	puts "convert file encoding $from -> $to " ; update
	set odir [pwd]
	cd $dir
	foreach item $args {
		foreach f [glob $item] {
			puts -nonewline [format "\t -> %s ..." [file join $dir $f]] ; update
			set fd [open $f r]
			fconfigure $fd -translation binary -encoding $from
			set data [read $fd]
			close $fd
		
			set fd [open $f w]
			fconfigure $fd -translation binary -encoding $to
			puts -nonewline $fd $data
			close $fd
			puts "ok"
		}
	}
	cd $odir
}

proc ::build::create_mac_app {} {
	variable Priv
	
	cd release
	if {[file exists $Priv(darwinTarget)]} {
		catch {file delete -force $Priv(appName)-app}
		file copy -force ../data/dApp-app $Priv(appName)-app
		file copy -force $Priv(darwinTarget) $Priv(appName)-app/Contents/MacOS/main
		set fd [open $Priv(appName)-app/Contents/Info.plist r]
		set data [read $fd]
		close $fd
		set data [format $data $Priv(appName) $Priv(appName)]
		set fd [open $Priv(appName)-app/Contents/Info.plist w]
		puts $fd $data
		close $fd		
	}
	cd ..
}

proc ::build::zip_all {} {
	variable Priv
	cd release
	foreach item [list darwin linux win32] {
		if {![file exists $Priv(${item}Target)]} {continue}
		set target [file rootname [file tail $Priv(${item}Target) ]]-$item.zip
		puts -nonewline "Zip $Priv(${item}Target) -> $target ....." ; update
		exec zip -r $target $Priv(${item}Target)
		puts "ok"
	}
	cd ..
}

proc ::build::cleanup {} {
	variable Priv
	puts -nonewline "Cleanup ....." ; update
	file delete -force $Priv(vfsDir)
	file delete -force [file join release lib_linux]
	file delete -force [file join release lib_darwin]
	file delete -force [file join release lib_win32]
	puts "ok"
}

puts "Start\n"
::build::init
::build::wrap win32
#::build::big5_to_utf8 $::build::Priv(vfsDir) big5 utf-8 *.tcl
#::build::wrap darwin
#::build::create_mac_app
::build::wrap linux
#::build::zip_all
::build::cleanup
puts "\nFinish"

exit
