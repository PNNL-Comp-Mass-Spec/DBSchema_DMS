USE master
GO

print 'Get the latest version of sp_WhoIsActive at http://whoisactive.com'
print 'See also http://sqlblog.com/blogs/adam_machanic/'

/* Example stored procedure calls */

exec sp_WhoIsActive

exec sp_whoisactive @help=1

exec sp_whoisactive @get_plans=1

GO
