#
# Copyright (c) 2003-2009, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Contains commands available in the full twapi build only (not LEAN version).

# Return list of process ids
# Note if -path or -name is specified, then processes for which this
# information cannot be obtained are skipped
proc twapi::get_process_ids {args} {

    set save_args $args;                # Need to pass to process_exists
    array set opts [parseargs args {
        user.arg
        path.arg
        name.arg
        logonsession.arg
        glob} -maxleftover 0]

    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {$opts(glob)} {
        set match_op match
    } else {
        set match_op equal
    }

    set process_pids [list ]

    # If we do not care about user or path, Twapi_GetProcessList
    # is faster than EnumProcesses or the WTS functions
    if {[info exists opts(user)] == 0 &&
        [info exists opts(logonsession)] == 0 &&
        [info exists opts(path)] == 0} {
        if {[info exists opts(name)] == 0} {
            return [Twapi_GetProcessList -1 0]
        }
        # We need to match against the name
        foreach {pid piddata} [Twapi_GetProcessList -1 2] {
            if {[string $match_op -nocase $opts(name) [kl_get $piddata ProcessName]]} {
                lappend process_pids $pid
            }
        }
        return $process_pids
    }

    # Only want pids with a specific user or path

    # If is the name we are looking for, try using the faster WTS
    # API's first. If they are not available, we try a slower method
    # If we need to match paths or logon sessions, we don't try this
    # at all as the wts api's don't provide that info
    if {[info exists opts(path)] == 0 &&
        [info exists opts(logonsession)] == 0} {
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

    # Either we are matching on path/logonsession, or the WTS call failed
    # Try yet another way.

    # Note that in the code below, we use "file join" with a single arg
    # to convert \ to /. Do not use file normalize as that will also
    # land up converting relative paths to full paths
    if {[info exists opts(path)]} {
        set opts(path) [file join $opts(path)]
    }

    set process_pids [list ]
    if {[info exists opts(name)]} {
        # Note we may reach here if the WTS call above failed
        foreach {pid piddata} [Twapi_GetProcessList -1 2] {
            if {[string $match_op -nocase $opts(name) [kl_get $piddata ProcessName]]} {
                lappend all_pids $pid
            }
        }
    } else {
        set all_pids [Twapi_GetProcessList -1 0]
    }

    set popts [list ]
    foreach opt {path user logonsession} {
        if {[info exists opts($opt)]} {
            lappend popts -$opt
        }
    }
    foreach {pid piddata} [eval [list get_multiple_process_info $all_pids] $popts] {
        array set pidvals $piddata
        if {[info exists opts(path)] &&
            ![string $match_op -nocase $opts(path) [file join $pidvals(-path)]]} {
            continue
        }

        if {[info exists opts(user)] && $pidvals(-user) ne $opts(user)} {
            continue
        }

        if {[info exists opts(logonsession)] &&
            $pidvals(-logonsession) ne $opts(logonsession)} {
            continue
        }

        lappend process_pids $pid
    }
    return $process_pids
}


# Return list of modules handles for a process
proc twapi::get_process_modules {pid args} {
    variable my_process_handle

    array set opts [parseargs args {handle name path imagedata all}]

    if {$opts(all)} {
        foreach opt {handle name path imagedata} {
            set opts($opt) 1
        }
    }
    set noopts [expr {($opts(name) || $opts(path) || $opts(imagedata) || $opts(handle)) == 0}]

    if {$pid == [pid]} {
        set hpid $my_process_handle
    } else {
        set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
    }
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
        if {$hpid != $my_process_handle} {
            CloseHandle $hpid
        }
    }
    return $results
}


#
# Kill a process
# Returns 1 if process was ended, 0 if not ended within timeout
#
proc twapi::end_process {pid args} {

    if {$pid == [pid]} {
        error "The passed PID is the PID of the current process. end_process cannot be used to commit suicide."
    }

    array set opts [parseargs args {
        {exitcode.int 1}
        force
        {wait.int 0}
    }]

    # In order to verify the process is really gone, we open the process
    # if possible and then wait on its handle. If access restrictions prevent
    # us from doing so, we ignore the issue and will simply check for the
    # the PID later (which is not a sure check since PID's can be reused
    # immediately)
    catch {set hproc [get_process_handle $pid -access synchronize]}

    # First try to close nicely. We need to send messages to toplevels
    # as well as message-only windows.
    set toplevels [concat [get_toplevel_windows -pid $pid] [find_windows -pids [list $pid] -messageonlywindow true]]
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
        if {[info exists hproc]} {
            set status [WaitForMultipleObjects [list $hproc] 1 $opts(wait)]
            CloseHandle $hproc
            set gone [expr {! $status}]
        } else {
            # We could not get a process handle to wait on, just check if
            # PID still exists. This COULD be a false positive...
            set gone [twapi::wait {process_exists $pid} 0 $opts(wait)]
        }
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
        set hproc [get_process_handle $pid -access {synchronize process_terminate}]
    } onerror {TWAPI_WIN32 5} {
        # Retry - if still fail, then just throw the error
        eval_with_privileges {
            set hproc [get_process_handle $pid -access synchronize process_terminate]
        } SeDebugPrivilege
    } onerror {TWAPI_WIN32 87} {
        # Process does not exist, we must have succeeded above but just
        # took a bit longer for it to exit
        return 1
    }

    try {
        TerminateProcess $hproc $opts(exitcode)
        set status [WaitForMultipleObjects [list $hproc] 1 $opts(wait)]
        if {$status == 0} {
            return 1
        }
    } finally {
        CloseHandle $hproc
    }

    return 0
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

# Check if the given process exists
# 0 - does not exist or exists but paths/names do not match,
# 1 - exists and matches path (or no -path or -name specified)
# -1 - exists but do not know path and cannot compare
proc twapi::process_exists {pid args} {
    array set opts [parseargs args { path.arg name.arg glob}]

    # Simplest case - don't care about name or path
    if {! ([info exists opts(path)] || [info exists opts(name)])} {
        if {$pid == [pid]} {
            return 1
        }
        # TBD - would it be faster to do OpenProcess ? If success or 
        # access denied, process exists.

        if {[llength [Twapi_GetProcessList $pid 0]] == 0} {
            return 0
        } else {
            return 1
        }
    }

    # Can't specify both name and path
    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {$opts(glob)} {
        set string_cmd match
    } else {
        set string_cmd equal
    }

    if {[info exists opts(name)]} {
        # Name is specified
        set piddata [Twapi_GetProcessList $pid 2]
        if {[llength $piddata] &&
            [string $string_cmd -nocase $opts(name) [kl_get [lindex $piddata 1] ProcessName]]} {
            # PID exists and name matches
            return 1
        } else {
            return 0
        }
    }

    # Need to match on the path
    set process_path [get_process_path $pid -noexist "" -noaccess "(unknown)"]
    if {[string length $process_path] == 0} {
        # No such process
        return 0
    }

    # Process with this pid exists
    # Path still has to match
    if {[string equal $process_path "(unknown)"]} {
        # Exists but cannot check path/name
        return -1
    }

    # Note we do not use file normalize here since that will tack on
    # absolute paths which we do not want for glob matching

    # We use [file join ] to convert \ to / to avoid special
    # interpretation of \ in string match command
    return [string $string_cmd -nocase [file join $opts(path)] [file join $process_path]]
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
    return [lindex [lindex [get_multiple_process_info [list $pid] -tids] 1] 1]
}


#
# Get process information
proc twapi::get_process_info {pid args} {
    return [lindex [eval [list get_multiple_process_info [list $pid]] $args] 1]
}


#
# Get multiple process information
proc twapi::get_multiple_process_info {pids args} {

    # Options that are directly available from Twapi_GetProcessList
    if {![info exists ::twapi::get_multiple_process_info_base_opts]} {
        # Array value is the flags to pass to Twapi_GetProcessList
        array set ::twapi::get_multiple_process_info_base_opts {
            basepriority       1
            parent             1
            tssession          1
            name               2
            createtime         4
            usertime           4
            privilegedtime     4
            elapsedtime        4
            handlecount        4
            pagefaults         8
            pagefilebytes      8
            pagefilebytespeak  8
            poolnonpagedbytes  8
            poolnonpagedbytespeak  8
            poolpagedbytes     8
            poolpagedbytespeak 8
            threadcount        4
            virtualbytes       8
            virtualbytespeak   8
            workingset         8
            workingsetpeak     8
            tids               32
        }

        # The ones below are not supported on NT 4
        array set ::twapi::get_multiple_process_info_base_opts {
            ioreadops         16
            iowriteops        16
            iootherops        16
            ioreadbytes       16
            iowritebytes      16
            iootherbytes      16
        }
    }


    # Note the PDH options match those of twapi::get_process_perf_counter_paths
    set pdh_opts {
        privatebytes
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
        virtualized
        elevation
        integrity
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
                                     toplevels \
                                     commandline \
                                     priorityclass \
                                     [list noexist.arg "(no such process)"] \
                                     [list noaccess.arg "(unknown)"] \
                                     [list interval.int 100]] \
                             [array names ::twapi::get_multiple_process_info_base_opts] \
                             $token_opts \
                             $pdh_opts \
                             $pdh_rate_opts]]

    array set results {}

    # If user is requested, try getting it through terminal services
    # if possible since the token method fails on some newer platforms
    if {$opts(all) || $opts(user)} {
        _get_wts_pids wtssids wtsnames
    }

    # See if any Twapi_GetProcessList options are requested and if
    # so, calculate the appropriate flags
    set flags 0
    foreach opt [array names ::twapi::get_multiple_process_info_base_opts] {
        if {$opts($opt) || $opts(all)} {
            set flags [expr {$flags | $::twapi::get_multiple_process_info_base_opts($opt)}]
        }
    }
    if {$flags} {
        if {[llength $pids] == 1} {
            array set basedata [twapi::Twapi_GetProcessList [lindex $pids 0] $flags]
        } else {
            array set basedata [twapi::Twapi_GetProcessList -1 $flags]
        }
    }

    foreach pid $pids {
        set result [list ]

        if {$opts(all) || $opts(pid)} {
            lappend result -pid $pid
        }

        foreach {opt field} {
            createtime         CreateTime
            usertime           UserTime
            privilegedtime     KernelTime
            handlecount        HandleCount
            pagefaults         VmCounters.PageFaultCount
            pagefilebytes      VmCounters.PagefileUsage
            pagefilebytespeak  VmCounters.PeakPagefileUsage
            poolnonpagedbytes  VmCounters.QuotaNonPagedPoolUsage
            poolnonpagedbytespeak  VmCounters.QuotaPeakNonPagedPoolUsage
            poolpagedbytespeak     VmCounters.QuotaPeakPagedPoolUsage
            poolpagedbytes     VmCounters.QuotaPagedPoolUsage
            basepriority       BasePriority
            threadcount        ThreadCount
            virtualbytes       VmCounters.VirtualSize
            virtualbytespeak   VmCounters.PeakVirtualSize
            workingset         VmCounters.WorkingSetSize
            workingsetpeak     VmCounters.PeakWorkingSetSize
            ioreadops          IoCounters.ReadOperationCount
            iowriteops         IoCounters.WriteOperationCount
            iootherops         IoCounters.OtherOperationCount
            ioreadbytes        IoCounters.ReadTransferCount
            iowritebytes       IoCounters.WriteTransferCount
            iootherbytes       IoCounters.OtherTransferCount
            parent             InheritedFromProcessId
            tssession          SessionId
        } {
            if {$opts($opt) || $opts(all)} {
                if {[info exists basedata($pid)]} {
                    lappend result -$opt [twapi::kl_get $basedata($pid) $field]
                } else {
                    lappend result -$opt $opts(noexist)
                }
            }
        }

        if {$opts(elapsedtime) || $opts(all)} {
            if {[info exists basedata($pid)]} {
                lappend result -elapsedtime [expr {[clock seconds]-[large_system_time_to_secs [twapi::kl_get $basedata($pid) CreateTime]]}]
            } else {
                lappend result -elapsedtime $opts(noexist)
            }
        }

        if {$opts(tids) || $opts(all)} {
            if {[info exists basedata($pid)]} {
                set tids [list ]
                foreach {tid threaddata} [twapi::kl_get $basedata($pid) Threads] {
                    lappend tids $tid
                }
                lappend result -tids $tids
            } else {
                lappend result -tids $opts(noexist)
            }
        }

        if {$opts(name) || $opts(all)} {
            if {[info exists basedata($pid)]} {
                set name [twapi::kl_get $basedata($pid) ProcessName]
                if {$name eq ""} {
                    if {[is_system_pid $pid]} {
                        set name "System"
                    } elseif {[is_idle_pid $pid]} {
                        set name "System Idle Process"
                    }
                }
                lappend result -name $name
            } else {
                lappend result -name $opts(noexist)
            }
        }

        if {$opts(all) || $opts(path)} {
            lappend result -path [get_process_path $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
        }

        if {$opts(all) || $opts(priorityclass)} {
            try {
                set prioclass [get_priority_class $pid]
            } onerror {TWAPI_WIN32 5} {
                set prioclass $opts(noaccess)
            } onerror {TWAPI_WIN32 87} {
                set prioclass $opts(noexist)
            }
            lappend result -priorityclass $prioclass
        }

        if {$opts(all) || $opts(toplevels)} {
            set toplevels [get_toplevel_windows -pid $pid]
            if {[llength $toplevels]} {
                lappend result -toplevels $toplevels
            } else {
                if {[process_exists $pid]} {
                    lappend result -toplevels [list ]
                } else {
                    lappend result -toplevels $opts(noexist)
                }
            }
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
                    # We speed up account lookup by caching sids
                    if {[info exists sidcache($wtssids($pid))]} {
                        lappend result -user $sidcache($wtssids($pid))
                    } else {
                        set uname [lookup_account_sid $wtssids($pid)]
                        lappend result -user $uname
                        set sidcache($wtssids($pid)) $uname
                    }
                }
            } else {
                lappend requested_opts -user
            }
        }
        foreach opt {elevation integrity groups primarygroup privileges logonsession virtualized} {
            if {$opts(all) || $opts($opt)} {
                lappend requested_opts -$opt
            }
        }
        if {[llength $requested_opts]} {
            try {
                set result [concat $result [eval [list _token_info_helper -pid $pid] $requested_opts]]
            } onerror {TWAPI_WIN32 5} {
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

                # Similarly, if we are looking for user account, special case
                # system and system idle processes
                if {[lsearch -exact $requested_opts "-user"] >= 0} {
                    if {[is_idle_pid $pid] || [is_system_pid $pid]} {
                        set tokresult(-user) SYSTEM
                    }
                }

                set result [concat $result [array get tokresult]]
            } onerror {TWAPI_WIN32 87} {
                foreach opt $requested_opts {
                    if {$opt eq "-user" && ([is_idle_pid $pid] || [is_system_pid $pid])} {
                        lappend result $opt SYSTEM
                    } else {
                        lappend result $opt $opts(noexist)
                    }
                }
            }
        }

        set results($pid) $result
    }

    # Now deal with the PDH stuff. We need to track what data we managed
    # to get
    array set gotdata {}

    # Now retrieve each PDH non-rate related counter which do not
    # require an interval of measurement
    set wanted_pdh_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
    if {[llength $wanted_pdh_opts] != 0} {
        set counters [eval [list get_perf_process_counter_paths $pids] \
                          $wanted_pdh_opts]
        foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval 0] {
            lappend results($pid) $opt $val
            set gotdata($pid,$opt) 1; # Since we have the data
        }
    }

    # NOw do the rate related counter. Again, we need to track missing data
    set wanted_pdh_rate_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
    foreach pid $pids {
        foreach opt $wanted_pdh_rate_opts {
            set missingdata($pid,$opt) 1
        }
    }
    if {[llength $wanted_pdh_rate_opts] != 0} {
        set counters [eval [list get_perf_process_counter_paths $pids] \
                          $wanted_pdh_rate_opts]
        foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval $opts(interval)] {
            lappend results($pid) $opt $val
            set gotdata($pid,$opt) 1; # Since we have the data
        }
    }

    # For data that we could not get from PDH assume the process does not exist
    foreach pid $pids {
        foreach opt [concat $wanted_pdh_opts $wanted_pdh_rate_opts] {
            if {![info exists gotdata($pid,$opt)]} {
                # Could not get this combination. Assume missing process
                lappend results($pid) $opt $opts(noexist)
            }
        }
    }

    return [array get results]
}


#
# Get thread information
# TBD - add info from GetGUIThreadInfo
proc twapi::get_thread_info {tid args} {

    # Options that are directly available from Twapi_GetProcessList
    if {![info exists ::twapi::get_thread_info_base_opts]} {
        # Array value is the flags to pass to Twapi_GetProcessList
        array set ::twapi::get_thread_info_base_opts {
            pid 32
            elapsedtime 96
            waittime 96
            usertime 96
            createtime 96
            privilegedtime 96
            contextswitches 96
            basepriority 160
            priority 160
            startaddress 160
            state 160
            waitreason 160
        }
    }

    # Note the PDH options match those of twapi::get_thread_perf_counter_paths
    # Right now, we don't need any PDH non-rate options
    set pdh_opts {
    }
    set pdh_rate_opts {
        privilegedutilization
        processorutilization
        userutilization
        contextswitchrate
    }

    set token_opts {
        groups
        user
        primarygroup
        privileges
    }

    array set opts [parseargs args \
                        [concat [list all \
                                     relativepriority \
                                     tid \
                                     [list noexist.arg "(no such thread)"] \
                                     [list noaccess.arg "(unknown)"] \
                                     [list interval.int 100]] \
                             [array names ::twapi::get_thread_info_base_opts] \
                             $token_opts $pdh_opts $pdh_rate_opts]]

    set requested_opts [_array_non_zero_switches opts $token_opts $opts(all)]
    # Now get token info, if any
    if {[llength $requested_opts]} {
        try {
            try {
                set results [eval [list _token_info_helper -tid $tid] $requested_opts]
            } onerror {TWAPI_WIN32 1008} {
                # Thread does not have its own token. Use it's parent process
                set results [eval [list _token_info_helper -pid [get_thread_parent_process_id $tid]] $requested_opts]
            }
        } onerror {TWAPI_WIN32 5} {
            # No access
            foreach opt $requested_opts {
                lappend results $opt $opts(noaccess)
            }
        } onerror {TWAPI_WIN32 87} {
            # Thread does not exist
            foreach opt $requested_opts {
                lappend results $opt $opts(noexist)
            }
        }

    } else {
        set results [list ]
    }

    # Now get the base options
    set flags 0
    foreach opt [array names ::twapi::get_thread_info_base_opts] {
        if {$opts($opt) || $opts(all)} {
            set flags [expr {$flags | $::twapi::get_thread_info_base_opts($opt)}]
        }
    }

    if {$flags} {
        # We need at least one of the base options
        foreach {pid piddata} [twapi::Twapi_GetProcessList -1 $flags] {
            foreach {thread_id threaddata} [kl_get $piddata Threads] {
                if {$tid == $thread_id} {
                    # Found the thread we want
                    array set threadinfo $threaddata
                    break
                }
            }
            if {[info exists threadinfo]} {
                break;  # Found it, no need to keep looking through other pids
            }
        }
        # It is possible that we looped through all the processs without
        # a thread match. Hence we check again that we have threadinfo for
        # each option value
        foreach {opt field} {
            pid            ClientId.UniqueProcess
            waittime       WaitTime
            usertime       UserTime
            createtime     CreateTime
            privilegedtime KernelTime
            basepriority   BasePriority
            priority       Priority
            startaddress   StartAddress
            state          State
            waitreason     WaitReason
            contextswitches ContextSwitchCount
        } {
            if {$opts($opt) || $opts(all)} {
                if {[info exists threadinfo]} {
                    lappend results -$opt $threadinfo($field)
                } else {
                    lappend results -$opt $opts(noexist)
                }
            }
        }

        if {$opts(elapsedtime) || $opts(all)} {
            if {[info exists threadinfo(CreateTime)]} {
                lappend results -elapsedtime [expr {[clock seconds]-[large_system_time_to_secs $threadinfo(CreateTime)]}]
            } else {
                lappend results -elapsedtime $opts(noexist)
            }
        }
    }

    # Now retrieve each PDH non-rate related counter which do not
    # require an interval of measurement
    set requested_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
    array set pdhdata {}
    if {[llength $requested_opts] != 0} {
        set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
                          $requested_opts]
        foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval 0] {
            set pdhdata($opt) $value
        }
        foreach opt $requested_opts {
            if {[info exists pdhdata($opt)]} {
                lappend results $opt $pdhdata($opt)
            } else {
                # Assume does not exist
                lappend results $opt $opts(noexist)
            }
        }
    }


    # Now do the same for any interval based counters
    set requested_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
    if {[llength $requested_opts] != 0} {
        set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
                          $requested_opts]
        foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval $opts(interval)] {
            set pdhdata($opt) $value
        }
        foreach opt $requested_opts {
            if {[info exists pdhdata($opt)]} {
                lappend results $opt $pdhdata($opt)
            } else {
                # Assume does not exist
                lappend results $opt $opts(noexist)
            }
        }
    }

    if {$opts(all) || $opts(relativepriority)} {
        try {
            lappend results -relativepriority [get_thread_relative_priority $tid]
        } onerror {TWAPI_WIN32 5} {
            lappend results -relativepriority $opts(noaccess)
        } onerror {TWAPI_WIN32 87} {
            lappend results -relativepriority $opts(noexist)
        }
    }

    if {$opts(all) || $opts(tid)} {
        lappend results -tid $tid
    }

    return $results
}

#
# Get a handle to a thread
proc twapi::get_thread_handle {tid args} {
    # OpenThread masks off the bottom two bits thereby converting
    # an invalid tid to a real one. We do not want this.
    if {$tid & 3} {
        win32_error 87;         # "The parameter is incorrect"
    }

    array set opts [parseargs args {
        {access.arg thread_query_information}
        {inherit.bool 0}
    }]
    return [OpenThread [_access_rights_to_mask $opts(access)] $opts(inherit) $tid]
}

#
# Suspend a thread
proc twapi::suspend_thread {tid} {
    set htid [get_thread_handle $tid -access thread_suspend_resume)]
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
    set htid [get_thread_handle $tid -access thread_suspend_resume)]
    try {
        set status [ResumeThread $htid]
    } finally {
        CloseHandle $htid
    }
    return $status
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
        # Assume max command line len is 1024 chars (2048 bytes)
        set max_len 2048
        set hgbl [GlobalAlloc 0 $max_len]
        set pgbl [GlobalLock $hgbl]
        try {
            set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
        } onerror {TWAPI_WIN32 87} {
            # Process does not exist
            return $opts(noexist)
        }

        # Get the address where the PEB is stored - see Nebbett
        set peb_addr [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 1]

        # Read the PEB as binary
        # The pointer to the process parameter block is the 5th pointer field.
        # The struct looks like:
        # 32 bit -
        # typedef struct _PEB {
        # BYTE                          Reserved1[2];
        # BYTE                          BeingDebugged;
        # BYTE                          Reserved2[1];
        # PVOID                         Reserved3[2];
        # PPEB_LDR_DATA                 Ldr;
        # PRTL_USER_PROCESS_PARAMETERS  ProcessParameters;
        # BYTE                          Reserved4[104];
        # PVOID                         Reserved5[52];
        # PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
        # BYTE                          Reserved6[128];
        # PVOID                         Reserved7[1];
        # ULONG                         SessionId;
        # } PEB, *PPEB;
        # 64 bit -
        # typedef struct _PEB {
        #   BYTE Reserved1[2];
        #   BYTE BeingDebugged;
        #   BYTE Reserved2[21];
        #   PPEB_LDR_DATA LoaderData;
        #   PRTL_USER_PROCESS_PARAMETERS ProcessParameters;
        #   BYTE Reserved3[520];
        #   PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
        #   BYTE Reserved4[136];
        #   ULONG SessionId;
        # } PEB;
        # So in both cases the pointer is 4 pointers from the start

        ReadProcessMemory $hpid [expr {$peb_addr+(4*$::tcl_platform(pointerSize))}] $pgbl $::tcl_platform(pointerSize)
        set proc_param_addr [Twapi_ReadMemoryPointer $pgbl 0]

        # Now proc_param_addr contains the address of the Process parameter
        # structure which looks like:
        # typedef struct _RTL_USER_PROCESS_PARAMETERS {
        #                      Offsets:     x86  x64
        #    BYTE           Reserved1[16];   0    0
        #    PVOID          Reserved2[10];  16   16
        #    UNICODE_STRING ImagePathName;  56   96
        #    UNICODE_STRING CommandLine;    64  112
        # } RTL_USER_PROCESS_PARAMETERS, *PRTL_USER_PROCESS_PARAMETERS;
        # UNICODE_STRING is defined as
        # typedef struct _UNICODE_STRING {
        #  USHORT Length;
        #  USHORT MaximumLength;
        #  PWSTR  Buffer;
        # } UNICODE_STRING;

        if {$::tcl_platform(pointerSize) == 8} {
            # Read the CommandLine field
            ReadProcessMemory $hpid [expr {$proc_param_addr + 112}] $pgbl 16
            if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 16] tutunum cmdline_bytelen cmdline_bufsize unused cmdline_addr]} {
                error "Could not get address of command line"
            }
        } else {
            # Read the CommandLine field
            ReadProcessMemory $hpid [expr {$proc_param_addr + 64}] $pgbl 8
            if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 8] tutunu cmdline_bytelen cmdline_bufsize cmdline_addr]} {
                error "Could not get address of command line"
            }
        }

        if {1} {
            if {$cmdline_bytelen == 0} {
                set cmdline ""
            } else {
                try {
                    ReadProcessMemory $hpid $cmdline_addr $pgbl $cmdline_bytelen
                } onerror {TWAPI_WIN32 299} {
                    # ERROR_PARTIAL_COPY
                    # Rumour has it this can be a transient error if the
                    # process is initializing, so try once more
                    Sleep 0;    # Relinquish control to OS to run other process
                    # Retry
                    ReadProcessMemory $hpid $cmdline_addr $pgbl $cmdline_bytelen
                }
                set cmdline [Twapi_ReadMemoryUnicode $pgbl 0 $cmdline_bytelen]
            }
        } else {
            # Old pre-2.3 code
            # Now read the command line itself. We do not know the length
            # so assume MAX_PATH (1024) chars (2048 bytes). However, this may
            # fail if the memory beyond the command line is not allocated in the
            # target process. So we have to check for this error and retry with
            # smaller read sizes
            while {$max_len > 128} {
                try {
                    ReadProcessMemory $hpid $cmdline_addr $pgbl $max_len
                    break
                } onerror {TWAPI_WIN32 299} {
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
        }
    } onerror {TWAPI_WIN32 5} {
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
        set hpid [get_process_handle $pid]
        set parent [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 5]

    } onerror {TWAPI_WIN32 5} {
        set error noaccess
    } onerror {TWAPI_WIN32 87} {
        set error noexist
    } finally {
        if {[info exists hpid]} {
            close_handles $hpid
        }
    }

    # TBD - if above fails, try through Twapi_GetProcessList

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
# Get the base priority class of a process
proc twapi::get_priority_class {pid} {
    set ph [get_process_handle $pid]
    try {
        return [GetPriorityClass $ph]
    } finally {
        CloseHandle $ph
    }
}

#
# Get the base priority class of a process
proc twapi::set_priority_class {pid priority} {
    if {$pid == [pid]} {
        variable my_process_handle
        SetPriorityClass $my_process_handle $priority
        return
    }

    set ph [get_process_handle $pid -access process_set_information]
    try {
        SetPriorityClass $ph $priority
    } finally {
        CloseHandle $ph
    }
}

#
# Get the priority of a thread
proc twapi::get_thread_relative_priority {tid} {
    set h [get_thread_handle $tid]
    try {
        return [GetThreadPriority $h]
    } finally {
        CloseHandle $h
    }
}

#
# Set the priority of a thread
proc twapi::set_thread_relative_priority {tid priority} {
    switch -exact -- $priority {
        abovenormal { set priority 1 }
        belownormal { set priority -1 }
        highest     { set priority 2 }
        idle        { set priority -15 }
        lowest      { set priority -2 }
        normal      { set priority 0 }
        timecritical { set priority 15 }
        default {
            if {![string is integer -strict $priority]} {
                error "Invalid priority value '$priority'."
            }
        }
    }

    set h [get_thread_handle $tid -access thread_set_information]
    try {
        SetThreadPriority $h $priority
    } finally {
        CloseHandle $h
    }
}


# Return whether a process is running under WoW64
proc twapi::wow64_process {args} {
    array set opts [parseargs args {
        pid.arg
        hprocess.arg
    } -maxleftover 0]

    if {[info exists opts(hprocess)]} {
        if {[info exists opts(pid)]} {
            error "Options -pid and -hprocess cannot be used together."
        }
        return [IsWow64Process $opts(hprocess)]
    }

    if {[info exists opts(pid)] && $opts(pid) != [pid]} {
        try {
            set hprocess [get_process_handle $opts(pid)]
            return [IsWow64Process $hprocess]
        } finally {
            if {[info exists hprocess]} {
                CloseHandle $hprocess
            }
        }
    }

    # Common case - checking about ourselves
    variable my_process_handle
    return [IsWow64Process $my_process_handle]
}

# Return type of process elevation
proc twapi::get_process_elevation {args} {
    lappend args -elevation
    return [lindex [_token_info_helper $args] 1]
}

# Return integrity level of process
proc twapi::get_process_integrity {args} {
    lappend args -integrity
    return [lindex [_token_info_helper $args] 1]
}

# Check whether a process is virtualized
proc twapi::virtualized_process {args} {
    lappend args -virtualized
    return [lindex [_token_info_helper $args] 1]
}

proc twapi::set_process_integrity {level args} {
    lappend args -integrity $level
    _token_set_helper $args
}

proc twapi::set_process_virtualization {enable args} {
    lappend args -virtualized $enable
    _token_set_helper $args
}

# Map a process handle to its pid
proc twapi::get_pid_from_handle {hprocess} {
    return [lindex [Twapi_NtQueryInformationProcessBasicInformation $hprocess] 4]
}

# Check if current process is an administrative process or not
proc twapi::process_in_administrators {} {

    # Administrators group SID - S-1-5-32-544

    if {[get_process_elevation] ne "limited"} {
        return [CheckTokenMembership NULL S-1-5-32-544]
    }

    # When running as with a limited token under UAC, we cannot check
    # if the process is in administrators group or not since the group
    # will be disabled in the token. Rather, we need to get the linked
    # token (which is unfiltered) and check that.
    set tok [lindex [_token_info_helper -linkedtoken] 1]
    try {
        return [CheckTokenMembership $tok S-1-5-32-544]
    } finally {
        close_token $tok
    }
}

#
# Utility procedures
#

#
# Get the path of a process
proc twapi::_get_process_name_path_helper {pid {type name} args} {

    # TBD - optimize for case $pid == [pid]

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

    try {
        set hprocess [get_process_handle $pid -access {process_query_information process_vm_read}]
    } onerror {TWAPI_WIN32 87} {
        return $opts(noexist)
    } onerror {TWAPI_WIN32 5} {
        # Access denied
        # If it is the name we want, first try WTS and if that
        # fails try getting it from PDH (slowest)

        # TBD - can we use Twapi_GetProcessList here? Seems to be faster

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
        set module [lindex [EnumProcessModules $hprocess] 0]
        if {[string equal $type "name"]} {
            set path [GetModuleBaseName $hprocess $module]
        } else {
            set path [_normalize_path [GetModuleFileNameEx $hprocess $module]]
        }
    } onerror {TWAPI_WIN32 5} {
        # Access denied
        # On win2k (and may be Win2k3), if the process has exited but some
        # app still has a handle to the process, the OpenProcess succeeds
        # but the EnumProcessModules call returns access denied. So
        # check for this case
        if {[min_os_version 5 0]} {
            # Try getting exit code. 259 means still running.
            # Anything else means process has terminated
            if {[GetExitCodeProcess $hprocess] == 259} {
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
        CloseHandle $hprocess
    }
    return $path
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

#
# Return various information from a process token
proc twapi::_token_info_helper {args} {
    if {[llength $args] == 1} {
        # All options specified as one argument
        set args [lindex $args 0]
    }

    array set opts [parseargs args {
        elevation
        virtualized
        integrity
        user
        groups
        primarygroup
        privileges
        logonsession
        linkedtoken
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
        pid.arg
        hprocess.arg
        tid.arg
        hthread.arg
        raw
        label
    } -maxleftover 0]

    if {[expr {[info exists opts(pid)] + [info exists opts(hprocess)] +
               [info exists opts(tid)] + [info exists opts(hthread)]}] > 1} {
        error "At most one option from -pid, -tid, -hprocess, -hthread can be specified."
    }

    if {[info exists opts(hprocess)]} {
        set tok [open_process_token -hprocess $opts(hprocess)]
    } elseif {[info exists opts(pid)]} {
        set tok [open_process_token -pid $opts(pid)]
    } elseif {[info exists opts(hthread)]} {
        set tok [open_thread_token -hthread $opts(hthread)]
    } elseif {[info exists opts(tid)]} {
        set tok [open_thread_token -tid $opts(tid)]
    } else {
        # Default is current process
        set tok [open_process_token]
    }

    set result [list ]
    try {
        if {$opts(linkedtoken)} {
            lappend result -linkedtoken [get_token_linked_token $tok]
        }
        if {$opts(elevation)} {
            lappend result -elevation [get_token_elevation $tok]
        }
        if {$opts(integrity)} {
            if {$opts(raw)} {
                set integrity [get_token_integrity $tok -raw]
            } elseif {$opts(label)} {
                set integrity [get_token_integrity $tok -label]
            } else {
                set integrity [get_token_integrity $tok]
            }
            lappend result -integrity $integrity
        }
        if {$opts(virtualized)} {
            lappend result -virtualized [get_token_virtualization $tok]
        }
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
# Set various information for a process token
# Caller assumed to have enabled appropriate privileges
proc twapi::_token_set_helper {args} {
    if {[llength $args] == 1} {
        # All options specified as one argument
        set args [lindex $args 0]
    }

    array set opts [parseargs args {
        virtualized.bool
        integrity.arg
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
        pid.arg
        hprocess.arg
    } -maxleftover 0]

    if {[info exists opts(pid)] && [info exists opts(hprocess)]} {
        error "Options -pid and -hprocess cannot be specified together."
    }

    # Open token with appropriate access rights depending on request.
    set access [list token_adjust_default]

    if {[info exists opts(hprocess)]} {
        set tok [open_process_token -hprocess $opts(hprocess) -access $access]
    } elseif {[info exists opts(pid)]} {
        set tok [open_process_token -pid $opts(pid) -access $access]
    } else {
        # Default is current process
        set tok [open_process_token -access $access]
    }

    set result [list ]
    try {
        if {[info exists opts(integrity)]} {
            set_token_integrity $tok $opts(integrity)
        }
        if {[info exists opts(virtualized)]} {
            set_token_virtualization $tok $opts(virtualized)
        }
    } finally {
        close_token $tok
    }

    return $result
}
