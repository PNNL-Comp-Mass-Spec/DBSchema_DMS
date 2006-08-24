/****** Object:  StoredProcedure [dbo].[GetDatasetID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetDatasetID
/****************************************************
**
**	Desc: Gets datasetID for given dataset name
**
**	Return values: 0: failure, otherwise, dataset ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
		@datasetNum varchar(80) = " "
)
As
	declare @datasetID int
	set @datasetID = 0
	SELECT @datasetID = Dataset_ID FROM T_Dataset WHERE (Dataset_Num = @datasetNum)
	return(@datasetID)
GO
GRANT EXECUTE ON [dbo].[GetDatasetID] TO [DMS_SP_User]
GO
