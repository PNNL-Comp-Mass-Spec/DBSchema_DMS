use Master
go

CREATE USER [MTUser] FOR LOGIN [mtuser] WITH DEFAULT_SCHEMA=[MTUser]
CREATE USER [MTAdmin] FOR LOGIN [mtadmin] WITH DEFAULT_SCHEMA=[MTAdmin]

GRANT EXECUTE ON [sys].[sp_OACreate] TO [MTUser]
GRANT EXECUTE ON [sys].[sp_OADestroy] TO [MTUser]
GRANT EXECUTE ON [sys].[sp_OAMethod] TO [MTUser]

GRANT EXECUTE ON [sys].[sp_OACreate] TO [PNL\MTSProc]
GRANT EXECUTE ON [sys].[sp_OADestroy] TO [PNL\MTSProc]
GRANT EXECUTE ON [sys].[sp_OAMethod] TO [PNL\MTSProc]
GRANT EXECUTE ON [sys].[xp_cmdshell] TO [PNL\MTSProc]
