/****** Object:  UserDefinedFunction [dbo].[GetDMSFileStoragePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetDMSFileStoragePath
/****************************************************
**
**	Desc: 
**	Returns internal path
**
**	Return values:
**
**	Auth:	grk
**	Date:	05/12/2010
**    
*****************************************************/
(
	@campaign varchar(64),
	@ID varchar(12),
	@type varchar(32)
)
RETURNS varchar(512)
AS
Begin
	declare @filePath varchar(512)
	
	SELECT @filePath = 
		CASE 
			WHEN @ID IS NULL THEN ''
			WHEN @type = 'sample_submission' THEN 'Campaigns\Campaign_' + REPLACE(@campaign, ' ', '_') + '\Shipment_Receiving\Sample_Sub_' + @ID
			WHEN @type = 'prep_lc' THEN 'Prep_LC_Run_' + @ID
			ELSE '' END 

	RETURN @filePath
End


GO
GRANT EXECUTE ON [dbo].[GetDMSFileStoragePath] TO [DMS2_SP_User] AS [dbo]
GO
