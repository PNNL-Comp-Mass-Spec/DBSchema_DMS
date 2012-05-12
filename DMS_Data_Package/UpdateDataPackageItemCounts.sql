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

	declare @JobCount int
	declare @DatasetCount int
	declare @ExperimentCount int
	declare @BiomaterialCount int
	
	set @JobCount = 0
	set @DatasetCount = 0
	set @ExperimentCount = 0
	set @BiomaterialCount = 0
	
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
        Experiment_Item_Count = @ExperimentCount,
        Biomaterial_Item_Count = @BiomaterialCount,
        Total_Item_Count = @JobCount + @DatasetCount + @ExperimentCount + @BiomaterialCount
	WHERE ID = @packageID

	---------------------------------------------------
	--  Exit
	---------------------------------------------------

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemCounts] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemCounts] TO [PNL\D3M580] AS [dbo]
GO
