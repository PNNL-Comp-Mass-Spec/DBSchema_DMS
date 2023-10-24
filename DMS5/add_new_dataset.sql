/****** Object:  StoredProcedure [dbo].[add_new_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_dataset]
/****************************************************
**
**  Desc:
**      Adds new dataset entry to DMS database from contents of XML
**
**      This procedure is called by the Data Import Manager (DIM) while processing dataset trigger files
**
**      This procedure extracts the metadata from the XML then calls add_update_dataset
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          05/04/2007 grk - Ticket #434
**          10/02/2007 grk - Automatically release QC datasets (http://prismtrac.pnl.gov/trac/ticket/540)
**          10/02/2007 mem - Updated to query T_Dataset_Rating_Name for rating 5=Released
**          10/16/2007 mem - Added support for the 'DS Creator (PRN)' field
**          01/02/2008 mem - Now setting the rating to 'Released' for datasets that start with "Blank" (Ticket #593)
**          02/13/2008 mem - Increased size of @datasetName to varchar(128) (Ticket #602)
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          09/09/2010 mem - Now always looking up the request number associated with the new dataset
**          03/04/2011 mem - Now validating that @runFinish is not a future date
**          03/07/2011 mem - Now auto-defining experiment name if empty for QC_Shew and Blank datasets
**                         - Now auto-defining EMSL usage type to Maintenance for QC_Shew and Blank datasets
**          05/12/2011 mem - Now excluding Blank%-bad datasets when auto-setting rating to 'Released'
**          01/25/2013 mem - Now converting @xmlDoc to an XML variable instead of using sp_xml_preparedocument and OpenXML
**          11/15/2013 mem - Now scrubbing "Buzzard:" out of the comment if there is no other text
**          06/20/2014 mem - Now removing "Buzzard:" from the end of the comment
**          12/18/2014 mem - Replaced QC_Shew_1[0-9] with QC_Shew[_-][0-9][0-9]
**          03/25/2015 mem - Now also checking the dataset's experiment name against dbo.get_dataset_priority() to see if we should auto-release the dataset
**          05/29/2015 mem - Added support for "Capture Subfolder"
**          06/22/2015 mem - Now ignoring "Capture Subfolder" if it is an absolute path to a local drive (e.g. D:\ProteomicsData)
**          11/21/2016 mem - Added parameter @logDebugMessages
**          02/23/2017 mem - Added support for "LC Cart Config"
**          08/18/2017 mem - Change @captureSubfolder to '' if it is the same as @datasetName
**          06/13/2019 mem - Leave the dataset rating as 'Not Released', 'No Data (Blank/Bad)', or 'No Interest' for QC datasets
**          07/02/2019 mem - Add support for parameter "Work Package" in the XML file
**          09/04/2020 mem - Rename variable and match both 'Capture Subfolder' and 'Capture Subdirectory' in @xmlDoc
**          10/10/2020 mem - Rename variables
**          12/17/2020 mem - Ignore @captureSubfolder if it is an absolute path to a network share (e.g. \\proto-2\External_Orbitrap_Xfer)
**          05/26/2021 mem - Expand @message to varchar(1024)
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          11/25/2022 mem - Rename variable and use new parameter name when calling add_update_dataset
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Show parsed values when mode is 'check_add' or 'check_update'
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @xmlDoc varchar(4000),
    @mode varchar(24) = 'add', --  'add', 'parse_only', 'update', 'bad', 'check_add', 'check_update'
    @message varchar(1024) output,
    @logDebugMessages tinyint = 0
)
AS
    Set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Declare @hDoc int
    Declare @datasetId int

    Declare @existingRequestID int

    Declare @internalStandards varchar(64)
    Declare @addUpdateTimeStamp datetime

    Declare @runStartDate datetime
    Declare @runFinishDate datetime

    Declare @logMessage Varchar(1024)

    Set @message = ''
    Set @logDebugMessages = IsNull(@logDebugMessages, 0)

    Declare
        @datasetName             varchar(128)  = '',
        @experimentName          varchar(64)   = '',
        @instrumentName          varchar(64)   = '',
        @captureSubdirectory     varchar(255)  = '',
        @separationType          varchar(64)   = '',
        @lcCartName              varchar(128)  = '',
        @lcCartConfig            varchar(128)  = '',
        @lcColumn                varchar(64)   = '',
        @wellplateName           varchar(64)   = '',
        @wellNumber              varchar(64)   = '',
        @datasetType             varchar(64)   = '',
        @operatorUsername        varchar(64)   = '',
        @comment                 varchar(512)  = '',
        @interestRating          varchar(32)   = '',
        @requestID               int           = 0,      -- Request ID; this might get updated by add_update_dataset
        @workPackage             varchar(50)   = '',
        @emslUsageType           varchar(50)   = '',
        @emslProposalID          varchar(10)   = '',
        @emslUsersList           varchar(1024) = '',
        @runStart                varchar(64)   = '',
        @runFinish               varchar(64)   = '',
        @datasetCreatorUsername  varchar(128)  = ''

        -- Note that @datasetCreatorUsername is the username of the person that created the dataset;
        -- It is typically only present in trigger files created due to a dataset manually being created by a user

    ---------------------------------------------------
    --  Create temporary table to hold list of parameters
    ---------------------------------------------------

    CREATE TABLE #TPAR (
        paramName varchar(128),
        paramValue varchar(512)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary parameter table'
        goto DONE
    End

    ---------------------------------------------------
    -- Convert @xmlDoc to XML
    ---------------------------------------------------

    Set @xmlDoc = Coalesce(@xmlDoc, '')
    Declare @xml xml = Convert(xml, @xmlDoc)

    ---------------------------------------------------
    -- Populate parameter table from XML parameter description
    ---------------------------------------------------

    INSERT INTO #TPAR (paramName, paramValue)
    SELECT [Name], IsNull([Value], '')
    FROM ( SELECT  xmlNode.value('@Name', 'varchar(128)') AS [Name],
                   xmlNode.value('@Value', 'varchar(512)') AS [Value]
           FROM @xml.nodes('/Dataset/Parameter') AS R(xmlNode)
    ) LookupQ
    WHERE NOT [Name] IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary parameter table'
        goto DONE
    End

    ---------------------------------------------------
    -- Trap 'parse_only' mode here
    ---------------------------------------------------
    --
    If @mode = 'parse_only'
    Begin
        -- Show the contents of the temporary table
        SELECT CONVERT(char(24), paramName) AS Name, paramValue FROM #TPAR

        -- The 'parse_only' mode stops after #TPAR has been populated using the XML
        -- Use mode 'check_add' to also call add_update_dataset to validate the metadata
        goto DONE
    End

    ---------------------------------------------------
    -- Get arguments from parsed parameters
    ---------------------------------------------------

    SELECT    @datasetName             = paramValue FROM #TPAR WHERE paramName = 'Dataset Name'
    SELECT    @experimentName          = paramValue FROM #TPAR WHERE paramName = 'Experiment Name'
    SELECT    @instrumentName          = paramValue FROM #TPAR WHERE paramName = 'Instrument Name'
    SELECT    @captureSubdirectory     = paramValue FROM #TPAR WHERE paramName IN ('Capture Subfolder', 'Capture Subdirectory')
    SELECT    @separationType          = paramValue FROM #TPAR WHERE paramName = 'Separation Type'
    SELECT    @lcCartName              = paramValue FROM #TPAR WHERE paramName = 'LC Cart Name'
    SELECT    @lcCartConfig            = paramValue FROM #TPAR WHERE paramName = 'LC Cart Config'
    SELECT    @lcColumn                = paramValue FROM #TPAR WHERE paramName = 'LC Column'
    SELECT    @wellplateName           = paramValue FROM #TPAR WHERE paramName IN ('Wellplate Number', 'Wellplate Name')
    SELECT    @wellNumber              = paramValue FROM #TPAR WHERE paramName = 'Well Number'
    SELECT    @datasetType             = paramValue FROM #TPAR WHERE paramName = 'Dataset Type'
    SELECT    @operatorUsername        = paramValue FROM #TPAR WHERE paramName IN ('Operator (PRN)', 'Operator (Username)')
    SELECT    @comment                 = paramValue FROM #TPAR WHERE paramName = 'Comment'
    SELECT    @interestRating          = paramValue FROM #TPAR WHERE paramName = 'Interest Rating'
    SELECT    @requestID               = paramValue FROM #TPAR WHERE paramName = 'Request'
    SELECT    @workPackage             = paramValue FROM #TPAR WHERE paramName = 'Work Package'
    SELECT    @emslUsageType           = paramValue FROM #TPAR WHERE paramName = 'EMSL Usage Type'
    SELECT    @emslProposalID          = paramValue FROM #TPAR WHERE paramName = 'EMSL Proposal ID'
    SELECT    @emslUsersList           = paramValue FROM #TPAR WHERE paramName = 'EMSL Users List'
    SELECT    @runStart                = paramValue FROM #TPAR WHERE paramName = 'Run Start'
    SELECT    @runFinish               = paramValue FROM #TPAR WHERE paramName = 'Run Finish'
    SELECT    @datasetCreatorUsername  = paramValue FROM #TPAR WHERE paramName IN ('DS Creator (PRN)', 'DS Creator (Username)')


    ---------------------------------------------------
    -- Check for QC or Blank datasets
    ---------------------------------------------------

    If dbo.get_dataset_priority(@datasetName) > 0 OR
       dbo.get_dataset_priority(@experimentName) > 0 OR
       (@datasetName LIKE 'Blank%' AND Not @datasetName LIKE '%-bad')
    Begin
        If @interestRating Not In ('Not Released', 'No Interest') And @interestRating Not Like 'No Data%'
        Begin
            -- Auto set interest rating to 5
            -- Initially set @interestRating to the text 'Released' but then query
            -- T_Dataset_Rating_Name for rating 5 in case the rating name has changed

            Set @interestRating = 'Released'

            SELECT @interestRating = DRN_name
            FROM T_Dataset_Rating_Name
            WHERE (DRN_state_ID = 5)
        End
    End

    ---------------------------------------------------
    -- Possibly auto-define the experiment
    ---------------------------------------------------
    --
    If @experimentName = ''
    Begin
        If @datasetName Like 'Blank%'
            Set @experimentName = 'Blank'
        Else
        If @datasetName Like 'QC_Shew[_-][0-9][0-9][_-][0-9][0-9]%'
            Set @experimentName = Substring(@datasetName, 1, 13)

    End

    ---------------------------------------------------
    -- Possibly auto-define the @emslUsageType
    ---------------------------------------------------
    --
    If @emslUsageType = ''
    Begin
        If @datasetName Like 'Blank%' OR @datasetName Like 'QC_Shew%'
            Set @emslUsageType = 'MAINTENANCE'
    End

    ---------------------------------------------------
    -- Establish default parameters
    ---------------------------------------------------

    Set @internalStandards  = 'none'
    Set @addUpdateTimeStamp = GetDate()

    ---------------------------------------------------
    -- Check for the comment ending in "Buzzard:"
    ---------------------------------------------------

    Set @comment = LTrim(RTrim(@comment))
    If @comment Like '%Buzzard:'
        Set @comment = Substring(@comment, 1, Len(@comment) - 8)

    If @captureSubdirectory LIKE '[A-Z]:\%' OR @captureSubdirectory LIKE '\\%'
    Begin
        Set @message = 'Capture subfolder is not a relative path for dataset ' + @datasetName + '; ignoring ' + @captureSubdirectory

        exec post_log_entry 'Error', @message, 'add_new_dataset'

        Set @captureSubdirectory = ''
    End

    If @captureSubdirectory = @datasetName
    Begin
        Set @message = 'Capture subfolder is identical to the dataset name for ' + @datasetName + '; changing to an empty string'

        -- Post this message to the log every 3 days
        If Not Exists (
           SELECT *
           FROM T_Log_Entries
           WHERE message LIKE 'Capture subfolder is identical to the dataset name%' AND
                 Entered > DATEADD(day, -3, GETDATE()) )
        Begin
            exec post_log_entry 'Debug', @message, 'add_new_dataset'
        End

        Set @captureSubdirectory = ''
    End

    ---------------------------------------------------
    -- Create new dataset
    ---------------------------------------------------

    exec @myError = add_update_dataset
                        @datasetName,
                        @experimentName,
                        @operatorUsername,
                        @instrumentName,
                        @datasetType,
                        @lcColumn,
                        @wellplateName,
                        @wellNumber,
                        @separationType,
                        @internalStandards,
                        @comment,
                        @interestRating,
                        @lcCartName,
                        @emslProposalID,
                        @emslUsageType,
                        @emslUsersList,
                        @requestID,
                        @workPackage,
                        @mode,
                        @message output,
                        @captureSubfolder = @captureSubdirectory,
                        @lcCartConfig = @lcCartConfig,
                        @logDebugMessages = @logDebugMessages

    If @myError <> 0
    Begin
        -- Uncomment to log the XML to the T_Log_Entries
        --
        /*
        If @mode = 'add'
        Begin
            Set @logMessage = 'Error adding new dataset: ' + @message + '; ' + @xmlDoc

            Exec post_log_entry @type = 'Error',
                                @message = @logMessage,
                                @postedBy = 'add_new_dataset'
        End
        */

        RAISERROR (@message, 10, 1)
        Return 51032
    End

    ---------------------------------------------------
    -- Trap 'check' modes here
    ---------------------------------------------------

    If @mode = 'check_add' OR @mode = 'check_update'
    Begin
        -- Show the parsed values

        print 'DatasetName: ' + @datasetName
        print 'ExperimentName: ' + @experimentName
        print 'InstrumentName: ' + @instrumentName
        print 'CaptureSubdirectory: ' + @captureSubdirectory
        print 'SeparationType: ' + @separationType
        print 'LcCartName: ' + @lcCartName
        print 'LcCartConfig: ' + @lcCartConfig
        print 'LcColumn: ' + @lcColumn
        print 'WellplateName: ' + @wellplateName
        print 'WellNumber: ' + @wellNumber
        print 'DatasetType: ' + @datasetType
        print 'OperatorUsername: ' + @operatorUsername
        print 'Comment: ' + @comment
        print 'InterestRating: ' + @interestRating
        print 'RequestID: ' + Cast(@requestID As varchar(12))
        print 'WorkPackage: ' + @workPackage
        print 'EmslUsageType: ' + @emslUsageType
        print 'EmslProposalID: ' + @emslProposalID
        print 'EmslUsersList: ' + @emslUsersList
        print 'RunStart: ' + @runStart
        print 'RunFinish: ' + @runFinish
        print 'DatasetCreatorUsername: ' + @datasetCreatorUsername

        goto DONE
    End

    ---------------------------------------------------
    -- It's possible that @requestID got updated by add_update_dataset
    -- Lookup the current value
    ---------------------------------------------------

    -- First use Dataset Name to lookup the Dataset ID
    --
    Set @datasetId = 0

    SELECT @datasetId = Dataset_ID
    FROM T_Dataset
    WHERE (Dataset_Num = @datasetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve dataset ID'
        RAISERROR (@message, 10, 1)
        Return 51034
    End

    If @datasetId = 0
    Begin
        Set @message = 'Could not resolve dataset ID'
        RAISERROR (@message, 10, 1)
        Return 51035
    End

    ---------------------------------------------------
    -- Find request associated with dataset
    ---------------------------------------------------

    Set @existingRequestID = 0

    SELECT @existingRequestID = ID
    FROM T_Requested_Run
    WHERE DatasetID = @datasetId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve request ID'
        RAISERROR (@message, 10, 1)
        Return 51036
    End

    If @existingRequestID <> 0
        Set @requestID = @existingRequestID

    If Len(@datasetCreatorUsername) > 0
    Begin
        ---------------------------------------------------
        -- Update T_Event_Log to reflect @datasetCreatorUsername creating this dataset
        ---------------------------------------------------

        UPDATE T_Event_Log
        SET Entered_By = @datasetCreatorUsername + '; via ' + IsNull(Entered_By, '')
        FROM T_Event_Log
        WHERE Target_ID = @datasetId AND
              Target_State = 1 AND
              Target_Type = 4 AND
              Entered Between @addUpdateTimeStamp AND DateAdd(minute, 1, @addUpdateTimeStamp)

    End

    ---------------------------------------------------
    -- Update the associated request with run start/finish values
    ---------------------------------------------------

    If @requestID <> 0
    Begin

        If @runStart <> ''
            Set @runStartDate = Convert(datetime, @runStart)
        Else
            Set @runStartDate = Null

        If @runFinish <> ''
            Set @runFinishDate = Convert(datetime, @runFinish)
        Else
            Set @runFinishDate = Null

        If Not @runStartDate Is Null and Not @runFinishDate Is Null
        Begin
            -- Check whether the @runFinishDate value is in the future
            -- If it is, update it to match @runStartDate
            If DateDiff(day, GetDate(), @runFinishDate) > 1
            Begin
                Set @runFinishDate = @runStartDate
            End
        End

        UPDATE T_Requested_Run
        SET
            RDS_Run_Start = @runStartDate,
            RDS_Run_Finish = @runFinishDate
        WHERE (ID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            set @message = 'Error trying to update run times'
            RAISERROR (@message, 10, 1)
            Return 51033
        End
    End

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_dataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_new_dataset] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_new_dataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_new_dataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_new_dataset] TO [svc-dms] AS [dbo]
GO
