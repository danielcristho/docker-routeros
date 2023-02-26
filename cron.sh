#!/usr/bin/env bash

# Cron fix
cd "$(dirname $0)"

function getTarballs
{
    curl https://mikrotik.com/download/archive -o - 2>/dev/null | \
        grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | \
        sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' | \
        grep -i vdi | \
        sed 's:.*/::' | \
        sort -V

    curl https://mikrotik.com/download -o - 2>/dev/null | \
        grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | \
        sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' | \
        grep -i vdi | \
        sed 's:.*/::' | \
        sort -V
}

function getTag
{
    echo "$1" | sed -r 's/chr\-(.*)\.vdi/\1/gi'
}

function checkTag
{
    git rev-list "$1" 2>/dev/null
}

getTarballs | while read line; do
    tag=`getTag "$line"`
    echo ">>> $line >>> $tag"

    if [ "x$(checkTag "$tag")" == "x" ]
        then

            url="https://download.mikrotik.com/routeros/$tag/chr-$tag.vdi.zip"
            if curl --output /dev/null --silent --head --fail "$url"; then
                echo ">>> URL exists: $url"
                curl -L -o "chr-$tag.vdi.zip" "$url"
                unzip -o "chr-$tag.vdi.zip"

                # create Docker image
                docker build -t mikrotik-routeros:$tag .

                # remove the VDI file and the Dockerfile
                rm "chr-$tag.vdi.zip"
                rm Dockerfile

                # commit changes and tag the release
                git add .
                git commit -m "Release of RouterOS changed to $tag" -a
                git push
                git tag "$tag"
                git push --tags
            else
                echo ">>> URL doesn't exist: $url"
            fi

        else
            echo ">>> Tag $tag has already been created"
    fi

done
