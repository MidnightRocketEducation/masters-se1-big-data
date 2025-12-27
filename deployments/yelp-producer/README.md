Yelp producer daemon deployment consists of the following components

- Persistent volume claim for raw yelp data
- Persistent volume claim for server state
- Yelp daemon/server
    - Init container which fetches yelp data.



# Reseting the server
Under most circumstances reseting the PV claim for server state
and restarting the yelp-daemon container is enough. 
This means that yelp data does not need to be downloaded again. 
