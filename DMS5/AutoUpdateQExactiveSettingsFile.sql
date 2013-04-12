ALTER FUNCTION dbo.AutoUpdateQExactiveSettingsFile
/****************************************************
**
**	Desc: 
**		Automatically changes the QExactive settings file to the MSConvert version if required
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	04/09/2013
**    
*****************************************************/
(
	@SettingsFile varchar(128)
)
RETURNS varchar(128)
AS
	BEGIN
	
		-- MSGF+ SettingsFiles
		If @SettingsFile = 'IonTrapDefSettings_DeconMSN.xml'
			Set @SettingsFile = 'IonTrapDefSettings_MSConvert.xml'

		If @SettingsFile = 'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ.xml'
			Set @SettingsFile = 'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ.xml'
			
		If @SettingsFile = 'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'
			Set @SettingsFile = 'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'

		-- Sequest Settings Files
		If @SettingsFile = 'FinniganDefSettings_DeconMSn.xml'
			Set @SettingsFile = 'FinniganDefSettings_MSConvert.xml'

		If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk.xml'
			Set @SettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk.xml'

		If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ.xml'
			Set @SettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ.xml'

		If @SettingsFile = 'FinniganDefSettings_DeconMSn_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'
			Set @SettingsFile = 'FinniganDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ_phospho.xml'

		RETURN @SettingsFile
	END
