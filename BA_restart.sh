#!/bin/bash

# Функция для обработки сигналов
cleanup() {
    echo "Получен сигнал завершения, останавливаем..."
    pkill -f "python run.py"
    exit 0
}

# Функция для получения токена HuggingFace
get_hf_token() {
    local token_file="hf.txt"
    
    # Проверяем существует ли файл с токеном
    if [ -f "$token_file" ]; then
        # Читаем токен из файла
        HF_TOKEN=$(cat "$token_file" | tr -d '\n\r')
        
        # Проверяем что токен не пустой
        if [ -n "$HF_TOKEN" ] && [ "$HF_TOKEN" != "" ]; then
            echo "Токен HuggingFace загружен из файла hf.txt"
            return 0
        fi
    fi
    
    # Если файла нет или токен пустой, запрашиваем у пользователя
    echo "Файл hf.txt не найден или не содержит токен."
    echo "Пожалуйста, введите ваш токен HuggingFace:"
    read -r HF_TOKEN
    
    # Проверяем что пользователь ввел токен
    if [ -z "$HF_TOKEN" ]; then
        echo "Ошибка: токен не может быть пустым!"
        exit 1
    fi
    
    # Сохраняем токен в файл
    echo "$HF_TOKEN" > "$token_file"
    echo "Токен сохранен в файл hf.txt"
}

# Перехват сигналов
trap cleanup SIGINT SIGTERM

# Переход в директорию blockassist
cd ~/blockassist

# Активация виртуального окружения
source blockassist-venv/bin/activate

# Получаем токен HuggingFace
get_hf_token

# Основной цикл
while true; do
    echo "========================================="
    echo "Запуск BlockAssist..."
    echo "========================================="
    
    # Создаем expect скрипт для интерактивного ввода
    cat > /tmp/blockassist_expect.sh << 'EOF'
#!/usr/bin/expect -f
set timeout -1
set token [lindex $argv 0]

spawn python run.py

# Ждем запроса токена
expect "Hugging Face token:"
send "$token\r"

# Ждем сообщения о Minecraft
expect "Please press ENTER when two Minecraft windows have opened"

# Ждем 30-60 секунд для загрузки окон
set wait_time [expr {30 + int(rand()*31)}]
puts "\nЖдем загрузку Minecraft окон ($wait_time секунд)..."
sleep $wait_time

# Нажимаем Enter и проверяем появление INSTRUCTIONS
set instructions_found 0
for {set i 0} {$i < 5} {incr i} {
    send "\r"
    expect {
        -timeout 3 "INSTRUCTIONS" {
            puts "INSTRUCTIONS найдено!"
            set instructions_found 1
            break
        }
        timeout {
            puts "Попытка [expr $i + 1]/5..."
        }
    }
}

# Ждем начала эпизода
expect "Please wait for the mission to load up on your Minecraft window"

# Даем время на загрузку миссии в игре (20-30 секунд)
set load_time [expr {20 + int(rand()*11)}]
puts "\nЖдем загрузку миссии: $load_time секунд..."
sleep $load_time

# Нажимаем Enter чтобы начать запись
puts "Запускаем запись..."
send "\r"

# Ждем немного чтобы таймер обновился
sleep 3

# Проверяем что запись началась
puts "Проверяем начало записи..."

# Генерируем случайное время записи (1-4 минуты)
set record_time [expr {60 + int(rand()*181)}]
puts "Записываем геймплей: $record_time секунд..."

# Записываем геймплей
sleep $record_time

# Останавливаем запись с проверкой
puts "\nОстанавливаем запись..."
set stopped 0
for {set i 0} {$i < 5} {incr i} {
    send "\r"
    expect {
        -timeout 3 "Enter received" {
            puts "Запись остановлена!"
            set stopped 1
            break
        }
        timeout {
            puts "Попытка остановки [expr $i + 1]/5..."
        }
    }
}

# Ждем завершения тренировки
expect "SHUTTING DOWN"
puts "Тренировка завершена!"

# Ждем полного завершения
expect "Thank you for contributing to BlockAssist!"
puts "Сессия завершена успешно!"

# Ждем завершения всех процессов
expect eof
EOF

    # Проверяем наличие expect
    if ! command -v expect &> /dev/null; then
        echo "Установка expect..."
        sudo apt-get update && sudo apt-get install -y expect
    fi
    
    # Запускаем через expect
    chmod +x /tmp/blockassist_expect.sh
    /tmp/blockassist_expect.sh "$HF_TOKEN"
    
    # Ждем 5 секунд перед новым запуском
    echo "Пауза 5 секунд перед новым циклом..."
    sleep 5
done
