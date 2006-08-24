/****** Object:  StoredProcedure [dbo].[GetAnalysisToolID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure GetAnalysisToolID
/****************************************************
**
**	Desc: Gets toolID for given dataset name
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
		@toolName varchar(80) = " "
)
As
	declare @toolID int
	set @toolID = 0
	SELECT @toolID = AJT_toolID FROM T_Analysis_Tool WHERE (AJT_toolName = @toolName)
	return(@toolID)
GO
GRANT EXECUTE ON [dbo].[GetAnalysisToolID] TO [DMS_SP_User]
GO
