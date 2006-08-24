/****** Object:  UserDefinedFunction [dbo].[JobsInBatch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.JobsInBatch
/****************************************************
**
**	Desc: 
**		returns count of number of jobs in given batch
**
**
**		Auth: grk
**		Date: 2/27/2004
**    
*****************************************************/
	(
	@batchID int
	)
RETURNS int
AS
	BEGIN
		declare @n int
		SELECT     @n = COUNT(*) 
		FROM         T_Analysis_Job
		WHERE     (AJ_batchID = @batchID)
		
 		RETURN @n
	END


GO
