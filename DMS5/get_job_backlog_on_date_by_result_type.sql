/****** Object:  UserDefinedFunction [dbo].[get_job_backlog_on_date_by_result_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_backlog_on_date_by_result_type]
/****************************************************
**
**  Desc:
**      returns count of number of jobs in backlog on given date
**
**  Auth:   grk
**  Date:   01/21/2005
**          01/22/2005 mem - Added two additional parameters
**          01/25/2005 grk - modified to use result type
**          02/23/2023 bcg - Rename function and parameters to a case-insensitive match to Postgres
**          04/27/2023 mem - Rename function to start with "get_"
**
*****************************************************/
(
    @targDate datetime,
    @resultType varchar(64) = 'Peptide_Hit', --'HMMA_Peak', 'Peptide_Hit', 'SIC', 'TIC'
    @processorNameFilter varchar(64) = '%'
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
GRANT VIEW DEFINITION ON [dbo].[get_job_backlog_on_date_by_result_type] TO [DDL_Viewer] AS [dbo]
GO
