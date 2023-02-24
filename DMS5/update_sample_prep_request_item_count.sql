/****** Object:  StoredProcedure [dbo].[UpdateSamplePrepRequestItemCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateSamplePrepRequestItemCount]
/****************************************************
**
**  Desc:
**      Updates data package item count
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/05/2013 grk - initial release
**
*****************************************************/
(
    @samplePrepRequestID int
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    DECLARE
        @biomaterialItemCount  INT = 0,
        @sampleSubmissionItemCount  INT = 0,
        @materialContainersItemCount  INT = 0,
        @experimentGroupItemCount  INT = 0,
        @experimentItemCount  INT = 0,
        @hpLCRunsItemCount  INT = 0,
        @dataPackagesItemCount  INT = 0,
        @datasetItemCount INT = 0,
        @requestedRunItemCount INT = 0,
        @totalItemCount  INT = 0

        SELECT @biomaterialItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'biomaterial'
        SELECT @sampleSubmissionItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'sample_submission'
        SELECT @materialContainersItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'material_container'
        SELECT @experimentGroupItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'experiment_group'
        SELECT @experimentItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'experiment'
        SELECT @hpLCRunsItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'prep_lc_run'
        SELECT @datasetItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'dataset'
        SELECT @requestedRunItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'requested_run'
        SELECT @totalItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID

    UPDATE T_Sample_Prep_Request
    SET
--      Last_Modified = GETDATE(),
        Biomaterial_Item_Count = @biomaterialItemCount ,
        Sample_Submission_Item_Count = @sampleSubmissionItemCount ,
        Material_Containers_Item_Count = @materialContainersItemCount ,
        Experiment_Group_Item_Count = @experimentGroupItemCount ,
        Experiment_Item_Count = @experimentItemCount ,
        HPLC_Runs_Item_Count = @hpLCRunsItemCount ,
        Requested_Run_Item_Count =  @requestedRunItemCount,
        Dataset_Item_Count = @datasetItemCount,
        Total_Item_Count = @totalItemCount
    WHERE dbo.T_Sample_Prep_Request.ID = @samplePrepRequestID

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSamplePrepRequestItemCount] TO [DDL_Viewer] AS [dbo]
GO
