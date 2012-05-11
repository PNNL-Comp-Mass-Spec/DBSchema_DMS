/****** Object:  UserDefinedFunction [dbo].[JobBacklogOnDateByTool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.JobBacklogOnDateByTool
/****************************************************
**
**	Desc: 
**		returns count of number of jobs in backlog on given date
**
**		Auth: grk
**		Date: 1/21/2005
**			  1/22/2005 mem - Added two additional parameters
**    
*****************************************************/
(
@targDate datetime,
@AnalysisJobToolID int = 1,				-- 1 = Sequest, 2 = ICR-2LS, 13 = MASIC_Finnigan
@ProcessorNameFilter varchar(64) = '%'
)
RETURNS integer
AS
	BEGIN
		declare @backlog integer
		set @backlog = 0

		SELECT @backlog =  count(*)
		FROM T_Analysis_Job
		WHERE
			(DATEDIFF(Hour, @targDate, AJ_finish) >= 0) AND 
			(DATEDIFF(Hour, @targDate, AJ_created) <= 0) AND 
			(AJ_StateID = 4) AND 
			(AJ_assignedProcessorName LIKE @ProcessorNameFilter) AND
			AJ_AnalysisToolID = @AnalysisJobToolID
	RETURN @backlog
	END

GO
