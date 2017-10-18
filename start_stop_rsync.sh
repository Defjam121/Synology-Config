#!/bin/sh

# E-Mail Adresse
# -------------------------------------------------------------------------
# Die E-Mail Adresse muss mit der bereits im DSM unter "Benachrichtigung" |
# hinterlegten E-Mail-Adresse identisch sein.                             |
# -------------------------------------------------------------------------
EMAIL=""              # E-Mail für Zustellung des Sicherungsprotokolls
EMAILFAIL="0"         # "0" = Sicherungsprotokoll immer senden
                      # "1" = Sicherungsprotokoll nur bei Problemen senden
# SSH - Verbindungsdaten
# -------------------------------------------------------------------------
# Werden keine Verbindungsdaten angegeben, wird eine lokale Datensicherung|
# durchgeführt.                                                           |
# -------------------------------------------------------------------------
SSH_USER=""           # Benutzername
SSH_FROM=""           # IP-, Host- oder Domain VON entfernter Quelle AUF lokales Ziel
SSH_TO=""             # IP-, Host- oder Domain VON lokaler Quelle AUF entferntes Ziel
SSH_PORT=""           # Leer = Port 22 ansonsten gewünschten Port angeben
RSYNC_PORT=""         # Alternativer Rsync Port kann hier eingetragen werden
MAC=""                # Leer = WOL wird nicht genutzt
SLEEP="300"           # Wartezeit in Sekunden bis Remoteserver gebootet ist
                      # MAC Adresse eintragen = Server wird hochgefahren, wenn dieser ausgeschaltet ist
SHUTDOWN="0"          # "0" = Entfernter Server wird nicht heruntergefahren
                      # "1" = Entfernter Server wird heruntergefahren wenn das Backup erfolgreich war

# Umgang mit verschlüsselten Ordnern
# ------------------------------------------------------------------------
# Angeben, ob eingehangene verschlüsselte Ordner nach der Datensicherung |
# wieder ausgehangen werden sollen.                                      |
# ------------------------------------------------------------------------
UNMOUNT="0"           # "0" = Eingehangene Ordner werden nicht ausgehängt
                      # "1" = Quelle und Ziel werden ausgehängt
                      # "2" = Quelle wird ausgehängt
                      # "3" = Ziel wird ausgehängt

# Backup - Quellen
# ------------------------------------------------------------------------
# Hier können beliebige, unverschlüsselte sowie verschlüsselte           |
# Backup-Quellen einer lokalen oder entfernten DS eingetragen werden.    |
# Zu beachten ist, das immer der vollständige Pfad ohne Angabe des       |
# entsprechenden Volume anzugeben ist. Weiterhin ist auf  die            |
# Schreibweise im Beispiel zu achten, pro Zeile je eine Backupquelle.    |
# ------------------------------------------------------------------------
SOURCES="/homes/admin
/ordner mit leerzeichen
/verschlüsselter ordner"

# Backup - Ziel
# ------------------------------------------------------------------------
# Wenn NOTTOSCRIPT="0"                                                   |
#  - dann entspricht TARGET einem "Unterverzeichnis" am Speicherort des  |
#    Scripts. Beisp.: volume[x]/share/[TARGET] oder bei einem            |
#    angeschlossenen USB-Datenträger: volumeUSB[x]/usbshare/[TARGET]     |
#  - Ist zusätzlich HOSTNAME="1" gesetzt, wird der Netzwerkname dem      |
#    Speicherort hinzugefügt. Beisp.: volume[x]/Share/[TARGET]/[HOSTNAME]|
#                                                                        |
# Wenn NOTTOSCRIPT="1" und Ziel ist eine Diskstation                     |
#  - dann entspricht TARGET einem "gemeinsamen Ordner" (Share) am        |
#    Speicherort des Ziel's. Beisp.: volume[x]/[TARGET]                  |
#  - Ist zusätzlich HOSTNAME="1" gesetzt, wird der Netzwerkname dem      |
#    Speicherort hinzugefügt. Beisp.: volume[x]/[TARGET]/[HOSTNAME]      |
#                                                                        |
# Wenn NOTTOSCRIPT="1" und Ziel ist ein RSync-kompatibler Server         |
#  - dann entspricht TARGET einem Ordner (Share) am Speicherort des      |
#    Ziel's. Beisp.: /[TARGET]                                           |
#  - Ist zusätzlich HOSTNAME="1" gesetzt, wird der Netzwerkname dem      |
#    Speicherort hinzugefügt. Beisp.: /[TARGET]/[HOSTNAME]               |
#-------------------------------------------------------------------------
TARGET="/RSync Backup"

FROMTHISDEVICE="0"     # "0" = Quelle ist ein gemeinsamer Ordner
                       # "1" = Quelle liegt auf externen USB/SATA-Speicher neben Script
NOTTOSCRIPT="0"        # "0" = Sicherungsziel liegt beim Script
                       # "1" = Sicherungsziel liegt im geinsamen Ordner
HOSTNAME="0"           # "0" = Sicherungsziel entspricht TARGET
                       # "1" = Sicherungsziel entspricht TARGET/HOSTNAME
AUTORUN="0"            # "0" = autorun wirft USB-Stick nicht aus
                       # "1" = autorun wirft USB-Stick aus

# Optische- sowie akustische Signalausgabe
#-------------------------------------------------------------------------
# Start  : Status-LED wechselt von grün nach orange. Ein Signalton ertönt|
# Ende   : Status-LED wechselt von orange nach grün. Ein Signalton ertönt|
# Fehler : Status-LED wechselt von orange nach grün. 3x Signalton ertönt |
#-------------------------------------------------------------------------
SIGNAL="0"             # "0" = Optische- sowie akustische Signalausgabe aus
                       # "1" = Optische- sowie akustische Signalausgabe an

# Exportieren der DSM-Systemkonfiguration (.dss)
#-------------------------------------------------------------------------
# Die DSM-Systemkonfigurartion (.dss) wird in den Systemordner           |
# /@DSMConfig exportiert.                                                |
#-------------------------------------------------------------------------
DSM_EXPORT="0"         # "0" = DSM-Systemkonfiguration wird NICHT exportiert
                       # "1" = DSM-Systemkonfiguration wird exportiert

# Rotationszyklus für das Löschen von @Recycle und @Logfiles
#-------------------------------------------------------------------------
# Zeitangabe, wann Ordner bzw. Dateien in den System-Ordnern endgültig   |
# gelöscht werden sollen, die älter als x Tage sind.                     |
# ------------------------------------------------------------------------
RECYCLE_ROTATE="90"   # @Recycle-Daten die älter als "x" Tage sind, löschen
LOGFILES_ROTATE="60"  # @Logfiles-Daten die älter als "x" Tage sind, löschen
DSMCONFIG_ROTATE="30" # @DSMConfig-Daten die älter als "x" Tage sind, löschen

# ------------------------------------------------------------------------
# Ab hier bitte nichts mehr ändern, wenn man nicht weiß was man tut !!!  |
# ------------------------------------------------------------------------
SCRIPTFILE="${0##*/}"
SCRIPTNAME="${SCRIPTFILE%.*}"
DATE=`date +%Y-%m-%d_%Hh%M`
# RSync Optionen konfigurieren
#-------------------------------------------------------------------------
SYNCOPT="-ahR"
LOGSTAT="--stats"
EXCLUDE="--exclude=@eaDir/*** --exclude=@Logfiles/*** --exclude=#recycle/*** --exclude=#snapshot/*** --exclude=.DS_Store/***"
RECYCLE="--delete --backup --backup-dir=@Recycle/"$DATE"_$SCRIPTNAME"

# Umgebungsvariablen definieren
#-------------------------------------------------------------------------
BACKIFS="$IFS"
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/syno/bin:/usr/syno/sbin
TARGET_EMPTY="/Backup_DS"
if [[ ${TARGET:0:1} != \/ ]] && [ -n "$TARGET" ]; then
  TARGET="/$TARGET"
fi
DEST="${TARGET#*/}"
TARGET_CUT="${TARGET#*/}"
TARGET_DECRYPT="${TARGET_CUT%%/*}"
TIMESTAMP=`date +%d.%m.%Y%t%H:%M:%S`
LOKALHOST="$(hostname)"
HR="------------------------------------------------------------------------------------------------"

# Variablen je nach Verbindung festlegen
#-------------------------------------------------------------------------
# Wenn Verbindung AUF entfernten Server... (TOSSH)
if [ -n "$SSH_FROM" ] && [ -z "$SSH_TO" ]; then
  if [ -n "$SSH_PORT" ]; then
    FROMSSH="ssh -p $SSH_PORT $SSH_USER@$SSH_FROM"
    SCP="scp -P $SSH_PORT"
  else
    FROMSSH="ssh $SSH_USER@$SSH_FROM"
    SCP="scp"
  fi
  if [ -n "$RSYNC_PORT" ]; then
    FROMRSYNC="ssh -p $RSYNC_PORT -l $SSH_USER"
  else
    FROMRSYNC="ssh -l $SSH_USER"
  fi
  REMOTEIP="$SSH_FROM"
# Wenn Verbindung VON entfernten Server... (FROMSSH)
elif [ -z "$SSH_FROM" ] && [ -n "$SSH_TO" ]; then
  if [ -n "$SSH_PORT" ]; then
    TOSSH="ssh -p $SSH_PORT $SSH_USER@$SSH_TO"
    SCP="scp -P $SSH_PORT"
  else
    TOSSH="ssh $SSH_USER@$SSH_TO"
    SCP="scp"
  fi
  if [ -n "$RSYNC_PORT" ]; then
    TORSYNC="ssh -p $RSYNC_PORT -l $SSH_USER"
  else
    TORSYNC="ssh -l $SSH_USER"
  fi
  REMOTEIP="$SSH_TO"
# Wenn Verbindung lokal...
elif [ -z "$SSH_FROM" ] && [ -z "$SSH_TO" ]; then
  FIND="find"
  SOURCE_TEST="test"
  TARGET_TEST="test"
  if [ $HOSTNAME -eq 1 ]; then
    NAME="$LOKALHOST"
  fi
fi

# DSM-Benachrichtigung: Script wird ausgeführt...
#-------------------------------------------------------------------------
synodsmnotify @administrators "Script: $SCRIPTNAME" "Wird ausgeführt.."

# Speicherort des Logfiles festlegen
#-------------------------------------------------------------------------
mkdir -p `dirname $0`/@Logfiles
LOG="`dirname $0`/@Logfiles/"$DATE"_$SCRIPTNAME.log"
if test ! -d `dirname $0`/@Logfiles; then
  DSMNOTIFY="Es konnte kein @Logfiles Ordner erstellt werden!"
fi
if [ $SIGNAL -eq 1 ]; then
  echo 3 >/dev/ttyS1; echo : >/dev/ttyS1
  sleep 2
fi

# Ordner/Datei für das Protokoll anlegen und Kopfdaten generieren
#-------------------------------------------------------------------------
# E-Mail-Kopf aufbauen...
if [ -n "$EMAIL" ]; then
  echo "To: $EMAIL" > $LOG
  echo "From: $EMAIL" >> $LOG
  echo "Subject: Sicherungsprotokoll vom $TIMESTAMP Uhr" >> $LOG
  echo "" >> $LOG
  echo "Ausgefuehrtes RSync-Script: $SCRIPTFILE" >> $LOG
  echo "" >> $LOG; echo "$HR" >> $LOG
# Protokoll-Kopf aufbauen...
else
  echo "Sicherungsprotokoll vom $TIMESTAMP Uhr" >> $LOG
  echo "" >> $LOG
  echo "Ausgefuehrtes RSync-Script: $SCRIPTFILE" >> $LOG
  echo "" >> $LOG; echo "$HR" >> $LOG
fi

# Fehlererkennung
#-------------------------------------------------------------------------
if [ -z "$TARGET" ] && [ "$NOTTOSCRIPT" -eq 1 ]; then
  STOP="Bitte TARGET setzen oder NOTTOSCRIPT nicht setzen..." >> $LOG
fi
if [ -z "$STOP" ] && [ -n "$SSH_FROM" ] && [ -n "$SSH_TO" ]; then
  STOP="Bitte nur SSH_FROM oder SSH_TO setzen!" >> $LOG
fi
if [ -z "$STOP" ] && [ -n "$SSH_TO" ] && [ -z "$TARGET" ]; then
  STOP="Bei SSH_TO muss TARGET angegeben werden!"
fi
if [ -z "$STOP" ] && [ "$NOTTOSCRIPT" -eq 1 ] && [ -z "$TARGET" ]; then
  STOP="Bei NOTTOSCRIPT=1 muss TARGET angegeben werden!"
fi
if [ -z "$STOP" ] && [ $FROMTHISDEVICE -eq 1 ] && [ -n "$SSH_FROM" ]; then
  STOP="Nur FROMTHISDEVICE setzen oder SSH_FROM !"
fi
# Ping Test
#-------------------------------------------------------------------------
if [ -z "$STOP" ]; then
  if [ -n "$SSH_FROM" ] || [ -n "$SSH_TO" ]; then
    ping $REMOTEIP -c 2
    ONLINE="$?"
    if [ $ONLINE -eq 0 ]; then
      echo "Remoteserver $REMOTEIP ist online." >> $LOG
    else
      if [ -z "$MAC" ]; then
        STOP="Remoteserver $REMOTEIP ist offline!" >> $LOG
      else
        echo "Remoteserver $REMOTEIP ist offline!" >> $LOG
      fi
    fi
    if [ -z "$SSH_USER" ]; then
      STOP="Bei der Netzwerksicherung bitte SSH_USER angeben." >> $LOG
    fi
  fi
fi

# WOL
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ -n "$MAC" ] && [ $ONLINE -eq 1 ]; then
  echo "Remoteserver $REMOTEIP wird geweckt." >> $LOG
  if test -f /usr/bin/ether-wake; then
    /usr/bin/ether-wake $MAC
  elif test -f /usr/syno/sbin/synonet; then
    /usr/syno/sbin/synonet --wake $MAC eth0
  fi
  sleep $SLEEP
  ping $REMOTEIP -c 2
  ONLINE="$?"
  if [ $ONLINE -eq 0 ]; then
    echo "Remoteserver $REMOTEIP wurde hochgefahren." >> $LOG
  else
    if [ -z "$STOP" ]; then
      STOP="Remoteserver $REMOTEIP konnte nicht hochgefahren werden." >> $LOG
    fi
  fi
fi

# Verbindungstest (SSH_FROM)
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ -n "$SSH_FROM" ] && [ -z "$SSH_TO" ]; then
  if [ ! "$FROMSSH" ]; then
    STOP="Es konnte keine SSH-Verbindung zu $SSH_FROM aufgebaut werden." >> $LOG
  elif [ "$FROMSSH" ]; then
    REMOTEHOST=$($FROMSSH "echo \`hostname\`")
    echo "SSH-Verbindung zu $REMOTEHOST aufgebaut." >> $LOG
    SYNOSHARE_SOURCE="$FROMSSH"
    FIND="$FROMSSH find"
    SOURCE_TEST="$FROMSSH test"
    TARGET_TEST="test"
    if [ $HOSTNAME -eq 1 ]; then
      NAME="$REMOTEHOST"
    fi
  fi
fi

# Verbindungstest (SSH_TO)
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ -z "$SSH_FROM" ] && [ -n "$SSH_TO" ]; then
  if [ ! "$TOSSH" ]; then
    STOP="Es konnte keine SSH-Verbindung zu $SSH_TO aufgebaut werden." >> $LOG
  elif [ "$TOSSH" ]; then
    REMOTEHOST=$($TOSSH "echo \`hostname\`")
    echo "SSH-Verbindung zu $REMOTEHOST aufgebaut." >> $LOG
    SYNOSHARE_TARGET="$TOSSH"
    FIND="$TOSSH find"
    SOURCE_TEST="test"
    TARGET_TEST="$TOSSH test"
    if [ $HOSTNAME -eq 1 ]; then
      NAME="$LOKALHOST"
    fi
  fi
fi

# Verbindungstest ob Quelle bzw. Ziel eine Diskstation ist oder nicht
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ -n "$SSH_FROM" ] || [ -n "$SSH_TO" ]; then
  if $SOURCE_TEST -d /usr/syno/synoman; then
    SOURCE_PATH="/volume*"
    SOURCEDS="1"
    echo "Quellserver ist eine DS" >> $LOG
  elif $SOURCE_TEST ! -d /usr/syno/synoman; then
    SOURCEDS="0"
    echo "Quellserver ist keine DS" >> $LOG
  fi

  if $TARGET_TEST -d /usr/syno/synoman; then
    TARGET_PATH="/volume*"
    TARGETDS="1"
    echo "Zielserver ist eine DS" >> $LOG
  elif $TARGET_TEST ! -d /usr/syno/synoman; then
    TARGETDS="0"
    echo "Zielserver ist keine DS" >> $LOG
  fi

elif [ -z "$STOP" ]; then
  SOURCE_PATH="/volume*"
  TARGET_PATH="/volume*"
  SOURCEDS="1"
  TARGETDS="1"
fi

if [ $FROMTHISDEVICE -eq 1 ]; then
  SOURCE_PATH="/volume*/*share"
fi

# Zielordner checken
#-------------------------------------------------------------------------
if [ -z "$STOP" ]; then
IFS="
"
  TARGET_ESCAPE=$(echo $TARGET | sed -e 's/ /\\ /g')
  TARGET_DECRYPT_ESCAPE=$(echo $TARGET_DECRYPT | sed -e 's/ /\\ /g')
  IFS="$BACKIFS"
  if [ -n "$SSH_TO" ]; then
    DEST_DECRYPT="$TARGET_DECRYPT_ESCAPE"
  else
    DEST_DECRYPT="$TARGET_DECRYPT"
  fi
  if [ "$NOTTOSCRIPT" -eq 1 ] || [ -n "$SSH_TO" ]; then
    if $TARGET_TEST ! -d $TARGET_PATH/@"$DEST_DECRYPT"@ && $TARGET_TEST -d $TARGET_PATH/"$DEST_DECRYPT"; then
      echo "Zielordner $TARGET_DECRYPT wurde lokalisiert..." >> $LOG
    elif $TARGET_TEST -d $TARGET_PATH/@"$DEST_DECRYPT"@ && $TARGET_TEST -d $TARGET_PATH/"$DEST_DECRYPT"; then
      echo "Verschluesselter Zielordner $TARGET_DECRYPT bereits eingehangen..." >> $LOG
    elif $TARGET_TEST -d $TARGET_PATH/@"$DEST_DECRYPT"@ && $TARGET_TEST ! -d $TARGET_PATH/"$DEST_DECRYPT"; then
      echo "Verschluesselter Zielordner $TARGET_DECRYPT nicht eingehangen..." >> $LOG
# Anhand des Key-Files versuchen einen verschluesselten Zielordner einbinden
      if test -f `dirname $0`/"$TARGET_DECRYPT".key; then
        echo "$TARGET_DECRYPT.key gefunden" >> $LOG
        echo "Verschluesselter Zielordner $TARGET_DECRYPT wird eingehangen..."  >> $LOG
        KEYFILEDEST=$(ecryptfs-unwrap-passphrase `dirname $0`/"$TARGET_DECRYPT".key "\$1\$5YN01o9y")
        $SYNOSHARE_TARGET /usr/syno/sbin/synoshare --enc_mount "$DEST_DECRYPT" "$KEYFILEDEST" >> $LOG
        sleep 20
        if $TARGET_TEST -d $TARGET_PATH/@"$DEST_DECRYPT"@ && $TARGET_TEST -d $TARGET_PATH/"$DEST_DECRYPT"; then
          echo "Verschluesselter Zielordner $TARGET_DECRYPT wurde eingehangen..."  >> $LOG
        elif $TARGET_TEST -d $TARGET_PATH/@"$DEST_DECRYPT"@ && $TARGET_TEST ! -d $TARGET_PATH/"$DEST_DECRYPT"; then
          echo "Verschluesselter Zielordner $TARGET_DECRYPT konnte nicht eingehangen werden..."  >> $LOG
        fi
      else
        echo "Kein Keyfile fuer $TARGET_DECRYPT gefunden! Verschluesselte Ordner muessen eingehangen werden!"
      fi
    fi
    if $TARGET_TEST ! -d $TARGET_PATH/"$DEST_DECRYPT"; then
      if [ -z "$STOP" ]; then
        STOP="Zielordner /$TARGET_DECRYPT nicht gefunden!"
      fi
    fi
  fi
fi

# Quellordner checken
#-------------------------------------------------------------------------
IFS="
"
for SHARE in $SOURCES; do
  if [[ ${SHARE:0:1} != \/ ]] ; then
    SHARE="/$SHARE"
  fi
  SHARE_ESCAPE=$(echo $SHARE | sed -e 's/ /\\ /g')
  SHARE_CUT="${SHARE#*/}"
  SHARE_DECRYPT="${SHARE_CUT%%/*}"
  SHARE_DECRYPT_ESCAPE=$(echo $SHARE_DECRYPT | sed -e 's/ /\\ /g')
  IFS="$BACKIFS"
  if [ -n "$SSH_FROM" ]; then
    SOURCE_DECRYPT="$SHARE_DECRYPT_ESCAPE"
  else
    SOURCE_DECRYPT="$SHARE_DECRYPT"
  fi
  if $SOURCE_TEST ! -d $SOURCE_PATH/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST -d $SOURCE_PATH/"$SOURCE_DECRYPT"; then
    echo "Quellordner $SHARE_DECRYPT wurde lokalisiert..." >> $LOG
  elif $SOURCE_TEST -d $SOURCE_PATH/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST -d $SOURCE_PATH/"$SOURCE_DECRYPT"; then
    echo "Verschluesselter Quellordner $SHARE_DECRYPT bereits eingehangen..." >> $LOG
  elif $SOURCE_TEST -d $SOURCE_PATH/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST ! -d $SOURCE_PATH/"$SOURCE_DECRYPT"; then
    echo "Verschluesselter Quellordner $SHARE_DECRYPT nicht eingehangen..." >> $LOG
# Anhand des Key-Files versuchen einen verschluesselten Quellordner einbinden
    if test -f `dirname $0`/"$SHARE_DECRYPT".key; then
      echo "$SHARE_DECRYPT.key gefunden" >> $LOG
      echo "Verschluesselter Quellordner $SHARE_DECRYPT wird eingehangen..."  >> $LOG
      KEYFILESHARE=$(ecryptfs-unwrap-passphrase `dirname $0`/"$SHARE_DECRYPT".key "\$1\$5YN01o9y")
      $SYNOSHARE_SOURCE /usr/syno/sbin/synoshare --enc_mount "$SHARE_DECRYPT" "$KEYFILESHARE" >> $LOG
      sleep 20
      if $SOURCE_TEST -d $SOURCE_PATH/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST -d $SOURCE_PATH/"$SOURCE_DECRYPT"; then
        echo "Verschluesselter Quellordner $SHARE_DECRYPT wurde eingehangen..."  >> $LOG
      elif $SOURCE_TEST -d $SOURCE_PATH/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST ! -d $SOURCE_PATH/"$SOURCE_DECRYPT"; then
        echo "Verschluesselter Quellordner $SHARE_DECRYPT konnte nicht eingehangen werden..."  >> $LOG
      fi
    else
      STOP="Kein Keyfile fuer $SHARE_DECRYPT gefunden! Verschluesselte Ordner muessen eingehangen werden! Datensicherung ABGEBROCHEN..."
    fi
  fi
done

# Ziel definieren
#-------------------------------------------------------------------------
if [ -z "$STOP" ]; then
  if [ -n "$SSH_TO" ] && [ -n "$TARGET" ]; then
    DEST_FULL=$($TOSSH "echo $TARGET_PATH/$TARGET_DECRYPT_ESCAPE")
    DEST_CUT="${DEST_FULL#*/}"
    DEST_VOL="${DEST_CUT%%/*}"
    if [ $TARGETDS -eq 1 ]; then
      DESTTARGET="/$DEST_VOL$TARGET_ESCAPE"
    else
      DESTTARGET="$TARGET_ESCAPE"
    fi
    if [ $HOSTNAME -eq 1 ]; then
      DESTINATION="$DESTTARGET/$NAME"
    else
      DESTINATION="$DESTTARGET"
    fi
  elif [ -z "$SSH_TO" ] && [ "$NOTTOSCRIPT" -eq 0 ] && [ -z "$TARGET" ]; then
    if [ $HOSTNAME -eq 1 ]; then
      DESTINATION="`dirname $0`$TARGET_EMPTY/$NAME"
    else
      DESTINATION="`dirname $0`$TARGET_EMPTY"
    fi
  elif [ -z "$SSH_TO" ] && [ "$NOTTOSCRIPT" -eq 1 ] && [ -n "$TARGET" ]; then
    DEST_FULL=$(echo $TARGET_PATH/"$TARGET_DECRYPT")
    DEST_CUT="${DEST_FULL#*/}"
    DEST_VOL="${DEST_CUT%%/*}"
    if [ -n "$TARGETDS" ]; then
      DESTTARGET="/$DEST_VOL$TARGET"
   else
       DESTTARGET="$TARGET"
   fi
   if [ $HOSTNAME -eq 1 ]; then
     DESTINATION="$DESTTARGET/$NAME"
   else
     DESTINATION="$DESTTARGET"
   fi
  elif [ -z "$SSH_TO" ] && [ "$NOTTOSCRIPT" -eq 0 ]; then
    if [ $HOSTNAME -eq 1 ]; then
      DESTINATION="`dirname $0`$TARGET/$NAME"
    else
      DESTINATION="`dirname $0`$TARGET"
    fi
  fi
  mkdir -p "$DESTINATION"
  if [ -n "$SSH_TO" ] && [ "$NOTTOSCRIPT" -eq 0 ]; then
    STOP="Bei SSH_TO muss NOTTOSCRIPT gesetzt werden!" >> $LOG
  elif [ -n "$SSH_TO" ] && [ "$NOTTOSCRIPT" -eq 1 ] && [ -n "$TARGET" ]; then
    if $TARGET_TEST -d $TARGET_PATH/$TARGET_DECRYPT_ESCAPE; then
      $TOSSH mkdir -p "$DESTINATION"
    fi
  fi
fi

# Check ob Zielordner erstellt wurde bzw. vorhanden war.
if $TARGET_TEST ! -d "$DESTINATION"; then
  if [ -z "$STOP" ]; then
    STOP="Zielordner $TARGET konnte nicht erstellt werden bzw. ist nicht vorhanden !"
  fi
fi

echo "" >> $LOG
echo "$HR" >> $LOG
echo "" >> $LOG
# Beginn der RSync-Datensicherung
#--------------------------------------------------------------------------
IFS="
"
for SHARE in $SOURCES; do
  if [ -z "$STOP" ]; then
    echo "" >> $LOG
    if [[ ${SHARE:0:1} != \/ ]] ; then
      SHARE="/$SHARE"
    fi
    SHARE_ESCAPE=$(echo $SHARE | sed -e 's/ /\\ /g')
    SHARE_CUT="${SHARE#*/}"
    SHARE_DECRYPT="${SHARE_CUT%%/*}"
    IFS="$BACKIFS"
    unset FORERROR
    if [ -n "$SSH_FROM" ]; then
      SOURCE="$SHARE_ESCAPE"
    else
     SOURCE="$SHARE"
    fi

  if $SOURCE_TEST ! -d $SOURCE_PATH"$SOURCE"; then
    ERROR="Quellordner $SHARE nicht erreichbar..." >> $LOG
    FORERROR="1"
  elif $SOURCE_TEST -d $SOURCE_PATH"$SOURCE"; then
    echo "Quellordner $SHARE erreichbar." >> $LOG
  fi
  if [ $FROMTHISDEVICE -eq 1 ] && [ -z "$SSH_FROM" ]; then
    SOURCE="`dirname $0`$SHARE"
  elif [ $FROMTHISDEVICE -eq 0 ] && [ -z "$SSH_FROM" ]; then
    SOURCE="$SHARE"
  fi

  if [ -z "$STOP" ] && [ -z "$FORERROR" ]; then
# SSH-SSH_FROM RSync-Datensicherung VON einer entfernten DS oder komp. Server
#--------------------------------------------------------------------------
    if [ -n "$SSH_FROM" ] && [ -z "$SSH_TO" ] && [ -n "$DESTINATION" ]; then
      echo "$HR" >> $LOG
      echo "Starte Datensicherung: $REMOTEHOST$SHARE nach $DESTINATION" >> $LOG
      echo "$HR" >> $LOG
      if [ $SOURCEDS -eq 1 ]; then
        rsync -e "$FROMRSYNC" $SYNCOPT $SSH_FROM:/volume*"$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE "$DESTINATION" >> $LOG
        RSYNC_EXIT="$?"
        elif [ $SOURCEDS -ne 1 ]; then
          rsync -e "$FROMRSYNC" $SYNCOPT $SSH_FROM:"$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE "$DESTINATION" >> $LOG
          RSYNC_EXIT="$?"
        fi
# SSH-SSH_TO RSync-Datensicherung AUF eine entfernte DS oder komp. Server
#--------------------------------------------------------------------------
      elif [ -n "$SSH_TO" ] && [ -z "$SSH_FROM" ] && [ -n "$DESTINATION" ]; then
        echo "$HR" >> $LOG
        echo "Starte Datensicherung: $LOKALHOST$SHARE nach $DESTINATION" >> $LOG
        echo "$HR" >> $LOG
        if [ $SOURCEDS -eq 1 ] && [ $FROMTHISDEVICE -ne 1 ]; then
          rsync -e "$TORSYNC" $SYNCOPT /volume*"$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE $SSH_TO:"$DESTINATION" >> $LOG
          RSYNC_EXIT="$?"
          elif [ $SOURCEDS -ne 1 ] || [ $FROMTHISDEVICE -eq 1 ]; then
            rsync -e "$TORSYNC" $SYNCOPT "$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE $SSH_TO:"$DESTINATION" >> $LOG
            RSYNC_EXIT="$?"
          fi
# RSync- Lokale Datensicherung auf Volume, USB- oder SATA-Datentr�ger
#-------------------------------------------------------------------------
      elif [ -z "$SSH_TO" ] && [ -z "$SSH_FROM" ] && [ -n "$DESTINATION" ]; then
        echo "$HR" >> $LOG
        echo "Starte Datensicherung: $REMOTEHOST$SHARE nach $DESTINATION" >> $LOG
        echo "$HR" >> $LOG
        if [ $SOURCEDS -eq 1 ] && [ $FROMTHISDEVICE -ne 1 ]; then
          rsync $SYNCOPT /volume*"$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE "$DESTINATION" >> $LOG
          RSYNC_EXIT="$?"
          elif [ $SOURCEDS -ne 1 ] || [ $FROMTHISDEVICE -eq 1 ]; then
            rsync $SYNCOPT "$SOURCE" $LOGSTAT $EXCLUDE $RECYCLE "$DESTINATION" >> $LOG
            RSYNC_EXIT="$?"
          fi
        fi
        echo "" >> $LOG
        if [ $RSYNC_EXIT -ne 0 ]; then
          RSYNC_CODE="$RSYNC_EXIT"
        fi
    fi
  fi
done

# RSync Exit-Code = Fehlermeldung
#-------------------------------------------------------------------------
if [ -n "$RSYNC_CODE" ]; then
# Exit-Code: Entfernter Server ausgeschaltet?
  if [ $RSYNC_CODE -eq 43 ]; then
    echo "RSync-Code $RSYNC_CODE: Entfernte DS oder RSync komp. Server nicht Online? Bitte RSYNC Port kontrollieren!" >> $LOG
# Exit-Code: DSL-Verbindung getrennt?
  elif [ $RSYNC_CODE -eq 255 ]; then
    echo "RSync-Code $RSYNC_CODE: Bitte Internetverbindung oder RSYNC Port kontrollieren!" >> $LOG
# Exit-Code ausgeben...
  elif [ $RSYNC_CODE -ne 0 ]; then
    echo "RSync Fehlermeldung (Exit Code): $RSYNC_CODE" >> $LOG
  fi
fi

# RSync Exit-Code = Erfolgreich bzw. Unvollständig
#-------------------------------------------------------------------------
if [ -z "$RSYNC_CODE" ] && [ -z "$STOP" ] && [ -z "$ERROR" ]; then
  echo "$HR" >> $LOG
  echo "RSync-Datensicherung erfolgreich. Sicherungsziel: $DESTINATION" >> $LOG
  if [ -z "$DSMNOTIFY" ]; then
    DSMNOTIFY="RSync-Datensicherung erfolgreich. Sicherungsziel: $DESTINATION"
  fi
# Signalausgabe - Datensicherung erfolgreich
  if [ $SIGNAL -eq 1 ]; then
    echo 3 >/dev/ttyS1; echo 8 >/dev/ttyS1
    sleep 2
  fi
# RSync Exit-Code = Fehlermeldung
elif [ $RSYNC_CODE -ne 0 ] || [ -n "$STOP" ] || [ -n "$ERROR" ]; then
  echo "$HR" >> $LOG
  echo "RSync-Datensicherung unvollstaendig oder fehlgeschlagen - Sicherungsziel: $DESTINATION" >> $LOG
  if [ -z "$DSMNOTIFY" ]; then
    DSMNOTIFY="RSync-Datensicherung unvollstaendig oder fehlgeschlagen - Bitte Protokoll prüfen!"
  fi
# Signalausgabe - Datensicherung fehlgeschlagen
  if [ $SIGNAL -eq 1 ]; then
    echo 2 >/dev/ttyS1; sleep 1; echo 2 >/dev/ttyS1; sleep 1; echo 2 >/dev/ttyS1; sleep 1; echo 8 >/dev/ttyS1
  fi
fi
echo "$HR" >> $LOG; echo "" >> $LOG
if [ -n "$STOP" ]; then
  echo "FEHLER: $STOP" >> $LOG
fi
if [ -n "$ERROR" ]; then
  echo "FEHLER: $ERROR" >> $LOG
fi

# DSM-Systemkonfiguration exportieren
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ "$DSM_EXPORT" -eq 1 ] && [ -z "$RSYNC_CODE" ]; then
  if [ -n "$SSH_FROM" ] && [ -z "$SSH_TO" ] && [ -n "$SOURCEDS" ]; then
    $FROMSSH /usr/syno/bin/synoconfbkp export --filepath DSMConfig_TEMP.dss
    mkdir -p "$DESTINATION"/@DSMConfig
    $SCP -r $SSH_USER@$SSH_FROM:DSMConfig_TEMP.dss "$DESTINATION"/@DSMConfig/DSMConfig_"$DATE"_$REMOTEHOST.dss
    $FROMSSH rm -rf DSMConfig_TEMP.dss
    echo  "Sicherung der DSM-Systemkonfiguration von $REMOTEHOST erfolgreich zu $LOKALHOST kopiert.." >> $LOG
    echo "" >> $LOG
  elif [ -z "$SSH_FROM" ] && [ -n "$SSH_TO" ]; then
    synoconfbkp export --filepath `dirname $0`/@DSMConfig/DSMConfig_"$DATE"_$LOKALHOST.dss
    $TOSSH mkdir -p "$DESTINATION"/@DSMConfig
    $SCP -r `dirname $0`/@DSMConfig/*.dss $SSH_USER@$SSH_TO:"$DESTINATION"/@DSMConfig/
    rm -rf `dirname $0`/@DSMConfig
    echo  "Sicherung der DSM-Systemkonfiguration von $LOKALHOST erfolgreich zu $REMOTEHOST kopiert.." >> $LOG
    echo "" >> $LOG
  elif [ -z "$SSH_FROM" ] && [ -z "$SSH_TO" ]; then
    mkdir -p "$DESTINATION"/@DSMConfig
    synoconfbkp export --filepath "$DESTINATION"/@DSMConfig/DSMConfig_"$DATE"_$LOKALHOST.dss
    echo  "Lokale Sicherung der DSM-Systemkonfiguration erfolgreich." >> $LOG
    echo "" >> $LOG
  fi
fi

# Rotationszyklus für das Löschen von @Recycle, @Logfiles und @DSMConfig
#-------------------------------------------------------------------------
# Dateien im Ordner @Recycle die älter als x Tage sind, löschen.
if [ -z "$STOP" ] && [ -z "$RSYNC_CODE" ]; then
  if $TARGET_TEST -d "$DESTINATION"/@Recycle/; then
    if [ -z "$STOP" ] && [ -n "$RECYCLE_ROTATE" ] && [ -z "$ERROR" ]; then
      $FIND "$DESTINATION"/@Recycle/* -type d -mtime +$RECYCLE_ROTATE -exec rm -rf {} \;
      echo  "HINWEIS: Daten aus dem Ordner /@Recycle, die mehr als $RECYCLE_ROTATE Tage alt waren, wurden geloescht." >> $LOG
      echo "" >> $LOG
  fi
  fi
# Dateien im Ordner @Logfiles die älter als x Tage sind, löschen.
  if $TARGET_TEST -d `dirname $0`/@Logfiles/; then
    if [ -z "$STOP" ] && [ -n "$LOGFILES_ROTATE" ] && [ -z "$ERROR" ]; then
      find `dirname $0`/@Logfiles -name "*.log" -type f -mtime +$LOGFILES_ROTATE -exec rm {} \;
      echo  "HINWEIS: Daten aus dem Ordner /@Logfiles, die mehr als $LOGFILES_ROTATE Tage alt waren, wurden geloescht." >> $LOG
      echo "" >> $LOG
    fi
  fi
# Dateien im Ordner @DSMConfig die älter als x Tage sind, löschen.
  if  $TARGET_TEST -d "$DESTINATION"/@DSMConfig/; then
    if [ -z "$STOP" ] && [ -n "$DSMCONFIG_ROTATE" ] && [ -z "$ERROR" ]; then
      $FIND "$DESTINATION"/@DSMConfig -name "*.dss" -type f -mtime +$DSMCONFIG_ROTATE -exec rm {} \;
      echo  "HINWEIS: Daten aus dem Ordner /@DSMConfig, die mehr als $DSMCONFIG_ROTATE Tage alt waren, wurden geloescht." >> $LOG
      echo "" >> $LOG
    fi
  fi
fi

# Verschlüsselte Shares wieder aushängen..
#-------------------------------------------------------------------------
if [ $UNMOUNT -ne 0 ] && [ -n "$TARGETDS" ]; then
  if [ $UNMOUNT -ne 2 ]; then
IFS="
"
    TARGET_ESCAPE=$(echo $TARGET | sed -e 's/ /\\ /g')
    TARGET_DECRYPT_ESCAPE=$(echo $TARGET_DECRYPT | sed -e 's/ /\\ /g')
    IFS="$BACKIFS"
    if [ -n "$SSH_TO" ]; then
      DEST_DECRYPT="$TARGET_DECRYPT_ESCAPE"
    else
      DEST_DECRYPT="$TARGET_DECRYPT"
    fi
    if $TARGET_TEST -d /volume*/@"$DEST_DECRYPT"@ && $TARGET_TEST -d /volume*/"$DEST_DECRYPT"; then
      echo "Ziel: $TARGET_DECRYPT wurde ausgehangen" >> $LOG
      $SYNOSHARE_TARGET /usr/syno/sbin/synoshare --enc_unmount "$DEST_DECRYPT" >> $LOG
      sleep 10
    fi
  fi
fi
if [ $UNMOUNT -ne 0 ] && [ -n "$SOURCEDS" ]; then
  if [ $UNMOUNT -ne 3 ]; then
IFS="
"
  for SHARE in $SOURCES; do
    SHARE_ESCAPE=$(echo $SHARE | sed -e 's/ /\\ /g')
    SHARE_CUT="${SHARE#*/}"
    SHARE_DECRYPT="${SHARE_CUT%%/*}"
    SHARE_DECRYPT_ESCAPE=$(echo $SHARE_DECRYPT | sed -e 's/ /\\ /g')
    IFS="$BACKIFS"
    if [ -n "$SSH_FROM" ]; then
      SOURCE_DECRYPT="$SHARE_DECRYPT_ESCAPE"
    else
      SOURCE_DECRYPT="$SHARE_DECRYPT"
    fi
    if $SOURCE_TEST -d /volume*/@"$SOURCE_DECRYPT"@ && $SOURCE_TEST -d /volume*/"$SOURCE_DECRYPT"; then
      echo "Quelle: $SHARE_DECRYPT wurde ausgehangen" >> $LOG
      $SYNOSHARE_SOURCE /usr/syno/sbin/synoshare --enc_unmount "$SHARE_DECRYPT" >> $LOG
      sleep 10
    fi
  done
  fi
fi
unset KEYFILEPW

# Entfernten Server herunterfahren
#-------------------------------------------------------------------------
if [ $SHUTDOWN -ne 0 ] && [ -z "$RSYNC_CODE" ] && [ -z "$STOP" ] && [ -z "$ERROR" ]; then
  if [ -n "$SSH_FROM" ]; then
    $FROMSSH poweroff
    echo "Remoteserver $SSH_FROM wird heruntergefahren." >> $LOG
  elif [ -n "$SSH_TO" ]; then
    $TOSSH poweroff
    echo "Remoteserver $SSH_TO wird heruntergefahren." >> $LOG
  fi
fi

# Benachrichtigung an die DSM-Administratorengruppe sowie E-Mail senden
#-------------------------------------------------------------------------
if [ -n "$DSMNOTIFY" ]; then
  synodsmnotify @administrators "Script: $SCRIPTNAME" "$DSMNOTIFY"
fi
if [ -n "$EMAIL" ]; then
  if [ "$EMAILFAIL" -eq 1 ] && [ -z "$RSYNC_CODE" ] || [ -n "$STOP" ] || [ -n "$ERROR" ]; then
    ssmtp $EMAIL < $LOG
  elif [ "$EMAILFAIL" -eq 0 ]; then
    ssmtp $EMAIL < $LOG
  fi
fi

# Script beenden...
#-------------------------------------------------------------------------
if [ -z "$STOP" ] && [ -z "$RSYNC_CODE" ] && [ -z "$ERROR" ] && [ "$AUTORUN" -eq 1 ]; then
  exit 100
else
  exit $?
fi
