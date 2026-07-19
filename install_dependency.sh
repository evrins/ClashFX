#!/bin/bash
set -e
echo "Build Clash core"

cd ClashFX/goClash
python3 build_clash_universal.py
cd ../..

echo "Pod install"
bundle install --jobs 4
bundle exec pod install
echo "delete old files"
rm -f ./ClashFX/Resources/Country.mmdb
rm -rf ./ClashFX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
gzip Country.mmdb
mv Country.mmdb.gz ./ClashFX/Resources/Country.mmdb.gz
echo "install dashboard"
tag="v3.15.0"
cd ClashFX/Resources
rm -rf dist.zip dist dashboard
curl -LO "https://github.com/Zephyruso/zashboard/releases/download/$tag/dist.zip"
unzip dist.zip
mv dist dashboard

if [ -d "dashboard/.git" ]; then
    cd dashboard
    rm -rf CNAME .git .nojekyll
    cd ..
fi
cd ../..
