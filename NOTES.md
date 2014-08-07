Notes
=========
---
Why Core Data ?
-------
In this project I'm using Core Data. I never had the opportunity to use it before, but it seemed to be the best fit for our case. Entity validations and requests might not be perfect, but like I said, it's the first time I use it.

---
Why Google Task ?
------
An online storage was needed to meet the requirements of the app, Google Tasks was the simpliest online service having API and pre-built librairies I've known of. Unfortunately, the Google Objective C library wasn't up to date. I had to fix some issues about date formatting, and JSON conversions.

---
Any help ?
------
I used the GTSyncManager of the [GTasksMaster project](https://github.com/kurthardin/GTaskMaster) found on GitHub but had to adapt it to my code, and rewrite some things to make it work as I wanted. (Sync priority when conflicts etc...)

---
Testing
-----
I'm relatively new to testing, as I never wrote tests in past office work, and barely tried them in personnal projects. I never had the time to get a proper look at how to write good tests, but I'm really interested in test-driven development, etc.

I wrote some basic tests for this app, but I hadn't time or expertise to write some tests with HTTP mockups regarding the synchronisation process, etc.
