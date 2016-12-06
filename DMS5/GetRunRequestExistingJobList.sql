/****** Object:  UserDefinedFunction [dbo].[GetRunRequestExistingJobList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetRunRequestExistingJobList]
/****************************************************
**
**	Desc: 
**  Builds a delimited list of existing jobs
**  for the given analysis job request, using
**  GetRunRequestExistingJobListTab() to generate
**  the job list.
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	12/06/2005
**			03/27/2009 mem - Increased maximum size of the list to varchar(3500)
**    
*****************************************************/
(
	@requestID int
)
RETURNS varchar(3500)
AS
	BEGIN
		declare @myRowCount int
		declare @myError int
		set @myRowCount = 0
		set @myError = 0

		declare @list varchar(3000)
		set @list = ''
	
		SELECT 
			@list = @list + CASE WHEN @list = '' THEN JobText
							ELSE ', ' + JobText
							END
		FROM 
		(
			SELECT	TOP 100 PERCENT Convert(varchar(19), Job) as JobText
			FROM	GetRunRequestExistingJobListTab(@RequestID)
			ORDER BY Job
		) TX
				
		if IsNull(@list, '') = ''
			set @list = '(none)'

		RETURN @list
	END


GO
GRANT VIEW DEFINITION ON [dbo].[GetRunRequestExistingJobList] TO [DDL_Viewer] AS [dbo]
GO
