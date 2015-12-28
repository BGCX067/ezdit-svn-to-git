#!/usr/bin/tclsh
 
set app_name "WGet"
set vfs_dir "src.vfs"
set win_target "${app_name}.exe"
set linux_target "${app_name}.bin"
set mac_target "${app_name}.mac"
set mac_app_dir "${app_name}.app"


proc del_svn {dpath} {
	if {[file exists [file join $dpath ".svn"]]} {file delete -force [file join $dpath ".svn"]}
	if {[file exists [file join $dpath ".__meta__"]]} {file delete -force [file join $dpath ".__meta__"]}

	set flist [glob -nocomplain -directory $dpath -types {d} *]
	foreach item $flist {del_svn $item}
}

catch {exec rm -rf "./release/*"}
catch {exec rm -rf $vfs_dir}



puts -nonewline "copy WGet to $vfs_dir...."
update
exec cp -r src $vfs_dir
puts ok

puts -nonewline "delete svn metadata...."
update
del_svn ./$vfs_dir
puts ok

exec mv [file join $vfs_dir lib_darwin] ./release
exec mv [file join $vfs_dir lib_linux] ./release

puts -nonewline "wrap win32 starpack...."
update
exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$win_target -vfs $vfs_dir -runtime ./tools/tclkit85-win
puts ok

exec rm -rf [file join $vfs_dir lib_win32]

#puts -nonewline "convert encoding ....."
#update
#encoding system big5
#cd $vfs_dir
#
#set fd [open version.txt r]
#set data [read $fd]
#close $fd
#
#set fd [open version.txt w]
#fconfigure $fd -translation binary
#puts -nonewline $fd [encoding convertto utf-8 $data]
#close $fd
#
#foreach f [glob *.tcl] {
#	if {$f =="utf8-conv.tcl"} {continue}
#	set fd [open $f r]
#	set data [read $fd]
#	close $fd
#
#	set fd [open $f w]
#	fconfigure $fd -translation binary
#	puts -nonewline $fd [encoding convertto utf-8 $data]
#	close $fd
#}
#cd ..
#encoding system utf-8
#puts  ok

exec mv ./release/lib_linux $vfs_dir
puts -nonewline "wrap linux starpack...."
update
exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$linux_target -vfs $vfs_dir -runtime ./tools/tclkit85-linux
puts ok
exec rm -rf [file join $vfs_dir lib_linux]


#exec mv ./release/lib_darwin $vfs_dir
#puts -nonewline "wrap mac starpack...."
#update
#exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$mac_target -vfs $vfs_dir -runtime ./tools/tclkit85-mac
#exec cp ./release/$mac_target ./release/$mac_app_dir/Contents/MacOS
#puts ok
exec rm -rf [file join $vfs_dir lib_darwin]
exec rm -rf [file join ./release lib_darwin]

catch {file delete -force $vfs_dir}


puts "creating zip file"
cd release
#exec zip -r WGet-mac.zip WGet.app
exec zip -r WGet-linux.zip WGet.bin
exec zip -r WGet-win.zip WGet.exe


puts "cleanup.....ok"
puts finish
exit
