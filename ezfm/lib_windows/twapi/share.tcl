#
# Copyright (c) 2003, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
}


#
# Create a network share
proc twapi::new_share {sharename path args} {
    variable windefs

    array set opts [parseargs args {
        system.arg
        {type.arg "file"}
        comment.arg
        {max_conn.int -1}
        secd.arg
    } -nulldefault]

    NetShareAdd $opts(system) \
        $sharename \
        [_share_type_symbols_to_code $opts(type)] \
        $opts(comment) \
        $opts(max_conn) \
        $path $opts(secd)
}

#
# Delete a network share
proc twapi::delete_share {sharename args} {
    array set opts [parseargs args {system.arg} -nulldefault]
    NetShareDel $opts(system) $sharename 0
}

#
# Enumerate network shares
proc twapi::get_shares {args} {
    variable windefs

    array set opts [parseargs args {
        system.arg
        type.arg
        excludespecial
    } -nulldefault]

    if {$opts(type) != ""} {
        set type_filter [_share_type_symbols_to_code $opts(type) 1]
    } else {
        set type_filter ""
    }

    set shares [list ]
    foreach share [Twapi_NetShareEnum $opts(system)] {
        foreach {name type comment} $share break
        set special [expr {$type & ($windefs(STYPE_SPECIAL) | $windefs(STYPE_TEMPORARY))}]
        if {$special && $opts(excludespecial)} {
            continue
        }
        # We need the special cast to int because else operands get promoted
        # to 64 bits as the hex is treated as an unsigned value
        set type [expr {int($type & ~ $special)}]
        if {([string length $type_filter] == 0) || ($type == $type_filter)} {
            lappend shares $name
        }
    }

    return $shares
}


#
# Get details about a share
proc twapi::get_share_info {sharename args} {
    array set opts [parseargs args {
        system.arg
        all
        name
        type
        path
        comment
        max_conn
        current_conn
        secd
    } -nulldefault]

    if {$opts(all)} {
        foreach opt {name type path comment max_conn current_conn secd} {
            set opts($opt) 1
        }
    }

    set level 0

    if {$opts(name) || $opts(type) || $opts(comment)} {
        set level 1
    }

    if {$opts(max_conn) || $opts(current_conn) || $opts(path)} {
        set level 2
    }

    if {$opts(secd)} {
        set level 502
    }

    if {! $level} {
        return
    }

    set shareinfo [NetShareGetInfo $opts(system) $sharename $level]

    set result [list ]
    if {$opts(name)} {
        lappend result -name [lindex $shareinfo 0]
    }
    if {$opts(type)} {
        lappend result -type [_share_type_code_to_symbols [lindex $shareinfo 1]]
    }
    if {$opts(comment)} {
        lappend result -comment [lindex $shareinfo 2]
    }
    if {$opts(max_conn)} {
        lappend result -max_conn [lindex $shareinfo 4]
    }
    if {$opts(current_conn)} {
        lappend result -current_conn [lindex $shareinfo 5]
    }
    if {$opts(path)} {
        lappend result -path [lindex $shareinfo 6]
    }
    if {$opts(secd)} {
        lappend result -secd [lindex $shareinfo 9]
    }
    
    return $result
}


#
# Set a share configuration
proc twapi::set_share_info {sharename args} {
    array set opts [parseargs args {
        {system.arg ""}
        comment.arg
        max_conn.int
        secd.arg
    }]

    # First get the current config so we can change specified fields
    # and write back
    array set shareinfo [get_share_info $sharename -system $opts(system) \
                             -comment -max_conn -secd]
    foreach field {comment max_conn secd} {
        if {[info exists opts($field)]} {
            set shareinfo(-$field) $opts($field)
        }
    }

    NetShareSetInfo $opts(system) $sharename $shareinfo(-comment) \
        $shareinfo(-max_conn) $shareinfo(-secd)
}


#
# Get list of remote shares
proc twapi::get_connected_shares {} {
    return [get_client_shares]
}


#
# Get list of remote shares
proc twapi::get_client_shares {} {
    return [NetUseEnum]
}


#
# Connect to a share
proc twapi::connect_share {remoteshare args} {
    array set opts [parseargs args {
        {type.arg  "disk"} 
        localdevice.arg
        provider.arg
        password.arg
        nopassword
        defaultpassword
        user.arg
        {window.arg 0}
        interactive
        prompt
        updateprofile
        commandline
    } -nulldefault]

    set flags 0

    switch -exact -- $opts(type) {
        "any"       {set type 0}
        "disk"      {set type 1}
        "printer"   {set type 2}
        default {
            error "Invalid network share type '$opts(type)'"
        }
    }

    # localdevice - "" means no local device, * means pick any, otherwise
    # it's a local device to be mapped
    if {$opts(localdevice) == "*"} {
        set opts(localdevice) ""
        setbits flags 0x80;             # CONNECT_REDIRECT
    }

    if {$opts(defaultpassword) && $opts(nopassword)} {
        error "Options -defaultpassword and -nopassword may not be used together"
    }
    if {$opts(nopassword)} {
        set opts(password) ""
        set ignore_password 1
    } else {
        set ignore_password 0
        if {$opts(defaultpassword)} {
            set opts(password) ""
        }
    }

    foreach {opt mask} {
        interactive   0x8
        prompt        0x10
        updateprofile 0x1
        commandline   0x800
    } {
        if {$opts($opt)} {
            setbits flags $mask
        }
    }

    return [Twapi_WNetUseConnection $opts(window) $type $opts(localdevice) \
                $remoteshare $opts(provider) $opts(user) $ignore_password \
                $opts(password) $flags]
}

#
# Disconnects an existing share
proc twapi::disconnect_share {sharename args} {
    array set opts [parseargs args {updateprofile force}]

    set flags [expr {$opts(updateprofile) ? 0x1 : 0}]
    WNetCancelConnection2 $sharename $flags $opts(force)
}


#
# Get information about a connected share
proc twapi::get_client_share_info {sharename args} {
    # We have to use a combination of NetUseGetInfo and 
    # WNetGetResourceInformation as neither gives us the full information
    # THe former takes the local device name if there is one and will
    # only accept a UNC if there is an entry for the UNC with
    # no local device mapped. The latter
    # always wants the UNC. So we need to figure out exactly if there
    # is a local device mapped to the sharename or not
    
    if {[regexp {^([[:alpha:]]+:)$} $sharename dontcare local]} {
        set unc [lindex [WNetGetUniversalName $sharename] 1]
    } else {
        # Check that it is a UNC sharename
        if {! [_is_unc $sharename]} {
            error "Invalid or unknown path format"
        }
        # There may be multiple entries for the same UNC
        # If there is an entry for the UNC with no device mapped, select
        # that else select any of the local devices mapped to it
        # TBD - any better way of finding out a mapping than calling
        # get_client_shares?
        set unc $sharename
        foreach elem [get_client_shares] {
            if {[string equal -nocase $sharename [lindex $elem 1]]} {
                if {[string length [lindex $elem 0]] == 0} {
                    # Found an entry without a local device. Use it
                    unset -nocomplain local; # In case we found a match earlier
                    break
                } else {
                    # Found a matching device
                    set local [lindex $elem 0]
                    # Keep looping in case we find an entry with no local device
                }
            }
        }
    }

    # At this point $unc is the UNC form of the share and
    # $local is either undefined or the local mapped device

    array set opts [parseargs args {
        user
        localdevice
        remoteshare
        status
        type
        opencount
        usecount
        domain
        provider
        comment
        all
    } -maxleftover 0]


    # Call Twapi_NetGetInfo always to get status. If we are not connected,
    # we will not call WNetGetResourceInformation as that will time out
    if {$opts(all) || $opts(user) || $opts(status) || $opts(type) ||
        $opts(opencount) || $opts(usecount) || $opts(domain)} {
        if {[info exists local]} {
            array set shareinfo [Twapi_NetUseGetInfo "" $local]
        } else {
            array set shareinfo [Twapi_NetUseGetInfo "" $unc]
        }
    }

    if {$opts(all) || $opts(comment) || $opts(provider) || $opts(remoteshare)} {
        # Only get this information if we are connected
        if {$shareinfo(ui2_status) == 0} {
            array set shareinfo [lindex [Twapi_WNetGetResourceInformation $unc "" 0] 0]
        } else {
            set shareinfo(lpRemoteName) $unc
            set shareinfo(lpProvider) ""
            set shareinfo(lpComment) ""
        }
    }


    array set result {}
    foreach {opt index} {
        user           ui2_username
        localdevice    ui2_local
        remoteshare    lpRemoteName
        status         ui2_status
        type           ui2_asg_type
        opencount      ui2_refcount
        usecount       ui2_usecount
        domain         ui2_domainname
        provider       lpProvider
        comment        lpComment
    } {
        if {$opts(all) || $opts($opt)} {
            set result(-$opt) $shareinfo($index)
        }
    }

    # Map values to symbols

    if {[info exists result(-status)]} {
        # Map code 0-5
        set temp [lindex {connected paused lostsession disconnected networkerror connecting reconnecting} $result(-status)]
        if {$temp ne ""} {
            set result(-status) $temp
        } else {
            set result(-status) "unknown"
        }
    }

    if {[info exists result(-type)]} {
        set temp [lindex {disk printer char ipc} $result(-type)]
        if {$temp ne ""} {
            set result(-type) $temp
        } else {
            set result(-type) "unknown"
        }
    }

    return [array get result]
}



#
# Get connected share info
proc twapi::get_mapped_share_info {path args} {
    array set opts [parseargs args {
        all user uncpath uncvolume relativepath
    }]

    if {! [regexp {^([[:alpha:]]:)} $path dontcare drive]} {
        error "No drive specified in path '$path'"
    }

    set result [list ]

    foreach {uncpath uncvolume relativepath} [WNetGetUniversalName $path] break
    foreach opt {uncpath uncvolume relativepath} {
        if {$opts($opt) || $opts(all)} {
            lappend result -$opt [set $opt]
        }
    }

    if {$opts(user) || $opts(all)} {
        lappend result -user [WNetGetUser $drive]
    }

    return $result
}



################################################################
# Utility functions

# NOTE: THIS ONLY MAPS FOR THE Net* functions, NOT THE WNet*
proc twapi::_share_type_symbols_to_code {typesyms {basetypeonly 0}} {
    variable windefs

    switch -exact -- [lindex $typesyms 0] {
        file    { set code $windefs(STYPE_DISKTREE) }
        printer { set code $windefs(STYPE_PRINTQ) }
        device  { set code $windefs(STYPE_DEVICE) }
        ipc     { set code $windefs(STYPE_IPC) }
        default {
            error "Unknown type network share type symbol [lindex $typesyms 0]"
        }
    }

    if {$basetypeonly} {
        return $code
    }

    set special 0
    foreach sym [lrange $typesyms 1 end] {
        switch -exact -- $sym {
            special   { setbits special $windefs(STYPE_SPECIAL) }
            temporary { setbits special $windefs(STYPE_TEMPORARY) }
            file    -
            printer -
            device  -
            ipc     {
                error "Base share type symbol '$sym' cannot be used as a share attribute type"
            }
            default {
                error "Unknown type network share type symbol '$sym'"
            }
        }
    }

    return [expr {$code | $special}]
}


# First element is always the base type of the share
# NOTE: THIS ONLY MAPS FOR THE Net* functions, NOT THE WNet*
proc twapi::_share_type_code_to_symbols {type} {
    variable windefs


    set special [expr {$type & ($windefs(STYPE_SPECIAL) | $windefs(STYPE_TEMPORARY))}]

    # We need the special cast to int because else operands get promoted
    # to 64 bits as the hex is treated as an unsigned value
    switch -exact -- [expr {int($type & ~ $special)}] \
        [list \
             $windefs(STYPE_DISKTREE) {set sym "file"} \
             $windefs(STYPE_PRINTQ)   {set sym "printer"} \
             $windefs(STYPE_DEVICE)   {set sym "device"} \
             $windefs(STYPE_IPC)      {set sym "ipc"} \
             default                  {set sym $type}
            ]

    set typesyms [list $sym]

    if {$special & $windefs(STYPE_SPECIAL)} {
        lappend typesyms special
    }

    if {$special & $windefs(STYPE_TEMPORARY)} {
        lappend typesyms temporary
    }
    
    return $typesyms
}

