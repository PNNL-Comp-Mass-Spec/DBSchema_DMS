/****** Object:  StoredProcedure [dbo].[update_sample_prep_request_item_count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_sample_prep_request_item_count]
/****************************************************
**
**  Desc:
**      Update sample prep request item counts in T_Sample_Prep_Request for the given prep request
**
**      Source data comes from table T_Sample_Prep_Request_Items,
**      which is populated by procedure update_sample_prep_request_items
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/05/2013 grk - Initial release
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/19/2023 mem - No longer populate column sample_submission_item_count since t_sample_prep_request_items does not track sample_submission items
**                           (sample submission items are associated with a campaign and container, but not a sample prep request)
**
*****************************************************/
(
    @samplePrepRequestID int
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @biomaterialItemCount int = 0
    Declare @materialContainersItemCount int = 0
    Declare @experimentGroupItemCount int = 0
    Declare @experimentItemCount int = 0
    Declare @hpLCRunsItemCount int = 0
    Declare @dataPackagesItemCount int = 0
    Declare @datasetItemCount int = 0
    Declare @requestedRunItemCount int = 0
    Declare @totalItemCount int = 0

    SELECT @biomaterialItemCount        = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'biomaterial'
    SELECT @materialContainersItemCount = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'material_container'
    SELECT @experimentGroupItemCount    = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'experiment_group'
    SELECT @experimentItemCount         = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'experiment'
    SELECT @hpLCRunsItemCount           = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'prep_lc_run'
    SELECT @datasetItemCount            = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'dataset'
    SELECT @requestedRunItemCount       = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID AND Item_Type = 'requested_run'
    SELECT @totalItemCount              = COUNT(*) FROM T_Sample_Prep_Request_Items WHERE ID = @samplePrepRequestID

    UPDATE T_Sample_Prep_Request
    SET Biomaterial_Item_Count = @biomaterialItemCount,
        Material_Containers_Item_Count = @materialContainersItemCount,
        Experiment_Group_Item_Count = @experimentGroupItemCount,
        Experiment_Item_Count = @experimentItemCount,
        HPLC_Runs_Item_Count = @hpLCRunsItemCount,
        Requested_Run_Item_Count =  @requestedRunItemCount,
        Dataset_Item_Count = @datasetItemCount,
        Total_Item_Count = @totalItemCount
        -- Leave Last_Modified unchanged
    WHERE dbo.T_Sample_Prep_Request.ID = @samplePrepRequestID

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_sample_prep_request_item_count] TO [DDL_Viewer] AS [dbo]
GO
