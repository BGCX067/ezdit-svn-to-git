#!/usr/bin/tclsh
  
set app_name "CrowAMP"
set vfs_dir "src.vfs"
set win_target "${app_name}.exe"
set linux_target "${app_name}.bin"
set mac_target "${app_name}.mac"


proc del_svn {dpath} {
	if {[file exists [file join $dpath ".svn"]]} {exec rm -rf [file join $dpath ".svn"]}
	if {[file exists [file join $dpath ".__meta__"]]} {exec rm -rf [file join $dpath ".__meta__"]}

	set flist [glob -nocomplain -directory $dpath -types {d} *]
	foreach item $flist {del_svn $item}
}

catch {exec rm -rf "./release/*"}
catch {exec rm -rf $vfs_dir}

puts -nonewline "copy $app_name to $vfs_dir...."
update
exec cp -r src $vfs_dir
puts ok

puts -nonewline "delete svn metadata...."
update
del_svn ./$vfs_dir
puts ok

exec cp -rf $vfs_dir ./release/ezamp-src

exec mv [file join $vfs_dir lib_linux] ./release
exec mv [file join $vfs_dir lib_darwin] ./release

puts -nonewline "wrap win32 starpack...."
update
exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$win_target -vfs $vfs_dir -runtime ./tools/tclkit-windows
puts ok

exec rm -rf [file join $vfs_dir lib_windows]


exec mv ./release/lib_linux $vfs_dir
puts -nonewline "wrap linux starpack...."
update
exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$linux_target -vfs $vfs_dir -runtime ./tools/tclkit-linux
puts ok
exec rm -rf [file join $vfs_dir lib_linux]

exec mv ./release/lib_darwin $vfs_dir
puts -nonewline "wrap mac starpack...."
update
exec ./tools/tclkit ./tools/sdx.kit wrap ./release/$mac_target -vfs $vfs_dir -runtime ./tools/tclkit-darwin
puts ok
exec rm -rf [file join $vfs_dir lib_darwin]


catch {file delete -force $vfs_dir}

puts "creating zip file"
cd release
catch {
	exec zip -r ${app_name}-linux.zip $linux_target
	exec zip -r ${app_name}-win.zip $win_target
	exec zip -r ${app_name}-mac.zip $mac_target
	exec zip -r ${app_name}-src.zip ezamp-src
}
puts "cleanup.....ok"
puts finish
exit
