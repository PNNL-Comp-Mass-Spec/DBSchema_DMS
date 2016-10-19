/****** Object:  StoredProcedure [dbo].[UpdateDataPackageEUSInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateDataPackageEUSInfo
/****************************************************
**
**	Desc: 
**		Updates fields EUS_Person_ID and EUS_Proposal_ID in T_Data_Package for one or more data packages
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	10/18/2016 mem - Initial version
**    
*****************************************************/
(
	@DataPackageID int,				-- 0 to update all data packages, otherwise a specific data package ID to update
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @DataPackageID = IsNull(@DataPackageID, 0);
	
	Set @message = ''
	
	---------------------------------------------------
	-- Populate a temporary table with the data package IDs to update
	---------------------------------------------------
	
	CREATE TABLE dbo.[#TmpDataPackagesToUpdate] (
		ID int not NULL,
		Best_EUS_Proposal_ID varchar(10) NULL
	)
	
	CREATE CLUSTERED INDEX [#IX_TmpDataPackagesToUpdate] ON [dbo].[#TmpDataPackagesToUpdate]
	(
		ID ASC
	)

	INSERT INTO #TmpDataPackagesToUpdate (ID)
	SELECT ID
	FROM T_Data_Package
	WHERE ID = @DataPackageID OR @DataPackageID <= 0

	---------------------------------------------------
	-- Update the EUS Person ID of the data package owner
	---------------------------------------------------
	
	UPDATE T_Data_Package
	SET EUS_Person_ID = EUSUser.EUS_Person_ID
	FROM T_Data_Package DP
	     INNER JOIN #TmpDataPackagesToUpdate Src
	       ON DP.ID = Src.ID
	     INNER JOIN S_DMS_V_EUS_User_ID_Lookup EUSUser
	       ON DP.Owner = EUSUser.Username
	WHERE IsNull(DP.EUS_Person_ID, '') <> IsNull(EUSUser.EUS_Person_ID, '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0 And @DataPackageID <= 0
	Begin
		Set @message = 'Updated EUS_Person_ID for ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' data package', ' data packages')
		Exec PostLogEntry 'Normal', @message, 'UpdateDataPackageEUSInfo'
	End


	---------------------------------------------------
	-- Find the most common EUS proposal used by the datasets associated with each data package
	---------------------------------------------------

	UPDATE #TmpDataPackagesToUpdate
	SET Best_EUS_Proposal_ID = FilterQ.EUS_Proposal_ID
	FROM #TmpDataPackagesToUpdate Target
	     INNER JOIN ( SELECT RankQ.Data_Package_ID,
	                         RankQ.EUS_Proposal_ID
	                  FROM ( SELECT Data_Package_ID,
	                                EUS_Proposal_ID,
	                                ProposalCount,
	                                Row_Number() OVER ( Partition By SourceQ.Data_Package_ID Order By ProposalCount DESC ) AS CountRank
	                         FROM ( SELECT DPD.Data_Package_ID,
	                                       DR.[EMSL Proposal] AS EUS_Proposal_ID,
	                                       COUNT(*) AS ProposalCount
	                                FROM T_Data_Package_Datasets DPD
	                                     INNER JOIN #TmpDataPackagesToUpdate Src
	                                       ON DPD.Data_Package_ID = Src.ID
	                                     INNER JOIN S_V_Dataset_List_Report_2 DR
	                                       ON DPD.Dataset_ID = DR.ID
	                                WHERE NOT DR.[EMSL Proposal] IS NULL
	                                GROUP BY DPD.Data_Package_ID, DR.[EMSL Proposal] 
	                              ) SourceQ 
	                       ) RankQ
	                  WHERE RankQ.CountRank = 1 
	                 ) FilterQ
	       ON Target.ID = FilterQ.Data_Package_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for any data packages that have a null Best_EUS_Proposal_ID in #TmpDataPackagesToUpdate
	-- yet have entries defined in T_Data_Package_EUS_Proposals
	---------------------------------------------------
	
	UPDATE #TmpDataPackagesToUpdate
	SET Best_EUS_Proposal_ID = FilterQ.Proposal_ID
	FROM #TmpDataPackagesToUpdate Target
	     INNER JOIN ( SELECT Data_Package_ID,
	                         Proposal_ID
	                  FROM ( SELECT Data_Package_ID,
	                                Proposal_ID,
	                                [Item Added],
	                                Row_Number() OVER ( Partition By Data_Package_ID Order By [Item Added] DESC ) AS IdRank
	                         FROM T_Data_Package_EUS_Proposals
	                         WHERE (Data_Package_ID IN ( SELECT ID
	                                                     FROM #TmpDataPackagesToUpdate
	                                                     WHERE Best_EUS_Proposal_ID IS NULL )) 
	                       ) RankQ
	                  WHERE RankQ.IdRank = 1 
	                ) FilterQ
	       ON Target.ID = FilterQ.Data_Package_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Update EUS Proposal ID as necessary
	---------------------------------------------------
	
	UPDATE T_Data_Package
	SET EUS_Proposal_ID = Best_EUS_Proposal_ID
	FROM T_Data_Package DP
	     INNER JOIN #TmpDataPackagesToUpdate Src
	       ON DP.ID = Src.ID
	WHERE IsNull(DP.EUS_Proposal_ID, '') <> IsNull(Src.Best_EUS_Proposal_ID, '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0 And @DataPackageID <= 0
	Begin
		Set @message = 'Updated EUS_Proposal_ID for ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' data package', ' data packages')
		Exec PostLogEntry 'Normal', @message, 'UpdateDataPackageEUSInfo'
	End

Done:


	Return @myError


GO
