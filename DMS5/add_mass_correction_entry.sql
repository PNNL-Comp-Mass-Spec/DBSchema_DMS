/****** Object:  StoredProcedure [dbo].[add_mass_correction_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_mass_correction_entry]
/****************************************************
**
**  Desc:   Adds a new or updates an existing global modification
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   kja
**  Date:   08/02/2004
**          10/17/2013 mem - Expanded @modDescription to varchar(128)
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          04/02/2020 mem - Expand @modName to varchar(32)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
(
    @modName varchar(32),
    @modDescription varchar(128),
    @modMassChange float(8),
    @modAffectedAtom char(1) = '-',
    @message varchar(512) output
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    set @myError = 0
    if LEN(@modName) < 1
    begin
        set @myError = 51000
        RAISERROR ('modName must be specified', 10, 1)
    end

    --

    if LEN(@modDescription) < 1
    begin
        set @myError = 51001
        RAISERROR ('modDescription must be specified', 10, 1)
    end

    if @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @MassCorrectionID int = 0
    --
    execute @MassCorrectionID = get_mass_correction_id @modMassChange

    -- Cannot create an entry that already exists

    if @MassCorrectionID <> 0
    begin
        set @msg = 'Cannot Add: Mass Correction "' + @modMasschange + '" already exists'
        RAISERROR (@msg, 10, 1)
        return 51003
    end

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    execute @MassCorrectionID = get_mass_correction_id_from_name @modName

    if @MassCorrectionID <> 0
    begin
        set @msg = 'Cannot Add: Mass Correction "' + @modName + '" already exists'
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Declare @transName varchar(32)
    set @transName = 'Add_Mass_Correction_Factor'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------

    begin

        INSERT INTO T_Mass_Correction_Factors (
            Mass_Correction_Tag,
            Description,
            Monoisotopic_Mass,
            Affected_Atom,
            Original_Source
        ) VALUES (
            @modName,
            @modDescription,
            Round(@modMassChange,4),
            @modAffectedAtom,
            'PNNL'
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @msg = 'Insert operation failed: "' + @modName + '"'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end

    commit transaction @transName

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_mass_correction_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_mass_correction_entry] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_mass_correction_entry] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_mass_correction_entry] TO [Limited_Table_Write] AS [dbo]
GO
