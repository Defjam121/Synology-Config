#!/tmp/sh
## NAME des getmail Scripts hier anpassen (ohne Pfadangabe!!!)
pfad_getmail=getmail.sh
# Pfad fuer Logfile hier angeben. ALLE Ausgaben des Skriptes werden hierhin umgeleitet
getmail_log=/opt/var/log/tobi.getmail.log


if test -e /tmp/checkmaill ; then
 echo "Code rennt bereits"
 exit
elif test "$(whoami)" != "root" ; then
 echo "Das Script MUSS unter root laufen. Mittels su <user> holt das Script die Emails dann als <user> ab"
 exit
elif test ! -e $getmail_log ; then
 echo "Das Logfile unter $getmail_log konnte nicht gefunden werden"
 exit
fi


## Benoetigte Kommandos in /tmp "erstellen", damit die Platten durchschlafen können
## WICTHIG: Der Link zwischen /tmp/busybox und /tmp/sh MUSS manuell vor dem Aufruf der Scriptes erstellt werden!!
cp -f /bin/busybox /tmp/ >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/sleep >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/expr >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/test >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/pidof >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/cut >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/ls >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/grep >> $getmail_log 2>&1
# su wird nur dann benoetigt wenn das Kommando DIREKT in diesem Script aufgerufen wird (siehe Zeile 48+49 und 65+66)
#ln -s /tmp/busybox /tmp/su >> $getmail_log 2>&1
ln -s /tmp/busybox /tmp/find >> $getmail_log 2>&1

i=0
touch /tmp/checkmaill
echo $$ > /tmp/checkmaill
PATH=/tmp
while true; do
 s=`pidof imap`
 t=''
 if test "$s" != '' ; then
  for var in $s ; do
   tt=`ls -all /proc | grep $var | cut -d' ' -f6`
   if test "$tt" != "$t" ; then
     for ii in `find /volume1/homes/$tt -name $pfad_getmail`; do
          # Die folgende Zeile nur dann "entkommentieren" wenn keine virtuellen Benutzer verwendet werden
          # Sonst gibt es Probleme mit deliver. ACHTUNG: Wenn diese Zeile auskommentiert ist MUSS su <user> in getmail.sh gesetzt werden,
          # sonst wird das Script (getmail.sh) unter root ausgeführt und das gibt garantiert Aerger mit dem dovecot
          #su $tt -c "$ii" >> $getmail_log 2>&1
      $ii >> $getmail_log 2>&1
      done
     t=$tt
   fi
  done
  i=`expr $i + 1`
  sleep 60
 else
  tt=''
  i=`expr $i + 1`
  sleep 1
  if test `expr $i % 3600` -eq 0 ; then
   i=0
   for ii in `find /volume1/homes/ -name $pfad_getmail`; do
    tt=`ls -all $ii | cut -d' ' -f6`
        # siehe oben (Zeile 44-46)
    #su $tt -c "$ii" >> $getmail_log 2>&1
    $ii >> $getmail_log 2>&1
   done
  fi
 fi
done
