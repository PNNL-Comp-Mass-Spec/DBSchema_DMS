/****** Object:  UserDefinedFunction [dbo].[JobBacklogOnDateByResultType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.JobBacklogOnDateByResultType
/****************************************************
**
**	Desc: 
**		returns count of number of jobs in backlog on given date
**
**		Auth: grk
**		Date: 1/21/2005
**			  1/22/2005 mem - Added two additional parameters
**			  1/25/2005 grk - modified to use result type
**    
*****************************************************/
(
@targDate datetime,
@resultType varchar(64) = 'Peptide_Hit', --'HMMA_Peak', 'Peptide_Hit', 'SIC', 'TIC'                              
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
			AJ_AnalysisToolID IN (
				SELECT AJT_toolID
				FROM T_Analysis_Tool
				WHERE (AJT_resultType = @resultType)
			)
	RETURN @backlog
	END

GO
