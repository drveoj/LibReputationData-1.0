## Description

LibReputationData-1.0 is a data store for addons that need the player's Reputations data. It has a simple API for data access and uses CallbackHandler-1.0 to propagate data changes.

## Why use? 

Provides a standardised method of accessing reputation and an event driven approach to reacting to changes to factions and standing. 

## Limitations

Currently does not update when the player changes their watched faction. This is because the Blizzard API does not have any such event fired (afaik)

## Credit

Based heavily off [LibArtifactData-1.0](https://www.wowace.com/addons/libartifactdata-1-0/) and [Reputation Bars](https://wow.curseforge.com/addons/reputation-bars/)

## Feedback

If you have problems using the library, run into any issues or have a feature request, please use the [issue tracker](https://github.com/joev/LibReputationData-1.0/issues).

## Further reading
  1. [How to use](https://github.com/joev/LibReputationData-1.0/wiki/How-to-use)  
  2. [API](https://github.com/joev/LibReputationData-1.0/wiki/API)  
  3. [Events](https://github.com/joev/LibReputationData-1.0/wiki/Events)  
  4. [Data structure](https://github.com/joev/LibReputationData-1.0/wiki/Data-structure)  
