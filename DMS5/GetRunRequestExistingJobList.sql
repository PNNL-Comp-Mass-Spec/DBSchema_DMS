/****** Object:  UserDefinedFunction [dbo].[GetRunRequestExistingJobList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetRunRequestExistingJobList]
/****************************************************
**
**  Desc: 
**      Builds a delimited list of existing jobs
**      for the given analysis job request, using
**      GetRunRequestExistingJobListTab() to generate
**      the job list.
**
**  Return value: delimited list
**
**  Parameters: 
**
**  Auth:   mem
**  Date:   12/06/2005 mem - Initial version
**          03/27/2009 mem - Increased maximum size of the list to varchar(3500)
**          07/30/2019 mem - Use T_Analysis_Job_Request_Existing_Jobs instead of GetRunRequestExistingJobListTab
**    
*****************************************************/
(
    @requestID int
)
RETURNS varchar(3500)
AS
    BEGIN
        Declare @myRowCount Int = 0
        Declare @myError int = 0

        Declare @list varchar(3000) = null
    
        SELECT @list = Coalesce(@list + ', ' + FilterQ.JobText, FilterQ.JobText)
        FROM 
        (
            SELECT TOP 100 PERCENT Convert(varchar(19), Job) AS JobText
            FROM T_Analysis_Job_Request_Existing_Jobs
            WHERE Request_ID = @requestID
            ORDER BY Job
        ) FilterQ
                
        If IsNull(@list, '') = ''
            set @list = '(none)'

        RETURN @list
    END


GO
GRANT VIEW DEFINITION ON [dbo].[GetRunRequestExistingJobList] TO [DDL_Viewer] AS [dbo]
GO
