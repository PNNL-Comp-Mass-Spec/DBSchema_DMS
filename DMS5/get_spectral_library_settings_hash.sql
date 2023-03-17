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
**
*****************************************************/
(
    @library_id int,
    @protein_collection_list varchar(2000) = '',
    @organism_db_file varchar(128) = '',
    @fragment_ion_mz_min real = 0,
    @fragment_ion_mz_max real = 0,
    @trim_n_terminal_met tinyint = 0,
    @cleavage_specificity varchar(64) = '',
    @missed_cleavages int = 0,
    @peptide_length_min tinyint = 0,
    @peptide_length_max tinyint = 0,
    @precursor_mz_min real = 0,
    @precursor_mz_max real = 0,
    @precursor_charge_min tinyint = 0,
    @precursor_charge_max tinyint = 0,
    @static_cys_carbamidomethyl tinyint = 0,
    @static_mods varchar(512) = '',
    @dynamic_mods varchar(512) = '',
    @max_dynamic_mods tinyint = 0,
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

    Set @library_id = Coalesce(@library_id, 0);

    If @library_id > 0
    Begin
        SELECT @protein_collection_list = Protein_Collection_List,
               @organism_db_file = Organism_DB_File,
               @fragment_ion_mz_min = Fragment_Ion_Mz_Min,
               @fragment_ion_mz_max = Fragment_Ion_Mz_Max,
               @trim_n_terminal_met = Trim_N_Terminal_Met,
               @cleavage_specificity = Cleavage_Specificity,
               @missed_cleavages = Missed_Cleavages,
               @peptide_length_min = Peptide_Length_Min,
               @peptide_length_max = Peptide_Length_Max,
               @precursor_mz_min = Precursor_Mz_Min,
               @precursor_mz_max = Precursor_Mz_Max,
               @precursor_charge_min = Precursor_Charge_Min,
               @precursor_charge_max = Precursor_Charge_Max,
               @static_cys_carbamidomethyl = Static_Cys_Carbamidomethyl,
               @static_mods = Static_Mods,
               @dynamic_mods = Dynamic_Mods,
               @max_dynamic_mods = Max_Dynamic_Mods
        FROM T_Spectral_Library
        WHERE Library_ID = @library_id;
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Spectral library ID not found in T_Spectral_Library: ' + Cast(@library_id As varchar(12));
            RAISERROR (@message, 10, 1)

            Set @hash = ''

            Return 50000
        End
    End
    Else
    Begin
        Set @protein_collection_list = Coalesce(@protein_collection_list, '');
        Set @organism_db_file = Coalesce(@organism_db_file, '');
        Set @fragment_ion_mz_min = Coalesce(@fragment_ion_mz_min, 0);
        Set @fragment_ion_mz_max = Coalesce(@fragment_ion_mz_max, 0);
        Set @trim_n_terminal_met = Coalesce(@trim_n_terminal_met, 0);
        Set @cleavage_specificity = Coalesce(@cleavage_specificity, '');
        Set @missed_cleavages = Coalesce(@missed_cleavages, 0);
        Set @peptide_length_min = Coalesce(@peptide_length_min, 0);
        Set @peptide_length_max = Coalesce(@peptide_length_max, 0);
        Set @precursor_mz_min = Coalesce(@precursor_mz_min, 0);
        Set @precursor_mz_max = Coalesce(@precursor_mz_max, 0);
        Set @precursor_charge_min = Coalesce(@precursor_charge_min, 0);
        Set @precursor_charge_max = Coalesce(@precursor_charge_max, 0);
        Set @static_cys_carbamidomethyl = Coalesce(@static_cys_carbamidomethyl, 0);
        Set @static_mods = Coalesce(@static_mods, '');
        Set @dynamic_mods = Coalesce(@dynamic_mods, '');
        Set @max_dynamic_mods = Coalesce(@max_dynamic_mods, 0);
    End

    -- Remove any spaces in the static and dynamic mods
    Set @static_mods = Replace(@static_mods, ' ', '');
    Set @dynamic_mods = Replace(@dynamic_mods, ' ', '');

    ---------------------------------------------------
    -- Store the options in @settings
    ---------------------------------------------------

    Set @settings = @protein_collection_list + '_' +
                    @organism_db_file + '_' +
                    Cast(@fragment_ion_mz_min As varchar(24)) + '_' +
                    Cast(@fragment_ion_mz_max As varchar(24)) + '_' +
                    Cast(@trim_n_terminal_met As varchar(24)) + '_' +
                    Cast(@cleavage_specificity As varchar(24)) + '_' +
                    Cast(@missed_cleavages As varchar(24)) + '_' +
                    Cast(@peptide_length_min As varchar(24)) + '_' +
                    Cast(@peptide_length_max As varchar(24)) + '_' +
                    Cast(@precursor_mz_min As varchar(24)) + '_' +
                    Cast(@precursor_mz_max As varchar(24)) + '_' +
                    Cast(@precursor_charge_min As varchar(24)) + '_' +
                    Cast(@precursor_charge_max As varchar(24)) + '_' +
                    Cast(@static_cys_carbamidomethyl As varchar(24)) + '_' +
                    @static_mods + '_' +
                    @dynamic_mods + '_' +
                    Cast(@max_dynamic_mods As varchar(24)) + '_'

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
