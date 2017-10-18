#!/bin/sh

# Zeichenkette für Script-Dateinamen definieren
# ------------------------------------------------------------------------
# Es ist nicht erforderlich, den kompletten Script-Dateinamen anzugeben. |
# Es reicht die Eingabe einer Zeichenkette, die in jedem auszuführenden  |
# Script-Dateinamen enthalten sein muss.                                 |
# Beispiele für die Zeichenkette: "local" = local_Backup_Filme.sh        |
# local_Filme.sh oder auch Filme_local_sichern.sh                        |
#-------------------------------------------------------------------------
SCRIPT_STRING="start"

# ------------------------------------------------------------------------
# Ab hier bitte nichts mehr ändern                                       |
# ------------------------------------------------------------------------

for SCRIPT in /volume*/*share/*$SCRIPT_STRING*.sh
  do
    if [ -f $SCRIPT ]; then
    sh $SCRIPT
    fi
  done
