/****** Object:  StoredProcedure [dbo].[find_matching_datasets_for_job_request_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_matching_datasets_for_job_request_proc]
/****************************************************
**
**  Desc:
**      Return list of datasets for given analysis job request, showing how many jobs exist for each that match the parameters of the request
**      (regardless of whether or not the job is linked to the request)
**
**      Used by web page https://dms2.pnl.gov/helper_aj_request_datasets_ckbx/param
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
(
    @requestID int,
    @message varchar(512) output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @requestID = IsNull(@requestID, 0)

    Exec @myError = find_matching_datasets_for_job_request
                        @requestID,
                        @message = @message Output;

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_matching_datasets_for_job_request_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_matching_datasets_for_job_request_proc] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_matching_datasets_for_job_request_proc] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_matching_datasets_for_job_request_proc] TO [Limited_Table_Write] AS [dbo]
GO
