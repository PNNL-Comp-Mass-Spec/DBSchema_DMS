/****** Object:  StoredProcedure [dbo].[GetDatasetID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetDatasetID
/****************************************************
**
**	Desc: Gets datasetID for given dataset name
**
**	Return values: 0: failure, otherwise, dataset ID
**
**	Auth:	grk
**	Date:	01/26/2001
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@datasetNum varchar(80) = " "
)
As
	Set NoCount On

	Declare @datasetID int = 0

	SELECT @datasetID = Dataset_ID
	FROM T_Dataset
	WHERE Dataset_Num = @datasetNum

	return(@datasetID)
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetID] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetID] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetID] TO [Limited_Table_Write] AS [dbo]
GO
