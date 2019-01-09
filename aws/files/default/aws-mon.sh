#!/bin/bash

# Copyright (C) 2014 mooapp
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not 
# use this file except in compliance with the License. A copy of the License 
# is located at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "LICENSE" file accompanying this file. This file is distributed 
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
# express or implied. See the License for the specific language governing 
# permissions and limitations under the License.


########################################
# Initial Settings
########################################
SCRIPT_NAME=${0##*/} 
SCRIPT_VERSION=1.1 

instanceid=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
azone=`wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone`
region=${azone/%?/}
export AWS_DEFAULT_REGION=$region


########################################
# Constants
########################################
KILO=1024
MEGA=1048576
GIGA=1073741824


########################################
# Usage
########################################
usage() 
{ 
    echo "Usage: $SCRIPT_NAME [options] "
    echo "Options:" 
    printf "    %-28s %s\n" "-h|--help" "Displays detailed usage information."
    printf "    %-28s %s\n" "--version" "Displays the version number."
    printf "    %-28s %s\n" "--verify" "Checks configuration and prepares a remote call."
    printf "    %-28s %s\n" "--verbose" "Displays details of what the script is doing."
    printf "    %-28s %s\n" "--debug" "Displays information for debugging."
    printf "    %-28s %s\n" "--from-cron" "Use this option when calling the script from cron."
    printf "    %-28s %s\n" "--bulk-post" "Use this option if you want to send all at once."
    printf "    %-28s %s\n" "--grouping-dimension" "(Only bulk post mode) Use this option if you want to use no instance id dimension."
    printf "    %-28s %s\n" "--associate-dimension-field" "Use this option if you want to associate other field."
    printf "    %-28s %s\n" "--profile VALUE" "Use a specific profile from your credential file."
    printf "    %-28s %s\n" "--load-ave1" "Reports load average for 1 minute in counts."
    printf "    %-28s %s\n" "--load-ave5" "Reports load average for 5 minutes in counts."
    printf "    %-28s %s\n" "--load-ave15" "Reports load average for 15 minutes in counts."
    printf "    %-28s %s\n" "--interrupt" "Reports interrupt in counts."
    printf "    %-28s %s\n" "--context-switch" "Reports context switch in counts."
    printf "    %-28s %s\n" "--cpu-us" "Reports cpu utilization (user) in percentages."
    printf "    %-28s %s\n" "--cpu-sy" "Reports cpu utilization (system) in percentages."
    printf "    %-28s %s\n" "--cpu-id" "Reports cpu utilization (idle) in percentages."
    printf "    %-28s %s\n" "--cpu-wa" "Reports cpu utilization (wait) in percentages."
    printf "    %-28s %s\n" "--cpu-st" "Reports cpu utilization (steal) in percentages."
    printf "    %-28s %s\n" "--memory-units UNITS" "Specifies units in which to report memory usage. If not specified, memory is reported in megabytes. UNITS may be one of the following: bytes, kilobytes, megabytes, gigabytes."
    printf "    %-28s %s\n" "--mem-used-incl-cache-buff" "Count memory that is cached and in buffers as used."
    printf "    %-28s %s\n" "--mem-util" "Reports memory utilization in percentages."
    printf "    %-28s %s\n" "--mem-used" "Reports memory used in megabytes."
    printf "    %-28s %s\n" "--mem-avail" "Reports available memory in megabytes."
    printf "    %-28s %s\n" "--swap-util" "Reports swap utilization in percentages."
    printf "    %-28s %s\n" "--swap-used" "Reports allocated swap space in megabytes."
    printf "    %-28s %s\n" "--swap-avail" "Reports available swap space in megabytes."
    printf "    %-28s %s\n" "--disk-path PATH" "Selects the disk by the path on which to report."
    printf "    %-28s %s\n" "--disk-space-units UNITS" "Specifies units in which to report disk space usage. If not specified, disk space is reported in gigabytes. UNITS may be one of the following: bytes, kilobytes, megabytes, gigabytes."
    printf "    %-28s %s\n" "--disk-space-util" "Reports disk space utilization in percentages."
    printf "    %-28s %s\n" "--disk-space-used" "Reports allocated disk space in gigabytes."
    printf "    %-28s %s\n" "--disk-space-avail" "Reports available disk space in gigabytes."
    printf "    %-28s %s\n" "--load-items" "Reports all load average items."
    printf "    %-28s %s\n" "--cpu-items" "Reports all cpu items."
    printf "    %-28s %s\n" "--mem-items" "Reports all memory items."
    printf "    %-28s %s\n" "--swap-items" "Reports all swap items."
    printf "    %-28s %s\n" "--disk-items" "Reports all disk items."
    printf "    %-28s %s\n" "--all-items" "Reports all items."
}


########################################
# Options
########################################
SHORT_OPTS="h"
LONG_OPTS="help,version,verify,verbose,debug,from-cron,bulk-post,grouping-dimension:,associate-dimension-field:,profile:,load-ave1,load-ave5,load-ave15,interrupt,context-switch,cpu-us,cpu-sy,cpu-id,cpu-wa,cpu-st,memory-units:,mem-used-incl-cache-buff,mem-util,mem-used,mem-avail,swap-util,swap-used,swap-avail,disk-path:,disk-space-units:,disk-space-util,disk-space-used,disk-space-avail,load-items,cpu-items,mem-items,swap-items,disk-items,all-items" 

ARGS=$(getopt -s bash --options $SHORT_OPTS --longoptions $LONG_OPTS --name $SCRIPT_NAME -- "$@" ) 

VERIFY=0
VERBOSE=0
DEBUG=0
FROM_CRON=0
BULK_POST=0
GROUPING_DIMENSION=""
ASSOCIATE_DIMENSION_FIELD=""
PROFILE=""
LOAD_AVE1=0
LOAD_AVE5=0
LOAD_AVE15=0
INTERRUPT=0
CONTEXT_SWITCH=0
CPU_US=0
CPU_SY=0
CPU_ID=0
CPU_WA=0
CPU_ST=0
MEM_UNITS="megabytes"
MEM_UNIT_DIV=1
MEM_USED_INCL_CACHE_BUFF=0
MEM_UTIL=0
MEM_USED=0
MEM_AVAIL=0
SWAP_UTIL=0
SWAP_USED=0
SWAP_AVAIL=0
DISK_PATH=("")
DISK_SPACE_UNITS="gigabytes"
DISK_SPACE_UNIT_DIV=1
DISK_SPACE_UTIL=0
DISK_SPACE_USED=0
DISK_SPACE_AVAIL=0

COLLECT_LOAD=0
COLLECT_CPU=0
COLLECT_MEM=0
COLLECT_DISK=0

declare -a BULK_POST_JSON=()

eval set -- "$ARGS" 
while true; do 
    case $1 in 
        # General
        -h|--help) 
            usage 
            exit 0 
            ;; 
        --version) 
            echo "$SCRIPT_VERSION" 
            ;;
        --verify)
            VERIFY=1  
            ;; 
        --verbose)
            VERBOSE=1   
            ;;
        --debug)
            DEBUG=1
            ;;
        --from-cron)
            FROM_CRON=1
            ;;
        --bulk-post)
            BULK_POST=1
            ;;
        --grouping-dimension)
            shift
            GROUPING_DIMENSION=$1
            ;;
        --associate-dimension-field)
            shift
            ASSOCIATE_DIMENSION_FIELD=$1
            ;;
        # Profile
        --profile)
            shift
            PROFILE=$1
            ;;
        # System
        --load-ave1)
            COLLECT_LOAD=1
            LOAD_AVE1=1
            ;;
        --load-ave5)
            COLLECT_LOAD=1
            LOAD_AVE5=1
            ;;
        --load-ave15)
            COLLECT_LOAD=1
            LOAD_AVE15=1
            ;;
        --interrupt)
            COLLECT_CPU=1
            INTERRUPT=1
            ;;
        --context-switch)
            COLLECT_CPU=1
            CONTEXT_SWITCH=1
            ;;
        # Cpu
        --cpu-us)
            COLLECT_CPU=1
            CPU_US=1
            ;;
        --cpu-sy)
            COLLECT_CPU=1
            CPU_SY=1
            ;;
        --cpu-id)
            COLLECT_CPU=1
            CPU_ID=1
            ;;
        --cpu-wa)
            COLLECT_CPU=1
            CPU_WA=1
            ;;
        --cpu-st)
            COLLECT_CPU=1
            CPU_ST=1
            ;;
        # Memory
        --memory-units)
            shift
            MEM_UNITS=$1
            ;;
        --mem-used-incl-cache-buff)
            MEM_USED_INCL_CACHE_BUFF=1
            ;;
        --mem-util)
            COLLECT_MEM=1
            MEM_UTIL=1  
            ;;
        --mem-used) 
            COLLECT_MEM=1
            MEM_USED=1 
            ;;
        --mem-avail) 
            COLLECT_MEM=1
            MEM_AVAIL=1 
            ;;
        --swap-util) 
            COLLECT_MEM=1
            SWAP_UTIL=1 
            ;;
        --swap-used) 
            COLLECT_MEM=1
            SWAP_USED=1 
            ;;
        --swap-avail)
            COLLECT_MEM=1
            SWAP_AVAIL=1
            ;;
        # Disk
        --disk-path) 
            shift 
            IFS=',' read -ra DISK_PATH <<< "$1"
            ;;
        --disk-space-units)
            shift
            DISK_SPACE_UNITS=$1
            ;;
        --disk-space-util)
            COLLECT_DISK=1
            DISK_SPACE_UTIL=1
            ;;
        --disk-space-used)
            COLLECT_DISK=1
            DISK_SPACE_USED=1
            ;;
        --disk-space-avail)
            COLLECT_DISK=1
            DISK_SPACE_AVAIL=1
            ;;
        --load-items)
            LOAD_AVE1=1
            LOAD_AVE5=1
            LOAD_AVE15=1
            ;;
        --cpu-items)
            INTERRUPT=1
            CONTEXT_SWITCH=1
            CPU_US=1
            CPU_SY=1
            CPU_ID=1
            CPU_WA=1
            CPU_ST=1
            ;;
        --mem-items)
            MEM_UTIL=1
            MEM_USED=1
            MEM_AVAIL=1
            ;;
        --swap-items)
            SWAP_UTIL=1
            SWAP_USED=1
            SWAP_AVAIL=1
            ;;
        --disk-items)
            DISK_SPACE_UTIL=1
            DISK_SPACE_USED=1
            DISK_SPACE_AVAIL=1
            ;;
        --all-items)
            COLLECT_LOAD=1
            COLLECT_CPU=1
            COLLECT_MEM=1
            COLLECT_DISK=1
            LOAD_AVE1=1
            LOAD_AVE5=1
            LOAD_AVE15=1
            INTERRUPT=1
            CONTEXT_SWITCH=1
            CPU_US=1
            CPU_SY=1
            CPU_ID=1
            CPU_WA=1
            CPU_ST=1
            MEM_UTIL=1
            MEM_USED=1
            MEM_AVAIL=1
            SWAP_UTIL=1
            SWAP_USED=1
            SWAP_AVAIL=1
            DISK_SPACE_UTIL=1
            DISK_SPACE_USED=1
            DISK_SPACE_AVAIL=1
            ;;
        --) 
            shift
            break 
            ;; 
        *) 
            shift
            break 
            ;; 
    esac 
    shift 
done


########################################
# Command Output
########################################
[ $COLLECT_LOAD -eq 1 ] && loadavg_output=`/bin/cat /proc/loadavg`
[ $COLLECT_CPU -eq 1 ] && vmstat_output=`/usr/bin/vmstat -n 1 2`
[ $COLLECT_MEM -eq 1 ] && meminfo_output=`/bin/cat /proc/meminfo`
[ $COLLECT_DISK -eq 1 ] && df_output=`/bin/df -k -l -P $(echo ${DISK_PATH[*]})`

########################################
# Utility Function
########################################
function getMemInfo()
{
    echo "$meminfo_output" | grep ^$1: | sed -e 's/'$1':\s*\([0-9]*\).*$/\1/'
}

function convertToJsonRow() {
    local metric_name="$1" value="$2" unit="$3" dimensions="$4" dimensions_section=""
    IFS=',' read -ra dimensions_list <<< "$dimensions"
    for dimension in ${dimensions_list[@]}; do
        IFS='=' read -ra dimension_pair <<< "$dimension"
        tmp=$(cat <<EOJ
{
    "Name": "${dimension_pair[0]}",
    "Value": "${dimension_pair[1]}"
}
EOJ
)
        [ -n "$dimensions_section" ] && dimensions_section="$dimensions_section,"
        dimensions_section="$dimensions_section$tmp"
    done
    cat <<EOJ
{
  "MetricName": "$metric_name",
  "Dimensions": [
    $dimensions_section
  ],
  "Value": $value,
  "Unit": "$unit"
}
EOJ
}

########################################
# Units Decision
########################################
# Memory
if [ $MEM_UNITS = "bytes" ]; then
    MEM_UNITS="Bytes"
    MEM_UNIT_DIV=1
elif [ $MEM_UNITS = "kilobytes" ]; then
    MEM_UNITS="Kilobytes"
    MEM_UNIT_DIV=$KILO
elif [ $MEM_UNITS = "megabytes" ]; then
    MEM_UNITS="Megabytes"
    MEM_UNIT_DIV=$MEGA
elif [ $MEM_UNITS = "gigabytes" ]; then
    MEM_UNITS="Gigabytes"
    MEM_UNIT_DIV=$GIGA
else
    echo "Unsupported memory units '$MEM_UNITS'. Use bytes, kilobytes, megabytes, or gigabytes."
fi

# Disk
if [ $DISK_SPACE_UNITS = "bytes" ]; then
    DISK_SPACE_UNITS="Bytes"
    DISK_SPACE_UNIT_DIV=1
elif [ $DISK_SPACE_UNITS = "kilobytes" ]; then
    DISK_SPACE_UNITS="Kilobytes"
    DISK_SPACE_UNIT_DIV=$KILO
elif [ $DISK_SPACE_UNITS = "megabytes" ]; then
    DISK_SPACE_UNITS="Megabytes"
    DISK_SPACE_UNIT_DIV=$MEGA
elif [ $DISK_SPACE_UNITS = "gigabytes" ]; then
    DISK_SPACE_UNITS="Gigabytes"
    DISK_SPACE_UNIT_DIV=$GIGA
else
    echo "Unsupported disk space units '$DISK_SPACE_UNITS'. Use bytes, kilobytes, megabytes, or gigabytes."
fi

########################################
# Main
########################################

# Avoid a storm of calls at the beginning of a minute
if [ $FROM_CRON -eq 1 ]; then
    sleep $(((RANDOM%20) + 1))
fi

# CloudWatch Command Line Interface Option
DEFAULT_DIMENSIONS="InstanceId=$instanceid"
if [ -n "$ASSOCIATE_DIMENSION_FIELD" ]; then
    DEFAULT_DIMENSIONS="$DEFAULT_DIMENSIONS,$ASSOCIATE_DIMENSION_FIELD"
fi
CLOUDWATCH_OPTS="--namespace System/Detail/Linux"
if [ $BULK_POST -eq 0 ]; then
    CLOUDWATCH_OPTS="$CLOUDWATCH_OPTS --dimensions=${DEFAULT_DIMENSIONS}"
fi
if [ -n "$PROFILE" ]; then
    CLOUDWATCH_OPTS="$CLOUDWATCH_OPTS --profile $PROFILE"
fi

# Command Output
if [ $DEBUG -eq 1 ]; then
    if [ $COLLECT_LOAD -eq 1 ]; then
        echo "-----loadavg-----"
        echo "$loadavg_output"
    fi
    if [ $COLLECT_CPU -eq 1 ]; then
        echo "-----vmstat-----"
        echo "$vmstat_output"
    fi
    if [ $COLLECT_MEM -eq 1 ]; then
        echo "-----/proc/meminfo-----"
        echo "$meminfo_output"
    fi
    if [ $COLLECT_DISK -eq 1 ]; then
        echo "-----df-----"
        echo "$df_output"
    fi
fi

# Load Average
if [ $COLLECT_LOAD -eq 1 ]; then
    if [ $LOAD_AVE1 -eq 1 ]; then
        loadave1=`echo $loadavg_output | tr -s ' ' | cut -d ' ' -f 1`
        if [ $VERBOSE -eq 1 ]; then
            echo "loadave1:$loadave1"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage1Min" "$loadave1" "Count" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage1Min" "$loadave1" "Count" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "LoadAverage1Min" --value "$loadave1" --unit "Count" $CLOUDWATCH_OPTS 
            fi
        fi
    fi

    if [ $LOAD_AVE5 -eq 1 ]; then
        loadave5=`echo $loadavg_output | tr -s ' ' | cut -d ' ' -f 2`
        if [ $VERBOSE -eq 1 ]; then
            echo "loadave5:$loadave5"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage5Min" "$loadave5" "Count" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage5Min" "$loadave5" "Count" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "LoadAverage5Min" --value "$loadave5" --unit "Count" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $LOAD_AVE15 -eq 1 ]; then
        loadave15=`echo $loadavg_output | tr -s ' ' | cut -d ' ' -f 3`
        if [ $VERBOSE -eq 1 ]; then
            echo "loadave15:$loadave15"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage15Min" "$loadave15" "Count" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "LoadAverage15Min" "$loadave15" "Count" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "LoadAverage15Min" --value "$loadave15" --unit "Count" $CLOUDWATCH_OPTS
            fi
        fi
    fi
fi 

if [ $COLLECT_CPU -eq 1 ]; then
    # Context Switch
    if [ $CONTEXT_SWITCH -eq 1 ]; then
        context_switch=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 13`
        if [ $VERBOSE -eq 1 ]; then
            echo "context_switch:$context_switch"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "ContextSwitch" "$context_switch" "Count" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "ContextSwitch" "$context_switch" "Count" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "ContextSwitch" --value "$context_switch" --unit "Count" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    # Interrupt
    if [ $INTERRUPT -eq 1 ]; then
        interrupt=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 12`
        if [ $VERBOSE -eq 1 ]; then
            echo "interrupt:$interrupt"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "Interrupt" "$interrupt" "Count" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "Interrupt" "$interrupt" "Count" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "Interrupt" --value "$interrupt" --unit "Count" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    # Cpu
    if [ $CPU_US -eq 1 ]; then
        cpu_us=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 14`
        if [ $VERBOSE -eq 1 ]; then
            echo "cpu_us:$cpu_us"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "CpuUser" "$cpu_us" "Percent" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "CpuUser" "$cpu_us" "Percent" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "CpuUser" --value "$cpu_us" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $CPU_SY -eq 1 ]; then
        cpu_sy=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 15`
        if [ $VERBOSE -eq 1 ]; then
            echo "cpu_sy:$cpu_sy"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "CpuSys" "$cpu_sy" "Percent" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "CpuSys" "$cpu_sy" "Percent" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "CpuUser" --value "$cpu_sy" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $CPU_ID -eq 1 ]; then
        cpu_id=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 16`
        if [ $VERBOSE -eq 1 ]; then
            echo "cpu_id:$cpu_id"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "CpuIdle" "$cpu_id" "Percent" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "CpuIdle" "$cpu_id" "Percent" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "CpuIdle" --value "$cpu_id" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $CPU_WA -eq 1 ]; then
        cpu_wa=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 17`
        if [ $VERBOSE -eq 1 ]; then
            echo "cpu_wa:$cpu_wa"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "CpuWait" "$cpu_wa" "Percent" "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "CpuWait" "$cpu_wa" "Percent" "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "CpuWait" --value "$cpu_wa" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $CPU_ST -eq 1 ]; then
        cpu_st=`echo "$vmstat_output" | tail -1 | tr -s ' ' | cut -d ' ' -f 18`
        if [ -n "$cpu_st" ]; then
            if [ $VERBOSE -eq 1 ]; then
                echo "cpu_st:$cpu_st"
            fi
            if [ $BULK_POST -eq 1 ]; then
                BULK_POST_JSON+=("$(convertToJsonRow "CpuSteal" "$cpu_st" "Percent" "$DEFAULT_DIMENSIONS")")
                [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "CpuSteal" "$cpu_st" "Percent" "$GROUPING_DIMENSION")")
            else
                if [ $VERIFY -eq 0 ]; then
                    /usr/local/bin/aws cloudwatch put-metric-data --metric-name "CpuSteal" --value "$cpu_st" --unit "Percent" $CLOUDWATCH_OPTS
                fi
            fi
        fi
    fi
fi

# Memory
if [ $COLLECT_MEM -eq 1 ]; then
    mem_total=`getMemInfo "MemTotal"`
    mem_total=`expr $mem_total \* $KILO`
    mem_free=`getMemInfo "MemFree"`
    mem_free=`expr $mem_free \* $KILO`
    mem_cached=`getMemInfo "Cached"`
    mem_cached=`expr $mem_cached \* $KILO`
    mem_buffers=`getMemInfo "Buffers"`
    mem_buffers=`expr $mem_buffers \* $KILO`
    mem_avail=$mem_free
    if [ $MEM_USED_INCL_CACHE_BUFF -eq 1 ]; then
        mem_avail=`expr $mem_avail + $mem_cached + $mem_buffers`
    fi
    mem_used=`expr $mem_total - $mem_avail`
    swap_total=`getMemInfo "SwapTotal"`
    swap_total=`expr $swap_total \* $KILO`
    swap_free=`getMemInfo "SwapFree"`
    swap_free=`expr $swap_free \* $KILO`
    swap_avail=$swap_free
    swap_used=`expr $swap_total - $swap_free`

    if [ $DEBUG -eq 1 ]; then
        echo "MemTotal:$mem_total"
        echo "MemFree:$mem_free"
        echo "Cached:$mem_cached"
        echo "Buffers:$mem_buffers"
        echo "SwapTotal:$swap_total"
        echo "SwapFree:$swap_free"
    fi

    if [ $MEM_UTIL -eq 1 -a $mem_total -gt 0 ]; then
        mem_util=`echo "scale=2; 100 * $mem_used / $mem_total" | bc`
        if [ $VERBOSE -eq 1 ]; then
            echo "mem_util:$mem_util"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "MemoryUtilization" "$mem_util" "Percent"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "MemoryUtilization" "$mem_util" "Percent"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 -a -n "$mem_util" ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "MemoryUtilization" --value "$mem_util" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $MEM_USED -eq 1 ]; then
        mem_used=`echo "scale=2; $mem_used / $MEM_UNIT_DIV" | bc`
        if [ $VERBOSE -eq 1 ]; then
            echo "mem_used:$mem_used"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "MemoryUsed" "$mem_used" "$MEM_UNITS"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "MemoryUsed" "$mem_used" "$MEM_UNITS"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "MemoryUsed" --value "$mem_used" --unit "$MEM_UNITS" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $MEM_AVAIL -eq 1 ]; then
        mem_avail=`echo "scale=2; $mem_avail / $MEM_UNIT_DIV" | bc`
        if [ $VERBOSE -eq 1 ]; then
            echo "mem_avail:$mem_avail"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "MemoryAvailable" "$mem_avail" "$MEM_UNITS"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "MemoryAvailable" "$mem_avail" "$MEM_UNITS"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then        
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "MemoryAvailable" --value "$mem_avail" --unit "$MEM_UNITS" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $SWAP_UTIL -eq 1 -a $swap_total -gt 0 ]; then
        swap_util=`expr 100 \* $swap_used / $swap_total`
        if [ $VERBOSE -eq 1 ]; then
            echo "swap_util:$swap_util"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "SwapUtilization" "$swap_util" "Percent"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "SwapUtilization" "$swap_util" "Percent"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 -a -n "$swap_util" ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "SwapUtilization" --value "$swap_util" --unit "Percent" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $SWAP_USED -eq 1 ]; then
        swap_used=`expr $swap_used / $MEM_UNIT_DIV`
        if [ $VERBOSE -eq 1 ]; then
            echo "swap_used:$swap_used"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "SwapUsed" "$swap_used" "$MEM_UNITS"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "SwapUsed" "$swap_used" "$MEM_UNITS"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "SwapUsed" --value "$swap_used" --unit "$MEM_UNITS" $CLOUDWATCH_OPTS
            fi
        fi
    fi

    if [ $SWAP_AVAIL -eq 1 ]; then
        swap_avail=`expr $swap_avail / $MEM_UNIT_DIV`
        if [ $VERBOSE -eq 1 ]; then
            echo "swap_avail:$swap_avail"
        fi
        if [ $BULK_POST -eq 1 ]; then
            BULK_POST_JSON+=("$(convertToJsonRow "SwapAvailable" "$swap_avail" "$MEM_UNITS"  "$DEFAULT_DIMENSIONS")")
            [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "SwapAvailable" "$swap_avail" "$MEM_UNITS"  "$GROUPING_DIMENSION")")
        else
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data --metric-name "SwapAvailable" --value "$swap_avail" --unit "$MEM_UNITS" $CLOUDWATCH_OPTS
            fi
        fi
    fi
fi

# Disk
if [ $COLLECT_DISK -eq 1 ]; then
    for _DISK_PATH in ${DISK_PATH[@]}; do
        DISK_DIMENSIONS="MountPath=$_DISK_PATH"
        disk_line=`echo "$df_output" | awk -v p="$_DISK_PATH" '$6==p'`
        disk_total=`echo "$disk_line" | tr -s ' ' | cut -d ' ' -f 2`
        disk_total=`expr $disk_total \* $KILO`
        disk_used=`echo "$disk_line" | tr -s ' ' | cut -d ' ' -f 3`
        disk_used=`expr $disk_used \* $KILO`
        disk_avail=`echo "$disk_line" | tr -s ' ' | cut -d ' ' -f 4`
        disk_avail=`expr $disk_avail \* $KILO`

        CLOUDWATCH_DISK_OPTS=$(echo "$CLOUDWATCH_OPTS" | sed -e "s@$DEFAULT_DIMENSIONS@$DEFAULT_DIMENSIONS,$DISK_DIMENSIONS@g")
        DISK_DEFAULT_DIMENSIONS="$DEFAULT_DIMENSIONS,$DISK_DIMENSIONS"

        if [ $DEBUG -eq 1 ]; then
            echo "DiskMountPath:$_DISK_PATH"
            echo "DiskTotal:$disk_total"
            echo "DiskUsed:$disk_used"
            echo "DiskAvailable:$disk_avail"
        fi

        if [ $DISK_SPACE_UTIL -eq 1 -a -n "$_DISK_PATH" -a $disk_total -gt 0 ]; then
            disk_util=`echo "scale=2; 100 * $disk_used / $disk_total" | bc`
            if [ $VERBOSE -eq 1 ]; then
                echo "disk_util[$_DISK_PATH]:$disk_util"
            fi
            if [ $BULK_POST -eq 1 ]; then
                BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceUtilization" "$disk_util" "Percent"  "$DISK_DEFAULT_DIMENSIONS")")
                [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceUtilization" "$disk_util" "Percent"  "$GROUPING_DIMENSION,$DISK_DIMENSIONS")")
            else
                if [ $VERIFY -eq 0 ]; then
                    /usr/local/bin/aws cloudwatch put-metric-data --metric-name "DiskSpaceUtilization" --value "$disk_util" --unit "Percent" $CLOUDWATCH_DISK_OPTS
                fi
            fi
        fi

        if [ $DISK_SPACE_USED -eq 1 -a -n "$_DISK_PATH" ]; then
            disk_used=`echo "scale=2; $disk_used / $DISK_SPACE_UNIT_DIV" | bc`
            if [ $VERBOSE -eq 1 ]; then
                echo "disk_used[$_DISK_PATH]:$disk_used"
            fi
            if [ $BULK_POST -eq 1 ]; then
                BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceUsed" "$disk_used" "$DISK_SPACE_UNITS" "$DISK_DEFAULT_DIMENSIONS")")
                [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceUsed" "$disk_used" "$DISK_SPACE_UNITS" "$GROUPING_DIMENSION,$DISK_DIMENSIONS")")
            else
                if [ $VERIFY -eq 0 ]; then
                    /usr/local/bin/aws cloudwatch put-metric-data --metric-name "DiskSpaceUsed" --value "$disk_used" --unit "$DISK_SPACE_UNITS" $CLOUDWATCH_DISK_OPTS
                fi
            fi
        fi

        if [ $DISK_SPACE_AVAIL -eq 1 -a -n "$_DISK_PATH" ]; then
            disk_avail=`echo "scale=2; $disk_avail / $DISK_SPACE_UNIT_DIV" | bc`
            if [ $VERBOSE -eq 1 ]; then
                echo "disk_avail[$_DISK_PATH]:$disk_avail"
            fi
            if [ $BULK_POST -eq 1 ]; then
                BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceAvailable" "$disk_avail" "$DISK_SPACE_UNITS" "$DISK_DEFAULT_DIMENSIONS")")
                [ -n "$GROUPING_DIMENSION" ] && BULK_POST_JSON+=("$(convertToJsonRow "DiskSpaceAvailable" "$disk_avail" "$DISK_SPACE_UNITS" "$GROUPING_DIMENSION,$DISK_DIMENSIONS")")
            else
                if [ $VERIFY -eq 0 ]; then
                    /usr/local/bin/aws cloudwatch put-metric-data --metric-name "DiskSpaceAvailable" --value "$disk_avail" --unit "$DISK_SPACE_UNITS" $CLOUDWATCH_DISK_OPTS
                fi
            fi
        fi
    done
fi

BULK_POST_COUNT=${#BULK_POST_JSON[@]}
if [ $BULK_POST -eq 1 -a $BULK_POST_COUNT -gt 0 ]; then
    JSON=""
    for ((i=0; i < $BULK_POST_COUNT; i++)); do
        [ -n "$JSON" ] && JSON="$JSON,"
        JSON="$JSON${BULK_POST_JSON[$i]}"
        if [ $(expr \( $i + 1 \) % 20) -eq 0 ]; then
            if [ $VERIFY -eq 0 ]; then
                /usr/local/bin/aws cloudwatch put-metric-data $CLOUDWATCH_OPTS --metric-data file://<(echo -e "[$JSON]")
            fi
            [ $DEBUG -eq 1 ] && echo "[$JSON]" | jq .
            JSON=""
        fi
    done
    if [ $VERIFY -eq 0 ]; then
        [ -n "$JSON" ] && /usr/local/bin/aws cloudwatch put-metric-data $CLOUDWATCH_OPTS --metric-data file://<(echo -e "[$JSON]")
    fi
    [ $DEBUG -eq 1 ] && echo "[$JSON]" | jq .
fi