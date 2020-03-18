# bash -c 'while [ 0 ]; do sh ./upload_to_s3.sh; sleep 0.5;done'

# aws s3 cp ./index.html s3://www.millerteamleague.com/
# aws s3 cp ./nba/draft.html s3://www.millerteamleague.com/
aws s3 cp ./nba/nba_2019.json s3://www.millerteamleague.com/
# aws s3 cp ./nba/index.html s3://www.millerteamleague.com/nba/
