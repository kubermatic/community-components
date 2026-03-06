# Portworx

Test setup at GCE was NOT successful it ended with.
```
Type    ID                      Resource                                Severity        Count   LastSeen                FirstSeen               Description
NODE    NodeStartFailure        83bede87-1fb5-4c2c-8625-e662b8a4fb99    ALARM           1       Feb 4 18:42:11 UTC 2026 Feb 4 18:42:11 UTC 2026 Failed to start Portworx: failed to initialize internal kvdb: failed to setup kvdb proxy: failed to setup internal kvdb: failed to provision internal kvdb: failed to start internal kvdb on this node: failed in initializing drives on this node: device /dev/sdb has a filesystem on it with labels any:pwx0: uuid 6d3b7f91-7e8a-4586-4d64-60a3ab7f4840
NODE    InternalKvdbSetupFailed 83bede87-1fb5-4c2c-8625-e662b8a4fb99    ALARM           1       Feb 4 18:42:11 UTC 2026 Feb 4 18:42:11 UTC 2026 failed to setup internal kvdb: failed to provision internal kvdb: failed to start internal kvdb on this node: failed in initializing drives on this node: device /dev/sdb has a filesystem on it with labels any:pwx0: uuid 6d3b7f91-7e8a-4586-4d64-60a3ab7f4840
```