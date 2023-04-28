/****** Object:  UserDefinedFunction [dbo].[job_backlog_on_date_by_tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[job_backlog_on_date_by_tool]
/****************************************************
**
**  Desc:
**      returns count of number of jobs in backlog on given date
**
**  Auth:   grk
**  Date:   01/21/2005
**          01/22/2005 mem - Added two additional parameters
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @targDate datetime,
    @analysisJobToolID int = 1,             -- 1 = Sequest, 2 = ICR-2LS, 13 = MASIC_Finnigan
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
            AJ_AnalysisToolID = @AnalysisJobToolID
    RETURN @backlog
    END

GO
GRANT VIEW DEFINITION ON [dbo].[job_backlog_on_date_by_tool] TO [DDL_Viewer] AS [dbo]
GO
