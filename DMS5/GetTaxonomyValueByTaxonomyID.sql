/****** Object:  StoredProcedure [dbo].[GetTaxonomyValueByTaxonomyID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetTaxonomyValueByTaxonomyID
/****************************************************
**
**	Desc: Looks up taxonomy values for the given TaxonomyID
**
**	Auth:	mem
**	Date:	03/02/2016 mem - Initial version
**			03/03/2016 mem - Auto define Phylum as Community when @NCBITaxonomyID is 48479
**    
*****************************************************/
(
	@NCBITaxonomyID int,					-- TaxonomyID value to lookup; ignored if @previewResults > 0 and the organism has NCBI_Taxonomy_ID defined in T_Organisms
	@orgDomain varchar(64)=''   output,		-- input/output value
	@orgKingdom varchar(64)=''  output,		-- input/output value
	@orgPhylum varchar(64)=''   output,		-- input/output value
	@orgClass varchar(64)=''    output,		-- input/output value
	@orgOrder varchar(64)=''    output,		-- input/output value
	@orgFamily varchar(64)=''   output,		-- input/output value
	@orgGenus varchar(128)=''   output,		-- input/output value
	@orgSpecies varchar(128)='' output,		-- input/output value
	@orgStrain varchar(128)=''  output,		-- input/output value
	@previewResults int = 0					-- Less than 0 to preview results for @NCBITaxonomyID; greater than 0 to preview results for the given OrganismID in T_Organisms
)
As
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @NCBITaxonomyID = IsNull(@NCBITaxonomyID, 0)
	
	Set @orgDomain = IsNull(@orgDomain, '')
	Set @orgKingdom = IsNull(@orgKingdom, '')
	Set @orgPhylum = IsNull(@orgPhylum, '')
	Set @orgClass = IsNull(@orgClass, '')
	Set @orgOrder = IsNull(@orgOrder, '')
	Set @orgFamily = IsNull(@orgFamily, '')
	Set @orgGenus = IsNull(@orgGenus, '')
	Set @orgSpecies = IsNull(@orgSpecies, '')
	Set @orgStrain = IsNull(@orgStrain, '')	
	
	Set @previewResults = IsNull(@previewResults, 0)

	Declare @OrganismName varchar(64)= '[No Organism]'
	
	If @previewResults > 0
	Begin
		Declare @newNCBITaxonomyID int
		
		Select @newNCBITaxonomyID = NCBI_Taxonomy_ID, 
		       @OrganismName = OG_name,
		       @orgDomain = OG_Domain,
		       @orgKingdom = OG_Kingdom,
		       @orgPhylum = OG_Phylum,
		       @orgClass = OG_Class,
		       @orgOrder = OG_Order,
		       @orgFamily = OG_Family,
		       @orgGenus = OG_Genus,
		       @orgSpecies = OG_Species,
		       @orgStrain = OG_Strain
		FROM T_Organisms
		WHERE Organism_ID = @previewResults
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount <> 1
		Begin
			Declare @message varchar(128) = 'Organism ID ' + Cast(@previewResults as varchar(12)) + ' not found; nothing to preview'
			RAISERROR (@message, 11, 4)
			return 0
		End

		If IsNull(@newNCBITaxonomyID, 0) > 0
			Set @NCBITaxonomyID = @newNCBITaxonomyID
			
	End
		
	If @NCBITaxonomyID = 0
		Return 0

	---------------------------------------------------
	-- Declare variables to hold the updated data
	---------------------------------------------------
	
	Declare @newDomain varchar(64) =   @orgDomain
	Declare @newKingdom varchar(64) =  @orgKingdom
	Declare @newPhylum varchar(64) =   @orgPhylum
	Declare @newClass varchar(64)  =   @orgClass
	Declare @newOrder varchar(64)  =   @orgOrder
	Declare @newFamily varchar(64) =   @orgFamily
	Declare @newGenus varchar(128) =   @orgGenus
	Declare @newSpecies varchar(128) = @orgSpecies
	Declare @newStrain varchar(128)  = @orgStrain
		
	---------------------------------------------------
	-- Create a temporary table
	---------------------------------------------------

	CREATE TABLE #Tmp_TaxonomyInfo (
		Entry_ID int not null,
		[Rank] varchar(32) not null,
		[Name] varchar(255) not null
	)

	---------------------------------------------------
	-- Lookup the taxonomy data
	---------------------------------------------------
	
	INSERT INTO #Tmp_TaxonomyInfo( Entry_ID,
		               [Rank],
		                            [Name] )
	SELECT Entry_ID,
		    [Rank],
		    [Name]
	FROM dbo.[S_GetTaxIDTaxonomyTable] ( @NCBITaxonomyID )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0
	Begin
		---------------------------------------------------
		-- Populate the taxonomy variables
		---------------------------------------------------
		
		-- Superkingdom
		exec UpdateTaxonomyItemIfDefined 'superkingdom', @newDomain output
		
		-- Subkingdom, Kingdom
		exec UpdateTaxonomyItemIfDefined 'subkingdom', @newKingdom output
		exec UpdateTaxonomyItemIfDefined 'kingdom', @newKingdom output

		If @newKingdom = '' And @newDomain = 'bacteria'
			Set @newKingdom = 'Prokaryote'
			
		-- Subphylum, phylum
		exec UpdateTaxonomyItemIfDefined 'subphylum', @newPhylum output
		exec UpdateTaxonomyItemIfDefined 'phylum', @newPhylum output

		-- Subclass, superclass, class
		exec UpdateTaxonomyItemIfDefined 'subclass', @newClass output
		exec UpdateTaxonomyItemIfDefined 'superclass', @newClass output
		exec UpdateTaxonomyItemIfDefined 'class', @newClass output


		-- Suborder, superorder, order
		exec UpdateTaxonomyItemIfDefined 'suborder', @newOrder output
		exec UpdateTaxonomyItemIfDefined 'superorder', @newOrder output
		exec UpdateTaxonomyItemIfDefined 'order', @newOrder output

		-- Subfamily, superfamily, family
		exec UpdateTaxonomyItemIfDefined 'subfamily', @newFamily output
		exec UpdateTaxonomyItemIfDefined 'superfamily', @newFamily output
		exec UpdateTaxonomyItemIfDefined 'family', @newFamily output

		-- Subgenus, Genus
		exec UpdateTaxonomyItemIfDefined 'subgenus', @newGenus output
		exec UpdateTaxonomyItemIfDefined 'genus', @newGenus output

		-- Subspecies, species
		exec UpdateTaxonomyItemIfDefined 'subspecies', @newSpecies output
		exec UpdateTaxonomyItemIfDefined 'species', @newSpecies output

		-- Remove genus from species
		Set @newSpecies = LTrim(Replace(@newSpecies, @newGenus, ''))

		Declare @TaxonomyName varchar(255)
		Declare @TaxonomyRank varchar(32)

		SELECT @TaxonomyName = [Name],
			    @TaxonomyRank = [Rank]
		FROM  #Tmp_TaxonomyInfo
		WHERE Entry_ID = 1

		If @TaxonomyRank = 'no rank' And @TaxonomyName <> 'environmental samples'
		Begin
			Set @newStrain = @TaxonomyName
			
			-- Remove genus and species if present
			Set @newStrain = LTrim(Replace(LTrim(Replace(@newStrain, @newGenus, '')), @newSpecies, ''))
		End

	End

	---------------------------------------------------
	-- Auto-define some values when the Taxonomy ID is 48479 (environmental samples)
	---------------------------------------------------
	--
	If @NCBITaxonomyID = 48479
	Begin
		-- Auto-define Phylum as Community if Phlyum is empty
		If IsNull(@newPhylum, '') In ('na', '')
			Set @newPhylum = 'Community'

		If Len(IsNull(@newClass,   '')) = 0 Set @newClass = 'na'
		If Len(IsNull(@newOrder,   '')) = 0 Set @newOrder = 'na'
		If Len(IsNull(@newFamily,  '')) = 0 Set @newFamily = 'na'
		If Len(IsNull(@newGenus,   '')) = 0 Set @newGenus = 'na'
		If Len(IsNull(@newSpecies, '')) = 0 Set @newSpecies = 'na'
					
	End
	
	---------------------------------------------------
	-- Possibly preview the old / new values
	---------------------------------------------------
	--
	If @previewResults <> 0
	Begin
		SELECT	Case When @previewResults > 0 Then @previewResults Else 0 End as OrganismID,
				@OrganismName as Organism,
				@NCBITaxonomyID AS NCBITaxonomyID,
		        @orgDomain AS Domain,
				@newDomain AS Domain_New,
				@orgKingdom AS Kingdom,
				@newKingdom AS Kingdom_New,
				@orgPhylum AS Phylum,
				@newPhylum AS Phylum_New,
				@orgClass AS Class,
				@newClass AS Class_New,
				@orgOrder AS [Order],
				@newOrder AS Order_New,
				@orgFamily AS Family,
				@newFamily AS Family_New,
				@orgGenus AS Genus,
				@newGenus AS Genus_New,
				@orgSpecies AS Species,
				@newSpecies AS Species_New,
				@orgStrain AS Strain,
				@newStrain AS Strain_New


	End
	
	---------------------------------------------------
	-- Update the output variables
	---------------------------------------------------
	--
	Set @orgDomain   = @newDomain  
	Set @orgKingdom  = @newKingdom 
	Set @orgPhylum   = @newPhylum  
	Set @orgClass    = @newClass   
	Set @orgOrder    = @newOrder   
	Set @orgFamily   = @newFamily  
	Set @orgGenus    = @newGenus   
	Set @orgSpecies  = @newSpecies 
	Set @orgStrain   = @newStrain  
		
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[GetTaxonomyValueByTaxonomyID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTaxonomyValueByTaxonomyID] TO [PNL\D3M580] AS [dbo]
GO
