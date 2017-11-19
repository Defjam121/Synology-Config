#!/bin/sh
LOCATION='MEINE_STADT'
LOGFILE=/var/log/shutdown.log
echo 6 > /dev/ttyS1
echo 7 > /dev/ttyS1
model=`dmesg | grep -m 1 Model | awk '{print $4}'`
netstat=`netstat -tu`
eth0_rx=`ifconfig eth0 | grep "bytes" | awk '{print $1 " " $2 " " $3 " " $4}'`
eth0_tx=`ifconfig eth0 | grep "bytes" | awk '{print $5 " " $6 " " $7 " " $8}'`
hostname=`hostname -s`
hours1=`/usr/syno/bin/smartctl -A /dev/hda | /bin/grep Power_On_Hours | /usr/bin/awk '{print $10}'`
hours2=`/usr/syno/bin/smartctl -A /dev/hdb | /bin/grep Power_On_Hours | /usr/bin/awk '{print $10}'`
hours3=`/usr/syno/bin/smartctl -A /dev/hdc | /bin/grep Power_On_Hours | /usr/bin/awk '{print $10}'`
hours4=`/usr/syno/bin/smartctl -A /dev/hdd | /bin/grep Power_On_Hours | /usr/bin/awk '{print $10}'`
temperatur1=`/usr/syno/bin/smartctl -A /dev/hda | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'`
temperatur2=`/usr/syno/bin/smartctl -A /dev/hdb | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'`
temperatur3=`/usr/syno/bin/smartctl -A /dev/hdc | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'`
temperatur4=`/usr/syno/bin/smartctl -A /dev/hdd | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'`
filesystem1=`df -h | grep /opt | awk '{print $6}'`
size1=`df -h | grep /opt | awk '{print $2}'`
used1=`df -h | grep /opt | awk '{print $3}'`
available1=`df -h | grep /opt | awk '{print $4}'`
percent1=`df -h | grep /opt | awk '{print $5}'`
datum=`date +"%d.%m.%y`
zeit=`date +"%H:%M`
up_time=`uptime | sed 's/^.*up //' | sed 's/, load.*$//'`
CPU=`/usr/bin/top -b -n 1 |awk 'NR>7&&NR<30 {s+=$9} END {printf("%2d",s)}'`
INT_IP=`ifconfig eth0 | grep inet | sed 's/^ *..........//' | sed 's/ .*$//' | sed 's/:$//'`
IP=`if [ -f /tmp/externalIP.result ];then /bin/get_key_value /tmp/externalIP.result externalIP;else echo 0.0.0.0;fi`
FREE=`free`
MEM=`echo "$FREE" | awk 'NR==2{printf("%2d",$3/$2*100)}'`
SWAP=`echo "$FREE" | awk 'NR==3{printf("%2d",$3/$2*100)}'`
IQ=`cat /var/spool/syno_indexing_queue* | wc -l`; IQ1=100; if [ $IQ -lt 100 ]; then IQ1=$IQ; fi
TQ=`cat /var/spool/thumb_create.queue* | wc -l`; TQ1=100; if [ $TQ -lt 100 ]; then TQ1=$TQ; fi
FQ=`cat /var/spool/flv_create_queue* | wc -l`; FQ1=100; if [ $FQ -lt 100 ]; then FQ1=$FQ; fi
MSG=`tail -1 /var/log/messages`
LASTMSG=`echo $MSG | cut -b 1-78`
WEATHER=`wget -O - "http://www.google.com/ig/api?weather="$LOCATION 2>/dev/null`
TEMP=`echo $WEATHER | sed -e 's/^.*temp_c data=\"\\([0-9-][0-9\]*\\)\".*/\\1/'`
COND=`echo $WEATHER | sed -e 's/^.*condition data="\(.*\)".*/\\1/'`
HUM=`echo $WEATHER | sed -e 's/^.*humidity data="Humidity:\(.*\)%.*/\\1/'`

log() {
echo `date +%c`: $1 >> $LOGFILE
}
log "Temperatur 1: $temperatur1 °C, Temperatur 2: $temperatur2 °C, Temperatur 3: $temperatur3 °C, Temperatur 4: $temperatur4 °C, IP: $IP"
nachricht="Status der Diskstation ($hostname ($model)) vom $datum ($zeit):
--------------------------------------------

[Speicherplatz in TB]
Groesse Datentraeger: $size1
Freier Speicher: $available1
Belegter Speicher: $used1 ($percent1)

[Auslastung]
CPU-Auslastung: ${CPU}%
Memory: ${MEM}%
Swap: ${SWAP}%
Indexing Queue: $IQ
Thumbs Queue: $TQ
FLV Queue: $FQ

[Datentraeger]
Volume 1: $temperatur1 Grad, $hours1 Stunden Laufzeit
Volume 2: $temperatur2 Grad, $hours2 Stunden Laufzeit
Volume 3: $temperatur3 Grad, $hours3 Stunden Laufzeit
Volume 4: $temperatur4 Grad, $hours4 Stunden Laufzeit

[IP]
Externe IP: $IP
Interne IP: $INT_IP

[Aktuelle Netzwerkverbindungen]
$netstat

[Netzwerkstatistik eth0]
$eth0_rx
$eth0_tx

[Uptime]
Uptime:$up_time Stunden

[Wetter]
Temperatur: ${TEMP} Grad C
Luftfeuchtigkeit:${HUM}%
Vorhersage: $COND

[Letzte Nachrichten]
$LASTMSG

"
echo "$nachricht" | /opt/bin/nail -s "Status Diskstation" USER.USER@PROVIDER.de
echo 2 >/dev/ttyS1
