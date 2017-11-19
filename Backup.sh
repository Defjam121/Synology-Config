#!/bin/sh

# E-Mail Adresse
# --------------------------------------------------------------
# Die E-Mail-Adresse muß identisch mit der im DSM unter 
# Systemsteuerung/Benachrichtigung konfigurierten sein.
    EMAIL="dein.name@mail.tld"

# Backup - Quelle
# --------------------------------------------------------------
    VOLUME="/volume1"        
    SHAREDFOLDER=(/photo 
                  /video/Spielfilme
                  /music/Alben/Deutsch )
                  
# Backup - Ziel 
# --------------------------------------------------------------
    #TARGET="/volume1/Backup"
    TARGET="/volumeUSB1/usbshare/Backup"

# --------------------------------------------------------------
# Ab hier bitte nichts mehr ändern
# --------------------------------------------------------------
    RSYNCCONF=(--stats --log-file-format="%i %o %f" --delete --backup --backup-dir=`$DATE`_Recycle)
    RSYNC="/bin/rsync"
    SSH="/bin/ssh" 
    SSMTP="/usr/bin/ssmtp"
    ECHO="/bin/echo" 
    DATE="/bin/date +%Y-%m-%d"; 
    TIMESTAMP="/bin/date +%d.%m.%Y_%H:%M:%S";
    LOGFILE="/`$DATE`_Sicherungsprotokoll.log"
    
if [ "$EMAIL" ]; then
  # Sicherungsprotokoll im Backup-Ziel als Datei speichern und 
  # daraus eine E-Mail generieren...
    LOG="$TARGET$LOGFILE"    
    $ECHO  "To: $EMAIL" > $LOG
    $ECHO  "From: $EMAIL" >> $LOG
    $ECHO  "Subject: Sicherungsprotokoll vom `$TIMESTAMP` Uhr" >> $LOG
    $ECHO  "" >> $LOG    
else
  # Sicherungsprotokoll im Backup-Ziel als Datei speichern
    LOG="$TARGET$LOGFILE"
    $ECHO "Sicherungsprotokoll vom `$TIMESTAMP` Uhr" > $LOG
    fi

for SHARE in "${SHAREDFOLDER[@]}"
    do
        $ECHO "" >> $LOG
        $ECHO "------------------------------------------------------------------------------------" >> $LOG
        $ECHO "Statusbericht für: $VOLUME$SHARE" >> $LOG
        $ECHO "------------------------------------------------------------------------------------" >> $LOG
        $RSYNC -ah "$VOLUME$SHARE" "${RSYNCCONF[@]}" "$TARGET"  >> $LOG 2>&1 
    done
    
if [ "$EMAIL" ]; then
  # Sicherungsprotokoll als E-Mail versenden...
    $SSMTP $EMAIL < $LOG
    fi  