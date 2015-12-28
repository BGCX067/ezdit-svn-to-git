#
# Copyright (c) 2003, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - convert file spec to drive root path

#
# Get info associated with a drive
proc twapi::get_volume_info {drive args} {
    variable windefs

    set drive [_drive_rootpath $drive]
    
    array set opts [parseargs args {
        all size freespace used useravail type serialnum label maxcomponentlen fstype attr device
    } -maxleftover 0]

    if {$opts(all)} {
        # -all option does not cover -type and -device
        set device_requested $opts(device)
        set type_requested   $opts(type)
        _array_set_all opts 1
        set opts(device) $device_requested
        set opts(type)   $type_requested
    }

    set result [list ]
    if {$opts(size) || $opts(freespace) || $opts(used) || $opts(useravail)} {
        foreach {useravail size freespace} [GetDiskFreeSpaceEx $drive] {break}
        foreach opt {size freespace useravail}  {
            if {$opts($opt)} {
                lappend result -$opt [set $opt]
            }
        }
        if {$opts(used)} {
            lappend result -used [expr {$size - $freespace}]
        }
    }

    if {$opts(type) || $opts(device)} {
        set drive_type [get_drive_type $drive]
        if {$opts(type)} {
            lappend result -type $drive_type
        }
        if {$opts(device)} {
            if {"remote" == $drive_type} {
                lappend result -device ""
            } else {
                lappend result -device [QueryDosDevice [string range $drive 0 1]]
            }
        }
    }

    if {$opts(serialnum) || $opts(label) || $opts(maxcomponentlen)
        || $opts(fstype) || $opts(attr)} {
        foreach {label serialnum maxcomponentlen attr fstype} \
            [GetVolumeInformation $drive] { break }
        foreach opt {label maxcomponentlen fstype}  {
            if {$opts($opt)} {
                lappend result -$opt [set $opt]
            }
        }
        if {$opts(serialnum)} {
            set low [expr {$serialnum & 0x0000ffff}]
            set high [expr {($serialnum >> 16) & 0x0000ffff}]
            lappend result -serialnum [format "%.4X-%.4X" $high $low]
        }
        if {$opts(attr)} {
            set attrs [list ]
            foreach val {
                case_preserved_names
                unicode_on_disk
                persistent_acls
                file_compression
                volume_quotas
                supports_sparse_files
                supports_reparse_points
                supports_remote_storage
                volume_is_compressed
                supports_object_ids
                supports_encryption
                named_streams
                read_only_volume
            } {
                # Coincidentally, the attribute values happen to match
                # the corresponding constant defines
                set cdef "FILE_[string toupper $val]"
                if {$attr & $windefs($cdef)} {
                    lappend attrs $val
                }
            }
            lappend result -attr $attrs
        }
    }

    return $result
}
interp alias {} twapi::get_drive_info {} twapi::get_volume_info


# Check if disk has at least n bytes available for the user (NOT total free)
proc twapi::user_drive_space_available {drv space} {
    return [expr {$space <= [lindex [get_drive_info $drv -useravail] 1]}]
}

# Get the drive type
proc twapi::get_drive_type {drive} {
    # set type [GetDriveType "[string trimright $drive :/\\]:\\"]
    set type [GetDriveType [_drive_rootpath $drive]]
    switch -exact -- $type {
        0 { return unknown}
        1 { return invalid}
        2 { return removable}
        3 { return fixed}
        4 { return remote}
        5 { return cdrom}
        6 { return ramdisk}
    }
}

#
# Get list of drives
proc twapi::find_logical_drives {args} {
    array set opts [parseargs args {type.arg}]

    set drives [list ]

    set i 0
    set drivebits [GetLogicalDrives]
    foreach drive {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
        if {[expr {$drivebits & (1 << $i)}]} {
            if {(![info exists opts(type)]) ||
                [lsearch -exact $opts(type) [get_drive_type $drive]] >= 0} {
                lappend drives $drive:
            }
        }
        incr i
    }
    return $drives
}
interp alias {} twapi::get_logical_drives {} twapi::find_logical_drives

#
# Set the drive label
proc twapi::set_drive_label {drive label} {
    SetVolumeLabel [_drive_rootpath $drive] $label
}

#
# Maps a drive letter to the given path
proc twapi::map_drive_local {drive path args} {
    array set opts [parseargs args {raw}]

    set drive [string range [_drive_rootpath $drive] 0 1]

    set flags [expr {$opts(raw) ? 0x1 : 0}]
    DefineDosDevice $flags $drive [file nativename $path]
}


#
# Unmaps a drive letter
proc twapi::unmap_drive_local {drive args} {
    array set opts [parseargs args {
        path.arg
        raw
    }]

    set drive [string range [_drive_rootpath $drive] 0 1]

    set flags [expr {$opts(raw) ? 0x1 : 0}]
    setbits flags 0x2;                  # DDD_REMOVE_DEFINITION
    if {[info exists opts(path)]} {
        setbits flags 0x4;              # DDD_EXACT_MATCH_ON_REMOVE
    }
    DefineDosDevice $flags $drive [file nativename $opts(path)]
}

#
# Monitor file changes
proc twapi::begin_filesystem_monitor {path script args} {
    array set opts [parseargs args {
        {subtree.bool false}
        filename.bool
        dirname.bool
        attr.bool
        size.bool
        write.bool
        access.bool
        create.bool
        secd.bool
    } -maxleftover 0]

    set have_opts 0
    set flags 0
    foreach {opt val} {
        filename 0x1
        dirname  0x2
        attr     0x4
        size     0x8
        write 0x10
        access 0x20
        create  0x40
        secd      0x100
    } {
        if {[info exists opts($opt)]} {
            if {$opts($opt)} {
                setbits flags $val
            }
            set have_opts 1
        }
    }

    if {! $have_opts} {
        # If no options specified, default to all
        set flags 0x17f
    }

    return [RegisterDirChangeNotifier $path $opts(subtree) $flags $script]
}

#
# Stop monitoring of files
proc twapi::cancel_filesystem_monitor {id} {
    UnregisterDirChangeNotifier $id
}


#
# Get list of volumes
proc twapi::find_volumes {} {
    set vols [list ]
    set found 1
    # Assumes there has to be at least one volume
    foreach {handle vol} [FindFirstVolume] break
    while {$found} {
        lappend vols $vol
        foreach {found vol} [FindNextVolume $handle] break
    }
    FindVolumeClose $handle
    return $vols
}

#
# Get list of volumes
proc twapi::find_volumes {} {
    set vols [list ]
    set found 1
    # Assumes there has to be at least one volume
    foreach {handle vol} [FindFirstVolume] break
    while {$found} {
        lappend vols $vol
        foreach {found vol} [FindNextVolume $handle] break
    }
    FindVolumeClose $handle
    return $vols
}

#
# Get list of volume mount points
proc twapi::find_volume_mount_points {vol} {
    set mntpts [list ]
    set found 1
    try {
        foreach {handle mntpt} [FindFirstVolumeMountPoint $vol] break
    } onerror {WINDOWS 18} {
        # ERROR_NO_MORE_FILES
        # No volume mount points
        return [list ]
    } onerror {WINDOWS 3} {
        # Volume does not support them
        return [list ]
    }

    # At least one volume found
    while {$found} {
        lappend mntpts $mntpt
        foreach {found mntpt} [FindNextVolumeMountPoint $handle] break
    }
    FindVolumeMountPointClose $handle
    return $mntpts
}

#
# Set volume mount point
proc twapi::mount_volume {volpt volname} {
    # Note we don't use _drive_rootpath for trimming since may not be root path
    SetVolumeMountPoint "[string trimright $volpt /\\]\\" "[string trimright $volname /\\]\\"
}

#
# Delete volume mount point
proc twapi::unmount_volume {volpt} {
    # Note we don't use _drive_rootpath for trimming since may not be root path
    DeleteVolumeMountPoint "[string trimright $volpt /\\]\\"
}

#
# Get the volume mounted at a volume mount point
proc twapi::get_mounted_volume_name {volpt} {
    # Note we don't use _drive_rootpath for trimming since may not be root path
    return [GetVolumeNameForVolumeMountPoint "[string trimright $volpt /\\]\\"]
}

#
# Get the mount point corresponding to a given path
proc twapi::get_volume_mount_point_for_path {path} {
    return [GetVolumePathName [file nativename $path]]
}

#
# Show property dialog for a volume
proc twapi::volume_properties_dialog {name args} {
    array set opts [parseargs args {
        {hwin.int 0}
        {page.arg ""}
    } -maxleftover 0]
    
    shell_object_properties_dialog $name -type volume -hwin $opts(hwin) -page $opts(page)
}

#
# Show property dialog for a file
proc twapi::file_properties_dialog {name args} {
    array set opts [parseargs args {
        {hwin.int 0}
        {page.arg ""}
    } -maxleftover 0]
    
    shell_object_properties_dialog $name -type file -hwin $opts(hwin) -page $opts(page)
}

#
# Utility functions

proc twapi::_drive_rootpath {drive} {
    if {[_is_unc $drive]} {
        # UNC
        return "[string trimright $drive ]\\"
    } else {
        return "[string trimright $drive :/\\]:\\"
    }
}

proc twapi::_is_unc {path} {
    return [expr {[string match {\\\\*} $path] || [string match // $path]}]
}
