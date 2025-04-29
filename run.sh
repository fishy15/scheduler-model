raco exe src/runner.rkt  # make sure up to date

invs=(
    "right-to-work"
    "right-to-work-swb"
    "moves-from-busiest"
    "moves-from-busiest-swb"
    "overloaded-to-idle"
    "overloaded-to-idle-swb"
    "overloaded-to-idle-cfs"
    "overloaded-to-idle-cfs-swb"
)

for inv in "${invs[@]}"; do
    for f in data/*; do
        echo "$inv --- $f"
        src/runner "$f" "$inv" bench
    done
done
