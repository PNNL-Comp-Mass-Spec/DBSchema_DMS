/****** Object:  StoredProcedure [dbo].[UpdateDMSFileInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDMSFileInfoXML
/****************************************************
**
**  Desc:
**		Calls S_UpdateDatasetFileInfoXML for the specified DatasetID
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	09/01/2010 mem - Initial Version
**    
*****************************************************/
(
	@DatasetID INT,
	@DeleteFromTableOnSuccess tinyint = 1,
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
		
	Declare @DatasetInfoXML xml

	--------------------------------------------
	-- Validate the inputs
	--------------------------------------------
	--
	set @DeleteFromTableOnSuccess = IsNull(@DeleteFromTableOnSuccess, 1)
	set @message = ''
	set @infoOnly = IsNull(@infoOnly, 0)
	
	SELECT @DatasetInfoXML = DS_Info_XML
	FROM dbo.T_Dataset_Info_XML
	WHERE Dataset_ID = @DatasetID
	
	IF NOT @DatasetInfoXML IS null
	BEGIN 
		EXEC @myError = S_UpdateDatasetFileInfoXML @DatasetID, @DatasetInfoXML, @message output, @infoOnly=@infoOnly
		
		If @myError = 0 And @infoOnly = 0 And @DeleteFromTableOnSuccess <> 0
			DELETE FROM dbo.T_Dataset_Info_XML WHERE Dataset_ID = @DatasetID
	END 

	return @myError
GO
