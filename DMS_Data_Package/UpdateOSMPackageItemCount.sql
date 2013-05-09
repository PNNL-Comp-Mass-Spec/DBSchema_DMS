/****** Object:  StoredProcedure [dbo].[UpdateOSMPackageItemCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOSMPackageItemCount]
/****************************************************
**
**	Desc:
**      Updates data package item count
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 
**          03/20/2013 grk - initial release
**
*****************************************************/
(
	@packageID int
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	DECLARE
		@campaignItemCount INT = 0,
		@biomaterialItemCount  INT = 0,
		@samplePrepRequestItemCount  INT = 0,
		@sampleSubmissionItemCount  INT = 0,
		@materialContainersItemCount  INT = 0,
		@experimentGroupItemCount  INT = 0,
		@experimentItemCount  INT = 0,
		@hpLCRunsItemCount  INT = 0,
		@dataPackagesItemCount  INT = 0,
		@datasetItemCount INT = 0,
		@requestedRunItemCount INT = 0,						
		@totalItemCount  INT = 0 	

		SELECT @campaignItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Campaigns'
		SELECT @biomaterialItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Biomaterial'
		SELECT @samplePrepRequestItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Sample_Prep_Requests'
		SELECT @sampleSubmissionItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Sample_Submissions'
		SELECT @materialContainersItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Material_Containers'
		SELECT @experimentGroupItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Experiment_Groups'
		SELECT @experimentItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Experiments'
		SELECT @hpLCRunsItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'HPLC_Runs'
		SELECT @dataPackagesItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Data_Packages'
		SELECT @datasetItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Datasets'
		SELECT @requestedRunItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID AND Item_Type = 'Requested_Runs'
		SELECT @totalItemCount = COUNT(*) FROM T_OSM_Package_Items WHERE OSM_Package_ID = @packageID 						

	UPDATE T_OSM_Package
	SET 
		Last_Modified = GETDATE(),		
		Campaign_Item_Count = @campaignItemCount,
		Biomaterial_Item_Count = @biomaterialItemCount ,
		Sample_Prep_Request_Item_Count = @samplePrepRequestItemCount ,
		Sample_Submission_Item_Count = @sampleSubmissionItemCount ,
		Material_Containers_Item_Count = @materialContainersItemCount ,
		Experiment_Group_Item_Count = @experimentGroupItemCount ,
		Experiment_Item_Count = @experimentItemCount ,
		HPLC_Runs_Item_Count = @hpLCRunsItemCount ,
		Data_Packages_Item_Count = @dataPackagesItemCount ,
		Requested_Run_Item_Count = 	@requestedRunItemCount,
		Dataset_Item_Count = @datasetItemCount,				
		Total_Item_Count = @totalItemCount    
	WHERE dbo.T_OSM_Package.ID = @packageID

GO
