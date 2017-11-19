#!/bin/sh

# Kurze Funktionsbeschreibung
# ------------------------------------------------------------------------
# Das Script kann manuell oder automatisiert über den Aufgabenplaner     |
# als "root" ausgeführt werden, je nachdem ob der externe Datenträger    |
# temporär oder permanent mit der DS verbunden wird.                     |
# Nach dem Start des Scriptes werden alle USB- sowie SATA Anschlüsse der |
# DS nach extern angeschlossenen Datenträgern durchsucht um im jeweiligen|
# Wurzelverzeichnis ein oder mehrere abgelegte Scripte zu lokalisieren.  |
# Es besteht also die Möglichkeit mehrere Scripte auszuführen, die dazu  |
# noch auf unterschiedlichen Datenträgern liegen. Dabei ist es auch nicht|
# zwingend erforderlich, das alle Script permanent verfügbar sein müssen.|
# Wird ein Script oder mehrere Scripte gefunden, werden diese            |
# ausgeführt und somit das eigentliche Backupsystem angestoßen.          |
# Im Vorfeld muß natürlich noch das rsync.sh Script den jeweiligen       |
# Bedürfnissen angepasst werden.                                         |
# ------------------------------------------------------------------------
SCRIPTNAME="Diskstation-Backup.sh"

# ------------------------------------------------------------------------
# Ab hier bitte nichts mehr ändern                                       |
# ------------------------------------------------------------------------
for SCRIPT in $SCRIPTNAME
  do
  # Durchsuche volumeUSB1
  if [ -f /volumeUSB1/usbshare/$SCRIPT ]; then
    sh /volumeUSB1/usbshare/$SCRIPT
  fi
  # Durchsuche volumeUSB2
  if [ -f /volumeUSB2/usbshare/$SCRIPT ]; then
    sh /volumeUSB2/usbshare/$SCRIPT
  fi
  # Durchsuche volumeUSB3
  if [ -f /volumeUSB3/usbshare/$SCRIPT ]; then
    sh /volumeUSB3/usbshare/$SCRIPT
  fi
  # Durchsuche volumeSATA
  if [ -f /volumeSATA/satashare/$SCRIPT ]; then
    sh /volumeSATA/satashare/$SCRIPT
  fi
done
