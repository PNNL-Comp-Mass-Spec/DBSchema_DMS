/****** Object:  StoredProcedure [dbo].[GetDatasetRequestID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetDatasetRequestID
/****************************************************
**
**	Desc: Gets Dataset Request ID for given Request name
**
**	Return values: 0: failure, otherwise, dataset request ID
**
**	Parameters: 
**
**		Auth: kja
**		Date: 08/18/2006
**    
*****************************************************/
(
	@requestNum varchar(64) = " "
)
As
	declare @datasetRequestID int
	set @datasetRequestID = 0
	SELECT @datasetRequestID = Exp_ID FROM T_Requested_Run WHERE (RDS_Name = @requestNum)
	return(@datasetRequestID)
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRequestID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetRequestID] TO [PNL\D3M578] AS [dbo]
GO
