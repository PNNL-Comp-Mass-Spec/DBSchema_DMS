/****** Object:  StoredProcedure [dbo].[update_requested_run_factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_factors]
/****************************************************
**
**  Desc:
**      Update requested run factors from input XML list
**
**      @factorList will look like this if it comes from web page https://dms2.pnl.gov/requested_run_factors/param
**                                                             or https://dms2.pnl.gov/requested_run_batch_blocking/grid
**
**      The "type" attribute of the <id> tag defines what the "i" attributes map to
**
**      <id type="Request" />
**      <r i="193911" f="Factor1" v="Aa" />
**      <r i="194113" f="Factor1" v="Bb" />
**      <r i="205898" f="Factor2" v="Aa" />
**      <r i="194113" f="Factor2" v="Bb" />
**
**
**      Second example for web page https://dms2.pnl.gov/requested_run_factors/param
**
**      <id type="Dataset" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor1" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor1" v="Bb" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor2" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor2" v="Bb" />
**
**
**      XML coming from stored procedure Make_Automatic_Requested_Run_Factors will look like the following
**      - Here, the identifier is RequestID
**
**      <r i="1197727" f="Actual_Run_Order" v="1" />
**      <r i="1197728" f="Actual_Run_Order" v="2" />
**      <r i="1197725" f="Actual_Run_Order" v="3" />
**      <r i="1197726" f="Actual_Run_Order" v="4" />
**      <r i="1197722" f="Actual_Run_Order" v="5" />
**
**
**      One other supported format uses DatasetID
**      - If any records contain "d" attributes, the "type" attribute of the <id> tag is ignored
**
**      <r d="214536" f="Factor1" v="Aa" />
**      <r d="214003" f="Factor1" v="Bb" />
**      <r d="213522" f="Factor2" v="Aa" />
**
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/20/2010 grk - initial release
**          03/17/2010 grk - expanded blacklist
**          03/22/2010 grk - allow dataset id
**          09/02/2011 mem - Now calling post_usage_log_entry
**          12/08/2011 mem - Added additional blacklisted factor names: Experiment, Dataset, Name, and Status
**          12/09/2011 mem - Now checking for invalid Requested Run IDs
**          12/15/2011 mem - Added support for the "type" attribute in the <id> tag
**          09/12/2012 mem - Now auto-removing columns Dataset_ID, Dataset, or Experiment if they are present as factor names
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/06/2016 mem - Populate column Last_Updated in T_Factor
**                         - Expand the warning message for unrecognized @IDType
**          11/08/2016 mem - Use get_user_login_without_domain to obtain the user's network login
**          11/10/2016 mem - Pass '' to get_user_login_without_domain
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/12/2022 mem - Trim leading and trailing whitespace when storing factors
**          11/11/2022 mem - Trim whitespace when checking for unnamed factors
**          12/13/2022 mem - Ignore factors named 'Dataset ID'
**                         - Rename temp table
**          01/25/2023 mem - Block factors named 'Run_Order'
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          11/03/2023 mem - Capitalize factor names based on historic usage
**
*****************************************************/
(
    @factorList text,                    -- XML (see above)
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0                -- Set to 1 to preview the changes that would be made
)
AS
    SET NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @Msg2 varchar(512)
    Declare @invalidCount int

    Declare @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_factors', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    SET @message = ''

    If IsNull(@callingUser, '') = ''
        SET @callingUser = dbo.get_user_login_without_domain('')

    Set @infoOnly = IsNull(@infoOnly, 0)

    -- Uncomment to log the XML for debugging purposes
    -- Declare @debugMessage Varchar(4096) = Cast(@factorList As varchar(4096))
    -- exec post_log_entry 'Debug', @debugMessage, 'update_requested_run_factors'

    -----------------------------------------------------------
    -- Temp table to hold factors
    -----------------------------------------------------------
    --
    CREATE TABLE #Tmp_FactorInfo (
        Entry_ID int Identity(1,1),
        Identifier varchar(128) null,   -- Could be RequestID or DatasetName
        Factor varchar(128) null,       -- Factor name
        Value varchar(128) null,
        DatasetID INT null,             -- DatasetID; not always present
        RequestID INT null,
        UpdateSkipCode tinyint          -- 0 to update, 1 means unchanged, 2 means invalid factor name
    )

    -----------------------------------------------------------
    -- Copy @factorList text variable into the XML variable
    -----------------------------------------------------------
    SET @xml = @factorList

    -----------------------------------------------------------
    -- Check whether the XML contains <id type="Request" />
    -- Note that this will be ignored if entries like the following exist in the XML:
    --    <r d="214536" f="Factor1" v="Aa" />
    -----------------------------------------------------------
    --
    Declare @IDType varchar(256)

    SELECT @IDType = xmlNode.value('@type', 'nvarchar(256)')
    FROM @xml.nodes('//id') AS R(xmlNode)

    If IsNull(@IDType, '') = ''
    Begin
        -- Assume @IDType is RequestID
        Set @IDType = 'RequestID'
    End

    Declare @IDTypeOriginal varchar(256) = @IDType

    -- Auto-update @IDType if needed
    If @IDType = 'Request'
        Set @IDType = 'RequestID'

    If @IDType = 'DatasetName' OR @IDType Like 'Dataset_Name' OR @IDType Like 'Dataset_Num'
        Set @IDType = 'Dataset'

    -----------------------------------------------------------
    -- Populate temp table with new parameters
    -----------------------------------------------------------
    --
    INSERT INTO #Tmp_FactorInfo (Identifier, Factor, Value, DatasetID, UpdateSkipCode)
    SELECT LTrim(RTrim(xmlNode.value('@i', 'nvarchar(256)'))) As Identifier,
           LTrim(RTrim(xmlNode.value('@f', 'nvarchar(256)'))) As Factor,
           LTrim(RTrim(xmlNode.value('@v', 'nvarchar(256)'))) As Value,
           LTrim(RTrim(xmlNode.value('@d', 'nvarchar(256)'))) As DatasetID,        -- Only sometimes present
           0 AS UpdateSkipCode
    FROM @xml.nodes('//r') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to convert list'
        Return 51009
    End

    -----------------------------------------------------------
    -- If table contains DatasetID values, auto-populate the Identifier column with RequestIDs
    -----------------------------------------------------------

    If Exists (SELECT * FROM #Tmp_FactorInfo WHERE Not DatasetID IS NULL)
    Begin -- <a>
        If Exists (SELECT * FROM #Tmp_FactorInfo WHERE DatasetID IS NULL)
        Begin
            Set @message = 'Encountered a mix of XML tag attributes; if using the "d" attribute for DatasetID, then all entries must have "d" defined'

            If @infoOnly <> 0
            Begin
                SELECT * FROM #Tmp_FactorInfo
            End

            Return 51016
        End

        UPDATE #Tmp_FactorInfo
        SET Identifier = RR.ID
        FROM #Tmp_FactorInfo
            INNER JOIN dbo.T_Requested_Run RR
            ON #Tmp_FactorInfo.DatasetID = RR.DatasetID
        WHERE #Tmp_FactorInfo.Identifier IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- The identifier column now contains RequestID values
        Set @IDType = 'RequestID'

        If Exists (SELECT * FROM #Tmp_FactorInfo WHERE Identifier IS NULL)
        Begin
            Set @message = 'Unable to resolve DatasetID to RequestID for one or more entries (DatasetID not found in Requested Run table)'

            -- Construct a list of DatasetIDs that are not present in T_Requested_Run
            Set @Msg2 = ''

            SELECT @Msg2 = @Msg2 + #Tmp_FactorInfo.DatasetID + ', '
            FROM #Tmp_FactorInfo
            WHERE Identifier Is Null

            If IsNull(@Msg2, '') <> ''
            Begin
                -- Append @Msg2 to @message
                Set @message = @message + '; error with: ' + Substring(@Msg2, 1, Len(@Msg2)-1)
            End

            If @infoOnly <> 0
            Begin
                SELECT * FROM #Tmp_FactorInfo
            End

            Return 51017
        End

    End -- </a>

    -----------------------------------------------------------
    -- Validate @IDType
    -----------------------------------------------------------

    If Not @IDType IN ('RequestID', 'DatasetID', 'Job', 'Dataset')
    Begin
        Set @message = 'Identifier type "' + @IDTypeOriginal + '" was not recognized in the header row; should be Request, RequestID, DatasetID, Job, or Dataset (i.e. Dataset Name)'

        If @infoOnly <> 0
        Begin
            SELECT * FROM #Tmp_FactorInfo
        End

        Return 51018
    End

    -----------------------------------------------------------
    -- Make sure the identifiers are all numeric for certain types
    -----------------------------------------------------------
    --
    If @IDType IN ('RequestID', 'DatasetID', 'Job')
    Begin
        Set @Msg2 = ''

        SELECT @Msg2 = @Msg2 + Identifier + ','
        FROM #Tmp_FactorInfo
        WHERE Try_Parse(Identifier as int) Is Null
        --
        If IsNull(@Msg2, '') <> ''
        Begin
            -- One or more entries is non-numeric
            Set @message = 'Identifier keys must all be integers when Identifier column contains ' + @IDTypeOriginal + '; error with: ' + Substring(@Msg2, 1, Len(@Msg2)-1)

            If @infoOnly <> 0
            Begin
                SELECT * FROM #Tmp_FactorInfo
            End

            Return 51019
        End
    End

    -----------------------------------------------------------
    -- Populate column RequestID using the Identifier column
    -----------------------------------------------------------
    --
    If @IDType = 'RequestID'
    Begin
        -- Identifier is Requestid
        UPDATE #Tmp_FactorInfo
        SET RequestID = Convert(int, Identifier)
    End

    If @IDType = 'DatasetID'
    Begin
        -- Identifier is DatasetID
        UPDATE #Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = Convert(int, #Tmp_FactorInfo.Identifier)
        FROM #Tmp_FactorInfo
             INNER JOIN T_Requested_Run RR
               ON Convert(int, #Tmp_FactorInfo.Identifier) = RR.DatasetID

    End

    If @IDType = 'Dataset'
    Begin
        -- Identifier is Dataset Name
        UPDATE #Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = DS.Dataset_ID
        FROM #Tmp_FactorInfo
             INNER JOIN T_Dataset DS
               ON #Tmp_FactorInfo.Identifier = DS.Dataset_Num
             INNER JOIN T_Requested_Run RR
               ON RR.DatasetID = DS.Dataset_ID
    End

    If @IDType = 'Job'
    Begin
        -- Identifier is Job
        UPDATE #Tmp_FactorInfo
        SET RequestID = RR.ID,
            DatasetID = DS.Dataset_ID
        FROM #Tmp_FactorInfo
             INNER JOIN T_Analysis_Job AJ
               ON Convert(int, #Tmp_FactorInfo.Identifier) = AJ.AJ_jobID
             INNER JOIN T_Dataset DS
               ON DS.Dataset_ID = AJ.AJ_datasetID
             INNER JOIN T_Requested_Run RR
               ON RR.DatasetID = DS.Dataset_ID

    End

    -----------------------------------------------------------
    -- Check for unresolved requests
    -----------------------------------------------------------
    --
    Set @myRowCount = 0
    Set @invalidCount = 0

    SELECT @myRowCount = Count(*),
           @invalidCount = Sum(CASE WHEN RequestID IS NULL THEN 1 ELSE 0 END)
    FROM ( SELECT DISTINCT Identifier,
                           RequestID
           FROM #Tmp_FactorInfo ) InnerQ

    If @invalidCount > 0
    Begin
        If @invalidCount = @myRowCount
            Set @message = 'Unable to determine RequestID for all ' + Convert(varchar(12), @myRowCount) + ' items'
        Else
            Set @message = 'Unable to determine RequestID for ' + Convert(varchar(12), @invalidCount) + ' of ' + Convert(varchar(12), @myRowCount) + ' items'

        Set @message = @message + '; treating the Identifier column as ' + @IDType

        If @infoOnly <> 0
        Begin
            SELECT * FROM #Tmp_FactorInfo
        End

        Return 51020
    End

    -----------------------------------------------------------
    -- Validate factor names
    -----------------------------------------------------------

    DECLARE @badFactorNames VARCHAR(8000) = ''

    SELECT
        @badFactorNames = @badFactorNames +
            CASE WHEN PATINDEX('%[^0-9A-Za-z_.]%', Factor) > 0
                 THEN CASE WHEN @badFactorNames = '' THEN Factor ELSE ', ' + Factor END
                 ELSE ''
            END
    FROM ( SELECT DISTINCT Factor
           FROM #Tmp_FactorInfo
           WHERE Not Factor In ('Dataset ID')      -- Note that factors named 'Dataset ID' and 'Dataset_ID' are removed later in this procedure
          ) LookupQ

    If @badFactorNames <> ''
    Begin
        If Len(@badFactorNames) < 256
            Set @message = 'Unacceptable characters in factor names "' + @badFactorNames + '"'
        Else
            Set @message = 'Unacceptable characters in factor names "' + LEFT(@badFactorNames, 256) + '..."'

        If @infoOnly <> 0
        Begin
            SELECT * FROM #Tmp_FactorInfo
        End

        Return 51027
    End

    -----------------------------------------------------------
    -- Auto-delete data that cannot be a factor
    -- These column names could be present if the user
    -- saved the results of a list report (or of https://dms2.pnl.gov/requested_run_factors/param)
    -- to a text file, then edited the data in Excel, then included the extra columns when copying from Excel
    --
    -- Name is not a valid factor name since it is used to label the Requested Run Name column at https://dms2.pnl.gov/requested_run_factors/param
    -----------------------------------------------------------

    UPDATE #Tmp_FactorInfo
    SET UpdateSkipCode = 2
    WHERE Factor IN ('Batch_ID', 'BatchID', 'Experiment', 'Dataset', 'Status', 'Request', 'Name')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0 And @infoOnly <> 0
    Begin
        SELECT *, Case When UpdateSkipCode = 2 Then 'Yes' Else 'No' End As AutoSkip_Invalid_Factor
        FROM #Tmp_FactorInfo

    End

    -----------------------------------------------------------
    -- Make sure factor name is not in blacklist
    --
    -- Note that Javascript code behind http://dms2.pnl.gov/requested_run_factors/param and https://dms2.pnl.gov/requested_run_batch_blocking/grid
    -- should auto-remove factors "Block" and "Run_Order" if it is present
    -----------------------------------------------------------
    --
    Set @badFactorNames = ''

    SELECT @badFactorNames = @badFactorNames + Factor  + ', '
    FROM ( SELECT DISTINCT Factor
           FROM #Tmp_FactorInfo
           WHERE Factor IN ('Block', 'Run_Order', 'Run Order', 'Type')
         ) LookupQ
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @badFactorNames <> ''
    Begin
        -- Remove the trailing comma
        Set @badFactorNames = Substring(@badFactorNames, 1, Len(@badFactorNames)-1)

        If @myRowCount = 1
            Set @message = 'Invalid factor name: ' + @badFactorNames
        Else
            Set @message = 'Invalid factor names: ' + @badFactorNames

        If @infoOnly <> 0
        Begin
            SELECT * FROM #Tmp_FactorInfo
        End

        Return 51015
    End

    -----------------------------------------------------------
    -- Auto-remove standard DMS names from the factor table
    -----------------------------------------------------------
    --
    DELETE FROM #Tmp_FactorInfo
    WHERE Factor IN ('Dataset_ID', 'Dataset ID', 'Dataset', 'Experiment')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------------------
    -- Capitalize factor names based on historic usage
    --
    -- Although factor case does not matter, some of the WHERE clauses
    -- are shown as lowercase based on observed inconsistencies in case
    -----------------------------------------------------------

    UPDATE #Tmp_FactorInfo SET Factor = 'AbbrName'                     WHERE Factor = 'AbbrName';
    UPDATE #Tmp_FactorInfo SET Factor = 'Age'                          WHERE Factor = 'Age';
    UPDATE #Tmp_FactorInfo SET Factor = 'Alias'                        WHERE Factor = 'Alias';
    UPDATE #Tmp_FactorInfo SET Factor = 'Analysis'                     WHERE Factor = 'analysis';
    UPDATE #Tmp_FactorInfo SET Factor = 'Batch'                        WHERE Factor = 'Batch';
    UPDATE #Tmp_FactorInfo SET Factor = 'Batch_Order_Number'           WHERE Factor = 'Batch_Order_Number';
    UPDATE #Tmp_FactorInfo SET Factor = 'Biol_Rep'                     WHERE Factor = 'Biol_rep';
    UPDATE #Tmp_FactorInfo SET Factor = 'Biological_Rep'               WHERE Factor = 'biological_rep';
    UPDATE #Tmp_FactorInfo SET Factor = 'BioRep'                       WHERE Factor = 'Biorep';
    UPDATE #Tmp_FactorInfo SET Factor = 'BioRepID'                     WHERE Factor = 'BioRepID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Bound'                        WHERE Factor = 'bound';
    UPDATE #Tmp_FactorInfo SET Factor = 'BoxNumber'                    WHERE Factor = 'BoxNumber';
    UPDATE #Tmp_FactorInfo SET Factor = 'Cart'                         WHERE Factor = 'Cart';
    UPDATE #Tmp_FactorInfo SET Factor = 'Cell_Line'                    WHERE Factor = 'cell_line';
    UPDATE #Tmp_FactorInfo SET Factor = 'Cohort'                       WHERE Factor = 'cohort';
    UPDATE #Tmp_FactorInfo SET Factor = 'Column'                       WHERE Factor = 'column';
    UPDATE #Tmp_FactorInfo SET Factor = 'Condition'                    WHERE Factor = 'Condition';
    UPDATE #Tmp_FactorInfo SET Factor = 'Created'                      WHERE Factor = 'Created';
    UPDATE #Tmp_FactorInfo SET Factor = 'Culture'                      WHERE Factor = 'culture'
    UPDATE #Tmp_FactorInfo SET Factor = 'DatasetID'                    WHERE Factor = 'DatasetID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Date'                         WHERE Factor = 'Date';
    UPDATE #Tmp_FactorInfo SET Factor = 'Day'                          WHERE Factor = 'Day';
    UPDATE #Tmp_FactorInfo SET Factor = 'Depletion_Column_ID'          WHERE Factor = 'Depletion_Column_ID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Fraction'                     WHERE Factor = 'fraction';
    UPDATE #Tmp_FactorInfo SET Factor = 'Fraction'                     WHERE Factor = 'Freaction';
    UPDATE #Tmp_FactorInfo SET Factor = 'Gender'                       WHERE Factor = 'Gender';
    UPDATE #Tmp_FactorInfo SET Factor = 'Group'                        WHERE Factor = 'Group';
    UPDATE #Tmp_FactorInfo SET Factor = 'Growth'                       WHERE Factor = 'Growth';
    UPDATE #Tmp_FactorInfo SET Factor = 'Growth_Condition'             WHERE Factor = 'Growth_condition';
    UPDATE #Tmp_FactorInfo SET Factor = 'Institute'                    WHERE Factor = 'Institute';
    UPDATE #Tmp_FactorInfo SET Factor = 'Instrument'                   WHERE Factor = 'Instrument';
    UPDATE #Tmp_FactorInfo SET Factor = 'Job'                          WHERE Factor = 'Job';
    UPDATE #Tmp_FactorInfo SET Factor = 'LC_Column'                    WHERE Factor = 'LC_Column';
    UPDATE #Tmp_FactorInfo SET Factor = 'LCColumnName'                 WHERE Factor = 'LCColumnName';
    UPDATE #Tmp_FactorInfo SET Factor = 'Location'                     WHERE Factor = 'Location';
    UPDATE #Tmp_FactorInfo SET Factor = 'Organism'                     WHERE Factor = 'organism';
    UPDATE #Tmp_FactorInfo SET Factor = 'Patient'                      WHERE Factor = 'Patient';
    UPDATE #Tmp_FactorInfo SET Factor = 'PatientID'                    WHERE Factor = 'PatientID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Plate'                        WHERE Factor = 'Plate';
    UPDATE #Tmp_FactorInfo SET Factor = 'PlateNumber'                  WHERE Factor = 'PlateNumber';
    UPDATE #Tmp_FactorInfo SET Factor = 'PlateWell'                    WHERE Factor = 'PlateWell';
    UPDATE #Tmp_FactorInfo SET Factor = 'Pool'                         WHERE Factor = 'Pool';
    UPDATE #Tmp_FactorInfo SET Factor = 'Post_Depletion_Concentration' WHERE Factor = 'Post_Depletion_Concentration';
    UPDATE #Tmp_FactorInfo SET Factor = 'PrepType'                     WHERE Factor = 'PrepType';
    UPDATE #Tmp_FactorInfo SET Factor = 'Probe'                        WHERE Factor = 'Probe';
    UPDATE #Tmp_FactorInfo SET Factor = 'ProcessRep'                   WHERE Factor = 'ProcessRep';
    UPDATE #Tmp_FactorInfo SET Factor = 'Protocol'                     WHERE Factor = 'Protocol';
    UPDATE #Tmp_FactorInfo SET Factor = 'Rep'                          WHERE Factor = 'Rep';
    UPDATE #Tmp_FactorInfo SET Factor = 'Replicate'                    WHERE Factor = 'replicate';
    UPDATE #Tmp_FactorInfo SET Factor = 'Replicates'                   WHERE Factor = 'Replicates';
    UPDATE #Tmp_FactorInfo SET Factor = 'RepRun'                       WHERE Factor = 'RepRun';
    UPDATE #Tmp_FactorInfo SET Factor = 'Run_Batch'                    WHERE Factor = 'Run_Batch';
    UPDATE #Tmp_FactorInfo SET Factor = 'RunDate'                      WHERE Factor = 'RunDate';
    UPDATE #Tmp_FactorInfo SET Factor = 'RunGroup'                     WHERE Factor = 'RunGroup';
    UPDATE #Tmp_FactorInfo SET Factor = 'Sample'                       WHERE Factor = 'Sample';
    UPDATE #Tmp_FactorInfo SET Factor = 'Sample_ID'                    WHERE Factor = 'Sample_ID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Sample_Number'                WHERE Factor = 'Sample_number';
    UPDATE #Tmp_FactorInfo SET Factor = 'Sample_Type'                  WHERE Factor = 'sample_type';
    UPDATE #Tmp_FactorInfo SET Factor = 'SampleName'                   WHERE Factor = 'SampleName';
    UPDATE #Tmp_FactorInfo SET Factor = 'SampleType'                   WHERE Factor = 'Sampletype';
    UPDATE #Tmp_FactorInfo SET Factor = 'Site'                         WHERE Factor = 'Site';
    UPDATE #Tmp_FactorInfo SET Factor = 'Species'                      WHERE Factor = 'Species';
    UPDATE #Tmp_FactorInfo SET Factor = 'StatGrp'                      WHERE Factor = 'StatGrp';
    UPDATE #Tmp_FactorInfo SET Factor = 'Strain'                       WHERE Factor = 'strain';
    UPDATE #Tmp_FactorInfo SET Factor = 'StudyID'                      WHERE Factor = 'StudyID';
    UPDATE #Tmp_FactorInfo SET Factor = 'SubjectGroup'                 WHERE Factor = 'SubjectGroup';
    UPDATE #Tmp_FactorInfo SET Factor = 'SubjectID'                    WHERE Factor = 'SubjectID';
    UPDATE #Tmp_FactorInfo SET Factor = 'Tech_Rep'                     WHERE Factor = 'Tech_rep';
    UPDATE #Tmp_FactorInfo SET Factor = 'TechRep'                      WHERE Factor = 'Techrep';
    UPDATE #Tmp_FactorInfo SET Factor = 'TechRepID'                    WHERE Factor = 'TechRepID';
    UPDATE #Tmp_FactorInfo SET Factor = 'TechReplicate'                WHERE Factor = 'TechReplicate';
    UPDATE #Tmp_FactorInfo SET Factor = 'Temperature'                  WHERE Factor = 'temperature';
    UPDATE #Tmp_FactorInfo SET Factor = 'Test'                         WHERE Factor = 'test';
    UPDATE #Tmp_FactorInfo SET Factor = 'Time'                         WHERE Factor = 'time';
    UPDATE #Tmp_FactorInfo SET Factor = 'Time_Desc'                    WHERE Factor = 'Time_Desc';
    UPDATE #Tmp_FactorInfo SET Factor = 'TimePoint'                    WHERE Factor = 'Timepoint';
    UPDATE #Tmp_FactorInfo SET Factor = 'Tissue'                       WHERE Factor = 'Tissue';
    UPDATE #Tmp_FactorInfo SET Factor = 'Treatment'                    WHERE Factor = 'treatment';
    UPDATE #Tmp_FactorInfo SET Factor = 'Weight'                       WHERE Factor = 'Weight';
    UPDATE #Tmp_FactorInfo SET Factor = 'Well'                         WHERE Factor = 'Well';

    -----------------------------------------------------------
    -- Check for invalid Request IDs in the factors table
    -----------------------------------------------------------

    DECLARE @InvalidRequestIDs VARCHAR(8000) = ''
    --
    SELECT @InvalidRequestIDs = @InvalidRequestIDs + Convert(varchar(12), RequestID) + ', '
    FROM #Tmp_FactorInfo
         LEFT OUTER JOIN T_Requested_Run RR
           ON #Tmp_FactorInfo.RequestID = RR.ID
    WHERE UpdateSkipCode = 0 And RR.ID IS NULL

    --
    If @InvalidRequestIDs <> ''
    Begin
        -- Remove the trailing comma
        Set @InvalidRequestIDs = Substring(@InvalidRequestIDs, 1, Len(@InvalidRequestIDs)-1)

        Set @message =  'Invalid Requested Run IDs: ' + @InvalidRequestIDs

        If @infoOnly <> 0
        Begin
            SELECT * FROM #Tmp_FactorInfo
        End

        Return 51013
    End


    -----------------------------------------------------------
    -- Flag values that are unchanged
    -----------------------------------------------------------

    UPDATE #Tmp_FactorInfo
    SET UpdateSkipCode = 1
    WHERE UpdateSkipCode = 0 AND
          EXISTS ( SELECT *
                   FROM T_Factor
                   WHERE T_Factor.Type = 'Run_Request' AND
                         #Tmp_FactorInfo.RequestID = T_Factor.TargetID AND
                         #Tmp_FactorInfo.Factor = T_Factor.Name AND
                         #Tmp_FactorInfo.Value = T_Factor.Value )



    If @infoOnly <> 0
    Begin
        -- Preview the contents of the #Tmp_FactorInfo table
        SELECT *
        FROM #Tmp_FactorInfo
    End
    Else
    Begin -- <CommitChanges>

        -----------------------------------------------------------
        -- Remove blank values from factors table
        -----------------------------------------------------------

        DELETE FROM T_Factor
        WHERE T_Factor.Type = 'Run_Request' AND
              EXISTS ( SELECT *
                       FROM #Tmp_FactorInfo
                       WHERE UpdateSkipCode = 0 AND
                             #Tmp_FactorInfo.RequestID = T_Factor.TargetID AND
                             #Tmp_FactorInfo.Factor = T_Factor.Name AND
                             LTrim(RTrim(#Tmp_FactorInfo.Value)) = '' )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error removing blank values from factors table'
            Return 51001
        End

        -----------------------------------------------------------
        -- Update existing items in factors tables
        -----------------------------------------------------------

        UPDATE T_Factor
        SET Value = #Tmp_FactorInfo.Value,
            Last_Updated = GetDate()
        FROM T_Factor AS TF
             INNER JOIN #Tmp_FactorInfo
               ON #Tmp_FactorInfo.RequestID = TF.TargetID AND
                  #Tmp_FactorInfo.Factor = TF.Name AND
              TF.Type = 'Run_Request'
        WHERE UpdateSkipCode = 0 AND
              #Tmp_FactorInfo.Value <> TF.Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error updating changed values in factors table'
            Return 51002
        End

        -----------------------------------------------------------
        -- Add new factors
        -----------------------------------------------------------

        INSERT INTO dbo.T_Factor( [Type],
                                  TargetID,
                                  Name,
                                  Value,
                                  Last_Updated )
        SELECT 'Run_Request' AS [Type],
               RequestID AS TargetID,
               Factor AS FactorName,
               Value,
               GetDate()
        FROM #Tmp_FactorInfo
        WHERE UpdateSkipCode = 0 AND
              LTrim(RTrim(#Tmp_FactorInfo.Value)) <> '' AND
              NOT EXISTS ( SELECT *
                           FROM T_Factor
                           WHERE #Tmp_FactorInfo.RequestID = T_Factor.TargetID AND
                                 #Tmp_FactorInfo.Factor = T_Factor.Name AND
                                 T_Factor.Type = 'Run_Request' )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error adding new factors to factors table'
            Return 51003
        End

        -----------------------------------------------------------
        -- Convert changed items to XML for logging
        -----------------------------------------------------------

        DECLARE @changeSummary varchar(max) = ''
        --
        SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), RequestID) + '" f="' + Factor + '" v="' + Value + '" />'
        FROM #Tmp_FactorInfo
        WHERE UpdateSkipCode = 0

        -----------------------------------------------------------
        -- Log changes
        -----------------------------------------------------------

        If @changeSummary <> ''
        Begin
            INSERT INTO T_Factor_Log (changed_by, changes)
            VALUES (@callingUser, @changeSummary)
        End

    End -- </CommitChanges>

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = ''

    Exec post_usage_log_entry 'update_requested_run_factors', @UsageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_factors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_factors] TO [Limited_Table_Write] AS [dbo]
GO
