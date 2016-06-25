/****** Object:  StoredProcedure [dbo].[UpdateCachedProteinCollectionMembers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateCachedProteinCollectionMembers
/****************************************************
**
**	Desc:	Updates the information in T_Protein_Collection_Members_Cached
**
**			By default, only adds new protein collections
**			Set @updateAll to 1 to force an update of all protein collections
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	06/24/2016 mem - Initial release
**    
*****************************************************/
(	
	@collectionIdFilter int = 0,
	@updateAll tinyint = 0,
	@maxCollectionsToUpdate int = 0,
	@message varchar(256)='' output
)

As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @statusMsg varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @collectionIdFilter = IsNull(@collectionIdFilter, 0)
	Set @updateAll = IsNull(@updateAll, 0)
	Set @maxCollectionsToUpdate = IsNull(@maxCollectionsToUpdate, 0)
	Set @message = ''
	
	---------------------------------------------------
	-- Create some temporary tables
	---------------------------------------------------
	
	CREATE TABLE #Tmp_ProteinCollections (
		Protein_Collection_ID int NOT NULL,
		NumProteins int NOT NULL,
		Processed tinyint NOT NULL
	)	
	
	CREATE CLUSTERED INDEX #IX_Tmp_ProteinCollections ON #Tmp_ProteinCollections ( Protein_Collection_ID )
	CREATE INDEX #IX_Tmp_ProteinCollections_Processed ON #Tmp_ProteinCollections ( Processed ) INCLUDE (Protein_Collection_ID)
	
	CREATE TABLE #Tmp_CurrentIDs (
		Protein_Collection_ID int NOT NULL
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_CurrentIDs ON #Tmp_CurrentIDs ( Protein_Collection_ID )
	
	CREATE TABLE #Tmp_ProteinCountErrors (
		Protein_Collection_ID int NOT NULL,
		NumProteinsOld int NOT NULL,
		NumProteinsNew int NOT NULL
	)
	
	---------------------------------------------------
	-- Find protein collections to process
	---------------------------------------------------
		
	If @updateAll > 0
	Begin
		-- Reprocess all of the protein collections
		--
		INSERT INTO #Tmp_ProteinCollections (Protein_Collection_ID, NumProteins, Processed)
		SELECT Protein_Collection_ID, NumProteins, 0
		FROM T_Protein_Collections
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	Else
	Begin
		-- Only add new protein collections
		--
		INSERT INTO #Tmp_ProteinCollections (Protein_Collection_ID, NumProteins, Processed)
		SELECT PC.Protein_Collection_ID,
		       PC.NumProteins,
		       0 as Processed
		FROM (SELECT Protein_Collection_ID, NumProteins
		      FROM T_Protein_Collections
		      WHERE Collection_State_ID NOT IN (4)) PC
		     LEFT OUTER JOIN ( SELECT Protein_Collection_ID,
		                              Count(*) AS CachedProteinCount
		                       FROM T_Protein_Collection_Members_Cached
		                       GROUP BY Protein_Collection_ID ) CacheQ
		       ON PC.Protein_Collection_ID = CacheQ.Protein_Collection_ID		          
		WHERE CacheQ.Protein_Collection_ID IS NULL OR
		      PC.NumProteins <> CachedProteinCount
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	
	If @collectionIdFilter <> 0
	Begin
		DELETE FROM #Tmp_ProteinCollections
		WHERE Protein_Collection_ID <> @collectionIdFilter
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	If Not Exists (Select * FROM #Tmp_ProteinCollections)
	Begin
		Print '#Tmp_ProteinCollections is empty; nothing to do'
	End
	
	---------------------------------------------------
	-- Process the protein collections
	-- Limit the number to process at a time with the goal of updating up to 500,000 records in each batch
	---------------------------------------------------

	Declare @continue tinyint = 1
	Declare @collectionCountUpdated int = 0
	Declare @currentRangeStart int
	Declare @currentRangeEnd int
	Declare @currentRangeCount int
	Declare @currentRange varchar(64) = ''
	
	While @continue > 0
	Begin -- <a>
		TRUNCATE TABLE #Tmp_CurrentIDs
		
		-- Find the next set of collections to process
		-- The goal is to process up to 500,000 proteins
		--
		INSERT INTO #Tmp_CurrentIDs (Protein_Collection_ID)
		SELECT PC.Protein_Collection_ID
		FROM #Tmp_ProteinCollections PC INNER JOIN
			(SELECT Protein_Collection_ID, NumProteins
			FROM #Tmp_ProteinCollections
			WHERE Processed = 0) SumQ ON SumQ.Protein_Collection_ID <= PC.Protein_Collection_ID
		WHERE Processed = 0
		GROUP BY PC.Protein_Collection_ID
		HAVING SUM(SumQ.NumProteins) < 500000
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If Not Exists (Select * From #Tmp_CurrentIDs)
		Begin
			-- The next available protein collection has over 500,000 proteins
			--
			INSERT INTO #Tmp_CurrentIDs (Protein_Collection_ID)
			SELECT TOP 1 Protein_Collection_ID
			FROM #Tmp_ProteinCollections 
			WHERE Processed = 0
			ORDER BY Protein_Collection_ID
		End
		
		IF @maxCollectionsToUpdate > 0
		Begin
			-- Too many candidate collections; delete the extras
			--
			DELETE #Tmp_CurrentIDs
			WHERE NOT Protein_Collection_ID IN ( SELECT TOP ( @maxCollectionsToUpdate ) Protein_Collection_ID
			                                     FROM #Tmp_CurrentIDs
			                                     ORDER BY Protein_Collection_ID )
		End
		
		-- Update the processed flag for the candidates
		--
		UPDATE #Tmp_ProteinCollections
		SET Processed = 1
		FROM #Tmp_ProteinCollections PC
		     INNER JOIN #Tmp_CurrentIDs C
		       ON C.Protein_Collection_ID = PC.Protein_Collection_ID

		Set @currentRangeCount = 0
		SELECT @currentRangeCount = Count(*),
		       @currentRangeStart = Min(Protein_Collection_ID),
		       @currentRangeEnd = Max(Protein_Collection_ID)
		FROM #Tmp_CurrentIDs

		If @currentRangeCount = 0
		Begin
			-- All collections have been processed
			Set @continue = 0
		End
		Else
		Begin -- <b>
			Set @currentRange = Cast(@currentRangeCount as varchar(9)) + ' protein ' + dbo.CheckPlural(@currentRangeCount, 'collection', 'collections') +
								' (' + Cast(@currentRangeStart as varchar(9)) + ' to ' + Cast(@currentRangeEnd as varchar(9)) + ')'

			Print 'Processing ' + @currentRange
			
			---------------------------------------------------
			-- Add/update data for protein collections in #Tmp_CurrentIDs
			---------------------------------------------------

			MERGE [dbo].[T_Protein_Collection_Members_Cached] AS t
			USING (
				SELECT PCM.Protein_Collection_ID,
				       ProtName.Reference_ID,
				       ProtName.Name AS Protein_Name,
				       Cast(ProtName.Description AS varchar(64)) AS Description,
				       Prot.Length AS Residue_Count,
				       Prot.Monoisotopic_Mass,
				       Prot.Protein_ID
				FROM T_Protein_Collection_Members PCM
				     INNER JOIN T_Proteins Prot
				       ON PCM.Protein_ID = Prot.Protein_ID
				     INNER JOIN T_Protein_Names ProtName
				       ON PCM.Protein_ID = ProtName.Protein_ID AND
				          PCM.Original_Reference_ID = ProtName.Reference_ID
				     INNER JOIN T_Protein_Collections PC
				       ON PCM.Protein_Collection_ID = PC.Protein_Collection_ID
				WHERE PCM.Protein_Collection_ID IN (SELECT Protein_Collection_ID FROM #Tmp_CurrentIDs)
			) as s
			ON ( t.[Protein_Collection_ID] = s.[Protein_Collection_ID] AND t.[Reference_ID] = s.[Reference_ID])
			WHEN MATCHED AND (
				t.[Protein_Name] <> s.[Protein_Name] OR
				t.[Residue_Count] <> s.[Residue_Count] OR
				t.[Protein_ID] <> s.[Protein_ID] OR
				ISNULL( NULLIF(t.[Description], s.[Description]),
						NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
				ISNULL( NULLIF(t.[Monoisotopic_Mass], s.[Monoisotopic_Mass]),
						NULLIF(s.[Monoisotopic_Mass], t.[Monoisotopic_Mass])) IS NOT NULL
				)
			THEN UPDATE SET 
				[Protein_Name] = s.[Protein_Name],
				[Description] = s.[Description],
				[Residue_Count] = s.[Residue_Count],
				[Monoisotopic_Mass] = s.[Monoisotopic_Mass],
				[Protein_ID] = s.[Protein_ID]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT([Protein_Collection_ID], [Reference_ID], [Protein_Name], [Description], [Residue_Count], [Monoisotopic_Mass], [Protein_ID])
				VALUES(s.[Protein_Collection_ID], s.[Reference_ID], s.[Protein_Name], s.[Description], s.[Residue_Count], s.[Monoisotopic_Mass], s.[Protein_ID])
			;
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount > 0
			Begin
				set @statusMsg = 'Inserted ' + Cast(@myRowCount as varchar(9)) + ' rows for ' + @currentRange
				Print @statusMsg
				exec PostLogEntry 'Normal', @statusMsg, 'UpdateCachedProteinCollectionMembers'
			End

			---------------------------------------------------
			-- Delete any extra rows
			---------------------------------------------------
			
			DELETE Target
			FROM T_Protein_Collection_Members_Cached Target
			   INNER JOIN #Tmp_CurrentIDs C
			       ON Target.Protein_Collection_ID = C.Protein_Collection_ID
			     LEFT OUTER JOIN ( SELECT PCM.Protein_Collection_ID,
			                              PCM.Original_Reference_ID
			                       FROM T_Protein_Collection_Members PCM
			                            INNER JOIN #Tmp_CurrentIDs C
			                              ON PCM.Protein_Collection_ID = C.Protein_Collection_ID 
			                      ) FilterQ
			       ON Target.Protein_Collection_ID = FilterQ.Protein_Collection_ID AND
			          Target.Reference_ID = FilterQ.Original_Reference_ID
			WHERE FilterQ.Protein_Collection_ID IS NULL
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0
			Begin
				set @statusMsg = 'Deleted ' + Cast(@myRowCount as varchar(9)) + ' extra rows from T_Protein_Collection_Members_Cached for ' + @currentRange
				Print @statusMsg
				exec PostLogEntry 'Normal', @statusMsg, 'UpdateCachedProteinCollectionMembers'
			End
			
			---------------------------------------------------
			-- Update @collectionCountUpdated
			---------------------------------------------------
			
			SELECT @myRowCount = Count(*)
			FROM #Tmp_CurrentIDs

			Set @collectionCountUpdated = @collectionCountUpdated + @myRowCount
			
			If @maxCollectionsToUpdate > 0 And @collectionCountUpdated >= @maxCollectionsToUpdate
				Set @continue = 0

		End -- </b>
		
	End -- </a>

	---------------------------------------------------
	-- Validate the NumProteins value in T_Protein_Collections
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ProteinCountErrors( Protein_Collection_ID,
	                                     NumProteinsOld,
	                                     NumProteinsNew)
	SELECT PC.Protein_Collection_ID,
	       PC.NumProteins,
	       StatsQ.NumProteinsNew
	FROM T_Protein_Collections PC
	     INNER JOIN ( SELECT Protein_Collection_ID,
	                         COUNT(*) AS NumProteinsNew
	                  FROM T_Protein_Collection_Members_Cached
	                  GROUP BY Protein_Collection_ID 
	                ) StatsQ
	       ON PC.Protein_Collection_ID = StatsQ.Protein_Collection_ID
	WHERE PC.NumProteins <> StatsQ.NumProteinsNew
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0
	Begin -- <c>
		SELECT *
		FROM #Tmp_ProteinCountErrors
		ORDER BY Protein_Collection_ID
		
		Declare @proteinCollectionID int = -1
		Declare @numProteinsOld int
		Declare @numProteinsNew int
		
		Set @continue = 1
		
		While @continue > 0
		Begin -- <d>
			SELECT TOP 1 @proteinCollectionID = Protein_Collection_ID,
			             @numProteinsOld = NumProteinsOld,
			             @numProteinsNew = NumProteinsNew
			FROM #Tmp_ProteinCountErrors
			WHERE Protein_Collection_ID > @proteinCollectionID
			ORDER BY Protein_Collection_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
			Begin
				Set @continue = 0
			End
			Else
			Begin -- <e>
				UPDATE T_Protein_Collections
				SET NumProteins = @numProteinsNew
				WHERE Protein_Collection_ID = @proteinCollectionID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				Set @statusMsg = 'Changed number of proteins' + 
								' from ' + Cast(@numProteinsOld as varchar(9)) + 
								' to '   + Cast(@numProteinsNew as varchar(9)) + 
								' for protein collection '  + Cast(@proteinCollectionID as varchar(9)) + 
								' in T_Protein_Collections'
				print @statusMsg
				
				exec PostLogEntry 'Warning', @statusMsg, 'UpdateCachedProteinCollectionMembers'
			End -- </e>
			
		End -- </d>
		
	End -- </c>
	

Done:
	return @myError

GO
