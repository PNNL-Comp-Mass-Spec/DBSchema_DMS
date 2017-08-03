/****** Object:  StoredProcedure [dbo].[GetDatasetRequestID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetDatasetRequestID
/****************************************************
**
**	Desc: Gets Dataset Request ID for given Request name
**
**	Return values: 0: failure, otherwise, dataset request ID
**
**	Auth:	grk
**	Date:	08/18/2006
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@requestNum varchar(64) = " "
)
As
	Set NoCount On
	
	Declare @datasetRequestID int = 0

	SELECT @datasetRequestID = Exp_ID
	FROM T_Requested_Run
	WHERE RDS_Name = @requestNum

	return @datasetRequestID
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRequestID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRequestID] TO [Limited_Table_Write] AS [dbo]
GO
