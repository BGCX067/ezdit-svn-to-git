#!/usr/bin/wish
package require msgcat
namespace eval ::build {
	variable Priv
	array set Priv [list ]

}

proc ::build::cleanup {dpath} {
	if {[file exists [file join $dpath ".svn"]]} {
		puts [format "\t delete %s" [file join $dpath ".svn"]]
		file delete -force [file join $dpath ".svn"]
	}

	if {[file exists [file join $dpath ".ezdit"]]} {
		puts [format "\t delete %s" [file join $dpath ".ezidt"]]
		file delete -force [file join $dpath ".ezdit"]
	}
	
	if {[file exists [file join $dpath ".__meta__"]]} {
		puts [format "\t delete %s" [file join $dpath ".__meta__"]]
		file delete -force [file join $dpath ".__meta__"]
	}

	set flist [glob -nocomplain -directory $dpath -types {d hidden} *]
	foreach item $flist {
		set ftail [file tail $item]
		if {$ftail == "." || $ftail == ".."} {continue}
		::build::cleanup $item
	}
	
	set flist [glob -nocomplain -directory $dpath -types {d} *]
	foreach item $flist {
		set ftail [file tail $item]
		if {$ftail == "." || $ftail == ".."} {continue}
		::build::cleanup $item
	}	
}

proc ::build::start {} {
	variable Priv
	
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	set appPath [file dirname $appPath]
	
	set Priv(appPath) $appPath
	
	set srcDir [file join $appPath src]
	set vfsDir [file join $appPath release src.vfs]
	
	foreach dir [list src.vfs lib_windows lib_linux lib_darwin] {
		set d [file join $appPath release $dir]
		if {![file exists $d]} {continue}
		file delete -force $d
	}

	puts -nonewline "copy src => release/src.vfs ..." ; update
	file copy -force $srcDir $vfsDir
	puts "ok"	
	
	puts -nonewline "cleanup release/src.vfs ..." ;	update
	::build::cleanup $vfsDir
	puts "ok"
	
	puts -nonewline "parse dApp information ..." ;	update
	set fd [open [file join $vfsDir main.tcl] r]
	set data [read $fd]
	close $fd
	set idx1 [string first "#conf_start" $data ]
	set idx2 [string first "#conf_end" $data ]
	eval [string range $data $idx1 $idx2]
	puts "ok"
	
	set opwd [pwd]
	cd [file join $appPath release]
	append tarball $::dApp::Env(appName) -src- $::dApp::Env(version) .zip
	puts -nonewline "creating $tarball ....." ;	update
	file rename src.vfs "$::dApp::Env(appName)-src-$::dApp::Env(version)"
	exec zip -r $tarball "$::dApp::Env(appName)-src-$::dApp::Env(version)"
	file rename "$::dApp::Env(appName)-src-$::dApp::Env(version)" src.vfs
	cd $opwd
	puts "ok"
	
	puts -nonewline "move release/src.vfs/lib_*  =>  release ..." ; update
	foreach item [list lib_darwin lib_linux lib_windows] {
		set d [file join $vfsDir $item]
		if {![file exists $d]} {continue}
		file rename -force [file join $vfsDir $item] [file join $appPath release $item]
	}
	puts "ok"
	
	foreach item [list  windows darwin linux] {
		set f [file join $appPath tools tclkit-$item]
		if {![file exists $f]} {continue}
		::build::wrap $item
	}
	
	if {[file exists [file join $appPath tools tclkit]]} {file delete [file join $appPath tools tclkit]}
	if {[file exists [file join $appPath tools tclkit.exe]]} {file delete [file join $appPath tools tclkit.exe]}

	puts "Finish!!"
}

proc ::build::wrap {target} {
	variable Priv
	
	puts -nonewline "Wrap $target starpack...." ; update
	
	append releaseName $::dApp::Env(appName) "-" $target "-" $::dApp::Env(version)
	
	set tclkit [file join tools "tclkit"]
	set sdx [file join tools "sdx.kit"]
	set chmod 1
	set runtime [file join tools "tclkit-$target"]
	
	set os [string tolower $::tcl_platform(os)]
	if {[string first "darwin" $os] >= 0 } {
		file copy -force [file join $Priv(appPath) tools "tclkit-darwin"] $tclkit
	} elseif {[string first "windows" $os] >= 0} {
		append tclkit ".exe"
		file copy -force [file join $Priv(appPath) tools "tclkit-windows"] $tclkit
		set chmod 0
		
	} else {
		file copy -force [file join $Priv(appPath) tools "tclkit-linux"] $tclkit
	}
	
	if {$target == "windows"} {set ext ".exe"}
	if {$target == "linux"} {set ext ".bin"}
	if {$target == "darwin"} {set ext ".mac"}
	
	append releaseName $ext
	
	set Priv(target,$target) $releaseName
	if {$chmod} {file attributes $tclkit  -permissions +x}
	file rename -force [file join $Priv(appPath) release lib_$target] [file join $Priv(appPath) release src.vfs lib_$target]
	exec $tclkit $sdx wrap [file join $Priv(appPath) release $releaseName] -vfs [file join $Priv(appPath) release src.vfs]  -runtime $runtime
	puts "ok"
	file delete -force [file join $Priv(appPath) release lib_$target]
	
	append tarball [file rootname $releaseName] .zip
	puts -nonewline "creating $tarball ....." ; update
	set opwd [pwd]
	cd [file join $Priv(appPath) release]
	exec zip -r $tarball $releaseName
	cd $opwd
	puts "ok"
}

::build::start
exit

