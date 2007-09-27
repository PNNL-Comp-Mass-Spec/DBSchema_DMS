/****** Object:  UserDefinedFunction [dbo].[GetArchiveVerificationMachine] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION dbo.GetArchiveVerificationMachine
/****************************************************
**
**	Desc: 
**		combs the log for most recent entry about archive verification
**		for given dataset
**
**	Return values: machine name as string
**
**	Parameters:
**	
**
**		Auth: grk
**		Date: 10/4/2005
**    
*****************************************************/
(
@dataset varchar(256)
)
RETURNS varchar(256)
AS
	BEGIN
		declare @machine varchar(1024)
		set @machine = ''


		SELECT     TOP 1 @machine = REPLACE(posted_by, 'ArchiveVerify: ', '')
		FROM         T_Log_Entries
		WHERE     (message = 'Verifying Archived dataset ' + @dataset)
		ORDER BY Entry_ID DESC

	RETURN @machine
	END


GO
GRANT EXECUTE ON [dbo].[GetArchiveVerificationMachine] TO [public]
GO
