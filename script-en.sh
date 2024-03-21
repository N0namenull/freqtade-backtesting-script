#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo." 
    echo "Re-running the script using sudo..."
    sudo "$0" "$@"
    exit $?
fi

echo "
'##::: ##:::'#####:::'##::: ##::::'###::::'##::::'##:'########:'##::: ##:'##::::'##:'##:::::::'##:::::::
 ###:: ##::'##.. ##:: ###:: ##:::'## ##::: ###::'###: ##.....:: ###:: ##: ##:::: ##: ##::::::: ##:::::::
 ####: ##:'##:::: ##: ####: ##::'##:. ##:: ####'####: ##::::::: ####: ##: ##:::: ##: ##::::::: ##:::::::
 ## ## ##: ##:::: ##: ## ## ##:'##:::. ##: ## ### ##: ######::: ## ## ##: ##:::: ##: ##::::::: ##:::::::
 ##. ####: ##:::: ##: ##. ####: #########: ##. #: ##: ##...:::: ##. ####: ##:::: ##: ##::::::: ##:::::::
 ##:. ###:. ##:: ##:: ##:. ###: ##.... ##: ##:.:: ##: ##::::::: ##:. ###: ##:::: ##: ##::::::: ##:::::::
 ##::. ##::. #####::: ##::. ##: ##:::: ##: ##:::: ##: ########: ##::. ##:. #######:: ########: ########:
..::::..::::.....::::..::::..::..:::::..::..:::::..::........::..::::..:::.......:::........::........::

"

echo "List of running Docker containers:"
docker ps --format "table {{.Names}}\t{{.Image}}"

read -p "Enter the name of the Docker container or just press Enter if the name is freqtrade: " container_name

default_container_name="freqtrade"

if [ -z "$container_name" ]; then
    container_name=$default_container_name
fi

if docker ps -a --format "{{.Names}}" | grep -q $container_name; then
    echo "Container with name '$container_name' found. Running 'docker exec' command to enter the container..."

    read -p "Enter the strategy name or multiple separated by space: " strategy_input

    num_strategies=$(echo $strategy_input | wc -w)

    strategies=""

    if [ "$num_strategies" -eq 1 ]; then
        strategies="-s $strategy_input"
    elif [ "$num_strategies" -gt 1 ]; then
        strategies="--strategy-list $strategy_input"
    fi

    read -p "Enter test timerange in YYYYMMDD-YYYYMMDD format: " timerange
    read -p "Specify timeframe (requered for multiple strategies): " timeframe
    read -p "Maximum number of open trades: " max_open_trades
    read -p "Amount per stake: " stake_amount
    read -p "List of pairs in format XYZ/ABC for spot and XYZ/ABC:HJK for futures: " p
    read -p "Absolute path to config file or filename: " config

    command="freqtrade backtesting $strategies"
    [[ -n $timerange ]] && command="$command --timerange $timerange"
    [[ -n $timeframe ]] && command="$command --timeframe $timeframe"
    [[ -n $max_open_trades ]] && command="$command --max-open-trades $max_open_trades"
    [[ -n $stake_amount ]] && command="$command --stake-amount $stake_amount"
    [[ -n $p ]] && command="$command -p $p"
    [[ -n $config ]] && command="$command --config $config"

    if docker exec -it $container_name bash -c "$command"; then
        echo "The command completed successfully."
    else
        echo "An error occurred while executing a command in the container."
    fi
    echo "$command"
else
    echo "Container with name '$container_name' not found."
fi
