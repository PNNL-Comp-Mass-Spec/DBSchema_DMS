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
**		That synonym calls UpdateDatasetFileInfoXML in DMS, which copies
**		data from T_Dataset_Info_XML in DMS_Capture to update:
**		- T_Dataset, columns Acq_Time_Start, Acq_Time_End, Scan_Count, File_Size_Bytes, File_Info_Last_Modified
**		- T_Dataset_Info, columns ScanCountMS, ScanCountMSn, Elution_Time_Max, etc.
**		- T_Dataset_ScanTypes
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
	    if @infoOnly > 0
	        Print 'Call S_UpdateDatasetFileInfoXML for DatasetID ' + cast(@DatasetID as varchar(12))
	        
		EXEC @myError = S_UpdateDatasetFileInfoXML @DatasetID, @DatasetInfoXML, @message output, @infoOnly=@infoOnly
		
		If @myError = 0 And @infoOnly = 0 And @DeleteFromTableOnSuccess <> 0
			DELETE FROM dbo.T_Dataset_Info_XML WHERE Dataset_ID = @DatasetID
	END 

	return @myError
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDMSFileInfoXML] TO [DDL_Viewer] AS [dbo]
GO
