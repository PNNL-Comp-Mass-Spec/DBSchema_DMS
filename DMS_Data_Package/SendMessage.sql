/****** Object:  StoredProcedure [dbo].[SendMessage] ******/
CREATE PROCEDURE [dbo].[SendMessage]
	@message [nvarchar](4000),
	@queue [nvarchar](4000),
	@server [nvarchar](4000),
	@port [int],
	@result [nvarchar](4000) OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [SqlClassLibrary].[StoredProcedures].[SendMessage]
GO
GRANT EXECUTE ON [dbo].[SendMessage] TO [DMS_SP_User]
GO
