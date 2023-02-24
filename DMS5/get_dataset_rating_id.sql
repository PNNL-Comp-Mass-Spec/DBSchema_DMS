/****** Object:  StoredProcedure [dbo].[GetDatasetRatingID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure GetDatasetRatingID
/****************************************************
**
**	Desc: Gets datasetRatingID for given  DatasetRating name
**
**	Return values: 0: failure, otherwise, datasetRatingID
**
**	Auth:	grk
**	Date:	01/26/2001
**			08/03/2017 mem - Add set nocount on
**    
*****************************************************/
(
	@datasetRatingName varchar(80) = " "
)
As
	set nocount on
	
	declare @datasetRatingID int = 0

	SELECT @datasetRatingID = DRN_state_ID 
	FROM T_DatasetRatingName 
	WHERE DRN_name = @datasetRatingName
	
	return @datasetRatingID
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRatingID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetRatingID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRatingID] TO [Limited_Table_Write] AS [dbo]
GO
