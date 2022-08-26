/****** Object:  StoredProcedure [dbo].[AddNewDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddNewDataset]
/****************************************************
**
**  Desc: 
**      Adds new dataset entry to DMS database from contents of XML.
**
**      This is for use by sample automation software
**      associated with the mass spec instrument to
**      create new datasets automatically following
**      an instrument run.
**
**      This procedure is called by the DataImportManager (DIM)
**
**  Return values: 0: success, otherwise, error code
** 
**  Auth:   grk
**          05/04/2007 grk - Ticket #434
**          10/02/2007 grk - Automatically release QC datasets (http://prismtrac.pnl.gov/trac/ticket/540)
**          10/02/2007 mem - Updated to query T_DatasetRatingName for rating 5=Released
**          10/16/2007 mem - Added support for the 'DS Creator (PRN)' field
**          01/02/2008 mem - Now setting the rating to 'Released' for datasets that start with "Blank" (Ticket #593)
**          02/13/2008 mem - Increased size of @datasetName to varchar(128) (Ticket #602)
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          09/09/2010 mem - Now always looking up the request number associated with the new dataset
**          03/04/2011 mem - Now validating that @runFinish is not a future date
**          03/07/2011 mem - Now auto-defining experiment name if empty for QC_Shew and Blank datasets
**                         - Now auto-defining EMSL usage type to Maintenance for QC_Shew and Blank datasets
**          05/12/2011 mem - Now excluding Blank%-bad datasets when auto-setting rating to 'Released'
**          01/25/2013 mem - Now converting @xmlDoc to an XML variable instead of using sp_xml_preparedocument and OpenXML
**          11/15/2013 mem - Now scrubbing "Buzzard:" out of the comment if there is no other text
**          06/20/2014 mem - Now removing "Buzzard:" from the end of the comment
**          12/18/2014 mem - Replaced QC_Shew_1[0-9] with QC_Shew[_-][0-9][0-9]
**          03/25/2015 mem - Now also checking the dataset's experiment name against dbo.GetDatasetPriority() to see if we should auto-release the dataset
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

    Set @message = ''
    Set @logDebugMessages = IsNull(@logDebugMessages, 0)
    
    Declare
        @datasetName          varchar(128)  = '',
        @experimentName       varchar(64)   = '',
        @instrumentName       varchar(64)   = '',
        @captureSubdirectory  varchar(255)  = '',
        @separationType       varchar(64)   = '',
        @lcCartName           varchar(128)  = '',
        @lcCartConfig         varchar(128)  = '',
        @lcColumn             varchar(64)   = '',
        @wellplateNumber      varchar(64)   = '',
        @wellNumber           varchar(64)   = '',
        @datasetType          varchar(64)   = '',
        @operatorPRN          varchar(64)   = '',
        @comment              varchar(512)  = '',
        @interestRating       varchar(32)   = '',
        @requestID            int           = 0,      -- Request ID; this might get updated by AddUpdateDataset
        @workPackage          varchar(50)   = '',
        @emslUsageType        varchar(50)   = '',
        @emslProposalID       varchar(10)   = '',
        @emslUsersList        varchar(1024) = '',
        @runStart             varchar(64)   = '',
        @runFinish            varchar(64)   = '',
        @datasetCreatorPRN    varchar(128)  = ''
        
        -- Note that @datasetCreatorPRN is the PRN of the person that created the dataset; 
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
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary parameter table'
        goto DONE
    End

    ---------------------------------------------------
    -- Convert @xmlDoc to XML
    ---------------------------------------------------
    
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
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary parameter table'
        goto DONE
    End

    ---------------------------------------------------
    -- Trap 'parse_only' mode here
    ---------------------------------------------------
    If @mode = 'parse_only'
    Begin
        --
        SELECT CONVERT(char(24), paramName) AS Name, paramValue FROM #TPAR
        goto DONE
    End

    ---------------------------------------------------
    -- Get arguments from parsed parameters
    ---------------------------------------------------

    SELECT    @datasetName          = paramValue FROM #TPAR WHERE paramName = 'Dataset Name'
    SELECT    @experimentName       = paramValue FROM #TPAR WHERE paramName = 'Experiment Name'
    SELECT    @instrumentName       = paramValue FROM #TPAR WHERE paramName = 'Instrument Name'
    SELECT    @captureSubdirectory  = paramValue FROM #TPAR WHERE paramName IN ('Capture Subfolder', 'Capture Subdirectory')
    SELECT    @separationType       = paramValue FROM #TPAR WHERE paramName = 'Separation Type'
    SELECT    @lcCartName           = paramValue FROM #TPAR WHERE paramName = 'LC Cart Name'
    SELECT    @lcCartConfig         = paramValue FROM #TPAR WHERE paramName = 'LC Cart Config'
    SELECT    @lcColumn             = paramValue FROM #TPAR WHERE paramName = 'LC Column'
    SELECT    @wellplateNumber      = paramValue FROM #TPAR WHERE paramName = 'Wellplate Number'
    SELECT    @wellNumber           = paramValue FROM #TPAR WHERE paramName = 'Well Number'
    SELECT    @datasetType          = paramValue FROM #TPAR WHERE paramName = 'Dataset Type'
    SELECT    @operatorPRN          = paramValue FROM #TPAR WHERE paramName = 'Operator (PRN)'
    SELECT    @comment              = paramValue FROM #TPAR WHERE paramName = 'Comment'
    SELECT    @interestRating       = paramValue FROM #TPAR WHERE paramName = 'Interest Rating'
    SELECT    @requestID            = paramValue FROM #TPAR WHERE paramName = 'Request'
    SELECT    @workPackage          = paramValue FROM #TPAR WHERE paramName = 'Work Package'
    SELECT    @emslUsageType        = paramValue FROM #TPAR WHERE paramName = 'EMSL Usage Type'
    SELECT    @emslProposalID       = paramValue FROM #TPAR WHERE paramName = 'EMSL Proposal ID'
    SELECT    @emslUsersList        = paramValue FROM #TPAR WHERE paramName = 'EMSL Users List'
    SELECT    @runStart             = paramValue FROM #TPAR WHERE paramName = 'Run Start'
    SELECT    @runFinish            = paramValue FROM #TPAR WHERE paramName = 'Run Finish'
    SELECT    @datasetCreatorPRN    = paramValue FROM #TPAR WHERE paramName = 'DS Creator (PRN)'

    
     ---------------------------------------------------
    -- Check for QC or Blank datasets
     ---------------------------------------------------

    If dbo.GetDatasetPriority(@datasetName) > 0 OR 
       dbo.GetDatasetPriority(@experimentName) > 0 OR
       (@datasetName LIKE 'Blank%' AND Not @datasetName LIKE '%-bad')
    Begin
        If @interestRating Not In ('Not Released', 'No Interest') And @interestRating Not Like 'No Data%'
        Begin
            -- Auto set interest rating to 5
            -- Initially set @interestRating to the text 'Released' but then query
            -- T_DatasetRatingName for rating 5 in case the rating name has changed
        
            Set @interestRating = 'Released'

            SELECT @interestRating = DRN_name
            FROM T_DatasetRatingName
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
        
        exec PostLogEntry 'Error', @message, 'AddNewDataset'
       
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
            exec PostLogEntry 'Debug', @message, 'AddNewDataset'
        End
       
        Set @captureSubdirectory = ''
    End
    
    ---------------------------------------------------
    -- Create new dataset
    ---------------------------------------------------
    exec @myError = AddUpdateDataset
                        @datasetName,
                        @experimentName,
                        @operatorPRN,
                        @instrumentName,
                        @datasetType,
                        @lcColumn,
                        @wellplateNumber,
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
                        @captureSubfolder=@captureSubdirectory,
                        @lcCartConfig=@lcCartConfig,
                        @logDebugMessages=@logDebugMessages
    If @myError <> 0
    Begin
        RAISERROR (@message, 10, 1)
        return 51032
    End

    ---------------------------------------------------
    -- Trap 'check' modes here
    ---------------------------------------------------
    If @mode = 'check_add' OR @mode = 'check_update'
        goto DONE


    ---------------------------------------------------
    -- It's possible that @requestID got updated by AddUpdateDataset
    -- Lookup the current value
    ---------------------------------------------------
    
    -- First use Dataset Name to lookup the Dataset ID
    --        
    Set @datasetId = 0
    --
    SELECT @datasetId = Dataset_ID
    FROM T_Dataset
    WHERE (Dataset_Num = @datasetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve dataset ID'
        RAISERROR (@message, 10, 1)
        return 51034
    End

    If @datasetId = 0
    Begin
        Set @message = 'Could not resolve dataset ID'
        RAISERROR (@message, 10, 1)
        return 51035
    End
    
    ---------------------------------------------------
    -- Find request associated with dataset
    ---------------------------------------------------
    
    Set @existingRequestID = 0
    --
    SELECT @existingRequestID = ID
    FROM T_Requested_Run
    WHERE DatasetID = @datasetId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve request ID'
        RAISERROR (@message, 10, 1)
        return 51036
    End
    
    If @existingRequestID <> 0
        Set @requestID = @existingRequestID
    
    If Len(@datasetCreatorPRN) > 0
    Begin -- <a>
        ---------------------------------------------------
        -- Update T_Event_Log to reflect @datasetCreatorPRN creating this dataset
        ---------------------------------------------------
        
        UPDATE T_Event_Log
        SET Entered_By = @datasetCreatorPRN + '; via ' + IsNull(Entered_By, '')
        FROM T_Event_Log
        WHERE Target_ID = @datasetId AND
              Target_State = 1 AND 
              Target_Type = 4 AND 
              Entered Between @addUpdateTimeStamp AND DateAdd(minute, 1, @addUpdateTimeStamp)
            
    End -- </a>
        

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
        --
        If @myError <> 0
        Begin
            set @message = 'Error trying to update run times'
            RAISERROR (@message, 10, 1)
            return 51033
        End
    End

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddNewDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [svc-dms] AS [dbo]
GO
