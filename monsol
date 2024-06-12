#!/bin/bash

### Config ###
max_catchup_good=10
min_val_balance=50

### Colors ###
# Дополнительные свойства для текта:
BOLD='\033[1m'       #	${BOLD}			# жирный шрифт (интенсивный цвет)
DBOLD='\033[2m'      #	${DBOLD}		# полу яркий цвет (тёмно-серый, независимо от цвета)
NBOLD='\033[22m'     #	${NBOLD}		# установить нормальную интенсивность
UNDERLINE='\033[4m'  #	${UNDERLINE}	# подчеркивание
NUNDERLINE='\033[4m' #	${NUNDERLINE}	# отменить подчеркивание
BLINK='\033[5m'      #	${BLINK}		# мигающий
NBLINK='\033[0m'     #	${NBLINK}		# отменить мигание
INVERSE='\033[7m'    #	${INVERSE}		# реверсия (знаки приобретают цвет фона, а фон -- цвет знаков)
NINVERSE='\033[7m'   #	${NINVERSE}		# отменить реверсию
BREAK='\033[m'       #	${BREAK}		# все атрибуты по умолчанию
NORMAL='\033[0m'     #	${NORMAL}		# все атрибуты по умолчанию
# Цвет текста:
BLACK='\033[30m'   #	${BLACK}		# чёрный цвет знаков
RED='\033[31m'     #	${RED}			# красный цвет знаков
GREEN='\033[32m'   #	${GREEN}		# зелёный цвет знаков
YELLOW='\033[33m'  #	${YELLOW}		# желтый цвет знаков
BLUE='\033[34m'    #	${BLUE}			# синий цвет знаков
MAGENTA='\033[35m' #	${MAGENTA}		# фиолетовый цвет знаков
CYAN='\033[36m'    #	${CYAN}			# цвет морской волны знаков
GRAY='\033[37m'    #	${GRAY}			# серый цвет знаков
# Цветом текста (жирным) (bold) :
DEF='\033[39m'        #	${DEF}
DGRAY='\033[1;30m'    #	${DGRAY}
LRED='\033[1;31m'     #	${LRED}
LGREEN='\033[1;32m'   #	${LGREEN}
LYELLOW='\033[1;33m'  #	${LYELLOW}
LBLUE='\033[1;34m'    #	${LBLUE}
LMAGENTA='\033[1;35m' #	${LMAGENTA}
LCYAN='\033[1;36m'    #	${LCYAN}
WHITE='\033[1;37m'    #	${WHITE}
# Цвет фона
BGBLACK='\033[40m'   #	${BGBLACK}
BGRED='\033[41m'     #	${BGRED}
BGGREEN='\033[42m'   #	${BGGREEN}
BGBROWN='\033[43m'   #	${BGBROWN}
BGBLUE='\033[44m'    #	${BGBLUE}
BGMAGENTA='\033[45m' #	${BGMAGENTA}
BGCYAN='\033[46m'    #	${BGCYAN}
BGGRAY='\033[47m'    #	${BGGRAY}
BGDEF='\033[49m'     #	${BGDEF}
tput sgr0 # Возврат цвета в "нормальное" состояние

### Catchup ###
touch catchup.log
script -a catchup.log -c "timeout 30 solana catchup --our-localhost --follow --log"
catchap=$(cat catchup.log | grep slot | awk '{print$2}' | grep -Eo '[0-9]+')
rm catchup.log
catchaps=($(echo $catchap | tr ";" "\n"))
min=999999999
sum=0
for i in "${catchaps[@]}"; do
    if ((i < min)); then
        min=$i
    fi
    let sum=$sum+$i
done
let average=$sum/${#catchaps[*]}
if ((min <= max_catchup_good)); then
    echo -e "Catchup ${BLACK}${BGGREEN}GOOD${NORMAL}. Average:" $average 'Min:' $min
else
    echo -e "Catchup ${WHITE}${BGRED}NOT GOOD${NORMAL}. Average:" $average 'Min:' $min
fi

### Credits ###
cr1=$(solana validators | grep $(solana address) | awk '{print$12}')
sleep 5
cr2=$(solana validators | grep $(solana address) | awk '{print$12}')
if [[ $cr2 > $cr1 ]]; then
    echo -e "Credits: ${BLACK}${BGGREEN}GOOD${NORMAL}" $cr2 ">" $cr1
elif [[ $cr1 == $cr2 ]]; then
    echo -e "Credits: ${WHITE}${BGRED}NOT GOOD${NORMAL}" $cr2 "=" $cr1
else
    echo -e "Credits: ${WHITE}${BGRED}FAIL${NORMAL}"
fi

### Balance ###
val_balance=$(solana balance ~/solana/validator-keypair.json)
vote_balance=$(solana balance ~/solana/vote-account-keypair.json)
topup=$(echo $vote_balance | awk '{print$1}' | awk '{print int($1)}')
if [[ $val_balance > $min_val_balance ]]; then
    echo -e "Validator balance: ${BLACK}${BGGREEN}$val_balance${NORMAL}"
    echo -e "Vote balance: $vote_balance"
else
    echo -e "vote account balance: ${WHITE}${BGRED}$val_balance${NORMAL}"
    echo -e "Vote balance: $vote_balance"
    printf 'Validator balance is low. Do you want to top up your balance from your vote account? (y/n)? '
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        printf "How much SOL transfer to your validator account? (Maximum is $topup). Press enter to transfer maximum"
        read amount
        if [[ $amount == "" ]]; then
            amount=$topup
        fi
        solana withdraw-from-vote-account --authorized-withdrawer ~/solana/withdrawer-keypair.json ~/solana/vote-account-keypair.json ~/solana/validator-keypair.json $amount
    fi
fi
