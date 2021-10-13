/****** Object:  UserDefinedFunction [dbo].[GetFileAttachmentPath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetFileAttachmentPath]
/****************************************************
**
**  Desc:
**    Returns storage path for file attachment for the given DMS tracking entity
**
**    @spreadFolder is the folder spreader, used to group items by date to avoid folders with 1000's of subfolders
**
**    The following entities have @spreadFolder based on year and month, e.g. 2016_2
**        Campaign
**        Dataset
**        Experiment
**        Sample_Prep_Request
**        Sample_Submission
**
**    The following entities have @spreadFolder based on year alone, e.g. 2016
**        Experiment_Group
**        Instrument_Config
**        Instrument_Config_History
**        Instrument_Operation
**        Instrument_Operation_History
**        LC_Cart_Config  (deprecated in 2017)
**        LC_Cart_Config_History
**
**    All other DMS entities have @spreadFolder in the form spread/ItemID, e.g. spread/195
**        LC_Cart_Configuration
**        Material_Container
**        Operations_Tasks
**        Osm_Package
**
**  Return value:
**    File attachment path, examples:
**        sample_prep_request/2017_1/4574
**        instrument_config/2015/5775
**        osm_package/spread/195
**
**  Auth:   grk
**  Date:   04/16/2011
**          04/26/2011 grk - added sample prep request
**          08/23/2011 grk - added experiment_group
**          11/15/2011 grk - added sample_submission
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          02/24/2017 mem - Update capitalization and add comments
**
*****************************************************/
(
    @entityType varchar(64),
    @entityID varchar(256)            -- Entity ID, though for Campaign, Dataset, Experiment, and Sample Prep Request supports both entity ID or entity name
)
Returns varchar(256)
AS
Begin

    Declare @spreadFolder varchar(24) = 'spread'
    Declare @created DateTime = '1/1/1900'

    -------------------------------------------------------
    IF @entityType = 'campaign'
    Begin
        Declare @campaignID int = Try_Convert(int, @entityID)

        IF @campaignID Is Null
        Begin
            SELECT @entityID = CONVERT(varchar(24), Campaign_ID),
                   @created = CM_created
            FROM dbo.T_Campaign
            WHERE Campaign_Num = @entityID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
        Else
        Begin
            SELECT @created = CM_created
            FROM dbo.T_Campaign
            WHERE Campaign_ID = @campaignID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
    End
    -------------------------------------------------------
    Else IF @entityType = 'experiment'
    Begin
        Declare @experimentID int = Try_Convert(int, @entityID)

        IF @experimentID Is Null
        Begin
            SELECT @entityID = CONVERT(varchar(24), Exp_ID),
                   @created = EX_created
            FROM T_Experiments
            WHERE Experiment_Num = @entityID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
        Else
        Begin
            SELECT @created = EX_created
            FROM T_Experiments
            WHERE Exp_ID = @experimentID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
    End
    -------------------------------------------------------
    Else IF @entityType = 'dataset'
    Begin
        Declare @datasetID int = Try_Convert(int, @entityID)

        IF @datasetID Is Null
        Begin
            SELECT @entityID = CONVERT(varchar(24), Dataset_ID),
                   @created = DS_created
            FROM T_Dataset
            WHERE Dataset_Num = @entityID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
        Else
        Begin
            SELECT @created = DS_created
            FROM T_Dataset
            WHERE Dataset_ID = @datasetID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
    End
    -------------------------------------------------------
    IF @entityType = 'sample_prep_request'
    Begin
        Declare @samplePrepID int = Try_Convert(int, @entityID)

        IF @samplePrepID Is Null
        Begin
            SELECT @entityID = CONVERT(varchar(24), ID),
                   @created = Created
            FROM dbo.T_Sample_Prep_Request
            WHERE Request_Name = @entityID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
        Else
        Begin
            SELECT @created = Created
            FROM dbo.T_Sample_Prep_Request
            WHERE ID = @samplePrepID

            SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
        End
    End
    -------------------------------------------------------
    Else IF @entityType = 'instrument_operation_history'
    Begin
        SET @entityType = 'instrument_operation'
        SELECT @created = Entered
        FROM dbo.T_Instrument_Operation_History
        WHERE ID = @entityID
        SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created))
    End
    -------------------------------------------------------
    Else IF @entityType = 'instrument_config_history'
    Begin
        SET @entityType = 'instrument_config'
        SELECT @created = Entered
        FROM dbo.T_Instrument_Config_History
        WHERE ID = @entityID
        SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created))
    End
    -------------------------------------------------------
    Else IF @entityType = 'lc_cart_config_history'
    Begin
        SET @entityType = 'lc_cart_config'
        SELECT @created = Entered
        FROM dbo.T_LC_Cart_Config_History
        WHERE ID = @entityID
        SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created))
    End
    -------------------------------------------------------
    Else IF @entityType = 'experiment_group'
    Begin
        SET @entityType = 'experiment_group'
        SELECT @created = EG_Created
        FROM T_Experiment_Groups
        WHERE Group_ID = @entityID
        SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created))
    End
    -------------------------------------------------------
    Else IF @entityType = 'sample_submission'
    Begin
        SELECT  @created = Created
        FROM    dbo.T_Sample_Submission
        WHERE   ID = @entityID
        SET @spreadFolder = CONVERT(varchar(12), DATEPART(year, @created)) + '_' + CONVERT(varchar(12), DATEPART(month, @created))
    End

    RETURN @entityType + '/' + @spreadFolder + '/' + @entityID

End

GO
GRANT VIEW DEFINITION ON [dbo].[GetFileAttachmentPath] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetFileAttachmentPath] TO [DMS2_SP_User] AS [dbo]
GO
