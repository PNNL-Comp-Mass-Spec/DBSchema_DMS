/****** Object:  StoredProcedure [dbo].[AutoUpdateSeparationType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AutoUpdateSeparationType]
/****************************************************
** 
**  Desc:   Update the separation type based on the name and acquisition length
** 
**  Auth:   mem
**  Date:   10/09/2020
**    
*****************************************************/
(
    @separationType varchar(64),
    @acqLengthMinutes int,
    @optimalSeparationType varchar(64) = '' output
)
As
    Set NoCount On
    
    Declare @message varchar(512)

    Set @separationType = ISNULL(@separationType, '')
    Set @acqLengthMinutes = ISNULL(@acqLengthMinutes, 0)
    Set @optimalSeparationType = ''

    -- Update the separation type name if it matches certain conditions
    If @separationType Like 'LC-Waters-Formic%' AND @acqLengthMinutes > 5
    Begin
        If @acqLengthMinutes < 35
	        Set @optimalSeparationType = 'LC-Waters-Formic_30min'
        Else If @acqLengthMinutes < 48
	        Set @optimalSeparationType = 'LC-Waters-Formic_40min'
        Else If @acqLengthMinutes < 80
	        Set @optimalSeparationType = 'LC-Waters-Formic_60min'
        Else If @acqLengthMinutes < 107
	        Set @optimalSeparationType = 'LC-Waters-Formic_90min'
        Else If @acqLengthMinutes < 165
	        Set @optimalSeparationType = 'LC-Waters-Formic_2hr'
        Else If @acqLengthMinutes < 220
	        Set @optimalSeparationType = 'LC-Waters-Formic_3hr'
        Else If @acqLengthMinutes < 280
	        Set @optimalSeparationType = 'LC-Waters-Formic_4hr'
        Else
	        Set @separationType = 'LC-Waters-Formic_5hr'
    End

    If @separationType Like 'LC-Dionex-Formic%' AND @acqLengthMinutes > 5
    Begin
        If @acqLengthMinutes < 35
           Set @optimalSeparationType = 'LC-Dionex-Formic_30min'
        Else If @acqLengthMinutes < 107
           Set @optimalSeparationType = 'LC-Dionex-Formic_100min'
        Else If @acqLengthMinutes < 165
           Set @optimalSeparationType = 'LC-Dionex-Formic_2hr'
        Else If @acqLengthMinutes < 280
           Set @optimalSeparationType = 'LC-Dionex-Formic_3hr'
        Else
           Set @optimalSeparationType = 'LC-Dionex-Formic_5hr'
    End

    If @separationType Like 'LC-Agilent-Formic%' AND @acqLengthMinutes > 5
    Begin
        If @acqLengthMinutes < 35
           Set @optimalSeparationType = 'LC-Agilent-Formic_30minute'
        Else If @acqLengthMinutes < 80
           Set @optimalSeparationType = 'LC-Agilent-Formic_60minute'
        Else If @acqLengthMinutes < 107
           Set @optimalSeparationType = 'LC-Agilent-Formic_100minute'
        Else If @acqLengthMinutes < 165
           Set @optimalSeparationType = 'LC-Agilent-Formic_2hr'
        Else
           Set @optimalSeparationType = 'LC-Agilent-Formic_3hr'
    End

    If @optimalSeparationType <> ''
    Begin
        -- Validate the auto-defined separation type
        If Not Exists (SELECT * from T_Secondary_Sep WHERE SS_name = @optimalSeparationType)
        Begin
            Set @message= 'Invalid separation type; ' + @optimalSeparationType + ' not found in T_Secondary_Sep'

            EXEC PostLogEntry 'Error', @message, 'AutoUpdateSeparationType', 1

            Set @optimalSeparationType = ''
        End
    End

    If @optimalSeparationType = ''
    Begin
        SET @optimalSeparationType = @separationType
    End

    return 0

GO
