package provide gvfs 1.0
#package require uuid
package require gutil
package require ttrc
package require Thread
package require tar

namespace eval ::gvfs {
	variable Priv
	array set Priv [list \
		rcDir $::dApp::Priv(rcPath) \
		splitSize [expr 1024*1024] \
		maxThread 2 \
		queueStart 1 \
		maxGDisk 5 \
		uuid_base [clock clicks] \
		msgTid "" \
	]
	
	if {![file exists $Priv(rcDir)]} {file mkdir $Priv(rcDir)}
	puts $Priv(rcDir)
	
}

proc ::gvfs::cmd_cd {dir} {
	variable Priv
	set tok $Priv(fstok)
	
	if {$dir == "."} {return $Priv(fspwd)}
	if {$dir == "/"} {set Priv(fspwd) $Priv(fsroot) ; return $Priv(fspwd)}
	if {$dir == ".." && $Priv(fspwd) == $Priv(fsroot)} {return $Priv(fspwd)}
	if {$dir == ".."} {set Priv(fspwd) [$tok item_parent $Priv(fspwd)] ; return $Priv(fspwd)}
	
	foreach item [$tok session_items $Priv(fspwd)] {
		if {[$tok attr_get $item "name"] == $dir} {
			array set meta [::gvfs::cmd_meta $item]
			if {$meta(type) == "directory" && $meta(cmd) == "DELETE" && [$tok session_items $item] == ""} {
				return  ""
			}
			set Priv(fspwd) $item
			return $Priv(fspwd)
		}
	}
	return ""
	
}

proc ::gvfs::cmd_delete {node} {
	variable Priv

	if {$Priv(gdiskList) == ""} {
		set ans [tk_messageBox -icon "error" \
			-default "ok" \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "There is not any GDisk exists."] \
			-type ok]		
		return
	}

	set tok $Priv(fstok)
	array set meta [::gvfs::cmd_meta $node]
	if {$meta(type) == "file"} {
			if {$meta(parts) == 0} {
				$tok item_del $node
			} else {
				$tok attr_set $node "cmd" "DELETE"
				foreach part [$tok session_items $node] {
					array set partMeta [::gvfs::cmd_meta $part]
					::gvfs::queue_add "DELETE" \
						$meta(metaId) \
						$partMeta(gdisk) \
						$partMeta(subject) \
						"" \
						0 \
						0 \
						"STOP"
				}
			}
	} else {
		set childNodes [$tok session_items $node]
		if {$childNodes == ""} {
			$tok item_del $node
		} else {
			$tok attr_set $node "cmd" "DELETE"
			foreach child $childNodes {
				array set meta [::gvfs::cmd_meta $child]
				::gvfs::cmd_delete $child
			}
		}
	}
	$tok save
}


proc ::gvfs::cmd_download {node saveDir} {
	variable Priv

	if {$Priv(gdiskList) == ""} {
		set ans [tk_messageBox -icon "error" \
			-default "ok" \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "There is not any GDisk exists."] \
			-type ok]		
		return
	}

	set tok $Priv(fstok)
	array set meta [::gvfs::cmd_meta $node]
	set fpath [file join $saveDir $meta(name)]
	if {$meta(complete) != 1} {return 0}
	if {$meta(type) == "file"} {
		$tok attr_set $node cmd "DOWNLOAD" wait $meta(parts)
		foreach part [$tok session_items $node] {
			array set partMeta [::gvfs::cmd_meta $part]
			::gvfs::queue_add "DOWNLOAD" \
				$meta(metaId) \
				$partMeta(gdisk) \
				$partMeta(subject) \
				$fpath.part.$partMeta(start) \
				$partMeta(start) \
				$partMeta(len) \
				"STOP"
		}
	} else {
		set childNodes [$tok session_items $node]
		file mkdir $fpath
		foreach child $childNodes {
			array set meta [::gvfs::cmd_meta $child]
			::gvfs::cmd_download $child $fpath
		}
	}
	$tok save
	return 1
}

proc ::gvfs::cmd_exists {name {node ""}} {
	variable Priv
	set tok $Priv(fstok)
	if {$node == ""} {set node $Priv(fspwd)}
	set item [$tok item_query $node "item\[@name='$name'\]"]
	if {$item == ""} {return 0}
	return 1
}
proc ::gvfs::cmd_locked {node {types "ALL"}} {
	variable Priv
	
	if {$node == $Priv(fsroot)} {return 0}
	
	if {$types == "ALL"} {set types [list DELETE DOWNLOAD UPLOAD]}
	
	set tok $Priv(fstok)
	set doc [dom parse [$node asXML]]
	set root [$doc documentElement ]
	set ret 0
	foreach type $types {
		set nodes	[$root selectNodes "//item\[@cmd='$type'\]"]
		if {$nodes != ""} {
			set ret 1
			break
		}
	}
	$doc delete
	return $ret
}

proc ::gvfs::cmd_list {{node ""}} {
	variable Priv

	set tok $Priv(fstok)
	set fspwd $Priv(fspwd) 
	if {$node == ""} {set node $Priv(fspwd)}
	set ret ""
	set flag 0
	foreach item [$tok session_items $node] {
		array set meta [::gvfs::cmd_meta $item]
		if {$meta(type) == "file" && $meta(cmd) == "DELETE" && $meta(parts) == "0"} {
			::gvfs::cmd_delete $item
			set flag 1
			continue
		}
		if {$meta(type) == "directory" && $meta(cmd) == "DELETE" && [$tok session_items $item] == ""} {
			::gvfs::cmd_delete $item
			set flag 1
			continue
		}	
		lappend ret $item	
	}
	if {$flag} {$tok save}
	return $ret
}

proc ::gvfs::cmd_meta {node} {
	variable Priv
	
	set tok $Priv(fstok)
	set root $Priv(fsroot) 
	set data [list]
	foreach attr [$tok attr_list $node] {lappend data $attr [$tok attr_get $node $attr]}
	return $data
}

proc ::gvfs::cmd_mkdir {dir {node ""}} {
	variable Priv
	
	if {$Priv(gdiskList) == ""} {
		set ans [tk_messageBox -icon "error" \
			-default "ok" \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "There is not any GDisk exists."] \
			-type ok]		
		return
	}	
	
	set tok $Priv(fstok)
	if {$node == ""} {set node $Priv(fspwd)}
	set item [$tok item_add $node "item"]
	set id [::gvfs::uuid generate]
	set size 0
	set ctime [clock format [clock scan now] -format "%Y-%m-%d %H:%M:%S"]
	$tok attr_set $item metaId $id type "directory" name $dir size $size ctime $ctime parts 0 cmd "" wait "" complete 1

	$tok save

	return $item
}

proc ::gvfs::cmd_mv {node targetNode} {
	variable Priv
	set tok $Priv(fstok)
	set parent [$tok item_parent $node]
	$parent removeChild $node
	$targetNode appendChild $node
	$tok save
	return $node
}

proc ::gvfs::cmd_path {{node ""}} {
	variable Priv
	set tok $Priv(fstok)
	
	if {$node == ""} {set node $Priv(fspwd)}
	if {$node == $Priv(fsroot)} {return "/"}
	
	set path [$tok attr_get $node "name"]
	set parent [$tok item_parent $node]
	while {$parent != $Priv(fsroot)} {
		set path [file join [$tok attr_get $parent "name"] $path]
		set parent [$tok item_parent $parent]
	}
	
	return [file join "/" $path]
	
}

proc ::gvfs::cmd_node {metaId} {
	variable Priv
	
	set tok $Priv(fstok)
	
	return [$tok item_query $Priv(fsroot) "//item\[@metaId='$metaId'\]"]
}

proc ::gvfs::cmd_pwd {} {
	variable Priv
	return $Priv(fspwd)
}

proc ::gvfs::cmd_rename {node name} {
	variable Priv
	set tok $Priv(fstok)
	if {[::gvfs::cmd_exists $name]} {return 0}
	$tok attr_set $node name $name
	$tok save
	return 1
}

proc ::gvfs::cmd_upload {fpath {node ""}} {
	variable Priv

	if {$Priv(gdiskList) == ""} {
		set ans [tk_messageBox -icon "error" \
			-default "ok" \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "There is not any GDisk exists."] \
			-type ok]		
		return
	}

	set tok $Priv(fstok)
	if {$node == ""} {set node $Priv(fspwd)}
	
	set fpath [file nativename $fpath]
	set fdir [file dirname $fpath]
	set fname [file tail $fpath]
	set fsize [file size $fpath]
	set ctime [clock format [clock scan now] -format "%Y-%m-%d %H:%M:%S"]
	
	set metaId [::gvfs::uuid generate]
	
	set item [$tok item_add $node "item"]
	$tok attr_set $item metaId $metaId type "file" name $fname size $fsize ctime $ctime parts 0 cmd "UPLOAD" wait "" complete 0
	
	
	set gdisk [lindex $Priv(gdiskList) $Priv(gdiskSelect)]



	set Priv(gdiskSelect) [expr ($Priv(gdiskSelect) + 1) % [llength $Priv(gdiskList)]]

	set splitSize $Priv(splitSize)
	set partCut [expr int($fsize / $splitSize)]
	
	for {set i 0} {$i < $partCut} {incr i} {
		set subject GFS::[::gvfs::uuid generate]
		::gvfs::queue_add "UPLOAD" $metaId $gdisk $subject $fpath [expr $i*$splitSize] $splitSize "STOP"
		set part [$tok item_add $item "part"]
		$tok attr_set $part gdisk $gdisk subject $subject start [expr $i*$splitSize] len $splitSize complete 0
	}
	
	if {$fsize % $splitSize} {
		set subject GFS::[::gvfs::uuid generate]
		::gvfs::queue_add "UPLOAD" $metaId $gdisk $subject $fpath [expr $i*$splitSize] [expr $fsize % $splitSize] "STOP"
		set part [$tok item_add $item "part"]
		$tok attr_set $part gdisk $gdisk subject $subject start [expr $i*$splitSize] len [expr $fsize % $splitSize] complete 0
		incr partCut
	}
	$tok attr_set $item parts $partCut wait $partCut complete 0
	
	$tok save
	
	return 1
}



proc ::gvfs::connect {} {
	variable Priv
	::gvfs::rc_load
	::gvfs::fs_open
	::gvfs::queue_open
	
	set master [lindex $Priv(gdiskList) 0]
	if {$master == ""} {return 0}
	set user $Priv(gdisk,$master,user)
	set passwd $Priv(gdisk,$master,passwd)
	
	#if {[::gutil::mkdir $user $passwd "GDisk"] == 0} {return 0}

	return 1
}

proc ::gvfs::disconnect {} {
	variable Priv
	
	::gvfs::rc_save
	::gvfs::queue_close
	
	array unset Priv gdisk,*
	unset Priv(gdiskList)
	unset Priv(gdiskMaster)
	unset Priv(gdiskSelect)
	return
}

proc ::gvfs::gdisk_add {user passwd args} {
	variable Priv
	
	if {[lsearch -exact $Priv(gdiskList) $user] >= 0} {return}
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_select "gdisk"]
	set item [$rc item_add $gdisk "partition"]
	$rc attr_set $item "user" $user "passwd" $passwd
	if {$Priv(gdiskList) == ""} {
		$rc attr_set $gdisk "select"  0
		$rc attr_set $gdisk "master"  $user
	}
	set Priv(gdisk,$user,user) $user
	set Priv(gdisk,$user,passwd) $passwd
	lappend Priv(gdiskList) $user
	$rc close	
	
	return 1
}

proc ::gvfs::gdisk_count {} {
	variable Priv
	return [llength $Priv(gdiskList)]
}
proc ::gvfs::gdisk_del {user} {
	variable Priv
	
	if {[lsearch -exact $Priv(gdiskList) $user] == -1} {return}
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	
	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_select "gdisk"]
	foreach item [$rc session_items $gdisk] {
		if {[$rc attr_get $item "user"] == $user} {
			$rc item_del $item
			array unset Priv gdisk,$user,*
			break
		}
	}
	
	set items [list]
	foreach item $Priv(gdiskList) {
		if {$item == $user} {continue}
		lappend items $item
	}
	set Priv(gdiskList) $items
	
	if {$items == ""} {
		$rc attr_set $gdisk "select"  ""
		$rc attr_set $gdisk "master"  ""	
	}
	
	$rc close		
}

proc ::gvfs::gdisk_list {} {
	variable Priv

	set ret ""
	set master 1
	foreach gdisk $Priv(gdiskList)  {
		lappend ret $Priv(gdisk,$gdisk,user) $Priv(gdisk,$gdisk,passwd) $master
		set master 0
	}
	return $ret
}

proc ::gvfs::gdisk_master {user} {
	variable Priv
	variable Priv
	
	if {[lsearch -exact $Priv(gdiskList) $user] <= 0} {return}
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_select "gdisk"]
	$rc attr_set $gdisk "master"  $user
	$rc close

	set items [list $user]
	foreach item $Priv(gdiskList) {
		if {$item == $user} {continue}
		lappend items $item
	}
	set Priv(gdiskList) $items	
	
}

proc ::gvfs::gdisk_passwd {user passwd} {
	variable Priv
	
	if {[lsearch -exact $Priv(gdiskList) $user] == -1} {return}
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	
	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_select "gdisk"]
	foreach item [$rc session_items $gdisk] {
		if {[$rc attr_get $item "user"] == $user} {
			$rc attr_set  $item "passwd" $passwd
			set Priv(gdisk,$user,passwd) $passwd
			break
		}
	}
	$rc close		
}

proc ::gvfs::dispatch {tok args} {
	variable Priv
	set cmd [list ::gvfs::cmd_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]
}

proc ::gvfs::fs_close {} {
	variable Priv
	$Priv(fstok) close
}

proc ::gvfs::fs_open {} {
	variable Priv
	set fsfile [file join $Priv(rcDir) "fs.xml"]
	
	if {![file exists $fsfile]} {
		set tok [::ttrc::openrc $fsfile]
		set root [$tok session_add "root"]
		$tok attr_set $root  metaId "GFS::Root" type "directory" version "1.0"
		$tok close
	}
	set Priv(fstok) [::ttrc::openrc $fsfile]
	set Priv(fspwd) [$Priv(fstok) session_select "root"]
	set Priv(fsroot) $Priv(fspwd)
}

proc ::gvfs::meta_backup {} {
	variable Priv
	set types {
	    {{Backup Files}       {.gbk}}
	}
	
	set ret [tk_getSaveFile -title [::msgcat::mc "v"] \
		-filetypes $types \
		-initialfile [clock format [clock scan now] -format "%Y%m%d"].gbk]
	if {$ret == "" || $ret == "-1"} {return}
	set wdir [pwd]
	cd [file dirname $Priv(rcDir)]
	set flist [glob -nocomplain -directory [file tail $Priv(rcDir)] -types {f} -- *]
	::tar::create $ret $flist
	cd $wdir
	tk_messageBox \
		-title [::msgcat::mc "Information"] \
		-message [::msgcat::mc "Backup successed!!"] \
		-type ok \
		-icon info
}

proc ::gvfs::meta_recover {} {
	variable Priv
	
	set types {
	    {{Backup Files}       {.gbk}}
	}	
	
	set ret [tk_getOpenFile -title [::msgcat::mc "Recover Filesystem"] \
		-filetypes $types]
	if {$ret == "" || $ret == "-1"} {return}
	
	set wdir [pwd]
	cd [file dirname $Priv(rcDir)]
	file copy $ret [file join [file dirname $Priv(rcDir)] gfmailfs.bak]
	if {[file exists $Priv(rcDir).bak]} {file delete -force $Priv(rcDir).bak}
	file rename $Priv(rcDir) $Priv(rcDir).bak
	if {[catch {
		set tarball [file join [file dirname $Priv(rcDir)] gfmailfs.bak]
		::tar::untar $tarball
		tk_messageBox \
			-title [::msgcat::mc "Information"] \
			-message [::msgcat::mc "Recover successed. Please restart GFMail. %sPress Ok to exit GFMail !!" "\n"] \
			-type ok \
			-icon info
		file delete $tarball
		exit
	}]} {
		file rename $Priv(rcDir).bak $Priv(rcDir)
		tk_messageBox \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Recover fail !!"] \
			-type ok \
			-icon error
	}
	file delete $tarball
	cd $wdir
	
}

proc ::gvfs::queue_add {type metaId gdiskId subject file start len flag} {
	variable Priv

	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_add $cmds "cmd"]
	set id [::gvfs::uuid generate]
	$qtok attr_set $cmd qId $id type $type metaId $metaId gdiskId $gdiskId subject $subject file $file start $start len $len flag $flag
	$qtok	save
	return $id
}

proc ::gvfs::queue_clear {} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set ret ""
	foreach cmd [$qtok session_items $cmds] {
		set flag [$qtok attr_get $cmd flag]
		if {$flag == "FINISH"} {$qtok item_del $cmd}
	}
	$qtok	save
	return $ret
}

proc ::gvfs::queue_close {} {
	variable Priv
	
	$Priv(qtok) close

}

proc ::gvfs::queue_co {} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set ret ""
	foreach cmd [$qtok session_items $cmds] {
		set flag [$qtok attr_get $cmd flag]
		if {$flag != "STOP"} {continue}
		set data [list]
		foreach attr [$qtok attr_list $cmd] {lappend data $attr [$qtok attr_get $cmd $attr]}
		set ret  $data
		break
	}
	return $ret
}

proc ::gvfs::queue_del {qid} {
	variable Priv
	
	set fstok $Priv(fstok)
	set qtok $Priv(qtok)
	
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@qId='$qid'\]"]
	if {$cmd != ""} {
		set metaId [$qtok attr_get $cmd metaId]
		set node [::gvfs::cmd_node $metaId]
		if {$node != ""} {
			$fstok attr_set $node cmd ""
		}
		
		$qtok item_del $cmd
	}
	$fstok save
	$qtok	save
	return $qid
}

proc ::gvfs::queue_list {} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set ret ""
	foreach cmd [$qtok session_items $cmds] {
		set data [list]
		foreach attr [$qtok attr_list $cmd] {lappend data [$qtok attr_get $cmd $attr]}
		lappend ret  $data
	}
	return $ret
}

proc ::gvfs::queue_query {qid} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@qId='$qid'\]"]
	set ret [list]
	if {$cmd != ""} {
		foreach attr [$qtok attr_list $cmd] {lappend ret [$qtok attr_get $cmd $attr]}
	}
	return $ret
}

proc ::gvfs::queue_query_meta {metaId} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@metaId='$metaId'\]"]
	set ret [list]
	if {$cmd != ""} {
		foreach attr [$qtok attr_list $cmd] {lappend ret [$qtok attr_get $cmd $attr]}
	}
	return $ret
}

proc ::gvfs::queue_start {} {
	variable Priv
	
	set Priv(queueStart) 1
	set len [llength [thread::names]]
	if {$len == ($Priv(maxThread) + 1)} {return}
	 ::gvfs::task_create 
}

proc ::gvfs::queue_reset {qid} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@qId='$qid'\ and @flag='ERROR'\]"]
	if {$cmd != ""} {$qtok attr_set $cmd flag "STOP"}
	$qtok	save
	return $qid
}

proc ::gvfs::queue_reset_all {} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@flag='ERROR' or @flag='RUNNING'\]"]
	foreach item $cmd {
		$qtok attr_set $item flag "STOP"
	}
	$qtok	save
	return
}

proc ::gvfs::queue_set {qid flag} {
	variable Priv
	
	set qtok $Priv(qtok)
	set cmds [$qtok session_select "cmds"]
	set cmd [$qtok item_query $cmds "//cmd\[@qId='$qid'\]"]
	if {$cmd != ""} {
		$qtok attr_set $cmd flag $flag
	}
	$qtok	save
	return $qid
}

proc ::gvfs::queue_stop {} {
	set Priv(queueStart) 0
}

proc ::gvfs::queue_open {} {
	variable Priv
	
	set qfile [file join $Priv(rcDir) "queue.xml"]
	set Priv(qtok) [::ttrc::openrc $qfile]
	if {![file exists $qfile]} {$Priv(qtok) session_add "cmds"}
}

proc ::gvfs::rc_load {} {
	variable Priv
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	
	if {![file exists $rcfile]} {
		set rc [::ttrc::openrc $rcfile]
		set gdisk [$rc session_add "gdisk"]
		$rc attr_set $gdisk "select"  "0"
		$rc attr_set $gdisk "master"  ""
		set env [$rc session_add "env"]
		$rc attr_set $env \
			splitSize $Priv(splitSize) \
			maxThread $Priv(maxThread) \
			queueStart $Priv(queueStart) \
			maxGDisk $Priv(maxGDisk)		
		$rc close
	}

	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_select "gdisk"]
	set Priv(gdiskList) [list]
	set Priv(gdiskSelect) [$rc attr_get $gdisk "select"]
	set Priv(gdiskMaster) [$rc attr_get $gdisk "master"]
	foreach node [$rc session_items $gdisk] {
		foreach attr [$rc attr_list $node] {set $attr [$rc attr_get $node $attr]}
		if {$user == $Priv(gdiskMaster)} {
			set Priv(gdiskList) [linsert $Priv(gdiskList) 0 $user]
		} else {
			lappend Priv(gdiskList) $user
		}
		set Priv(gdisk,$user,user) $user 
		set Priv(gdisk,$user,passwd) $passwd
	}
	set env [$rc session_select "env"]

	set Priv(splitSize) [$rc attr_get $env "splitSize"]
	set Priv(maxThread) [$rc attr_get $env "maxThread"]
	if {$Priv(maxThread) > 5} {set Priv(maxThread) 5}
	set Priv(queueStart) [$rc attr_get $env "queueStart"]
	set Priv(maxGDisk)		[$rc attr_get $env "maxGDisk"]
	if {$Priv(maxGDisk) > 5} {set Priv(maxGDisk) 5}
	$rc close
	return
}

proc ::gvfs::rc_save {} {
	variable Priv
	
	set rcfile [file join $Priv(rcDir) "settings.xml"]
	if {[file exists $rcfile]} {file delete $rcfile}
	set rc [::ttrc::openrc $rcfile]
	set gdisk [$rc session_add "gdisk"]

	foreach item $Priv(gdiskList) {
		set part [$rc item_add $gdisk "partition"]
		$rc attr_set $part "user" $Priv(gdisk,$item,user) "passwd" $Priv(gdisk,$item,passwd)
	}
	$rc attr_set $gdisk "select"  $Priv(gdiskSelect) "master" [lindex $Priv(gdiskList) 0]
	set env [$rc session_add "env"]
	$rc attr_set $env \
		splitSize $Priv(splitSize) \
		maxThread $Priv(maxThread) \
		queueStart $Priv(queueStart) \
		maxGDisk $Priv(maxGDisk)
	$rc close	
}

proc ::gvfs::task_count {} {
	variable Priv
	return [expr [llength [thread::names]] -1]
}

proc ::gvfs::task_create {} {
	variable Priv

	if {[llength [thread::names]] >= [expr $Priv(maxThread) + 1]} {return}
	
	array unset qinfo
	array set qinfo [::gvfs::queue_co]
	if {![info exists qinfo(qId)]} {return}
	
	set tid [::thread::create]
	set Priv($tid,qId) $qinfo(qId)

	set user $Priv(gdisk,$qinfo(gdiskId),user)
	set passwd $Priv(gdisk,$qinfo(gdiskId),passwd)
	set subject $qinfo(subject)
	
	::thread::send $tid [list set ::auto_path $::auto_path]
	
	::thread::send $tid [list package require Thread]
	::thread::send $tid [list set ::parentTID [::thread::id]]
	::thread::send $tid [list package require msgcat]
	::thread::send $tid [list package require gutil]
	
	switch -exact -- $qinfo(type) {
		"DELETE" {
			::thread::send -async $tid {
				proc ::start {user passwd subject {cb ""}} {
					set cmd [list ::gutil::delete $user $passwd $subject]
					set ret 1
					lappend cmd -command ::cbfun
					set ::CB $cb
					set ::SIZE 0
					if {[catch {set ret [eval $cmd]}]} {set ret 0}
					set cmd [linsert $::CB end [::thread::id] $::SIZE $::SIZE "0 KB" "100%" 0 "00:00:00"]
					::thread::send -async $::parentTID [list eval $cmd]					
					::thread::send -async $::parentTID [list ::gvfs::task_finish_cb [::thread::id] $ret]
					::thread::exit					
					return $ret
				}
				proc ::cbfun {max curr} {
					if {$::CB == ""} {return}
					set ::SIZE $max
					set tid [::thread::id]
					set percent [expr $curr*100.0/$max]
					foreach {v1 v2} [split $percent  "."] {break}
					set percent $v1.[string index $v2 0]
					if {$percent > 100.0} {set percent 100} 
					set percent ${percent}%
										
					set cmd [linsert $::CB end $tid $max $curr "0 KB" $percent "0 KB" "00:00:00"]
					::thread::send -async $::parentTID [list eval $cmd]					
				}
			}
			set cmd [list  ::start $user $passwd $subject "::gvfs::task_progress_cb"]
			::gvfs::queue_set $qinfo(qId) "RUNNING"
			::thread::send -async $tid $cmd
		}
		"DOWNLOAD" {
			::thread::send -async $tid {
				proc ::start {user passwd subject fpath {cb ""}} {
					set cmd [list ::gutil::download $user $passwd $subject $fpath]
					set ret 1
					lappend cmd -command ::cbfun
					set ::T0 [clock milliseconds]
					set ::T1 $::T0
					set ::T2 $::T0
					set ::SIZE 0
					set ::CB $cb
					set ret [eval $cmd]
					#if {[catch {set ret [eval $cmd]}]} {set ret 0}
					set util "B"
					set size $::SIZE
					if {$size > 1024} {
						set size [expr $size/1024.0]
						set util "KB"
						if {$size > 1024} {
							set size [expr $size/1024.0]
							set util "MB"
						}
						foreach {v1 v2} [split $size "."] {break}
						set size $v1.[string index $v2 0]
					}
					set size "$size $util"					
					set cmd [linsert $::CB end [::thread::id] $::SIZE $::SIZE "0 KB" "100%" $size "00:00:00"]
					::thread::send -async $::parentTID [list eval $cmd]
					::thread::send -async $::parentTID [list ::gvfs::task_finish_cb [::thread::id] $ret]
					::thread::exit					
					return $ret
				}
				proc ::cbfun {max curr} {
					if {$::CB == ""} {return}
					
					set ::T2 [clock milliseconds]
					if {$::T2-$::T1 < 200} {return}
					
					set speed [expr (($curr-$::SIZE)*1000.0/($::T2-$::T1))]
					#if {$speed <= 0} {return}
					set util "B"
					if {$speed > 1024} {
						set speed [expr $speed/1024.0]
						set util "KB"
						if {$speed > 1024} {
							set speed [expr $speed/1024.0]
							set util "MB"
						}
					}
					foreach {v1 v2} [split $speed "."] {break}
					set speed $v1.[string index $v2 0]					
					set speed "$speed $util"
					
					set percent [expr $curr*100.0/$max]
					foreach {v1 v2} [split $percent  "."] {break}
					set percent $v1.[string index $v2 0]
					if {$percent > 100.0} {set percent 100} 
					set percent ${percent}%
											
					set remainT [expr int((($::T2-$::T0)*($max.0/$curr -1 )) /1000) + 1]
					set s [clock add [clock scan "0000-00-00 00:00:00"] $remainT seconds]
					set remainT [clock format $s -format "%H:%M:%S"]

					set util "B"
					set size $curr
					if {$size > 1024} {
						set size [expr $size/1024.0]
						set util "KB"
						if {$size > 1024} {
							set size [expr $size/1024.0]
							set util "MB"
						}
						foreach {v1 v2} [split $size "."] {break}
						set size $v1.[string index $v2 0]
					}
					set size "$size $util"
					
					set tid [::thread::id]
					set cmd [linsert $::CB end $tid $max $curr $speed $percent $size $remainT]
					::thread::send -async $::parentTID [list eval $cmd]
					set ::T1 $::T2
					set ::SIZE $curr
				}
			}		
			set cmd [list  ::start $user $passwd $subject $qinfo(file) "::gvfs::task_progress_cb"]
			::gvfs::queue_set $qinfo(qId) "RUNNING"
			::thread::send -async $tid $cmd			
		}
		"UPLOAD" {

			set body [file tail $qinfo(file)]
			array set arglist [list \
				-file $qinfo(file) \
				-start $qinfo(start) \
				-len $qinfo(len) \
			]
			if {![file exists $qinfo(file) ]} {
				::gvfs::queue_set $qinfo(qId) "ERROR"
			} else {
				::thread::send -async $tid {
					proc ::start {user passwd subject body {cb ""} args} {
						set cmd [list ::gutil::upload  $user $passwd $subject $body]
						foreach {arg} $args {lappend cmd $arg}
						set ret 1
						lappend cmd -command ::cbfun
						set ::T0 [clock milliseconds]
						set ::T1 $::T0
						set ::T2 $::T0
						set ::SIZE 0
						set ::CB $cb
						if {[catch {set ret [eval $cmd]}]} {set ret 0}
						set util "B"
						set size $::SIZE
						if {$size > 1024} {
							set size [expr $size/1024.0]
							set util "KB"
							if {$size > 1024} {
								set size [expr $size/1024.0]
								set util "MB"
							}
							foreach {v1 v2} [split $size "."] {break}
							set size $v1.[string index $v2 0]
						}
						set size "$size $util"					
						set cmd [linsert $::CB end [::thread::id] $::SIZE $::SIZE "0 KB" "100%" $size "00:00:00"]
						::thread::send -async $::parentTID [list eval $cmd]								
						::thread::send -async $::parentTID [list ::gvfs::task_finish_cb [::thread::id] $ret]
						::thread::exit					
						return $ret
					}
					proc ::cbfun {max curr} {
						if {$::CB == ""} {return}
						
						set ::T2 [clock milliseconds]
						if {$::T2-$::T1 < 200} {return}
						
						set speed [expr ($curr-$::SIZE)/(($::T2-$::T1)/1000.0)]
						if {$speed <= 0} {return}
						set util "B"
						if {$speed > 1024} {
							set speed [expr $speed/1024.0]
							set util "KB"
							if {$speed > 1024} {
								set speed [expr $speed/1024.0]
								set util "MB"
							}
						}
						foreach {v1 v2} [split $speed "."] {break}
						set speed $v1.[string index $v2 0]					
						set speed "$speed $util"
						
						set percent [expr $curr.0/$max*100]
						foreach {v1 v2} [split $percent  "."] {break}
						set percent $v1.[string index $v2 0]
						if {$percent > 100.0} {set percent 100} 
						set percent ${percent}%
						
						set remainT [expr int((($::T2-$::T0)*($max.0/$curr -1 )) /1000) + 1]
						set s [clock add [clock scan "0000-00-00 00:00:00"] $remainT seconds]
						set remainT [clock format $s -format "%H:%M:%S"]
	
						set util "B"
						set size $curr
						if {$size > 1024} {
							set size [expr $size/1024.0]
							set util "KB"
							if {$size > 1024} {
								set size [expr $size/1024.0]
								set util "MB"
							}
							foreach {v1 v2} [split $size "."] {break}
							set size $v1.[string index $v2 0]
						}
						set size "$size $util"
						
						set tid [::thread::id]
						set cmd [linsert $::CB end $tid $max $curr $speed $percent $size $remainT]
						::thread::send -async $::parentTID [list eval $cmd]
						set ::T1 $::T2
						set ::SIZE $curr
					}
				}
				set cmd [list  ::start $user $passwd $subject $body "::gvfs::task_progress_cb"]
				foreach {arg} [array get arglist] {lappend cmd $arg}
				::gvfs::queue_set $qinfo(qId) "RUNNING"
				::thread::send -async $tid $cmd
			}
		}
	}
	::body::queue_refresh
	after idle [list ::gvfs::queue_start]
	return $tid
}

proc ::gvfs::task_progress_cb {tid args} {
	variable Priv

	set qid $Priv($tid,qId)
	lassign $args max curr speed percent size remainT
	if {[winfo exists $Priv(pbar,$qid)]} {
		if {[$Priv(pbar,$qid) cget -maximum] == 0} {$Priv(pbar,$qid) configure -maximum $max}
		$Priv(pbar,$qid) configure -value $curr
	}
	set Priv(remainT,$qid) $remainT
 	set Priv(size,$qid) $size
 	set Priv(speed,$qid) $speed
 	set Priv(percent,$qid)	$percent
}

proc ::gvfs::task_finish_cb {tid ret} {
	variable Priv

	set fstok $Priv(fstok)
	set qId $Priv($tid,qId)

	lassign [::gvfs::queue_query $qId] qId type metaId gdiskId subject file start len flag
	set node [::gvfs::cmd_node $metaId]
	if {$ret != 0} {
		::gvfs::queue_set $qId "FINISH" 
		switch -exact -- $type {
			"DELETE" {			
				set parts [$fstok attr_get $node "parts"]
				$fstok attr_set $node "parts" [incr parts -1]
				if {$parts == 0} {$fstok item_del $node}
				$fstok save
			}
			"DOWNLOAD" {
				set wait [$fstok attr_get $node "wait"]
				set outfile [file join [file dirname $file] [$fstok attr_get $node name]]
				$fstok attr_set $node "wait" [incr wait -1]

				if {$wait == 0} {
					$fstok attr_set $node cmd ""
					$fstok save
					set fdOut [open $outfile w]
					chan configure $fdOut -encoding binary -translation binary
					foreach part [$fstok session_items $node] {
						array set partMeta [::gvfs::cmd_meta $part]
						set infile $outfile.part.$partMeta(start)
						set fdIn [open $infile r]
						chan configure $fdIn -encoding binary -translation binary						
						chan copy $fdIn $fdOut
						close $fdIn
						file delete $infile
					}
					close $fdOut
				}
			}
			"UPLOAD" {
					set wait [$fstok attr_get $node "wait"]
					set part [$fstok item_query $node "part\[@subject='$subject'\]"]
					$fstok attr_set $part "complete" 1
					$fstok attr_set $node "wait" [incr wait -1]
					if {$wait == 0} {$fstok attr_set $node "complete" 1 cmd ""}
					$fstok save
			}
		}
		
	} else {
		::gvfs::queue_set $qId "ERROR" 
		switch -exact -- $type {
			"DELETE" {
			}
			"DOWNLOAD" {
			}
			"UPLOAD" {
			}
		}			
	}
	
	array unset Priv $tid,*
	if {$Priv(queueStart)} {after 1000 [list ::gvfs::task_create]}
	::body::queue_refresh
	::body::tree_item_state $node
	return

}

proc ::gvfs::uuid {args} {
	variable Priv
	return $Priv(uuid_base)_[clock clicks]
}
