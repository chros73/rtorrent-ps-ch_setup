#!/bin/bash
# Calculates and prints elapsed time in the form of "6 years, 5 months, 18 days, 02:40:00" (year/month info isn't shown if their value is 0)
# Usage: getElapsedTime.sh current_timestamp startup_timestamp


# checking parameter count
[ ! $# -ge 2 ] && echo -n "" && exit 0;


# get difference
let difftimestamp=$1-$2;
[ "$difftimestamp" -lt 0 ] && difftimestamp=0;


# get year, month, day numbers as one string with 'date' util to get accurate result
DATESTR=$(date -d @$difftimestamp '+%y:%m,%d');

# get year, month, day values out of it
YEARD=${DATESTR%:*};
MONTHYEARD=${DATESTR%,*};
MONTHD=${MONTHYEARD##*:};
DAYD=${DATESTR##*,};

# get the correct numbers: substract appropriate numbers from the above values, taking care of possible leading zeros in the values above
YEAR=$((10#$YEARD-70));
MONTH=$((10#$MONTHD-1));
DAY=$((10#$DAYD-1));


# get hours, minutes, seconds
HOUR=$((difftimestamp/60/60%24));
MIN=$((difftimestamp/60%60));
SEC=$((difftimestamp%60));


# deal with plural in stings
[ "$YEAR" -lt 2 ] && YEARP="" || YEARP="s";
[ "$MONTH" -lt 2 ] && MONTHP="" || MONTHP="s";
[ "$DAY" -lt 2 ] && DAYP="" || DAYP="s";

# don't display year or month info if their value is 0
[ "$YEAR" -eq 0 ] && YEARSTR="" || YEARSTR="$YEAR year$YEARP, ";
[ "$MONTH" -eq 0 ] && MONTHSTR="" || MONTHSTR="$MONTH month$MONTHP, ";


# print the result
printf '%s%s%d day%s, %02d:%02d:%02d' "$YEARSTR" "$MONTHSTR" "$DAY" "$DAYP" "$HOUR" "$MIN" "$SEC";

