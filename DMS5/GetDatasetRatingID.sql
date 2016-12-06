/****** Object:  StoredProcedure [dbo].[GetDatasetRatingID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create Procedure GetDatasetRatingID
/****************************************************
**
**	Desc: Gets datasetRatingID for given  DatasetRating name
**
**	Return values: 0: failure, otherwise, datasetRatingID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@datasetRatingName varchar(80) = " "
)
As
	declare @datasetRatingID int
	set @datasetRatingID = 0

	SELECT @datasetRatingID = DRN_state_ID 
	FROM T_DatasetRatingName 
	WHERE (DRN_name = @datasetRatingName)
	
	return(@datasetRatingID)
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRatingID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetRatingID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRatingID] TO [Limited_Table_Write] AS [dbo]
GO
