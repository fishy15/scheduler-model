raco exe src/runner.rkt  # make sure up to date
for f in data/*; do
    echo "$f"
    time src/runner "$f" right-to-work > /dev/null
    time src/runner "$f" right-to-work-swb > /dev/null
    time src/runner "$f" moves-from-busiest > /dev/null
    time src/runner "$f" moves-from-busiest-swb > /dev/null
    time src/runner "$f" overloaded-to-idle > /dev/null
    time src/runner "$f" overloaded-to-idle-swb > /dev/null
    time src/runner "$f" overloaded-to-idle-cfs > /dev/null
    time src/runner "$f" overloaded-to-idle-cfs-swb > /dev/null
done
