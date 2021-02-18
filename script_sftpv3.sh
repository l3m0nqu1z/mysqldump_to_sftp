#!/bin/bash
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#задаем домашнюю папку пользгвателя, узнать ее можно подключившись к хостингу по ssh и набрав команду pwd
HOME=/home/sanglyb
#задаем имя бэкапу
FILE=site_ru_$(date +"%Y-%m-%d_%H:%M").tgz
#старый бэкап, который будет удален с сервера. Подразумевается, что ротация - 30 дневная, значит и 
#старый бэкап будет в имени иметь дату меньше на 30 дней от сегодняшней
OLDFILE=site_ru_$(date -d 'now -30 days' +"%Y-%m-%d")*
# $HOME/web - папка с файлами сайта, если у вас будет отличаться - измените ее
tar czf $HOME/tmp/files.tgz $HOME/web
# подключение к mysql - тут не забудьте ввести ваш хост, пользователя и пароль, а так же измените название базы данных
mysqldump -h 127.0.0.1 -u sanglyb_sanglyb -p passw0rd sanglyb_test > $HOME/tmp/mysql.sql
tar czf $HOME/backup/$FILE $HOME/tmp/*
cd $HOME/backup
rm -rf $HOME/tmp/*
#параметры подключения к ftp серверу
HOST='mytechnote.ru'
USER='test@mytechnote.ru'
PASSWD='passw0rd'
#для подключения используется пассивный режим, если вам нужен активный - здесь и ниже при подключении к ftp уберите ключ -p
ftp -np $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
binary
cd backup_test
put $FILE
quit
END_SCRIPT
#получаем количество файлов в папке на ftp сервере
CONTENT="$(ftp -inp $HOST <<HERE
user $USER $PASSWD
cd backup_test
ls
bye
HERE
)"
NUMBER=`echo "$CONTENT" | egrep -v "user|ls|^d|bye" | wc -l`
NUMBER=$((NUMBER-1))
#если файлов больше 30ти, удалим старый файл
if [ $NUMBER -gt 30 ]
then
ftp -np $HOST <<END_SCRIPT1
quote USER $USER
quote PASS $PASSWD
binary
prompt
cd backup_test
mdelete $OLDFILE
quit
END_SCRIPT1
fi
#удаляем локальную копию бэкапа
rm -rf $HOME/backup/$FILE
exit 0