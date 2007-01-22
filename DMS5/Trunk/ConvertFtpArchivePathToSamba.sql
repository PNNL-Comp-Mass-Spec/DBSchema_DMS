/****** Object:  UserDefinedFunction [dbo].[ConvertFtpArchivePathToSamba] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.ConvertFtpArchivePathToSamba
/****************************************************
**
**	Desc: 
**		Converts an FTP archive path for archive access via Samba
**
**	Return value: Samba archive path as string
**
**	Parameters: Archive path formulated for FTP access
**	
**
**		Auth: dac
**		Date: 01/18/2006
**    
*****************************************************/

	(
	@FtpArchPath varchar (256)
	)
RETURNS varchar(256)
AS
	BEGIN
		declare @SambaPath varchar(256)
		
		set @SambaPath = ISNULL(REPLACE(REPLACE(@FtpArchPath, '/nwfs/dmsarch/', '\\n2.emsl.pnl.gov\dmsarch\'), '/', '\'),'')
		
		RETURN @SambaPath
	END

GO
