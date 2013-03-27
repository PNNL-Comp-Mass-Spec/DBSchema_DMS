/****** Object:  UserDefinedFunction [dbo].[ExperimentsFromRequestMostRecentNDays] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION ExperimentsFromRequestMostRecentNDays
/****************************************************
**
**	Desc: 
**		Returns count of number of experiments made
**      from given sample prep request
**
**		Only includes experiments created within the most recent N days, specified by @days
**
**
**		Auth: mem
**		Date: 03/26/2013
**    
*****************************************************/
(
	@requestID int,
	@days int
)
RETURNS int
AS
	BEGIN
		declare @n int
		
		SELECT @n = COUNT(*)
		FROM   T_Experiments
		WHERE (EX_sample_prep_request_ID = @requestID) AND
		      DATEDIFF(DAY, EX_created, GETDATE()) < ISNULL(@days, 1) + 1		
		
 		RETURN @n
	END
GO
