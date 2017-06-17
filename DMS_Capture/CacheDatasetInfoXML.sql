/****** Object:  StoredProcedure [dbo].[CacheDatasetInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.CacheDatasetInfoXML
/****************************************************
** 
**	Desc:	Caches the XML-based dataset info in table T_Dataset_Info_XML
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	05/03/2010 mem - Initial version
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
	@DatasetID int,
	@DatasetInfoXML xml,
	@message varchar(255) = '' output
)
As
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0

	Set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'CacheDatasetInfoXML', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End
	
	-----------------------------------------------
	-- Add/Update T_Dataset_Info_XML using a MERGE statement
	-----------------------------------------------
	--
	MERGE T_Dataset_Info_XML AS target
	USING 
		(SELECT  @DatasetID AS Dataset_ID, @DatasetInfoXML AS DS_Info_XML
		) AS Source (Dataset_ID, DS_Info_XML)
	ON (target.Dataset_ID = Source.Dataset_ID)
	WHEN Matched 
		THEN UPDATE 
			Set	DS_Info_XML = source.DS_Info_XML, 
				Cache_Date = GetDate()
	WHEN Not Matched THEN
		INSERT ( Dataset_ID, DS_Info_XML, Cache_Date )
		VALUES (source.Dataset_ID, source.DS_Info_XML, GetDate())
	;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
Done:
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CacheDatasetInfoXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CacheDatasetInfoXML] TO [DMS_SP_User] AS [dbo]
GO
