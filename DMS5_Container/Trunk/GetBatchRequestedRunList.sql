/****** Object:  UserDefinedFunction [dbo].[GetBatchRequestedRunList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION GetBatchRequestedRunList
/****************************************************
**
**	Desc: 
**  Builds delimited list of requested runst for
**  given requested run batch
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/11/2006
**    
*****************************************************/
(
@batchID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		set @list = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN cast(ID as varchar(12))
								ELSE ', ' + cast(ID as varchar(12))
							END
		FROM         T_Requested_Run
		WHERE     (RDS_BatchID = @batchID)
		

		RETURN @list
	END


GO
