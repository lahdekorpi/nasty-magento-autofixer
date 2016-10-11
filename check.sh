#!/bin/bash

TIMESTAMP=$(date +%s)
BASE="https://example.com"
URLS=( "/" "/somepage" "/some-category" "/some-product" "/?timestamp=$TIMESTAMP" "/customer/account/create/" "/customer/account/login/" )
ELEMENTS=( "title" "footer" )
EMAIL="your.name@example.com"

echo "[$(date)] Starting Magento checking now..."

function autorepair {
        echo "[$(date)] So it has come to this. We are going to try to autorepair Magento"
        # Flush cache
        echo "[$(date)] Flushing cache via bin/magento cache:flush"
        su www-data -s /bin/bash -c "/var/www/magento/bin/magento cache:flush"
        # Wait for a moment for things to calm down
        echo -ne "\n\nWaiting for a moment before moving on"
        for i in {1..5}
        do
                sleep 1
                echo -ne "."
        done
        echo " "
        # Restart Varnish, instead of banning just in case
        echo "[$(date)] Restarting Varnish via systemctl"
        systemctl restart varnish
        echo "[$(date)] Autorepair complete. Going to also send an alert now."
        alert
}

function alert {
        mail -s "Alert from FINEN production server on $(date)" "$EMAIL" < /tmp/monitor.log
}

function test {
        current=$(curl -vv -s "$BASE$url" | ./pup "$el text{}")
}

for url in "${URLS[@]}"
do
        for el in "${ELEMENTS[@]}"
        do
                sleep 1
                echo "[$(date)] Checking $BASE$url for a response in $el"
                test
                if [[ $? != 0 ]]; then
                        echo "Command failed"
                fi
                if [ -n "$current" ]; then
                        echo "OK"
                else
                        echo "Empty response for $el. Double checking in a bit"
                        sleep 10
                        test
                        if [ -n "$current" ]; then
                                echo "This time we got an OK, so not doing anything with this. But going to exit just in case."
                        else
                                echo "Still having problems..."
                                autorepair
                        fi
                        exit 1
                fi
        done
done

exit 0
