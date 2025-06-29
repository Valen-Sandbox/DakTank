# DakTank

It's been ages since I've updated this little readme panel. The mod has come a long way from the little "WWII" arcady combat mod it once was, now there's WWII, cold war, and modern vehicles, detailed post penetration functionality, multiple types of composite armors and types of standard armor available, loads of guns and ammo types, great optimizations, and more to come.

Extra note for server owners:
Are you running a server? Are your projectiles moving slow instead of fast?

Put this line in your server's SERVER.CFG

lua_run local tbl = physenv.GetPerformanceSettings() tbl.MaxVelocity = 1000000 physenv.SetPerformanceSettings(tbl)