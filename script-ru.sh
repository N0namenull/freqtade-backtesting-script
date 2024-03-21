#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен с sudo." 
    echo "Повторный запуск скрипта с использованием sudo..."
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

echo "Список запущенных контейнеров Docker:"
docker ps --format "table {{.Names}}\t{{.Image}}"

read -p "Введите имя контейнера Docker или нажмите Enter если название freqtrade: " container_name

default_container_name="freqtrade"

if [ -z "$container_name" ]; then
    container_name=$default_container_name
fi

if docker ps -a --format "{{.Names}}" | grep -q $container_name; then
    echo "Контейнер с именем '$container_name' найден. Запускаем команду 'docker exec' для входа в контейнер..."

    read -p "Введите имя стратегии или несколько через пробел: " strategy_input

    num_strategies=$(echo $strategy_input | wc -w)

    strategies=""

    if [ "$num_strategies" -eq 1 ]; then
        strategies="-s $strategy_input"
    elif [ "$num_strategies" -gt 1 ]; then
        strategies="--strategy-list $strategy_input"
    fi

    read -p "Временной диапазон теста в формате ГГГГММДД-ГГГГММДД: " timerange
    read -p "Укажите таймфрейм (обязательно при указании нескольких стратегий): " timeframe
    read -p "Максимальное количество открытых позиций: " max_open_trades
    read -p "Объем одной позиции: " stake_amount
    read -p "Список пар в формате XYZ/ABC для спота и XYZ/ABC:HJK для фьючерсов: " p
    read -p "Абсолютный путь к конфигу или название файла: " config

    command="freqtrade backtesting $strategies"
    [[ -n $timerange ]] && command="$command --timerange $timerange"
    [[ -n $timeframe ]] && command="$command --timeframe $timeframe"
    [[ -n $max_open_trades ]] && command="$command --max-open-trades $max_open_trades"
    [[ -n $stake_amount ]] && command="$command --stake-amount $stake_amount"
    [[ -n $p ]] && command="$command -p $p"
    [[ -n $config ]] && command="$command --config $config"

    if docker exec -it $container_name bash -c "$command"; then
        echo "Команда выполнена успешно."
    else
        echo "Произошла ошибка при выполнении команды в контейнере."
    fi
    echo "$command"
else
    echo "Контейнер с именем '$container_name' не найден."
fi
