/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItemCounts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDataPackageItemCounts
/****************************************************
**
**  Desc: Adds new or edits existing T_Data_Package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	mem
**	Date:	06/09/2009 mem - Code ported from procedure UpdateDataPackageItems
**			06/10/2009 mem - Updated to support item counts of zero
**			06/10/2009 grk - Added update for total count
**			12/31/2013 mem - Added support for EUS Proposals
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@packageID int,
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @JobCount int = 0
	declare @DatasetCount int = 0
	declare @ProposalCount int = 0
	declare @ExperimentCount int = 0
	declare @BiomaterialCount int = 0
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	
	set @packageID = IsNull(@packageID, -1)
	set @message = ''

	---------------------------------------------------
	-- Determine the new item counts for this data package
	---------------------------------------------------
	--
	SELECT @JobCount = COUNT(*)
	FROM T_Data_Package_Analysis_Jobs
	WHERE Data_Package_ID = @packageID

	SELECT @DatasetCount = COUNT(*)
	FROM T_Data_Package_Datasets
	WHERE Data_Package_ID = @packageID

	SELECT @ProposalCount = COUNT(*)
	FROM T_Data_Package_EUS_Proposals
	WHERE Data_Package_ID = @packageID

	SELECT @ExperimentCount = COUNT(*)
	FROM T_Data_Package_Experiments
	WHERE Data_Package_ID = @packageID

	SELECT @BiomaterialCount = COUNT(*)
	FROM T_Data_Package_Biomaterial
	WHERE Data_Package_ID = @packageID

	---------------------------------------------------
	-- Update the item counts for this data package
	---------------------------------------------------
	--
	UPDATE T_Data_Package
	SET Analysis_Job_Item_Count = @JobCount,
        Dataset_Item_Count = @DatasetCount,
        EUS_Proposal_Item_Count = @ProposalCount,
        Experiment_Item_Count = @ExperimentCount,
        Biomaterial_Item_Count = @BiomaterialCount,
        Total_Item_Count = @JobCount + @DatasetCount + @ExperimentCount + @BiomaterialCount		-- Exclude EUS proposals from this total
	WHERE ID = @packageID

	---------------------------------------------------
	--  Exit
	---------------------------------------------------

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemCounts] TO [DDL_Viewer] AS [dbo]
GO
