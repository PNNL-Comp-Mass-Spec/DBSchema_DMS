/****** Object:  UserDefinedFunction [dbo].[auto_update_settings_file_to_centroid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[auto_update_settings_file_to_centroid]
/****************************************************
**
**  Desc:
**      Automatically changes the settings file to a version that uses MSConvert to centroid the data
**      This is useful for QExactive datasets, since DeconMSn seems to do more harm than good with QExactive data
**      Also useful for Orbitrap datasets with profile-mode MS/MS spectra
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   04/09/2013
**          01/11/2015 mem - Updated MSGF+ settings files to use DeconMSn_Centroid versions
**          03/30/2015 mem - Added parameter @toolName
**                         - Now retrieving MSGF+ auto-centroid values from column MSGFPlus_AutoCentroid
**                         - Renamed the procedure from AutoUpdateQExactiveSettingsFile
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @settingsFile varchar(128),
    @toolName varchar(64)
)
RETURNS varchar(128)
AS
    BEGIN
        Declare @NewSettingsFile varchar(128) = ''

        -- First look for a match in T_Settings_Files

        SELECT @NewSettingsFile = MSGFPlus_AutoCentroid
        FROM T_Settings_Files
        WHERE File_Name = @SettingsFile And
              Analysis_Tool = @toolName


        If IsNull(@NewSettingsFile, '') = '' And @toolName Like 'Sequest%'
        Begin
            -- Sequest Settings Files
            If @SettingsFile = 'FinniganDefSettings_DeconMSn.xml'
                Set @NewSettingsFile = 'FinniganDefSettings_MSConvert.xml'

            If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk.xml'
                Set @NewSettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk.xml'

            If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ.xml'
                Set @NewSettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ.xml'

            If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'
                Set @NewSettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'
        End

        If IsNull(@NewSettingsFile, '') <> ''
            Set @SettingsFile = @NewSettingsFile

        Return @SettingsFile

    END

GO
GRANT VIEW DEFINITION ON [dbo].[auto_update_settings_file_to_centroid] TO [DDL_Viewer] AS [dbo]
GO
