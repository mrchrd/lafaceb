#!/bin/sh

URL="https://airtime.lafaceb.live"

get_current_track() {
  name=$(curl -ks ${URL}/api/live-info | jq -r .current.name)

  showFull=$(echo ${name} | cut -d'-' -f1 | xargs echo -n)
  show=$(echo ${showFull} | cut -d'#' -f1 | xargs echo -n)
  episode=$(echo ${showFull} | cut -d'#' -f2 | xargs echo -n)
  artist=$(echo ${name} | cut -d'-' -f2 | xargs echo -n)

  echo "En ondes:"
  echo ""
  echo "${show} #${episode} - ${artist}"
  echo ""
}

get_week_schedule() {
  scheduleFull=$(curl -ks "${URL}/api/week-info" | jq .)

  echo "En vedette:"
  weekDays="monday tuesday wednesday thursday friday saturday sunday nextmonday nexttuesday nextwednesday nextthursday nextfriday nextsaturday nextsunday"
  for d in ${weekDays}; do
    scheduleDay=$(echo ${scheduleFull} | jq .${d})
    day=$(echo ${scheduleDay} | jq -r .[0].starts)
    yyyymmdd=$(echo ${day} | cut -d' ' -f1)
    mmdd=$(echo ${yyyymmdd} | cut -d'-' -f3,2)
    ammdd="$(date -d ${yyyymmdd} +%a) ${mmdd}"

    echo ""
    echo "${ammdd}"

    n=$(echo ${scheduleDay} | jq length)
    for i in $(seq 0 $((n-1))); do
      s=$(echo ${scheduleDay} | jq -r .[$i])
      show=$(echo $s | jq -r .name)
      starts=$(echo $s | jq -r .starts | cut -d' ' -f2)

      echo "${starts} ${show}"
    done
  done
  echo ""
}

get_current_track
get_week_schedule
