/****** Object:  StoredProcedure [dbo].[get_spectral_library_settings_hash] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_spectral_library_settings_hash]
/****************************************************
**
**  Desc:
**    Computes a SHA-1 hash value using the settings used to create an in-silico digest based spectral library
**
**    If the Spectral library ID is non-zero, reads settings from T_Spectral_Library
**    Otherwise, uses the values provided to the other parameters
**
**  Returns:
**    Computed hash and string-based settings, using output arguments @hash and @settings
**    Hash will be an empty string if an error
**
**  Auth:   mem
**  Date:   03/15/2023 mem - Initial Release
**          03/16/2023 mem - Use lowercase variable names
**          03/18/2023 mem - Rename parameters
**          03/28/2023 mem - Change @trimNTerminalMet and @staticCysCarbamidomethyl from tinyint to bit
**          03/29/2023 mem - Change tinyint parameters to smallint
**          04/16/2023 mem - Auto-update @proteinCollectionList and @organismDbFile to 'na' if an empty string
**
*****************************************************/
(
    @libraryId int,
    @proteinCollectionList varchar(2000) = '',
    @organismDbFile varchar(128) = '',
    @fragmentIonMzMin real = 0,
    @fragmentIonMzMax real = 0,
    @trimNTerminalMet bit = 0,
    @cleavageSpecificity varchar(64) = '',
    @missedCleavages int = 0,
    @peptideLengthMin smallint = 0,
    @peptideLengthMax smallint = 0,
    @precursorMzMin real = 0,
    @precursorMzMax real = 0,
    @precursorChargeMin smallint = 0,
    @precursorChargeMax smallint = 0,
    @staticCysCarbamidomethyl bit = 0,
    @staticMods varchar(512) = '',
    @dynamicMods varchar(512) = '',
    @maxDynamicMods smallint = 0,
    @hash varchar(64) = '' Output,
    @settings varchar(4000) = '' Output
)
As
Begin
    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @message varchar(128)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @libraryId = Coalesce(@libraryId, 0);

    If @libraryId > 0
    Begin
        SELECT @proteinCollectionList = Protein_Collection_List,
               @organismDbFile = Organism_DB_File,
               @fragmentIonMzMin = Fragment_Ion_Mz_Min,
               @fragmentIonMzMax = Fragment_Ion_Mz_Max,
               @trimNTerminalMet = Trim_N_Terminal_Met,
               @cleavageSpecificity = Cleavage_Specificity,
               @missedCleavages = Missed_Cleavages,
               @peptideLengthMin = Peptide_Length_Min,
               @peptideLengthMax = Peptide_Length_Max,
               @precursorMzMin = Precursor_Mz_Min,
               @precursorMzMax = Precursor_Mz_Max,
               @precursorChargeMin = Precursor_Charge_Min,
               @precursorChargeMax = Precursor_Charge_Max,
               @staticCysCarbamidomethyl = Static_Cys_Carbamidomethyl,
               @staticMods = Static_Mods,
               @dynamicMods = Dynamic_Mods,
               @maxDynamicMods = Max_Dynamic_Mods
        FROM T_Spectral_Library
        WHERE Library_ID = @libraryId;
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Spectral library ID not found in T_Spectral_Library: ' + Cast(@libraryId As varchar(12));
            RAISERROR (@message, 10, 1)

            Set @hash = ''

            Return 50000
        End
    End
    Else
    Begin
        Set @proteinCollectionList = Coalesce(@proteinCollectionList, '');
        Set @organismDbFile = Coalesce(@organismDbFile, '');
        Set @fragmentIonMzMin = Coalesce(@fragmentIonMzMin, 0);
        Set @fragmentIonMzMax = Coalesce(@fragmentIonMzMax, 0);
        Set @trimNTerminalMet = Coalesce(@trimNTerminalMet, 0);
        Set @cleavageSpecificity = Coalesce(@cleavageSpecificity, '');
        Set @missedCleavages = Coalesce(@missedCleavages, 0);
        Set @peptideLengthMin = Coalesce(@peptideLengthMin, 0);
        Set @peptideLengthMax = Coalesce(@peptideLengthMax, 0);
        Set @precursorMzMin = Coalesce(@precursorMzMin, 0);
        Set @precursorMzMax = Coalesce(@precursorMzMax, 0);
        Set @precursorChargeMin = Coalesce(@precursorChargeMin, 0);
        Set @precursorChargeMax = Coalesce(@precursorChargeMax, 0);
        Set @staticCysCarbamidomethyl = Coalesce(@staticCysCarbamidomethyl, 0);
        Set @staticMods = Coalesce(@staticMods, '');
        Set @dynamicMods = Coalesce(@dynamicMods, '');
        Set @maxDynamicMods = Coalesce(@maxDynamicMods, 0);
        
        If Len(@proteinCollectionList) = 0
            Set @proteinCollectionList = 'na'

        If Len(@organismDbFile) = 0
            Set @organismDbFile = 'na'
    End

    -- Remove any spaces in the static and dynamic mods
    Set @staticMods = Replace(@staticMods, ' ', '');
    Set @dynamicMods = Replace(@dynamicMods, ' ', '');

    ---------------------------------------------------
    -- Store the options in @settings
    ---------------------------------------------------

    Set @settings = @proteinCollectionList + '_' +
                    @organismDbFile + '_' +
                    Cast(@fragmentIonMzMin As varchar(24)) + '_' +
                    Cast(@fragmentIonMzMax As varchar(24)) + '_' +
                    Case When @trimNTerminalMet > 0 Then 'true' Else 'false' End + '_' +
                    Cast(@cleavageSpecificity As varchar(24)) + '_' +
                    Cast(@missedCleavages As varchar(24)) + '_' +
                    Cast(@peptideLengthMin As varchar(24)) + '_' +
                    Cast(@peptideLengthMax As varchar(24)) + '_' +
                    Cast(@precursorMzMin As varchar(24)) + '_' +
                    Cast(@precursorMzMax As varchar(24)) + '_' +
                    Cast(@precursorChargeMin As varchar(24)) + '_' +
                    Cast(@precursorChargeMax As varchar(24)) + '_' +
                    Case When @staticCysCarbamidomethyl > 0 Then 'true' Else 'false' End + '_' +
                    @staticMods + '_' +
                    @dynamicMods + '_' +
                    Cast(@maxDynamicMods As varchar(24)) + '_'

    ---------------------------------------------------
    -- Convert @settings to a SHA-1 hash (upper case hex string)
    --
    -- Use HashBytes() to get the full SHA-1 hash, as a varbinary
    -- Use Convert() to convert to text, truncating to only use the first 32 characters
    -- The '2' sent to Convert() means 'no 0x prefix'
    ---------------------------------------------------

    Set @hash = CONVERT(varchar(64), HashBytes('SHA1', @settings), 2)

    Return 0
END

GO
