/****** Object:  StoredProcedure [dbo].[AddUpdateReferenceCompound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateReferenceCompound]
/****************************************************
**
**  Desc:
**      Adds new or updates existing reference compound in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/28/2017 mem - Initial version
**          12/19/2017 mem - Add parameters @compoundTypeName, @organismName, @wellplateName, @wellNumber, and @modifications
**          01/03/2018 mem - Add parameter @geneName and move parameter @modifications
**                         - No longer require that @compoundName be unique in T_Reference_Compound
**                         - Allow @description to be empty
**                         - Properly handle float-based dates (resulting from Excel copy / paste-value issues)
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**
*****************************************************/
(
    @compoundID int,
    @compoundName varchar(64),        -- Reference compound name or peptide sequence
    @description varchar(500),
    @compoundTypeName varchar(64),
    @geneName varchar(128),            -- Gene or Protein name
    @modifications varchar(500),
    @organismName varchar(128),
    @pubChemID varchar(30),            -- Will be converted to an integer; empty strings are stored as null
    @campaignName varchar(64),
    @containerName varchar(128) = 'na',
    @wellplateName varchar(64),
    @wellNumber varchar(64),
    @contactPRN varchar(64),        -- Contact for the Source; typically PNNL staff, but can be offsite person
    @supplier varchar(64),             -- Source that the material came from; can be a person (onsite or offsite) or a company
    @productId varchar(128),
    @purchaseDate varchar(30),        -- Will be converted to a date
    @purity varchar(64),
    @purchaseQuantity varchar(128),
    @mass varchar(30),                -- Will be converted to a float
    @active varchar(3),                -- Can be: Yes, No, Y, N, 1, 0
    @mode varchar(12) = 'add',        -- 'add', 'update', 'check_add', 'check_update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 0
    Declare @compoundIdAndName varchar(128) = Cast(IsNull(@compoundID, 0) as varchar(12)) + ': ' + IsNull(@compoundName, '??')

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateReferenceCompound', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @compoundName = LTrim(RTrim(IsNull(@compoundName, '')))
    Set @description = LTrim(RTrim(IsNull(@description, '')))
    Set @compoundTypeName = LTrim(RTrim(IsNull(@compoundTypeName, '')))
    Set @geneName = LTrim(RTrim(IsNull(@geneName, '')))
    Set @organismName = LTrim(RTrim(IsNull(@organismName, '')))
    Set @pubChemID = LTrim(RTrim(IsNull(@pubChemID, '')))
    Set @campaignName = LTrim(RTrim(IsNull(@campaignName, '')))
    Set @contactPRN = LTrim(RTrim(IsNull(@contactPRN, '')))
    Set @supplier = LTrim(RTrim(IsNull(@supplier, '')))
    Set @productId = LTrim(RTrim(IsNull(@productId, '')))
    Set @purchaseDate = LTrim(RTrim(IsNull(@purchaseDate, '')))
    Set @mass = LTrim(RTrim(IsNull(@mass, '')))
    set @active = LTrim(RTrim(IsNull(@active, '1')))
    Set @callingUser = IsNull(@callingUser, '')

    Set @myError = 0

    If @compoundID Is Null AND NOT @mode IN ('add', 'check_add')
    Begin
        RAISERROR ('Compound ID cannot be null', 11, 1)
    End

    If LEN(@compoundName) < 1
    Begin
        RAISERROR ('Compound Name must be defined', 11, 1)
    End

    Set @compoundIdAndName = Cast(IsNull(@compoundID, 0) as varchar(12)) + ': ' + IsNull(@compoundName, '??')

    If LEN(@compoundTypeName) < 1
    Begin
        RAISERROR ('Compound type name must be defined', 11, 7)
    End

    If LEN(@organismName) < 1
    Begin
        Set @organismName = 'None'
    End

    If LEN(@campaignName) < 1
    Begin
        RAISERROR ('Campaign Name must be defined', 11, 1)
    End

    If LEN(@contactPRN) < 1
    Begin
        RAISERROR ('Contact Name cannot be blank', 11, 3)
    End

    If LEN(@supplier) < 1
    Begin
        RAISERROR ('Supplier cannot be blank', 11, 5)
    End

    Declare @pubChemIdValue int
    Declare @massValue float
    Declare @purchaseDateValue datetime
    Declare @activeValue tinyint

    If @pubChemID = ''
        Set @pubChemIdValue = null
    Else
    Begin
        Set @pubChemIdValue = Try_Parse(@pubChemID as int)
        If @pubChemIdValue Is Null
            RAISERROR ('Error, PubChemID is not an integer: %s', 11, 9, @pubChemID)
    End

    If @mass = ''
        Set @massValue = 0
    Else
    Begin
        Set @massValue = Try_Parse(@mass as float)
        If @massValue Is Null
            RAISERROR ('Error, non-numeric mass: %s', 11, 9, @mass)
    End

    If @active in ('Y', 'Yes', '1')
        Set @activeValue = 1
    Else If @active in ('N', 'No', '0')
        Set @activeValue = 0
    Else
        RAISERROR ('Active should be Y or N', 11, 1)

    If @purchaseDate = ''
        Set @purchaseDateValue = null
    Else
    Begin
        If IsDate(@purchaseDate) = 1
            Set @purchaseDateValue = CONVERT(datetime, @purchaseDate)
        Else
        Begin
            If Not TRY_CAST(@purchaseDate as float) IS NULL
            Begin
                -- Integer or float based date (likely an Excel conversion artifact)
                -- Convert to a float then subtract 2 (trial and error revealed this subtraction to be necessary)
                Declare @purchaseDateFloat int = Cast(@purchaseDate AS float) - 2
                Set @purchaseDateValue = CONVERT(datetime, @purchaseDateFloat)
            End
            Else
            Begin
                RAISERROR ('Error, invalid purchase date: %s', 11, 9, @purchaseDate)
            End
        End
    End

    ---------------------------------------------------
    -- Resolve compound type name to ID
    ---------------------------------------------------

    Declare @compoundTypeID int = 0

    SELECT @compoundTypeID = Compound_Type_ID
    FROM T_Reference_Compound_Type_Name
    WHERE Compound_Type_Name = @compoundTypeName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @compoundTypeID = 0
    Begin
        RAISERROR ('Invalid compound type name', 11, 5)
    End

    ---------------------------------------------------
    -- Resolve organism name to ID
    ---------------------------------------------------

    Declare @organismID int = 0

    exec @organismID = GetOrganismID @organismName

    If @organismID = 0
    Begin
        RAISERROR ('Could not find entry in database for organism name "%s"', 11, 43, @organismName)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @curContainerID int = 0

    If @mode IN ('update', 'check_update')
    Begin
        -- Confirm the compound exists
        --
        If Not Exists (SELECT * FROM T_Reference_Compound WHERE Compound_ID = @compoundID)
        Begin
            Set @msg = 'Cannot update: Reference compound ID ' + Cast(@compoundID as varchar(12)) + ' is not in database '
            RAISERROR (@msg, 11, 12)
        End

        SELECT @curContainerID = Container_ID
        FROM T_Reference_Compound
        WHERE Compound_ID = @compoundID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End

    ---------------------------------------------------
    -- Resolve campaign name to ID
    ---------------------------------------------------

    Declare @campaignID int = 0
    --
    execute @campaignID = GetCampaignID @campaignName
    --
    If @campaignID = 0
    Begin
        Set @msg = 'Could not resolve campaign name "' + @campaignName + '" to ID"'
        RAISERROR (@msg, 11, 13)
    End

    ---------------------------------------------------
    -- Resolve container name to ID
    ---------------------------------------------------

    Declare @containerID int = 0
    --
    If ISNULL(@containerName, '') = ''
        Set @containerName = 'na'

    SELECT @containerID = ID
    FROM T_Material_Containers
    WHERE Tag = @containerName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Could not resolve container name "' + @containerName + '" to ID'
        RAISERROR (@msg, 11, 15)
    End

    ---------------------------------------------------
    -- Resolve current container id to name
    ---------------------------------------------------

    Declare @curContainerName varchar(125) = ''
    --
    SELECT @curContainerName = Tag
    FROM T_Material_Containers
    WHERE ID = @curContainerID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error resolving name of current container'
        RAISERROR (@msg, 11, 16)
    End

    ---------------------------------------------------
    -- Resolve PRNs to user number
    ---------------------------------------------------

    -- Verify that Contact PRN is valid and resolve its ID
    --
    Declare @userID int

    Declare @MatchCount int
    Declare @NewPRN varchar(64)

    execute @userID = GetUserID @contactPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @contactPRN contains simply the username
        --
        SELECT @contactPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @contactPRN
        -- Try to auto-resolve the name

        exec AutoResolveNameToPRN @contactPRN, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match found; update @contactPRN
            Set @contactPRN = @NewPRN
        End

    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin -- <add>
        INSERT INTO T_Reference_Compound (
            Compound_Name,
            Description,
            Compound_Type_ID,
            Gene_Name,
            Organism_ID,
            PubChem_CID,
            Campaign_ID,
            Container_ID,
            Wellplate_Name,
            Well_Number,
            Contact_PRN,
            Supplier,
            Product_ID,
            Purchase_Date,
            Purity,
            Purchase_Quantity,
            Mass,
            Modifications,
            Created,
            [Active]
        ) VALUES (
            @compoundName,
            @description,
            @compoundTypeID,
            @geneName,
            @organismID,
            @pubChemIdValue,
            @campaignID,
            @containerID,
            @wellplateName,
            @wellNumber,
            @contactPRN,
            @supplier,
            @productId,
            @purchaseDateValue,
            @purity,
            @purchaseQuantity,
            @massValue,
            @modifications,
            GETDATE(),
            1             -- Active
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Insert operation failed: "' + @compoundName + '"'
            RAISERROR (@msg, 11, 18)
        End

        Set @compoundID = SCOPE_IDENTITY()

        Declare @StateID int = 1

        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
            Exec AlterEventLogEntryUser 13, @compoundID, @StateID, @callingUser

        -- Material movement logging
        --
        If @curContainerID != @containerID
        Begin
            exec PostMaterialLogEntry
                'Reference Compound Move',  -- Type
                @compoundIdAndName,         -- Item
                'na',                       -- Initial State (aka Old container)
                @containerName,             -- Final State   (aka New container
                @callingUser,
                'Reference Compound added'

        End

    End -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin -- <update>
        Set @myError = 0
        --
        UPDATE T_Reference_Compound
        Set
            Compound_Name = @compoundName,
            Description = @description,
            Compound_Type_ID = @compoundTypeID,
            Gene_Name = @geneName,
            Organism_ID = @organismID,
            PubChem_CID = @pubChemIdValue,
            Campaign_ID = @campaignID,
            Container_ID = @containerID,
            Wellplate_Name = @wellplateName,
            Well_Number = @wellNumber,
            Contact_PRN = @contactPRN,
            Supplier = @supplier,
            Product_ID = @productID,
            Purchase_Date = @purchaseDateValue,
            Purity = @purity,
            Purchase_Quantity = @purchaseQuantity,
            Mass = @massValue,
            Modifications = @modifications,
            [Active] = @activeValue
        WHERE Compound_ID = @compoundID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Update operation failed, ID ' + @compoundIdAndName
            RAISERROR (@msg, 11, 19)
        End

        -- Material movement logging
        --
        If @curContainerID != @containerID
        Begin
            exec PostMaterialLogEntry
                'Reference Compound Move',  -- Type
                @compoundIdAndName,         -- Item
                @curContainerName,          -- Initial State (aka Old container)
                @containerName,             -- Final State   (aka New container
                @callingUser,
                'Reference Compound updated'
        End

    End -- </update>

    End TRY
    Begin CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; ID ' + @compoundIdAndName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateReferenceCompound'
        End

    End CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateReferenceCompound] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateReferenceCompound] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateReferenceCompound] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateReferenceCompound] TO [Limited_Table_Write] AS [dbo]
GO
