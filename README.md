# Fairlaunch-Token
fairlaunch token, ignore bot and frontrun prevent.

added features:
1. max allowned gasPrice to prevent frontrun txs.
2. only originOwner can start dex listing.
3. at dex listing time, transfer fee started at 100% and reduced 1% every 1% listingDuration seconds. Fee removed once listing finised (after listingDuration).
4. transferFee affected after dex listing.
