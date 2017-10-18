#!/bin/sh

# Zeichenkette auf der DS sowie angeschlossenen Datenträgern suchen
# ------------------------------------------------------------------------
# Hierbei werden nicht nur extern angeschlossene USB- und SATA           |
# Datenträger, sondern auch alle Volume innerhalb der Diskstation        |
#                                                                        |
# Es ist nicht erforderlich, den kompletten Script-Dateinamen anzugeben. |
# Es reicht die Eingabe einer Zeichenkette, die in jedem auszuführenden  |
# Script-Dateinamen enthalten sein muss.                                 |
# Beispiele für die Zeichenkette: "start" = start_Backup_Filme.sh        |
# start_Filme.sh oder auch _start_Filme_sichern.sh                       |
#                                                                        |
# Soll eine Scriptausführung bei einer bestimmten Zeichenkette verhindert|
# werden, weil sich ein Script z.B. noch im Testbetrieb befindet, kann   |
# dies über die Variable EXCLUDE_STRING gesteuert werden.                |
# Beispiel: start_Backup_Filme.sh wird ausgeführt test_Backup_Filme.sh   |
# jedoch nicht.                                                          |
#-------------------------------------------------------------------------
SCRIPT_STRING="start"
EXCLUDE_STRING="test"


if [ "$EXCLUDE_STRING" ]
  then
    find /volume*/ -type f -name "*$SCRIPT_STRING*.sh" ! -name "*$EXCLUDE_STRING*" -exec sh {} \;
  else
    find /volume*/ -type f -name "*$SCRIPT_STRING*.sh" -exec sh {} \;
fi
