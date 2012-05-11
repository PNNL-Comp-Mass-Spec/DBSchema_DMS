/****** Object:  StoredProcedure [dbo].[UpdateJobParamOrgDbInfoUsingDataPkg] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateJobParamOrgDbInfoUsingDataPkg
/****************************************************
**
**	Desc:
**		Create or update entries for OrganismName, LegacyFastaFileName, 
**		ProteinOptions, and ProteinCollectionList in T_Job_Parameters
**		for the specified job using the specified data package
**
**	Auth:	mem
**			03/20/2012 mem - Initial version
**    
*****************************************************/
(
	@job int,
	@DataPackageID int,
	@deleteIfInvalid tinyint = 0,			-- When 1, then deletes entries for OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList if @DataPackageID = 0, or @DataPackageID points to a non-existent data package, or if the data package doesn't have any Peptide_Hit jobs
	@message varchar(512)= '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @LogMessage varchar(256)

	Declare @OrgDBInfo table (
		EntryID int Identity(1,1) NOT NULL,
		OrganismName varchar(128) NULL,
		LegacyFastaFileName varchar(128) NULL,
		ProteinCollectionList varchar(2000) NULL,
		ProteinOptions varchar(256) NULL,
		UseCount int NOT NULL
	)
		
	Declare @OrganismName varchar(128) = ''
	Declare @LegacyFastaFileName varchar(128) = ''
	Declare @ProteinCollectionList varchar(2000) = ''
	Declare @ProteinOptions varchar (256) = ''


	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	
	If @job Is Null Or @DataPackageID Is Null
	Begin
		Set @message = '@Job and @DataPackageID are required'
		Return 50000
	End
	
	Set @deleteIfInvalid = IsNull(@deleteIfInvalid, 0)
	Set @message = ''

	
	---------------------------------------------------
	-- Validate @DataPackageID
	---------------------------------------------------
	--	
	
	Declare @MatchCount int = 0
	
	SELECT @MatchCount = COUNT(*) 
	FROM S_Data_Package_Details
	WHERE ID = @DataPackageID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @MatchCount = 0
	Begin
		Set @message = 'Data package ' + Convert(varchar(12), @DataPackageID) + ' not found in the Data_Package database'
		Set @DataPackageID = -1
	End

	If @DataPackageID > 0
	Begin -- <a>
		
		---------------------------------------------------
		-- Lookup the OrgDB info for jobs associated with data package @DataPackageID
		---------------------------------------------------
		--
		INSERT INTO @OrgDBInfo( OrganismName,
		                        LegacyFastaFileName,
		                        ProteinCollectionList,
		                        ProteinOptions,
		                        UseCount )
		SELECT Organism,
		       CASE
		           WHEN IsNull(ProteinCollectionList, 'na') <> 'na' AND
		                IsNull(ProteinOptionsList, 'na')    <> 'na' THEN 'na'
		           ELSE OrganismDBName
		       END AS LegacyFastaFileName,
		       ProteinCollectionList,
		       ProteinOptionsList,
		       COUNT(*) AS UseCount
		FROM dbo.S_DMS_V_GetPipelineJobParameters J
		WHERE Job IN ( SELECT Job
		               FROM [S_Data_Package_Analysis_Jobs]
		               WHERE Data_Package_ID = @DataPackageID 
		             ) AND
		      J.OrgDBRequired <> 0
		GROUP BY Organism, OrganismDBName, ProteinCollectionList, ProteinOptionsList
		ORDER BY COUNT(*) DESC
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		---------------------------------------------------
		-- Check for invalid data
		---------------------------------------------------
		--
		If @myRowCount = 0
		Begin
			Set @message = 'Data package ' + Convert(varchar(12), @DataPackageID) + ' either has no jobs or has no jobs with a protein collection or legacy fasta file'
			Set @DataPackageID = -1
		End
		Else
		Begin -- <b>
			If @myRowCount > 1
			Begin
				-- Mix of protein collections / fasta files defined
				
				Set @OrganismName = 'InvalidData'
				Set @LegacyFastaFileName = 'na'
				Set @ProteinCollectionList = 'MixOfOrgDBs_DataPkg_' + Convert(varchar(12), @DataPackageID) + '_UniqueComboCount_' + Convert(varchar(12), @myRowCount) 
				Set @ProteinOptions = 'seq_direction=forward,filetype=fasta'
	
			End
			Else	
			Begin
				-- @myRowCount is 1
			
				SELECT @OrganismName = OrganismName,
				       @LegacyFastaFileName = LegacyFastaFileName,
				       @ProteinCollectionList = ProteinCollectionList,
				       @ProteinOptions = ProteinOptions
				FROM @OrgDBInfo
			
			End
			
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'OrganismName',          @value=@OrganismName,          @DeleteParam=0
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'legacyFastaFileName',   @value=@LegacyFastaFileName,   @DeleteParam=0
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinCollectionList', @value=@ProteinCollectionList, @DeleteParam=0
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinOptions',        @value=@ProteinOptions,        @DeleteParam=0
			
			Set @message = 'Defined OrgDb related parameters for job ' + Convert(varchar(12), @job)
		
		End -- </b>
		
	End -- </a>


	If @DataPackageID <= 0
	Begin
		---------------------------------------------------
		-- Data package ID was invalid, or it had no valid jobs
		---------------------------------------------------
		--
		
		If @deleteIfInvalid <> 0
		Begin
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'OrganismName',          @value='',  @DeleteParam=1
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'legacyFastaFileName',   @value='',  @DeleteParam=1
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinCollectionList', @value='',  @DeleteParam=1
			Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinOptions',        @value='',  @DeleteParam=1

			Set @LogMessage = 'Deleted OrgDb related parameters from the PeptideSearch section of the job parameters for job ' + Convert(varchar(12), @job)
			
			If IsNull(@message, '') = ''
				Set @message = @LogMessage
			Else
				Set @message = @message + '; ' + @LogMessage
				
		End
		
	End
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
