# Automated Redpill Loader

This particular project was created to facilitate my testing with Redpill and I decided to share it with other users.

It is still in alpha stage, with little documentation, but it is functional.

I tried to make the system as user-friendly as possible, to make life easier. The loader automatically detects which device is being used, SATADom or USB, detecting its VID and PID correctly. redpill-lkm has been edited to allow booting the kernel without setting the variables related to network interfaces so the loader (and user) doesn't have to worry about that.

More information will be added in the future.
