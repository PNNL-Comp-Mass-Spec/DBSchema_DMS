ALTER PROCEDURE dbo.RefreshDataPackageItemsUsingDMS
/****************************************************
**
**	Desc:
**      Updates metadata for items associated with the given data package
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 05/21/2009
**          06/10/2009 grk - changed size of item list to max
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - changed data type of @itemList from varchar(max) to text
**
*****************************************************/
(
	@packageID int	
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @message varchar(1024)
	set @message = ''

	---------------------------------------------------
	-- Update the experiment name associated with each dataset
	---------------------------------------------------
	--
	UPDATE T_Data_Package_Datasets
	SET Experiment = E.Experiment_Num
	FROM T_Data_Package_Datasets Target INNER JOIN
		DMS5.dbo.T_Dataset DS ON Target.Dataset_ID = DS.Dataset_ID INNER JOIN
		DMS5.dbo.T_Experiments E ON DS.Exp_ID = E.Exp_ID AND Target.Experiment <> E.Experiment_Num
	WHERE (Target.Data_Package_ID = @packageID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0
	Begin
		Set @message = 'Updated the experiment name for ' + Convert(varchar(12), @myRowCount) + ' datasets associated with data package ' + Convert(varchar(12), @packageID)
		
		Exec PostLogEntry 'Info', @message, 'RefreshDataPackageItemsUsingDMS'
	End

	---------------------------------------------------
	-- Update the campaign name associated with biomaterial (cell culture) entities
	---------------------------------------------------
	--
	UPDATE T_Data_Package_Biomaterial
	SET Campaign = C.Campaign_Num
	FROM DMS5.dbo.T_Campaign C INNER JOIN
		DMS5.dbo.T_Cell_Culture CC ON C.Campaign_ID = CC.CC_Campaign_ID INNER JOIN
		T_Data_Package_Biomaterial Target ON CC.CC_ID = Target.Biomaterial_ID AND C.Campaign_Num <> Target.Campaign
	WHERE (Target.Data_Package_ID = @packageID)
	   
	If @myRowCount > 0
	Begin
		Set @message = 'Updated the campaign name for ' + Convert(varchar(12), @myRowCount) + ' biomaterial entries associated with data package ' + Convert(varchar(12), @packageID)
		
		Exec PostLogEntry 'Info', @message, 'RefreshDataPackageItemsUsingDMS'
	End

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError

