/****** Object:  StoredProcedure [dbo].[GetNewDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetNewDatasets
/****************************************************
**
**	Desc: Gets all datasets that are in "new" state
**
**	Return values: 0: success
**                 recordset containing dataset information
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
As
	/* set nocount on */
	SELECT Dataset_Num, DS_created, DS_instrument_name_ID, 
    DS_folder_name, DS_state_ID, Dataset_ID
	FROM T_Dataset
	WHERE (DS_state_ID = 1)
	return 0
GO
GRANT EXECUTE ON [dbo].[GetNewDatasets] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewDatasets] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewDatasets] TO [PNL\D3M578] AS [dbo]
GO
