log4f --type=i "Loading ⚙️ system functions..."

function sys
    # TODO: inherit variable $_
    log4f --type=i "Invoking system command..."

    # set --local sys_cmd (status current-function)
    set --local sys_sub $argv[1]
    set --local sys_obj $argv[2]
    set --local sys_arg $argv[3]

    if has_arg\? $sys_sub
        log4f --type=d "Invoking with subcommand: $sys_sub"
        if has_arg\? $sys_obj
            log4f --type=d "Invoking \"sys $sys_sub\" with system object: $sys_obj"
            set --local cmd "_sys_$sys_sub\_$sys_obj"
            eval $cmd $sys_arg # TODO: exec?
            # TODO: error handling
        else
            # TODO: print help in this case (look for event
            # fish_usage_err or fish_err)
            log4f --type=e "Missing system object for \"sys $sys_sub\""
            return 2
        end
    else
        echo we dont
    end
end
funcsave sys

function _sys_get_cores \
    --argument-names host \
    --description "Get the number of cores for the specified host."
    log4f --type=d "Getting the number of cores for host: \"$host\""

    set --local phys_cpus 1
    set --local logi_cpus
    set --local sysct_cmd "sysctl -n machdep.cpu.core_count"

    if [ -z "$host" -o "$host" = localhost ]
        set host localhost
        log4f "Either localhost or no host was specificed: \"$host\""
        set logi_cpus ($sysct_cmd)
    else
        log4f "A host was specified: $host"
        set logi_cpus (ssh $host $sysct_cmd)
        # if the above fails...
        # if test ! $status -eq 0
        #     echo "Previous command failed"
        # end
        # if test $status -ne 0
        #     echo "Previous command failed"
        # end
    end

    log4f --type=i "Number of physical CPUs: $phys_cpus"
    log4f --type=n "Number of logical CPUs: $logi_cpus"

    set -l num_cores (math "$phys_cpus * $logi_cpus")

    log4f "Number of cores: $num_cores"
    log4f --type=e "Host $host has $num_cores cores"
    log4f --type=f "Host $host has $num_cores cores"
    set --local array tim steve bob joe
    log4f -v array

    echo $num_cores
end
funcsave _sys_get_cores

function _sys_get_tasks \
    --description "Gets the optimal number of tasks that can be run in parallel on the machine."
    # Formula: num_of_cpu * cores_per_cpu * threads_per_core
    set -l cpu_count 1
    set -l core_count (sysctl -n machdep.cpu.core_count)
    set -l thread_count (sysctl -n machdep.cpu.thread_count)
    set -l threads_per_core (math "$thread_count / $core_count")
    set -l tasks_count (math "$cpu_count * $core_count * $threads_per_core")

    echo $tasks_count
end
funcsave _sys_get_tasks

function _sys_get_proc \
    --argument-names process
    # --description ""
    log4f --type=n "Getting process: \"$process\"..."

    set --local proc (ps -ecx -o "pid,command" | grep $process)
    set proc (strm $proc)
    set proc (strs " " $proc)

    log4f --var proc

    set --local pid $proc[1]
    set --local prc $proc[2]

    log4f --type=n "Retrieved process: \"$prc\", with pid: \"$pid\""

    echo $pid
    echo $prc
end
funcsave _sys_get_proc

# TODO: _sys_get_pid
# 1: start job
# 2: get pid with above or %last or $last_pid
# function _sys_get_pid
#     # set PID (jobs -l | awk '{print $2}') # just get the pid
#     # jobs -l | read jobid pid cpu state cmd # get all the things
# end
# funcsave _sys_get_pid

function _sys_kill_proc \
    --argument-names process
    # --description ""
    set --local proc (_sys_get_proc $process)
    set --local pid $proc[1]
    set --local prc $proc[2]

    log4f --type=n "Killing process: \"$prc\", with pid :\"$pid\"..."

    kill --signal KILL $pid

    # TODO: wait pid

    set proc (_sys_get_proc $prc)
    set pid $proc[1]
    set prc $proc[2]

    log4f --type=n "Process: \"$prc\" respawned, with pid: \"$pid\""
end
funcsave _sys_kill_proc
