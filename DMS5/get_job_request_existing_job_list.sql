/****** Object:  UserDefinedFunction [dbo].[GetJobRequestExistingJobList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetJobRequestExistingJobList]
/****************************************************
**
**  Desc:   Builds a comma separated list of existing jobs
**          for the given analysis job request
**          using T_Analysis_Job_Request_Existing_Jobs
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   12/06/2005
**          03/27/2009 mem - Increased maximum size of the list to varchar(3500)
**          07/30/2019 mem - Get jobs from T_Analysis_Job_Request_Existing_Jobs
**
*****************************************************/
(
    @requestID int
)
RETURNS varchar(3500)
AS
    BEGIN
        Declare @myRowCount Int = 0
        Declare @myError Int = 0

        Declare @list varchar(4000) = null

        SELECT @list = Coalesce(@list + ', ' + Cast(job AS varchar(19)), Cast(job AS varchar(19)))
        FROM T_Analysis_Job_Request_Existing_Jobs
        WHERE Request_ID = @requestID
        ORDER BY Job

        if IsNull(@list, '') = ''
            set @list = '(none)'

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobRequestExistingJobList] TO [DDL_Viewer] AS [dbo]
GO
