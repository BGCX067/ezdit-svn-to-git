#
# Copyright (c) 2003-2006, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - allow access rights to be specified symbolically using procs
# from security.tcl
# TBD - add -user option to get_process_info and get_thread_info
# TBD - add wrapper for GetProcessExitCode

namespace eval twapi {
}

#
# Get my process id
proc twapi::get_current_process_id {} {
    return [::pid]
}

#
# Get my thread id
proc twapi::get_current_thread_id {} {
    return [GetCurrentThreadId]
}

# Return list of process ids
# Note if -path or -name is specified, then processes for which this
# information cannot be obtained are skipped
proc twapi::get_process_ids {args} {

    set save_args $args;                # Need to pass to process_exists
    array set opts [parseargs args { user.arg path.arg name.arg glob}]

    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {[info exists opts(user)] == 0 &&
         [info exists opts(path)] == 0
         && [info exists opts(name)] == 0} {
        # Return all pids
        return [twapi::EnumProcesses]
    }
    
    if {$opts(glob)} {
        set match_op match
    } else {
        set match_op equal
    }

    # Only want pids with a specific user, path or name
    set process_pids [list ]

    # If is the name we are looking for, try using the faster WTS
    # API's first. If they are not available, we try a slower method
    # If we need to match paths we don't try this at all as the wts
    # api's don't provide that info
    if {![info exists opts(path)]} {
        if {[info exists opts(user)]} {
            if {[catch {map_account_to_sid $opts(user)} sid]} {
                # No such user. Return empty list (no processes)
                return [list ]
            }
        }
        if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
            foreach wtselem $wtslist {
                array set procinfo $wtselem
                if {[info exists sid] &&
                    $procinfo(pUserSid) ne $sid} {
                    continue;           # User does not match
                }
                if {[info exists opts(name)]} {
                    # We need to match on name as well
                    if {![string $match_op -nocase $opts(name) $procinfo(pProcessName)]} {
                        # No match
                        continue
                    }
                }
                lappend process_pids $procinfo(ProcessId)
            }
            return $process_pids
        }
    }

    # Either we are matching on path, or the WTS call failed
    # Try yet another way.

    # Note that in the code below, we use "file join" with a single arg
    # to convert \ to /. Do not use file normalize as that will also
    # land up converting relative paths to full paths
    if {[info exists opts(path)]} {
        set opts(path) [file join $opts(path)]
    }

    set process_pids [list ]
    foreach pid [twapi::EnumProcesses] {
        if {[info exists opts(name)] &&
            ![string $match_op -nocase $opts(name) [get_process_name $pid]]} {
            continue
        }
        if {[info exists opts(path)] &&
            ![string $match_op -nocase $opts(path) [file join [get_process_path $pid]]]} {
            continue
        }

        if {[info exists opts(user)] &&
            [lindex [get_process_info $pid -user] 1] ne $opts(user)} {
            continue
        }

        lappend process_pids $pid
    }
    return $process_pids
}


# Return list of modules handles for a process
proc twapi::get_process_modules {pid args} {
    variable windefs

    array set opts [parseargs args {handle name path imagedata all}]

    if {$opts(all)} {
        foreach opt {handle name path imagedata} {
            set opts($opt) 1
        }
    }
    set noopts [expr {($opts(name) || $opts(path) || $opts(imagedata) || $opts(handle)) == 0}]

    set privs [expr {$windefs(PROCESS_QUERY_INFORMATION) | $windefs(PROCESS_VM_READ)}]
    set hpid [OpenProcess $privs 0 $pid]
    set results [list ]
    try {
        foreach module [EnumProcessModules $hpid] {
            if {$noopts} {
                lappend results $module
                continue
            }
            set module_data [list ]
            if {$opts(handle)} {
                lappend module_data -handle $module
            }
            if {$opts(name)} {
                if {[catch {GetModuleBaseName $hpid $module} name]} {
                    set name ""
                }
                lappend module_data -name $name
            }
           if {$opts(path)} {
                if {[catch {GetModuleFileNameEx $hpid $module} path]} {
                    set path ""
                }
               lappend module_data -path [_normalize_path $path]
            }
            if {$opts(imagedata)} {
                if {[catch {GetModuleInformation $hpid $module} imagedata]} {
                    set base ""
                    set size ""
                    set entry ""
                } else {
                    array set temp $imagedata
                    set base $temp(lpBaseOfDll)
                    set size $temp(SizeOfImage)
                    set entry $temp(EntryPoint)
                }                
                lappend module_data -imagedata [list $base $size $entry]
            }
            lappend results $module_data
        }
    } finally {
        CloseHandle $hpid
    }
    return $results
}



#
# Get the path of a process
proc twapi::get_process_path {pid args} {
    return [eval [list twapi::_get_process_name_path_helper $pid path] $args]
}


#
# Get the path of a process
proc twapi::get_process_name {pid args} {
    return [eval [list twapi::_get_process_name_path_helper $pid name] $args]
}


# Return list of device drivers
proc twapi::get_device_drivers {args} {
    variable windefs

    array set opts [parseargs args {name path base all}]

    set results [list ]
    foreach module [EnumDeviceDrivers] {
        catch {unset module_data}
        if {$opts(base) || $opts(all)} {
            set module_data [list -base $module]
        }
        if {$opts(name) || $opts(all)} {
            if {[catch {GetDeviceDriverBaseName $module} name]} {
                    set name ""
            }
            lappend module_data -name $name
        }
        if {$opts(path) || $opts(all)} {
            if {[catch {GetDeviceDriverFileName $module} path]} {
                set path ""
            }
            lappend module_data -path [_normalize_path $path]
        }
        if {[info exists module_data]} {
            lappend results $module_data
        }
    }

    return $results
}

#
# Kill a process 
# Returns 1 if process was ended, 0 if not ended within timeout
# 
proc twapi::end_process {pid args} {

    array set opts [parseargs args {
        {exitcode.int 1}
        force
        {wait.int 0}
    }]
    
    set process_path [get_process_path $pid]

    # First try to close nicely
    set toplevels [get_toplevel_windows -pid $pid]
    if {[llength $toplevels]} {
        # Try and close by sending them a message. WM_CLOSE is 0x10
        foreach toplevel $toplevels {
            # Send a message but come back right away
            if {0} {
                catch {PostMessage $toplevel 0x10 0 0}
            } else {
                catch {SendNotifyMessage $toplevel 0x10 0 0}
            }
        }

        # Wait for the specified time to verify process has gone away
        set gone [twapi::wait {process_exists $pid -path $process_path} 0 $opts(wait)]
        if {$gone || ! $opts(force)} {
            # Succeeded or do not want to force a kill
            return $gone
        }
        
        # Only wait 10 ms since we have already waited above
        if {$opts(wait)} {
            set opts(wait) 10
        }
    }

    # Open the process for terminate access. IF access denied (5), retry after
    # getting the required privilege
    try {
        set hpid [OpenProcess $twapi::windefs(PROCESS_TERMINATE) 0 $pid]
    } onerror {WINDOWS 5} {
        # Retry - if still fail, then just throw the error
        eval_with_privileges {
            set hpid [OpenProcess $twapi::windefs(PROCESS_TERMINATE) 0 $pid]
        } SeDebugPrivilege
    }

    try {
        TerminateProcess $hpid $opts(exitcode)
    } finally {
        CloseHandle $hpid
    }

    if {0} {
        While the process is being terminated, we can get access denied
        if we try to get the path so this if branch is commented out
        return [twapi::wait {process_exists $pid -path $process_path} 0 $opts(wait)]
    } else {
        return [twapi::wait {process_exists $pid} 0 $opts(wait)]
    }
}


# Check if the given process exists
# 0 - does not exist or exists but paths/names do not match, 
# 1 - exists and matches path (or no -path or -name specified)
# -1 - exists but do not know path and cannot compare
proc twapi::process_exists {pid args} {
    array set opts [parseargs args { path.arg name.arg glob}]

    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {[info exists opts(path)]} {
        set get_proc get_process_path
    } else {
        set get_proc get_process_name
    }

    set process_path [$get_proc $pid -noexist "" -noaccess "(unknown)"]
    if {[string length $process_path] == 0} {
        # No such process
        return 0
    }

    # Process with this pid exists

    if {[info exists opts(path)] == 0 && [info exists opts(name)] == 0} {
        # Don't care about the path or name
        return 1
    }

    # The process exists, but paths/names have to match
    if {[string equal $process_path "(unknown)"]} {
        # Exists but cannot check path/name
        return -1
    }

    if {$opts(glob)} {
        set string_cmd match
    } else {
        set string_cmd equal
    }

    if {[info exists opts(path)]} {
        # Note we do not use file normalize here since that will tack on
        # absolute paths which we do not want for glob matching

        # We use [file join ] to convert \ to / to avoid special
        # interpretation of \ in string match command
        return [string $string_cmd -nocase [file join $opts(path)] [file join $process_path]]
    } else {
        return [string $string_cmd -nocase $opts(name) $process_path]
    }
}

#
# Get the parent process of a thread. Return "" if no such thread
proc twapi::get_thread_parent_process_id {tid} {
    set status [catch {
        set th [get_thread_handle $tid]
        try {
            set pid [lindex [lindex [Twapi_NtQueryInformationThreadBasicInformation $th] 2] 0]
        } finally {
            close_handles [list $th]
        }
    }]

    if {$status == 0} {
        return $pid
    }


    # Could not use undocumented function. Try slooooow perf counter method
    set pid_paths [get_perf_thread_counter_paths $tid -pid]
    if {[llength $pid_paths] == 0} {
        return ""
    }
    
    if {[get_counter_path_value [lindex [lindex $pid_paths 0] 3] -var pid]} {
        return $pid
    } else {
        return ""
    }
}

#
# Get the thread ids belonging to a process
proc twapi::get_process_thread_ids {pid} {
    set counter_paths [get_perf_instance_counter_paths \
                           [_localize_perf_counter "Thread"] \
                           [list [_localize_perf_counter "ID Thread"]] \
                           [_localize_perf_counter "ID Process"] \
                           [list $pid]]
    set tids [list ]
    foreach counter_path $counter_paths {
        if {[get_counter_path_value $counter_path -var tid]} {
            lappend tids $tid
        }
    }
    return $tids
}


#
# Get process information 
proc twapi::get_process_info {pid args} {
    return [lindex [eval [list get_multiple_process_info [list $pid]] $args] 1]
}


#
# Get multiple process information 
proc twapi::get_multiple_process_info {pids args} {

    # Note the PDH options match those of twapi::get_process_perf_counter_paths
    # Opt -parent now uses get_process_parent
    set pdh_opts {
        elapsedtime
        handlecount
        pagefilebytes
        pagefilebytespeak
        poolnonpagedbytes
        poolpagedbytes
        basepriority
        privatebytes
        threadcount
        virtualbytes
        virtualbytespeak
        workingset
        workingsetpeak
    }

    set pdh_rate_opts {
        privilegedutilization
        processorutilization
        userutilization
        iodatabytesrate
        iodataopsrate
        iootherbytesrate
        iootheropsrate
        ioreadbytesrate
        ioreadopsrate
        iowritebytesrate
        iowriteopsrate
        pagefaultrate
    }

    set token_opts {
        user
        groups
        primarygroup
        privileges
        logonsession
    }

    array set opts [parseargs args \
                        [concat [list all \
                                     pid \
                                     handles \
                                     path \
                                     name \
                                     tids \
                                     toplevels \
                                     commandline \
                                     parent \
                                     [list noexist.arg "(no such process)"] \
                                     [list noaccess.arg "(unknown)"] \
                                     [list interval.int 100]] \
                             $token_opts \
                             $pdh_opts \
                             $pdh_rate_opts]]

    array set results {}

    # If user is requested, try getting it through terminal services
    # if possible since the token method fails on some newer platforms
    if {$opts(all) || $opts(user)} {
        _get_wts_pids wtssids wtsnames
    }

    foreach pid $pids {
        set result [list ]

        if {$opts(all) || $opts(pid)} {
            lappend result -pid $pid
        }

        if {$opts(all) || $opts(name)} {
            # See if we already have the name
            if {[info exists wtsnames($pid)] && $wtsnames($pid) != ""} {
                lappend result -name $wtsnames($pid)
            } else {
                lappend result -name [get_process_name $pid]
            }
        }
        
        if {$opts(all) || $opts(path)} {
            lappend result -path [get_process_path $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
        }
        
        if {$opts(all) || $opts(tids)} {
            lappend result -tids [get_process_thread_ids $pid]
        }
        
        if {$opts(all) || $opts(toplevels)} {
            lappend result -toplevels [get_toplevel_windows -pid $pid]
        }

        # NOTE: we do not check opts(all) for handles since the latter
        # is an unsupported option
        if {$opts(handles)} {
            set handles [list ]
            foreach hinfo [get_open_handles $pid] {
                lappend handles [list [kl_get $hinfo -handle] [kl_get $hinfo -type] [kl_get $hinfo -name]]
            }
            lappend result -handles $handles
        }

        if {$opts(all) || $opts(commandline)} {
            lappend result -commandline [get_process_commandline $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
        }

        if {$opts(all) || $opts(parent)} {
            lappend result -parent [get_process_parent $pid]
        }

        # Now get token related info, if any requested
        set requested_opts [list ]
        if {$opts(all) || $opts(user)} {
            # See if we already have the user. Note sid of system idle
            # will be empty string
            if {[info exists wtssids($pid)]} {
                if {$wtssids($pid) == ""} {
                    # Put user as System
                    lappend result -user "SYSTEM"
                } else {
                    lappend result -user [lookup_account_sid $wtssids($pid)]
                }
            } else {
                lappend requested_opts -user
            }
        }
        foreach opt {groups primarygroup privileges logonsession} {
            if {$opts(all) || $opts($opt)} {
                lappend requested_opts -$opt
            }
        }
        if {[llength $requested_opts]} {
            try {
                eval lappend result [_get_token_info process $pid $requested_opts]
            } onerror {WINDOWS 5} {
                foreach opt $requested_opts {
                    set tokresult($opt) $opts(noaccess)
                }
                # The NETWORK SERVICE and LOCAL SERVICE processes cannot
                # be accessed. If we are looking for the logon session for
                # these, try getting it from the witssid if we have it
                # since the logon session is hardcoded for these accounts
                if {[lsearch -exact $requested_opts "-logonsession"] >= 0} {
                    if {![info exists wtssids]} {
                        _get_wts_pids wtssids wtsnames
                    }
                    if {[info exists wtssids($pid)]} {
                        # Map user SID to logon session
                        switch -exact -- $wtssids($pid) {
                            S-1-5-18 {
                                # SYSTEM
                                set tokresult(-logonsession) 00000000-000003e7
                            }
                            S-1-5-19 {
                                # LOCAL SERVICE
                                set tokresult(-logonsession) 00000000-000003e5
                            }
                            S-1-5-20 {
                                # LOCAL SERVICE
                                set tokresult(-logonsession) 00000000-000003e4
                            }
                        }
                    }
                }
                set result [concat $result [array get tokresult]]
            } onerror {WINDOWS 87} {
                foreach opt $requested_opts {
                    lappend result $opt $opts(noexist)
                }
            }
        }

        set results($pid) $result
    }

    # Now retrieve each PDH non-rate related counter which do not
    # require an interval of measurement
    set requested_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
    if {[llength $requested_opts] != 0} {
        set counters [eval [list get_perf_process_counter_paths $pids] \
                          $requested_opts]
        foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval 0] {
            lappend results($pid) $opt $val
        }
    }

    # NOw do the rate related counter
    set requested_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
    if {[llength $requested_opts] != 0} {
        set counters [eval [list get_perf_process_counter_paths $pids] \
                          $requested_opts]
        foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval $opts(interval)] {
            lappend results($pid) $opt $val
        }
    }

    return [array get results]
}


#
# Get thread information 
# TBD - add info from GetGUIThreadInfo
proc twapi::get_thread_info {tid args} {
    # Note the PDH options match those of twapi::get_thread_perf_counter_paths
    set pdh_opts {
        elapsedtime
        pid
        basepriority
        priority
        startaddress
        state
        waitreason
    }

    set pdh_rate_opts {
        privilegedutilization 
        processorutilization
        userutilization
        contextswitches
    }

    set token_opts {
        groups
        user
        primarygroup
        privileges
    }

    array set opts [parseargs args \
                        [concat [list all tid [list interval.int 100]] $token_opts $pdh_opts $pdh_rate_opts]]

    set requested_opts [_array_non_zero_switches opts $token_opts $opts(all)]
    # Now get token info, if any
    if {[llength $requested_opts]} {
        if {[catch {_get_token_info thread $tid $requested_opts} results]} {
            set erCode $::errorCode
            set erInfo $::errorInfo
            if {[string equal [lindex $erCode 0] "WINDOWS"] &&
                [lindex $erCode 1] == 1008} {
                # Thread does not have its own token. Use it's parent process
                set results [_get_token_info process [get_thread_parent_process_id $tid] $requested_opts]
            } else {
                error $results $erInfo $erCode
            }
        }
    } else {
        set results [list ]
    }

    # Now retrieve each PDH non-rate related counter which do not
    # require an interval of measurement
    set requested_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
    if {[llength $requested_opts] != 0} {
        set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
                          $requested_opts]
        foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval 0] {
            lappend results $opt $value
        }
    }

    # Now do the same for any interval based counters
    set requested_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
    if {[llength $requested_opts] != 0} {
        set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
                          $requested_opts]
        foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval $opts(interval)] {
            lappend results $opt $value
        }
    }

    if {$opts(all) || $opts(tid)} {
        lappend results -tid $tid
    }

    return $results
}


#
# Wait until the process is ready
proc twapi::process_waiting_for_input {pid args} {
    array set opts [parseargs args {{wait.int 0}}]

    set hpid [OpenProcess $twapi::windefs(PROCESS_QUERY_INFORMATION) 0 $pid]
    try {
        set status [WaitForInputIdle $hpid $opts(wait)]
    } finally {
        CloseHandle $hpid
    }
    return $status
}

#
# Create a process
proc twapi::create_process {path args} {
    array set opts [parseargs args \
                        [list \
                             [list cmdline.arg ""] \
                             [list inheritablechildprocess.bool 0] \
                             [list inheritablechildthread.bool 0] \
                             [list childprocesssecd.arg ""] \
                             [list childthreadsecd.arg ""] \
                             [list inherithandles.bool 0] \
                             [list env.arg ""] \
                             [list startdir.arg ""] \
                             [list inheriterrormode.bool 1] \
                             [list newconsole.bool 0] \
                             [list detached.bool 0] \
                             [list newprocessgroup.bool 0] \
                             [list noconsole.bool 0] \
                             [list separatevdm.bool 0] \
                             [list sharedvdm.bool 0] \
                             [list createsuspended.bool 0] \
                             [list debugchildtree.bool 0] \
                             [list debugchild.bool 0] \
                             [list priority.arg "normal" [list normal abovenormal belownormal high realtime idle]] \
                             [list desktop.arg "__null__"] \
                             [list title.arg ""] \
                             windowpos.arg \
                             windowsize.arg \
                             screenbuffersize.arg \
                             [list feedbackcursoron.bool false] \
                             [list feedbackcursoroff.bool false] \
                             background.arg \
                             foreground.arg \
                             [list fullscreen.bool false] \
                             [list showwindow.arg ""] \
                             [list stdhandles.arg ""] \
                             [list returnhandles.bool 0]\
                            ]]
                             
    set process_sec_attr [_make_secattr $opts(childprocesssecd) $opts(inheritablechildprocess)]
    set thread_sec_attr [_make_secattr $opts(childthreadsecd) $opts(inheritablechildthread)]

    # Check incompatible options
    foreach {opt1 opt2} {
        newconsole detached
        sharedvdm  separatevdm
    } {
        if {$opts($opt1) && $opts($opt2)} {
            error "Options -$opt1 and -$opt2 cannot be specified together"
        }
    }
    # Create the start up info structure
    set si_flags 0
    if {[info exists opts(windowpos)]} {
        foreach {xpos ypos} [_parse_integer_pair $opts(windowpos)] break
        setbits si_flags 0x4
    } else {
        set xpos 0
        set ypos 0
    }
    if {[info exists opts(windowsize)]} {
        foreach {xsize ysize} [_parse_integer_pair $opts(windowsize)] break
        setbits si_flags 0x2
    } else {
        set xsize 0
        set ysize 0
    }
    if {[info exists opts(screenbuffersize)]} {
        foreach {xscreen yscreen} [_parse_integer_pair $opts(screenbuffersize)] break
        setbits si_flags 0x8
    } else {
        set xscreen 0
        set yscreen 0
    }

    set fg 7;                           # Default to white
    set bg 0;                           # Default to black
    if {[info exists opts(foreground)]} {
        set fg [_map_console_color $opts(foreground) 0]
        setbits si_flags 0x10
    }
    if {[info exists opts(background)]} {
        set bg [_map_console_color $opts(background) 1]
        setbits si_flags 0x10
    }

    if {$opts(feedbackcursoron)} {
        setbits si_flags 0x40
    }

    if {$opts(feedbackcursoron)} {
        setbits si_flags 0x80
    }

    if {$opts(fullscreen)} {
        setbits si_flags 0x20
    }

    switch -exact -- $opts(showwindow) {
        ""        { }
        hidden    {set opts(showwindow) 0}
        normal    {set opts(showwindow) 1}
        minimized {set opts(showwindow) 2}
        maximized {set opts(showwindow) 3}
        default   {error "Invalid value '$opts(showwindow)' for -showwindow option"}
    }
    if {[string length $opts(showwindow)]} {
        setbits si_flags 0x1
    }
    
    if {[string length $opts(stdhandles)]} {
        if {! $opts(inherithandles)} {
            error "Cannot specify -stdhandles option if option -inherithandles is specified as 0"
        }
        setbits si_flags 0x100
    }

    set startup [list $opts(desktop) $opts(title) $xpos $ypos \
                     $xsize $ysize $xscreen $yscreen \
                     [expr {$fg|$bg}] $si_flags $opts(showwindow) \
                     $opts(stdhandles)]

    # Figure out process creation flags
    set flags 0x00000400;               # CREATE_UNICODE_ENVIRONMENT
    foreach {opt flag} {
        debugchildtree       0x00000001
        debugchild           0x00000002
        createsuspended      0x00000004
        detached             0x00000008
        newconsole           0x00000010
        newprocessgroup      0x00000200
        separatevdm          0x00000800
        sharedvdm            0x00001000
        inheriterrormode     0x04000000
        noconsole            0x08000000    
    } {
        if {$opts($opt)} {
            setbits flags $flag
        }
    }

    switch -exact -- $opts(priority) {
        normal      {set priority 0x00000020}
        abovenormal {set priority 0x00008000}
        belownormal {set priority 0x00004000}
        ""          {set priority 0}
        high        {set priority 0x00000080}
        realtime    {set priority 0x00000100}
        idle        {set priority 0x00000040}
        default     {error "Unknown priority '$priority'"}
    }
    setbits flags $priority

    # Create the environment strings
    if {[llength $opts(env)]} {
        set child_env [list ]
        foreach {envvar envval} $opts(env) {
            lappend child_env "$envvar=$envval"
        }
    } else {
        set child_env "__null__"
    }
    foreach {ph th pid tid} [CreateProcess [file nativename $path] \
                                 $opts(cmdline) \
                                 $process_sec_attr $thread_sec_attr \
                                 $opts(inherithandles) $flags $child_env \
                                 [file normalize $opts(startdir)] $startup] {
        break
    }

    # From the Tcl source code - (tclWinPipe.c)
    #     /* 
    #      * "When an application spawns a process repeatedly, a new thread 
    #      * instance will be created for each process but the previous 
    #      * instances may not be cleaned up.  This results in a significant 
    #      * virtual memory loss each time the process is spawned.  If there 
    #      * is a WaitForInputIdle() call between CreateProcess() and
    #      * CloseHandle(), the problem does not occur." PSS ID Number: Q124121
    #      */
    # WaitForInputIdle $ph 5000 -- Apparently this is only needed for NT 3.5


    if {$opts(returnhandles)} {
        return [list $pid $tid $ph $th]
    } else {
        CloseHandle $th
        CloseHandle $ph
        return [list $pid $tid]
    }
}


#
# Get a handle to a process
proc twapi::get_process_handle {pid args} {
    array set opts [parseargs args {
        {access.arg process_query_information}
        {inherit.bool 0}
    }]
    return [OpenProcess [_access_rights_to_mask $opts(access)] $opts(inherit) $pid]
}

#
# Get a handle to a thread
proc twapi::get_thread_handle {tid args} {
    array set opts [parseargs args {
        {access.arg thread_query_information}
        {inherit.bool 0}
    }]
    return [OpenThread [_access_rights_to_mask $opts(access)] $opts(inherit) $tid]
}

#
# Suspend a thread
proc twapi::suspend_thread {tid} {
    set htid [OpenProcess $twapi::windefs(THREAD_SUSPEND_RESUME) 0 $tid]
    try {
        set status [SuspendThread $htid]
    } finally {
        CloseHandle $htid
    }
    return $status
}

#
# Resume a thread
proc twapi::resume_thread {tid} {
    set htid [OpenThread $twapi::windefs(THREAD_SUSPEND_RESUME) 0 $tid]
    try {
        set status [ResumeThread $htid]
    } finally {
        CloseHandle $htid
    }
    return $status
}


#
# Get the exit code for a process. Returns "" if still running.
proc twapi::get_process_exit_code {hpid} {
    set code [GetExitCodeProcess $hpid]
    return [expr {$code == 259 ? "" : $code}]
}


#
# Get the command line for a process
proc twapi::get_process_commandline {pid args} {

    if {[is_system_pid $pid] || [is_idle_pid $pid]} {
        return ""
    }

    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    }]

    try {
        # Assume max command line len is 512 chars (1024 bytes)
        set max_len 1024
        set hgbl [GlobalAlloc 0 $max_len]
        set pgbl [GlobalLock $hgbl]
        try {
            set hpid [OpenProcess [expr {$twapi::windefs(PROCESS_QUERY_INFORMATION)
                                         | $twapi::windefs(PROCESS_VM_READ)}] \
                          0 \
                          $pid]
        } onerror {WINDOWS 87} {
            # Process does not exist
            return $opts(noexist)
        }
        
        # Get the address where the PEB is stored - see Nebbett
        set peb_addr [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 1]
        # Read the PEB as binary
        # The pointer to the process information block is the 5th longword
        ReadProcessMemory $hpid [expr {16+$peb_addr}] $pgbl 4
        
        # Convert this to an integer address
        if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 4] i info_addr]} {
            error "Could not get address of process information block"
        }
        # The pointer to the command line is stored at offset 68
        ReadProcessMemory $hpid [expr {$info_addr + 68}] $pgbl 4
        if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 4] i cmdline_addr]} {
            error "Could not get address of command line"
        }

        # Now read the command line itself. We do not know the length
        # so assume MAX_PATH (1024) chars (2048 bytes). However, this may
        # fail if the memory beyond the command line is not allocated in the
        # target process. So we have to check for this error and retry with
        # smaller read sizes
        while {$max_len > 128} {
            try {
                ReadProcessMemory $hpid $cmdline_addr $pgbl $max_len
                break
            } onerror {WINDOWS 299} {
                # Reduce read size
                set max_len [expr {$max_len / 2}]
            }
        }

        # OK, got something. It's in Unicode format, may not be null terminated
        # or may have multiple null terminated strings. THe command line
        # is the first string.
        set cmdline [encoding convertfrom unicode [Twapi_ReadMemoryBinary $pgbl 0 $max_len]]
        set null_offset [string first "\0" $cmdline]
        if {$null_offset >= 0} {
            set cmdline [string range $cmdline 0 [expr {$null_offset-1}]]
        }
        
    } onerror {WINDOWS 5} {
        # Access denied
        set cmdline $opts(noaccess)
    } finally {
        if {[info exists hpid]} {
            close_handles $hpid
        }
        if {[info exists hgbl]} {
            if {[info exists pgbl]} {
                # We had locked the memory
                GlobalUnlock $hgbl
            }
            GlobalFree $hgbl
        }
    }

    return $cmdline
}


#
# Get process parent - can return ""
proc twapi::get_process_parent {pid args} {
    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    }]

    if {[is_system_pid $pid] || [is_idle_pid $pid]} {
        return ""
    }

    try {
        # Assume max command line len is 512 chars (1024 bytes)
        set hpid [OpenProcess $twapi::windefs(PROCESS_QUERY_INFORMATION) 0 $pid]
        
        # Get the address where the PEB is stored - see Nebbett
        set parent [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 5]
        
    } onerror {WINDOWS 5} {
        set error noaccess
    } onerror {WINDOWS 87} {
        set error noexist
    } finally {
        if {[info exists hpid]} {
            close_handles $hpid
        }
    }

    if {![info exists parent]} {
        # Try getting through pdh library
        set counters [get_perf_process_counter_paths $pid -parent]
        if {[llength counters]} {
            set vals [get_perf_values_from_metacounter_info $counters -interval 0]
            if {[llength $vals] > 2} {
                set parent [lindex $vals 2]
            }
        }
        if {![info exists parent]} {
            set parent $opts($error)
        }
    }

    return $parent
}

#
# Get the command line
proc twapi::get_command_line {} {
    return [GetCommandLineW]
}

#
# Parse the command line
proc twapi::get_command_line_args {cmdline} {
    return [CommandLineToArgv $cmdline]
}



# Return true if passed pid is system
proc twapi::is_system_pid {pid} {
    foreach {major minor} [get_os_version] break
    if {$major == 4 } {
        # NT 4
        set syspid 2
    } elseif {$major == 5 && $minor == 0} {
        # Win2K
        set syspid 8
    } else {
        # XP and Win2K3
        set syspid 4
    }

    # Redefine ourselves and call the redefinition
    proc ::twapi::is_system_pid pid "expr \$pid==$syspid"
    return [is_system_pid $pid]
}

# Return true if passed pid is of idle process
proc twapi::is_idle_pid {pid} {
    return [expr {$pid == 0}]
}


#
# Utility procedures
#


#
# Get the path of a process
proc twapi::_get_process_name_path_helper {pid {type name} args} {
    variable windefs

    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    }]

    if {![string is integer $pid]} {
        error "Invalid non-numeric pid $pid"
    }
    if {[is_system_pid $pid]} {
        return "System"
    }
    if {[is_idle_pid $pid]} {
        return "System Idle Process"
    }
    # OpenProcess masks off the bottom two bits thereby converting
    # an invalid pid to a real one. We do not want this
    if {$pid & 3} {
        return $opts(noexist)
    }

    set privs [expr {$windefs(PROCESS_QUERY_INFORMATION) | $windefs(PROCESS_VM_READ)}]

    try {
        set hpid [OpenProcess $privs 0 $pid]
    } onerror {WINDOWS 87} {
        return $opts(noexist)
    } onerror {WINDOWS 5} {
        # Access denied
        # If it is the name we want, first try WTS and if that
        # fails try getting it from PDH (slowest)

        if {[string equal $type "name"]} {
            if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
                foreach wtselem $wtslist {
                    if {[kl_get $wtselem ProcessId] == $pid} {
                        return [kl_get $wtselem pProcessName]
                    }
                }
            }

            # That failed as well, try PDH
            set pdh_path [lindex [lindex [twapi::get_perf_process_counter_paths [list $pid] -pid] 0] 3]
            array set pdhinfo [parse_perf_counter_path $pdh_path]
            return $pdhinfo(instance)
        }                        
        return $opts(noaccess)
    }

    try {
        set module [lindex [EnumProcessModules $hpid] 0]
        if {[string equal $type "name"]} {
            set path [GetModuleBaseName $hpid $module]
        } else {
            set path [_normalize_path [GetModuleFileNameEx $hpid $module]]
        }
    } onerror {WINDOWS 5} {
        # Access denied
        # On XP (and may be Win2k3), if the process has exited but some
        # app still has a handle to the process, the OpenProcess succeeds
        # but the EnumProcessModules call returns access denied. So
        # check for this case
        if {[min_os_version 5 1]} {
            # Try getting exit code. 259 means still running.
            # Anything else means process has terminated
            if {[GetExitCodeProcess $hpid] == 259} {
                return $opts(noaccess)
            } else {
                return $opts(noexist)
            }
        } else {
            # Rethrows original error - note try automatically beings these
            # into scope
            error $errorResult $errorInfo $errorCode
        }
    } finally {
        CloseHandle $hpid
    }
    return $path
}

#
# Return various information from a process token
proc twapi::_get_token_info {type id optlist} {
    array set opts [parseargs optlist {
        user
        groups
        primarygroup
        privileges
        logonsession
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    } -maxleftover 0]

    if {$type == "thread"} {
        set tok [open_thread_token -tid $id -access [list token_query]]
    } else {
        set tok [open_process_token -pid $id -access [list token_query]]
    }
    
    set result [list ]
    try {
        if {$opts(user)} {
            lappend result -user [get_token_user $tok -name]
        }
        if {$opts(groups)} {
            lappend result -groups [get_token_groups $tok -name]
        }
        if {$opts(primarygroup)} {
            lappend result -primarygroup [get_token_primary_group $tok -name]
        }
        if {$opts(privileges)} {
            lappend result -privileges [get_token_privileges $tok -all]
        }
        if {$opts(logonsession)} {
            array set stats [get_token_statistics $tok]
            lappend result -logonsession $stats(authluid)
        }
    } finally {
        close_token $tok
    }

    return $result
}

#
# Fill in arrays with result from WTSEnumerateProcesses if available
proc twapi::_get_wts_pids {v_sids v_names} {
    # Note this call is expected to fail on NT 4.0 without terminal server
    if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
        upvar $v_sids wtssids
        upvar $v_names wtsnames
        foreach wtselem $wtslist {
            set pid [kl_get $wtselem ProcessId]
            set wtssids($pid) [kl_get $wtselem pUserSid]
            set wtsnames($pid) [kl_get $wtselem pProcessName]
        }
    }
}