/****** Object:  StoredProcedure [dbo].[GetArchivedFileIDForProteinCollectionList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetArchivedFileIDForProteinCollectionList
/****************************************************
** 
**	Desc:	Given a series of protein collection names, determine
**			the entry in T_Archived_Output_Files that corresponds to the list
**
**			If an entry is not found, then sets @ArchivedFileID to 0
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	06/07/2006
**			07/04/2006 mem - Updated to return the newest Archived File Collection ID when there is more than one possible match
** 
*****************************************************/
(
	@ProteinCollectionList varchar(2048),
	@CreationOptions varchar(512) = 'seq_direction=forward,filetype=fasta',
	@ArchivedFileID int=0 output,
	@ProteinCollectionCount int=0 output,
	@message varchar(512)='' output
)
As
	Set NoCount On
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @ProteinCollectionName varchar(512)
	Declare @UniqueID int
	Declare @continue tinyint

	Declare @ProteinCollectionListClean varchar(2048)
	Set @ProteinCollectionListClean = ''

	-----------------------------------------------------
	-- Validate the intputs
	-----------------------------------------------------
	Set @ProteinCollectionList = LTrim(RTrim(IsNull(@ProteinCollectionList, '')))
	Set @ArchivedFileID = 0
	Set @ProteinCollectionCount = 0
	Set @message = ''
	
	If Len(@ProteinCollectionList) = 0
	Begin
		Set @message = 'Warning: Protein collection list is empty'
		Goto Done
	End
	
	-----------------------------------------------------
	-- Create some temporary tables
	-----------------------------------------------------
	--
	if exists (select * from dbo.sysobjects where id = object_id(N'[#TmpProteinCollectionList]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	drop table [#TmpProteinCollectionList]
	
	CREATE TABLE dbo.#TmpProteinCollectionList (
		Unique_ID int identity(1,1),
		ProteinCollectionName varchar(512) NOT NULL
	)

	if exists (select * from dbo.sysobjects where id = object_id(N'[#TmpArchived_Output_File_IDs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	drop table [#TmpArchived_Output_File_IDs]
	
	CREATE TABLE dbo.#TmpArchived_Output_File_IDs (
		Archived_File_ID int NOT NULL,
		Valid_Member_Count int NOT NULL Default 0
	)
	
	-----------------------------------------------------
	-- Parse the protein collection names and populate a temporary table
	-----------------------------------------------------
	--
	INSERT INTO #TmpProteinCollectionList (ProteinCollectionName)
	SELECT Value
	FROM dbo.udfParseDelimitedList(@ProteinCollectionList, ',')
	--
	SELECT @myRowcount = @@rowcount, @myError = @@error
	
	If @myError <> 0
	Begin
		Set @message = 'Error parsing the protein collection list: Code = ' + Convert(varchar(12), @myError)
		Goto Done
	End
		
	If @myRowcount < 1
	Begin
		Set @message = 'Error parsing the protein collection list: could not find any entries'
		Goto Done
	End
	
	-----------------------------------------------------
	-- Count the number of protein collection names present
	-----------------------------------------------------
	--
	Set @ProteinCollectionName = ''
	Set @ProteinCollectionCount = 0
	
	SELECT @ProteinCollectionName = MIN(ProteinCollectionName),
		   @ProteinCollectionCount = COUNT(*)
	FROM #TmpProteinCollectionList
	--
	SELECT @myRowcount = @@rowcount, @myError = @@error

	If @ProteinCollectionCount < 1
	Begin
		Set @message = 'Could not find any entries in #TmpProteinCollectionList; this is unexpected'
		Goto Done
	End

	-----------------------------------------------------
	-- Query to find the archived output files that include @ProteinCollectionName and @CreationOptions
	-- Additionally, count the number of protein collections included in each archived output file
	--  and only return the archived output files that contain @ProteinCollectionCount collections
	-----------------------------------------------------
	--
	INSERT INTO #TmpArchived_Output_File_IDs (Archived_File_ID)
	SELECT AOF.Archived_File_ID
	FROM T_Archived_Output_File_Collections_XRef AOFC INNER JOIN
		 T_Archived_Output_Files AOF ON AOFC.Archived_File_ID = AOF.Archived_File_ID
	WHERE (AOF.Archived_File_ID IN
			(	SELECT AOF.Archived_File_ID
				FROM T_Archived_Output_File_Collections_XRef AOFC INNER JOIN
					 T_Archived_Output_Files AOF ON AOFC.Archived_File_ID = AOF.Archived_File_ID INNER JOIN
					 T_Protein_Collections PC ON AOFC.Protein_Collection_ID = PC.Protein_Collection_ID
				WHERE PC.FileName = @ProteinCollectionName AND AOF.Creation_Options = @CreationOptions)
			)
	GROUP BY AOF.Archived_File_ID
	HAVING COUNT(*) = @ProteinCollectionCount
	--
	SELECT @myRowcount = @@rowcount, @myError = @@error

	If @myError <> 0
	Begin
		Set @message = 'Error querying the T_Archived_Output_File tables for the given protein collection list: Code = ' + Convert(varchar(12), @myError)
		Goto Done
	End
	
	If @myRowcount < 1
	Begin
		Set @message = 'Warning: Could not find any archived output files '
		If @ProteinCollectionCount > 1
			Set @message = @message + 'that contain "' + @ProteinCollectionList + '"'
		Else
			Set @message = @message + 'that only contain "' + @ProteinCollectionName + '"'
		
		Set @message = @message + ' and have Creation_Options "' + @CreationOptions + '"'
		Goto Done
	End
	
	If @ProteinCollectionCount = 1
	Begin
		-----------------------------------------------------
		-- Just one protein collection; query #TmpArchived_Output_File_IDs to determine the ID
		-- (the table should really only contain one row, but updates to the fasta file
		--  creation DLL could result in different versions of the output .fasta file, so
		--  we'll always return the newest version)
		-----------------------------------------------------
		--
		SELECT TOP 1 @ArchivedFileID = Archived_File_ID
		FROM #TmpArchived_Output_File_IDs
		ORDER BY Archived_File_ID Desc
		--
		SELECT @myRowcount = @@rowcount, @myError = @@error

	End
	Else
	Begin -- <a>
		-----------------------------------------------------
		-- More than one protein collection; find the best match
		-- Do this by querying #TmpArchived_Output_File_IDs for
		--  each protein collection in #TmpProteinCollectionList
		-- Note that this procedure does not worry about the order of the protein
		--  collections in @ProteinCollectionList.  If more than one archive exists
		--  with the same collections, but a different ordering, then the ID value
		--  for only one of the archives will be returned
		-----------------------------------------------------
		--
		Set @UniqueID = 0
		Set @ProteinCollectionCount = 0
		
		Set @continue = 1
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @ProteinCollectionName = ProteinCollectionName,
						 @UniqueID = Unique_ID
			FROM #TmpProteinCollectionList
			WHERE Unique_ID > @UniqueID
			ORDER BY Unique_ID
			--
			SELECT @myRowcount = @@rowcount, @myError = @@error
			
			If @myRowcount < 1
				Set @Continue = 0
			Else
			Begin -- <c>
				UPDATE #TmpArchived_Output_File_IDs
				SET Valid_Member_Count = Valid_Member_Count + 1
				FROM #TmpArchived_Output_File_IDs AOF INNER JOIN
					 T_Archived_Output_File_Collections_XRef AOFC ON AOF.Archived_File_ID = AOFC.Archived_File_ID INNER JOIN
					 T_Protein_Collections PC ON AOFC.Protein_Collection_ID = PC.Protein_Collection_ID
				WHERE PC.FileName = @ProteinCollectionName
				--
				SELECT @myRowcount = @@rowcount, @myError = @@error
				
				Set @ProteinCollectionCount = @ProteinCollectionCount + 1
				
				If @ProteinCollectionCount = 1
					Set @ProteinCollectionListClean = @ProteinCollectionName
				Else
					Set @ProteinCollectionListClean = @ProteinCollectionListClean + ',' + @ProteinCollectionName
				
			End -- </c>
		End -- </b>

		-----------------------------------------------------
		-- Grab the last entry in #TmpArchived_Output_File_IDs with
		--  Valid_Member_Count equal to @ProteinCollectionCount
		-- Note that all of the entries in #TmpArchived_Output_File_IDs
		--  should contain the same number of protein collections,
		--  but only those entries that contain all of the collections
		--  in #TmpProteinCollectionList will have Valid_Member_Count 
		--  equal to @ProteinCollectionCount
		-----------------------------------------------------
		--
		SELECT TOP 1 @ArchivedFileID = Archived_File_ID
		FROM #TmpArchived_Output_File_IDs
		WHERE Valid_Member_Count = @ProteinCollectionCount
		ORDER BY Archived_File_ID Desc
		--
		SELECT @myRowcount = @@rowcount, @myError = @@error

		If @myRowcount < 1
		Begin
			Set @message = 'Warning: Could not find any archived output files that contain "' + @ProteinCollectionListClean + '"'
			Set @message = @message + ' and have Creation_Options "' + @CreationOptions + '"'

			Goto Done
		End
	End -- </a>

Done:
	Return @myError

GO
GRANT EXECUTE ON [dbo].[GetArchivedFileIDForProteinCollectionList] TO [MTS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetArchivedFileIDForProteinCollectionList] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
