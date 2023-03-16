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
**    Computed hash, or an empty string if an error
**
**  Auth:   mem
**  Date:   03/15/2023 mem - Initial Release
**
*****************************************************/
(
    @library_id Int,
    @protein_collection_list varchar(2000) = '',
    @organism_db_file varchar(128) = '',
    @fragment_ion_mz_min real = 0,
    @fragment_ion_mz_max real = 0,
    @trim_n_terminal_met tinyint = 0,
    @cleavage_specificity varchar(64) = '',
    @missed_cleavages int  = 0,
    @peptide_length_min tinyint  = 0,
    @peptide_length_max tinyint  = 0,
    @precursor_mz_min real  = 0,
    @precursor_mz_max real  = 0,
    @precursor_charge_min tinyint  = 0,
    @precursor_charge_max tinyint  = 0,
    @static_cys_carbamidomethyl tinyint  = 0,
    @static_mods varchar(512) = '',
    @dynamic_mods varchar(512) = '',
    @max_dynamic_mods tinyint = 0,
    @hash Varchar(64) = '' Output,
    @settings Varchar(4000) = '' Output
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
        SELECT @Protein_Collection_List = Protein_Collection_List,
               @Organism_DB_File = Organism_DB_File,
               @Fragment_Ion_Mz_Min = Fragment_Ion_Mz_Min,
               @Fragment_Ion_Mz_Max = Fragment_Ion_Mz_Max,
               @Trim_N_Terminal_Met = Trim_N_Terminal_Met,
               @Cleavage_Specificity = Cleavage_Specificity,
               @Missed_Cleavages = Missed_Cleavages,
               @Peptide_Length_Min = Peptide_Length_Min,
               @Peptide_Length_Max = Peptide_Length_Max,
               @Precursor_Mz_Min = Precursor_Mz_Min,
               @Precursor_Mz_Max = Precursor_Mz_Max,
               @Precursor_Charge_Min = Precursor_Charge_Min,
               @Precursor_Charge_Max = Precursor_Charge_Max,
               @Static_Cys_Carbamidomethyl = Static_Cys_Carbamidomethyl,
               @Static_Mods = Static_Mods,
               @Dynamic_Mods = Dynamic_Mods,
               @Max_Dynamic_Mods = Max_Dynamic_Mods
        FROM T_Spectral_Library
        WHERE Library_ID = @library_id;
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Spectral library ID not found in T_Spectral_Library: ' + Cast(@library_id As Varchar(12));
            RAISERROR (@message, 10, 1)

            Set @hash = ''

            Return 50000
        End
    End
    Else
    Begin
        Set @Protein_Collection_List = Coalesce(@Protein_Collection_List, '');
        Set @Organism_DB_File = Coalesce(@Organism_DB_File, '');
        Set @Fragment_Ion_Mz_Min = Coalesce(@Fragment_Ion_Mz_Min, 0);
        Set @Fragment_Ion_Mz_Max = Coalesce(@Fragment_Ion_Mz_Max, 0);
        Set @Trim_N_Terminal_Met = Coalesce(@Trim_N_Terminal_Met, 0);
        Set @Cleavage_Specificity = Coalesce(@Cleavage_Specificity, '');
        Set @Missed_Cleavages = Coalesce(@Missed_Cleavages, 0);
        Set @Peptide_Length_Min = Coalesce(@Peptide_Length_Min, 0);
        Set @Peptide_Length_Max = Coalesce(@Peptide_Length_Max, 0);
        Set @Precursor_Mz_Min = Coalesce(@Precursor_Mz_Min, 0);
        Set @Precursor_Mz_Max = Coalesce(@Precursor_Mz_Max, 0);
        Set @Precursor_Charge_Min = Coalesce(@Precursor_Charge_Min, 0);
        Set @Precursor_Charge_Max = Coalesce(@Precursor_Charge_Max, 0);
        Set @Static_Cys_Carbamidomethyl = Coalesce(@Static_Cys_Carbamidomethyl, 0);
        Set @Static_Mods = Coalesce(@Static_Mods, '');
        Set @Dynamic_Mods = Coalesce(@Dynamic_Mods, '');
        Set @Max_Dynamic_Mods = Coalesce(@Max_Dynamic_Mods, 0);
    End

    -- Remove any spaces in the static and dynamic mods
    Set @Static_Mods = Replace(@Static_Mods, ' ', '');
    Set @Dynamic_Mods = Replace(@Dynamic_Mods, ' ', '');

    ---------------------------------------------------
    -- Store the options in @settings
    ---------------------------------------------------

    Set @settings = @Protein_Collection_List + '_' +
                    @Organism_DB_File + '_' +
                    Cast(@Fragment_Ion_Mz_Min As Varchar(24)) + '_' +
                    Cast(@Fragment_Ion_Mz_Max As Varchar(24)) + '_' +
                    Cast(@Trim_N_Terminal_Met As Varchar(24)) + '_' +
                    Cast(@Cleavage_Specificity As Varchar(24)) + '_' +
                    Cast(@Missed_Cleavages As Varchar(24)) + '_' +
                    Cast(@Peptide_Length_Min As Varchar(24)) + '_' +
                    Cast(@Peptide_Length_Max As Varchar(24)) + '_' +
                    Cast(@Precursor_Mz_Min As Varchar(24)) + '_' +
                    Cast(@Precursor_Mz_Max As Varchar(24)) + '_' +
                    Cast(@Precursor_Charge_Min As Varchar(24)) + '_' +
                    Cast(@Precursor_Charge_Max As Varchar(24)) + '_' +
                    Cast(@Static_Cys_Carbamidomethyl As Varchar(24)) + '_' +
                    @Static_Mods + '_' +
                    @Dynamic_Mods + '_' +
                    Cast(@max_dynamic_mods As Varchar(24)) + '_'

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
