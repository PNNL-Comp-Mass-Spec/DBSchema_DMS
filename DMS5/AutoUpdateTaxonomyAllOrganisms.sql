/****** Object:  StoredProcedure [dbo].[AutoUpdateTaxonomyAllOrganisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AutoUpdateTaxonomyAllOrganisms]
/****************************************************
**
**  Desc:   Auto-defines the taxonomy for all organisms 
**          using the NCBI_Taxonomy_ID value defined for each organism
**
**  Auth:    mem
**  Date:    03/02/2016 mem - Initial version
**           03/31/2021 mem - Expand OrganismName to varchar(128)
**    
*****************************************************/
(
    @infoOnly tinyint = 1            -- 1 to preview results
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Create a temporary table for previewing the results
    ---------------------------------------------------

    CREATE TABLE #Tmp_OrganismsToUpdate (
        OrganismID int not null, 
        OrganismName varchar(128) not null, 
        NCBITaxonomyID int not null,
        OldDomain varchar(64), 
        NewDomain varchar(64), 
        OldKingdom varchar(64),  
        NewKingdom varchar(64), 
        OldPhylum varchar(64),   
        NewPhylum varchar(64), 
        OldClass varchar(64),    
        NewClass varchar(64), 
        OldOrder varchar(64),    
        NewOrder varchar(64), 
        OldFamily varchar(64),   
        NewFamily varchar(64), 
        OldGenus varchar(128),    
        NewGenus varchar(128), 
        OldSpecies varchar(128),  
        NewSpecies varchar(128), 
        OldStrain varchar(128),   
        NewStrain  varchar(128)
    )

    ---------------------------------------------------
    -- Declare variables
    ---------------------------------------------------

    Declare @oldDomain varchar(64),
        @oldKingdom varchar(64),
        @oldPhylum varchar(64),
        @oldClass varchar(64),
        @oldOrder varchar(64),
        @oldFamily varchar(64),
        @oldGenus varchar(128),
        @oldSpecies varchar(128),
        @oldStrain varchar(128),
        @orgDomain varchar(64),
        @orgKingdom varchar(64),
        @orgPhylum varchar(64),
        @orgClass varchar(64),
        @orgOrder varchar(64),
        @orgFamily varchar(64),
        @orgGenus varchar(128),
        @orgSpecies varchar(128),
        @orgStrain varchar(128)

    Declare @ncbiTaxonomyID int
    Declare @organismName varchar(128)
    Declare @organismID int = 0

    ---------------------------------------------------
    -- Loop over the organism entries
    ---------------------------------------------------

    While @organismID > -1
    Begin -- <WhileLoop>
    
        SELECT TOP 1 @ncbiTaxonomyID = NCBI_Taxonomy_ID,
                     @organismName = OG_name,
                     @organismID = Organism_ID,
                     @oldDomain = IsNull(OG_Domain, ''),
                     @oldKingdom = IsNull(OG_Kingdom, ''),
                     @oldPhylum = IsNull(OG_Phylum, ''),
                     @oldClass = IsNull(OG_Class, ''),
                     @oldOrder = IsNull(OG_Order, ''),
                     @oldFamily = IsNull(OG_Family, ''),
                     @oldGenus = IsNull(OG_Genus, ''),
                     @oldSpecies = IsNull(OG_Species, ''),
                     @oldStrain = IsNull(OG_Strain, '')
        FROM T_Organisms
        WHERE Organism_ID > @organismID AND
              NOT NCBI_Taxonomy_ID IS NULL
        ORDER BY Organism_ID         
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @organismID = -1
        Else
        Begin -- <MatchFound>

            ---------------------------------------------------
            -- Auto-define the taxonomy terms
            ---------------------------------------------------

            Set @orgDomain  = @oldDomain
            Set @orgKingdom = @oldKingdom
            Set @orgPhylum  = @oldPhylum
            Set @orgClass   = @oldClass
            Set @orgOrder   = @oldOrder
            Set @orgFamily  = @oldFamily
            Set @orgGenus   = @oldGenus
            Set @orgSpecies = @oldSpecies
            Set @orgStrain  = @oldStrain
                
            EXEC GetTaxonomyValueByTaxonomyID 
                    @ncbiTaxonomyID,
                    @orgDomain =  @orgDomain output,
                    @orgKingdom = @orgKingdom output,
                    @orgPhylum =  @orgPhylum output,
                    @orgClass =   @orgClass output,
                    @orgOrder =   @orgOrder output,
                    @orgFamily =  @orgFamily output,
                    @orgGenus =   @orgGenus output,
                    @orgSpecies = @orgSpecies output,
                    @orgStrain =  @orgStrain output,
                    @previewResults = 0

            If  @orgDomain  <> @oldDomain  OR
                @orgKingdom <> @oldKingdom OR
                @orgPhylum  <> @oldPhylum  OR
                @orgClass   <> @oldClass   OR
                @orgOrder   <> @oldOrder   OR
                @orgFamily  <> @oldFamily  OR
                @orgGenus   <> @oldGenus   OR
                @orgSpecies <> @oldSpecies OR
                @orgStrain  <> @oldStrain
            Begin -- <ValuesDiffer>
            
                ---------------------------------------------------
                -- New data to preview or store
                ---------------------------------------------------

                If @infoOnly <> 0
                Begin
                    INSERT INTO #Tmp_OrganismsToUpdate( 
                                    OrganismID, OrganismName, NCBITaxonomyID,
                                    OldDomain,  NewDomain,
                                    OldKingdom, NewKingdom,
                                    OldPhylum,  NewPhylum,
                                    OldClass,   NewClass,
                                    OldOrder,   NewOrder,
                                    OldFamily,  NewFamily,
                                    OldGenus,   NewGenus,
                                    OldSpecies, NewSpecies,
                                    OldStrain,  NewStrain )
                    VALUES( @organismID, @organismName, @ncbiTaxonomyID, 
                            @oldDomain,  @orgDomain, 
                            @oldKingdom, @orgKingdom, 
                            @oldPhylum,  @orgPhylum, 
                            @oldClass,   @orgClass, 
                            @oldOrder,   @orgOrder, 
                            @oldFamily,  @orgFamily, 
                            @oldGenus,   @orgGenus, 
                            @oldSpecies, @orgSpecies, 
                            @oldStrain,  @orgStrain)
                End
                Else
                Begin
                
                    UPDATE T_Organisms
                    SET OG_Domain =  @orgDomain,
                        OG_Kingdom = @orgKingdom,
                        OG_Phylum =  @orgPhylum,
                        OG_Class =   @orgClass,
                        OG_Order =   @orgOrder,
                        OG_Family =  @orgFamily,
                        OG_Genus =   @orgGenus,
                        OG_Species = @orgSpecies,
                        OG_Strain =  @orgStrain
                    WHERE Organism_ID = @organismID
                    
                End -- </InfoOnly>
                    
            End -- </ValuesDiffer>

        End -- </MatchFound>
        
    End -- </WhileLoop>

    If @infoOnly <> 0
    Begin
        SELECT *
        FROM #Tmp_OrganismsToUpdate
        ORDER BY OrganismID
    End
    
    return 0
    

GO
GRANT VIEW DEFINITION ON [dbo].[AutoUpdateTaxonomyAllOrganisms] TO [DDL_Viewer] AS [dbo]
GO
