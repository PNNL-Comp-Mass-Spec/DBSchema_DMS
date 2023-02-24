/****** Object:  StoredProcedure [dbo].[get_taxonomy_value_by_taxonomy_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_taxonomy_value_by_taxonomy_id]
/****************************************************
**
**  Desc: Looks up taxonomy values for the given TaxonomyID
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/03/2016 mem - Auto define Phylum as Community when @NCBITaxonomyID is 48479
**          03/31/2021 mem - Expand @organismName to varchar(128)
**          08/08/2022 mem - Use Substring instead of Replace when removing genus name from species name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @ncbiTaxonomyID int,                    -- TaxonomyID value to lookup; ignored if @previewResults > 0 and the organism has NCBI_Taxonomy_ID defined in T_Organisms
    @orgDomain varchar(64)=''   output,     -- input/output value
    @orgKingdom varchar(64)=''  output,     -- input/output value
    @orgPhylum varchar(64)=''   output,     -- input/output value
    @orgClass varchar(64)=''    output,     -- input/output value
    @orgOrder varchar(64)=''    output,     -- input/output value
    @orgFamily varchar(64)=''   output,     -- input/output value
    @orgGenus varchar(128)=''   output,     -- input/output value
    @orgSpecies varchar(128)='' output,     -- input/output value
    @orgStrain varchar(128)=''  output,     -- input/output value
    @previewResults int = 0                 -- Less than 0 to preview results for @ncbiTaxonomyID; greater than 0 to preview results for the given OrganismID in T_Organisms
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @ncbiTaxonomyID = IsNull(@ncbiTaxonomyID, 0)

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

    Declare @organismName varchar(128)= '[No Organism]'

    If @previewResults > 0
    Begin
        Declare @newNCBITaxonomyID int

        Select @newNCBITaxonomyID = NCBI_Taxonomy_ID,
               @organismName = OG_name,
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
            Set @ncbiTaxonomyID = @newNCBITaxonomyID

    End

    If @ncbiTaxonomyID = 0
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

    INSERT INTO #Tmp_TaxonomyInfo( Entry_ID, [Rank], [Name] )
    SELECT Entry_ID,
           [Rank],
           [Name]
    FROM dbo.[s_get_taxid_taxonomy_table] ( @ncbiTaxonomyID )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        ---------------------------------------------------
        -- Populate the taxonomy variables
        ---------------------------------------------------

        -- Superkingdom
        exec update_taxonomy_item_if_defined 'superkingdom', @newDomain output

        -- Subkingdom, Kingdom
        exec update_taxonomy_item_if_defined 'subkingdom', @newKingdom output
        exec update_taxonomy_item_if_defined 'kingdom', @newKingdom output

        If @newKingdom = '' And @newDomain = 'bacteria'
            Set @newKingdom = 'Prokaryote'

        -- Subphylum, phylum
        exec update_taxonomy_item_if_defined 'subphylum', @newPhylum output
        exec update_taxonomy_item_if_defined 'phylum', @newPhylum output

        -- Subclass, superclass, class
        exec update_taxonomy_item_if_defined 'subclass', @newClass output
        exec update_taxonomy_item_if_defined 'superclass', @newClass output
        exec update_taxonomy_item_if_defined 'class', @newClass output


        -- Suborder, superorder, order
        exec update_taxonomy_item_if_defined 'suborder', @newOrder output
        exec update_taxonomy_item_if_defined 'superorder', @newOrder output
        exec update_taxonomy_item_if_defined 'order', @newOrder output

        -- Subfamily, superfamily, family
        exec update_taxonomy_item_if_defined 'subfamily', @newFamily output
        exec update_taxonomy_item_if_defined 'superfamily', @newFamily output
        exec update_taxonomy_item_if_defined 'family', @newFamily output

        -- Subgenus, Genus
        exec update_taxonomy_item_if_defined 'subgenus', @newGenus output
        exec update_taxonomy_item_if_defined 'genus', @newGenus output

        -- Subspecies, species
        exec update_taxonomy_item_if_defined 'subspecies', @newSpecies output
        exec update_taxonomy_item_if_defined 'species', @newSpecies output

        -- If the species name starts with the genus name, remove it
        If @newSpecies Like @newGenus + ' %' And Len(@newSpecies) > Len(@newGenus) + 1
        Begin
            Set @newSpecies = Substring(@newSpecies, LEN(@newGenus) + 2, 200)
        End

        Declare @taxonomyName varchar(255)
        Declare @taxonomyRank varchar(32)

        SELECT @taxonomyName = [Name],
                @taxonomyRank = [Rank]
        FROM  #Tmp_TaxonomyInfo
        WHERE Entry_ID = 1

        If @taxonomyRank = 'no rank' And @taxonomyName <> 'environmental samples'
        Begin
            Set @newStrain = @taxonomyName

            -- Remove genus and species if present
            Set @newStrain = LTrim(Replace(LTrim(Replace(@newStrain, @newGenus, '')), @newSpecies, ''))
        End

    End

    ---------------------------------------------------
    -- Auto-define some values when the Taxonomy ID is 48479 (environmental samples)
    ---------------------------------------------------
    --
    If @ncbiTaxonomyID = 48479
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
        SELECT  Case When @previewResults > 0 Then @previewResults Else 0 End as OrganismID,
                @organismName as Organism,
                @ncbiTaxonomyID AS NCBITaxonomyID,
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
GRANT VIEW DEFINITION ON [dbo].[get_taxonomy_value_by_taxonomy_id] TO [DDL_Viewer] AS [dbo]
GO
