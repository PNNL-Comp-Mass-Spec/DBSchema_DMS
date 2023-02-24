/****** Object:  StoredProcedure [dbo].[GetDatasetTypeID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetDatasetTypeID
/****************************************************
**
**	Desc: Gets DatasetTypeID for given for given dataset type name
**
**	Return values: 0: failure, otherwise, campaign ID
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	01/26/2001
**			09/02/2010 mem - Expand @datasetType to varchar(50)
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@datasetType varchar(50) = ''
)
As
	Set NoCount On

	Declare @datasetTypeID int = 0
	
	SELECT @datasetTypeID = DST_Type_ID 
	FROM T_DatasetTypeName 
	WHERE DST_name = @datasetType
	
	return @datasetTypeID
	

GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetTypeID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetTypeID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetTypeID] TO [Limited_Table_Write] AS [dbo]
GO
