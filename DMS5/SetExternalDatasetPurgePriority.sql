/****** Object:  StoredProcedure [dbo].[SetExternalDatasetPurgePriority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.SetExternalDatasetPurgePriority
/****************************************************
**
**	Desc: Sets the purge priority to 2 for datasets acquired on external instruments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	04/09/2014
**    
*****************************************************/
(
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	CREATE TABLE #Tmp_DatasetsToUpdate 
	(
		Dataset_ID int not null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_DatasetsToUpdate ON #Tmp_DatasetsToUpdate (Dataset_ID)
	
	---------------------------------------------------
	-- Update the purge priority for datasets acquired on offsite instruments
	-- However, bump up the PurgeHoldOff date by 45 day to skip newer datasetes
	---------------------------------------------------
	--
	
	INSERT INTO #Tmp_DatasetsToUpdate (Dataset_ID)
	SELECT DS.Dataset_ID
	FROM T_Dataset DS
	     INNER JOIN T_Instrument_Name InstName
	       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	     INNER JOIN T_Dataset_Archive DA
	       ON DS.Dataset_ID = DA.AS_Dataset_ID
	WHERE DA.AS_instrument_data_purged = 0 AND
	      DA.Purge_Priority = 3 AND
	      InstName.IN_operations_role = 'Offsite' AND
	      DATEADD(DAY, 45, DA.AS_purge_holdoff_date) < GETDATE()
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	If @infoOnly <> 0
	Begin
		SELECT InstName.IN_name AS Instrument,
		       DS.Dataset_Num AS Dataset,
		       DS.DS_created AS Dataset_Created,
		       DA.Purge_Priority AS Purge_Priority,
		       DA.AS_instrument_data_purged AS Instrument_Data_Purged
		FROM T_Dataset DS
		     INNER JOIN T_Instrument_Name InstName
		       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
		     INNER JOIN T_Dataset_Archive DA
		       ON DS.Dataset_ID = DA.AS_Dataset_ID
		     INNER JOIN #Tmp_DatasetsToUpdate U
		       ON DS.Dataset_ID = U.Dataset_ID
	
	End
	Else	
	Begin
		UPDATE T_Dataset_Archive
		SET Purge_Priority = 2
		FROM T_Dataset_Archive DA
		     INNER JOIN #Tmp_DatasetsToUpdate U
		       ON DA.AS_Dataset_ID = U.Dataset_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	return @myError

GO
