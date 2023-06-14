/****** Object:  StoredProcedure [dbo].[auto_update_separation_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_update_separation_type]
/****************************************************
**
**  Desc:
**      Update the separation type based on the name and acquisition length
**      Ignores datasets with an acquisition length under 6 minutes
**
**  Auth:   mem
**  Date:   10/09/2020 mem - Initial version
**          10/10/2020 mem - Adjust threshold for LC-Dionex-Formic_30min
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/13/2023 mem - Exit the procedure if the acquisition length is <= 5 minutes
**
*****************************************************/
(
    @separationType varchar(64),
    @acqLengthMinutes int,
    @optimalSeparationType varchar(64) = '' output
)
AS
    Set NoCount On

    Declare @message varchar(512)

    Set @separationType = ISNULL(@separationType, '')
    Set @acqLengthMinutes = ISNULL(@acqLengthMinutes, 0)
    Set @optimalSeparationType = ''

    If @acqLengthMinutes <= 5
    Begin
        If @acqLengthMinutes <= 0
            PRINT 'Acquisition length is 0 minutes; not updating separation type';
        Else
            PRINT 'Acquisition length is less than 5 minutes; not updating separation type';

        Set @optimalSeparationType = @separationType;

        Return 0
    End

    ---------------------------------------------------
    -- Update the separation type name if it matches certain conditions
    ---------------------------------------------------

    If @separationType Like 'LC-Waters-Formic%'
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

    If @separationType Like 'LC-Dionex-Formic%'
    Begin
        If @acqLengthMinutes < 50
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

    If @separationType Like 'LC-Agilent-Formic%'
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

            EXEC post_log_entry 'Error', @message, 'auto_update_separation_type', 1

            Set @optimalSeparationType = ''
        End
    End

    If @optimalSeparationType = ''
    Begin
        SET @optimalSeparationType = @separationType
    End

    Return 0

GO
