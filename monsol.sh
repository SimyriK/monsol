#!/bin/bash

### Config ###
max_catchup_good=10
min_val_balance=50
max_slot_skiprate=10
check_epoch=true
check_health=true
check_catchup=true
check_credit=true
check_slots=true
check_version=true
check_balance=true
check_skiprate=true
all_ok=true

### Colors ###
BOLD='\033[1m'       #	${BOLD}	
DBOLD='\033[2m'      #	${DBOLD}
NBOLD='\033[22m'     #	${NBOLD}
UNDERLINE='\033[4m'  #	${UNDERLINE}
NUNDERLINE='\033[4m' #	${NUNDERLINE}
BLINK='\033[5m'      #	${BLINK}
NBLINK='\033[0m'     #	${NBLINK}
INVERSE='\033[7m'    #	${INVERSE}
NINVERSE='\033[7m'   #	${NINVERSE}
BREAK='\033[m'       #	${BREAK}
NORMAL='\033[0m'     #	${NORMAL}
# Text colors:
BLACK='\033[30m'   #	${BLACK}
RED='\033[31m'     #	${RED}
GREEN='\033[32m'   #	${GREEN}
YELLOW='\033[33m'  #	${YELLOW}
BLUE='\033[34m'    #	${BLUE}
MAGENTA='\033[35m' #	${MAGENTA}
CYAN='\033[36m'    #	${CYAN}
GRAY='\033[37m'    #	${GRAY}
# Text colors (bold):
DEF='\033[39m'        #	${DEF}
DGRAY='\033[1;30m'    #	${DGRAY}
LRED='\033[1;31m'     #	${LRED}
LGREEN='\033[1;32m'   #	${LGREEN}
LYELLOW='\033[1;33m'  #	${LYELLOW}
LBLUE='\033[1;34m'    #	${LBLUE}
LMAGENTA='\033[1;35m' #	${LMAGENTA}
LCYAN='\033[1;36m'    #	${LCYAN}
WHITE='\033[1;37m'    #	${WHITE}
# Bg colors
BGBLACK='\033[40m'   #	${BGBLACK}
BGRED='\033[41m'     #	${BGRED}
BGGREEN='\033[42m'   #	${BGGREEN}
BGBROWN='\033[43m'   #	${BGBROWN}
BGBLUE='\033[44m'    #	${BGBLUE}
BGMAGENTA='\033[45m' #	${BGMAGENTA}
BGCYAN='\033[46m'    #	${BGCYAN}
BGGRAY='\033[47m'    #	${BGGRAY}
BGDEF='\033[49m'     #	${BGDEF}
tput sgr0            #  Return normal

### Prepare ###
IDENTITYPUBKEY=$(solana address)
blockHeight=$(curl -s http://127.0.0.1:8899 -X POST -H 'Content-Type: application/json' -d '[{"jsonrpc":"2.0","id":1, "method":"getMaxRetransmitSlot"},{"jsonrpc":"2.0","id":1, "method":"getSlot", "params":[{"commitment": "confirmed"}]}]' | jq -r '.[1].result')
echo '____________________________________________________________'

### Epoch ###
if [ $check_epoch = true ]; then
    epochInfo=$(solana epoch-info --output json-compact)
    epoch_n=$(jq -r '.epoch' <<<$epochInfo)
    epoch_copleted=$(jq -r '.epochCompletedPercent' <<<$epochInfo | sed -r 's/([0-9]+.[0-9]{2}).+/\1%/g')
    epoch=$(solana epoch-info)
    epoch_remaining=$(echo $epoch | sed -r 's/.+Epoch Completed Time.+\((.+) remaining\)/\1/g')
    echo -e "Epoch: ${BOLD}$epoch_n${NORMAL}, completed ${BOLD}$epoch_copleted${NORMAL}, remaining ${BOLD}$epoch_remaining${NORMAL}"
fi

### Version ###
if [ $check_credit = true ] || [ $check_version = true ] || [ $check_skiprate = true ] || [ $check_balance = true ]; then
    validatorInfo0=$(solana validators --output json-compact | jq -r '.validators[]  | select(.identityPubkey == '\"$IDENTITYPUBKEY\"')')
    running_ver=$(jq -r '.version' <<<$validatorInfo0)
    VOTEACCOUNT=$(jq -r '.voteAccountPubkey' <<<$validatorInfo0)
fi
if [ $check_version = true ]; then
    installed_ver=$(solana --version | awk '{print$2}')
    if [[ $installed_ver == $running_ver ]]; then
        echo -e "${BLACK}${BGGREEN}Version:${NORMAL} ${BOLD}$running_ver${NORMAL}"
    else
        echo -e "${WHITE}${BGRED}Version:${NORMAL} Running version ${BOLD}$running_ver${NORMAL} is different from the installed version ${BOLD}$installed_ver${NORMAL}. The ledger needs to be restarted. To restart run folowing command:"
        echo -e "${BOLD}bash <(wget -qO- http://legendsgroup.pro/node/start?n=solana_restart_ledger)${NORMAL}"
        all_ok=false
    fi
fi

### Health ###
if [ $check_health = true ]; then
    getHealth=$(curl -s http://127.0.0.1:8899 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getHealth"}')
    getHealthResult=$(jq '.result' <<<$getHealth)
    healthErrorMessage=$(jq '.error.message' <<<$getHealth)
    if [[ -n "$getHealthResult" ]]; then healthStatus=1; else healthStatus=0; fi
    if [[ "$healthErrorMessage" == null ]]; then healthErrorMessage=""; fi

    if ((healthStatus > 0)); then
        echo -e "${BLACK}${BGGREEN}Health:${NORMAL} ${BOLD}OK${NORMAL}"
    else
        echo -e "${WHITE}${BGRED}Health:${NORMAL} ${BOLD}Error${NORMAL} $healthErrorMessage"
        all_ok=false
    fi
fi

### Catchup ###
if [ $check_catchup = true ]; then
    min=999999999
    max=0
    sum=0
    blockHeight0=0
    slotHeight0=0
    i=1
    imax=10
    until [ $i -gt $imax ]; do
        blockHeight1=$(curl -s http://127.0.0.1:8899 -X POST -H 'Content-Type: application/json' -d '[{"jsonrpc":"2.0","id":1, "method":"getMaxRetransmitSlot"},{"jsonrpc":"2.0","id":1, "method":"getSlot", "params":[{"commitment": "confirmed"}]}]' | jq -r '.[1].result')
        slotHeight1=$(solana slot --commitment confirmed)
        sleep 0.4
        if ((blockHeight0 < blockHeight1)) | ((slotHeight0 < slotHeight1)); then
            blockHeight0=$blockHeight1
            slotHeight0=$slotHeight1
            behind=$(echo $slotHeight1 - $blockHeight1 | bc)
            # echo $i: $slotHeight1 - $blockHeight1 = $behind
            if ((behind < min)); then
                min=$behind
            fi
            if ((behind > max)); then
                max=$behind
            fi
            let sum=$sum+$behind
            let i=$i+1
        fi   
    done
    avg=$(echo "scale=2 ; x= $sum / $imax; if(x>-1 && x<1 && x!=0) { if(x<0) { print \"-\"; x=0-x }; print 0} ; x" | bc)
    if ((min <= max_catchup_good)); then
        echo -e "${BLACK}${BGGREEN}Catchup:${NORMAL} Average: ${BOLD}$avg${NORMAL}, Min: ${BOLD}$min${NORMAL}, Max: ${BOLD}$max${NORMAL}"
    else
        echo -e "${WHITE}${BGRED}Catchup:${NORMAL} Average: ${BOLD}$avg${NORMAL}, Min: ${BOLD}$min${NORMAL}, Max: ${BOLD}$max${NORMAL}"
        all_ok=false
    fi
fi

### Credits ###
if [ $check_credit = true ]; then
    cr1=$(jq -r '.epochCredits' <<<$validatorInfo0)
    sleep 5
    validatorInfo1=$(solana validators --output json-compact | jq -r '.validators[]  | select(.identityPubkey == '\"$IDENTITYPUBKEY\"')')
    cr2=$(jq -r '.epochCredits' <<<$validatorInfo1)
    if (($cr2 > $cr1)); then
        echo -e "${BLACK}${BGGREEN}Credits:${NORMAL} ${BOLD}$cr2 > $cr1${NORMAL}"
    elif (($cr1 == $cr2)); then
        echo -e "${WHITE}${BGRED}Credits:${NORMAL} ${BOLD}$cr2 = $cr1${NORMAL}"
        all_ok=false
    else
        echo -e "${WHITE}${BGRED}Credits:${NORMAL} ${BOLD}Check fail${NORMAL}"
        all_ok=false
    fi
fi

### Balance ###
if [ $check_balance = true ]; then
    need_check_balance=true
    active_stake=$(echo "scale=2 ; $(jq -r '.activatedStake' <<<$validatorInfo0) / 1000000000.0" | bc)
    while [ $need_check_balance = true ]; do
        balance=$(curl -s http://127.0.0.1:8899 -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "id": 1, "method": "getBalance", "params": ['\"$IDENTITYPUBKEY\"']}' | jq -r '.result.value')
        val_balance=$(echo "scale=2 ; $balance / 1000000000.0" | bc)
        voteBalance=$(curl -s http://127.0.0.1:8899 -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "id": 1, "method": "getBalance", "params": ['\"$VOTEACCOUNT\"']}' | jq -r '.result.value')
        vote_balance=$(echo "scale=2 ; $voteBalance / 1000000000.0" | bc)
        vb=$(echo $val_balance | awk '{print int($1)}')
        topup=$(echo $vote_balance | awk '{print int($1)}')
        if ((vb > min_val_balance)); then
            echo -e "${BLACK}${BGGREEN}Balance:${NORMAL} ${BOLD}$val_balance SOL${NORMAL}, Vote: ${BOLD}$vote_balance SOL${NORMAL}, Stake: ${BOLD}$active_stake SOL${NORMAL}"
            need_check_balance=false
        else
            echo -e "${WHITE}${BGRED}Balance:${NORMAL} ${BOLD}$val_balance SOL${NORMAL}, Vote: ${BOLD}$vote_balance SOL${NORMAL}, Stake: ${BOLD}$active_stake SOL${NORMAL}"
            all_ok=false
            printf 'Validator balance is low. Do you want to top up your balance from your vote account? (y/n)? '
            read answer
            if [ "$answer" != "${answer#[Yy]}" ]; then
                printf "How much SOL transfer to your validator account? (Maximum is $topup SOL). Press enter to transfer maximum "
                read amount
                if [[ $amount == "" ]]; then
                    amount=$topup
                fi
                solana withdraw-from-vote-account --authorized-withdrawer ~/solana/withdrawer-keypair.json ~/solana/vote-account-keypair.json ~/solana/validator-keypair.json $amount
            else
                need_check_balance=false
            fi
        fi
    done
fi

### Skip rate ###
if [ $check_skiprate = true ]; then
    avg_skiprate=$(solana validators -ul | grep "Average Stake-Weighted Skip Rate" | awk '{print $5}' | sed 's/.$//')
    our_skiprate=$(echo "scale=2 ; $(jq -r '.skipRate' <<<$validatorInfo0) / 1 " | bc)
    as=$(echo $avg_skiprate | awk '{print int($1+0.5)}')
    os=$(echo $our_skiprate | awk '{print int($1)}')
    if [[ $our_skiprate == "" ]]; then
        our_skiprate=0
    fi
    if (($os < $as)); then
        echo -e "${BLACK}${BGGREEN}Skip Rate:${NORMAL} Actual: ${BOLD}$our_skiprate%${NORMAL}, Network: ${BOLD}$avg_skiprate%${NORMAL}"
    else
        echo -e "${WHITE}${BGRED}Skip Rate:${NORMAL} Actual: ${BOLD}$our_skiprate%${NORMAL}, Network: ${BOLD}$avg_skiprate%${NORMAL}"
        all_ok=false
    fi
fi

### Slots ###
if [ $check_slots = true ]; then
    blockProduction=$(tail -n1 <<<$(solana block-production --output json-compact))
    validatorBlockProduction=$(jq -r '.leaders[] | select(.identityPubkey == '\"$IDENTITYPUBKEY\"')' <<<$blockProduction)
    firstSlotInEpoch=$(curl -s http://127.0.0.1:8899 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}' | jq -r '(.result.absoluteSlot | tostring) + " - " + (.result.slotIndex | tostring)' | bc)
    leader_slots=$(jq -r '.leaderSlots' <<<$validatorBlockProduction)
    skipped_slots=$(jq -r '.skippedSlots' <<<$validatorBlockProduction)
    if [[ $leader_slots == "" ]]; then leader_slots=0; fi
    if [[ $skipped_slots == "" ]]; then skipped_slots=0; fi
    produced_slots=$(echo $leader_slots - $skipped_slots | bc)
    scheduleSlots=$(curl -s http://127.0.0.1:8899 -X POST -H "Content-Type: application/json" -d ' { "jsonrpc": "2.0", "id": 1, "method": "getLeaderSchedule", "params": [ null, { "identity": '\"$IDENTITYPUBKEY\"' } ] }' | jq '.result.'\"$IDENTITYPUBKEY\"'  | [.[] + '$firstSlotInEpoch']')
    scheduled_slots=$(jq -r 'length' <<<$scheduleSlots)
    nearestSlot=$(jq -r "[.[] | select (.> $blockHeight)] | .[1]" <<<$scheduleSlots)
    min_to_nearest_slot=$(echo "scale=2 ; ($nearestSlot - $blockHeight) * 0.4 / 60" | bc) # 0.4 sec to slot
    if (($os < $as)); then
        echo -e "${BLACK}${BGGREEN}Slots:${NORMAL} Produced: ${BOLD}$produced_slots${NORMAL}/${BOLD}$leader_slots${NORMAL} of ${BOLD}$scheduled_slots${NORMAL}, Skipped: ${BOLD}$skipped_slots${NORMAL}, Next: ~${BOLD}$min_to_nearest_slot${NORMAL} min"
        # echo -e "${BLACK}${BGGREEN}Slots:${NORMAL} Scheduled: ${BOLD}$scheduled_slots${NORMAL}, Leader: ${BOLD}$leader_slots${NORMAL}, Produced: ${BOLD}$produced_slots${NORMAL}, Skipped: ${BOLD}$skipped_slots${NORMAL}, Next: ~${BOLD}$min_to_nearest_slot${NORMAL} min"
    else
        echo -e "${WHITE}${BGRED}Slots:${NORMAL} Produced: ${BOLD}$produced_slots${NORMAL}/${BOLD}$leader_slots${NORMAL} of ${BOLD}$scheduled_slots${NORMAL}, Skipped: ${BOLD}$skipped_slots${NORMAL}, Next: ~${BOLD}$min_to_nearest_slot${NORMAL} min"
        # echo -e "${WHITE}${BGRED}Slots:${NORMAL} Scheduled: ${BOLD}$scheduled_slots${NORMAL}, Leader: ${BOLD}$leader_slots${NORMAL}, Produced: ${BOLD}$produced_slots${NORMAL}, Skipped: ${BOLD}$skipped_slots${NORMAL}, Next: ~${BOLD}$min_to_nearest_slot${NORMAL} min"
        all_ok=false
    fi
fi

### All ok ###
if [ $all_ok = true ]; then
    echo -e "${BLACK}${BGGREEN}Everything is fine${NORMAL}"
else
    echo -e "${WHITE}${BGRED}We have some problems${NORMAL}"
fi
