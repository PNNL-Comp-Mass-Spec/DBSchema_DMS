/****** Object:  StoredProcedure [dbo].[validate_analysis_job_request_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_analysis_job_request_datasets]
/****************************************************
**
**  Desc:   Validates datasets in temporary table #TD
**          The calling procedure must create #TD and populate it with the dataset names;
**          the remaining columns in the table will be populated by this procedure
**
**      CREATE TABLE #TD (
**          Dataset_Name varchar(128),
**          Dataset_ID int NULL,
**          IN_class varchar(64) NULL,
**          DS_state_ID int NULL,
**          AS_state_ID int NULL,
**          Dataset_Type varchar(64) NULL,
**          DS_rating smallint NULL,
**      )
**
**  Return values:
**      0 if no problems
**      Error code if a problem; @message will contain the error message
**
**  Auth:   mem
**          11/12/2012 mem - Initial version (extracted code from add_update_analysis_job_request and validate_analysis_job_parameters)
**          03/05/2013 mem - Added parameter @autoRemoveNotReleasedDatasets
**          08/02/2013 mem - Tweaked message for "Not Released" datasets
**          03/30/2015 mem - Tweak warning message grammar
**          04/23/2015 mem - Added parameter @toolName
**          06/24/2015 mem - Added parameter @showDebugMessages
**          07/20/2016 mem - Tweak error messages
**          12/06/2017 mem - Add @allowNewDatasets
**          07/30/2019 mem - Tabs to spaces
**          03/10/2021 mem - Skip HMS vs. MS check when the tool is MaxQuant
**          05/25/2021 mem - Add @allowNonReleasedDatasets
**          08/26/2021 mem - Skip HMS vs. MS check when the tool is MSFragger
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**          03/22/2023 mem - Rename column in temp table
**                         - Also auto-remove datasets named 'Dataset Name' and 'Dataset_Name' from #TD
**          03/27/2023 mem - Skip HMS vs. MS check when the tool is DiaNN
**
*****************************************************/
(
    @message varchar(512) output,
    @autoRemoveNotReleasedDatasets tinyint = 0,           -- When 1, then automatically removes datasets from #TD if they have an invalid rating
    @toolName varchar(64) = 'unknown',
    @allowNewDatasets tinyint = 0,                        -- When 0, all datasets must have state 3 (Complete); when 1, will also allow datasets with state 1 or 2 (New or Capture In Progress)
    @allowNonReleasedDatasets tinyint = 0,                -- When 1, allow datasets to have a rating of "Not Released"
    @showDebugMessages tinyint = 0                        -- 1 to print @message strings; 2 to also see the contents of #TD
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    set @message = ''

    Set @autoRemoveNotReleasedDatasets = IsNull(@autoRemoveNotReleasedDatasets, 0)
    Set @showDebugMessages = IsNull(@showDebugMessages, 0)

    ---------------------------------------------------
    -- Auto-delete dataset column names from #TD
    ---------------------------------------------------
    --
    DELETE FROM #TD
    WHERE Dataset_Name IN ('Dataset', 'Dataset Name', 'Dataset_Name', 'Dataset_Num')

    ---------------------------------------------------
    -- Update the additional info in #TD
    ---------------------------------------------------
    --
    UPDATE #TD
    SET #TD.Dataset_ID = T_Dataset.Dataset_ID,
        #TD.IN_class = T_Instrument_Class.IN_class,
        #TD.DS_state_ID = T_Dataset.DS_state_ID,
        #TD.AS_state_ID = isnull(T_Dataset_Archive.AS_state_ID, 0),
        #TD.Dataset_Type = T_Dataset_Type_Name.DST_name,
        #TD.DS_rating = T_Dataset.DS_Rating
    FROM #TD
         INNER JOIN T_Dataset
           ON #TD.Dataset_Name = T_Dataset.Dataset_Num
         INNER JOIN T_Instrument_Name
           ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
         INNER JOIN T_Instrument_Class
           ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
         INNER JOIN T_Dataset_Type_Name
           ON T_Dataset_Type_Name.DST_Type_ID = T_Dataset.DS_type_ID
         LEFT OUTER JOIN T_Dataset_Archive
           ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @showDebugMessages > 1
    Begin
        SELECT *
        FROM #TD
        ORDER BY Dataset_Name
    End

    ---------------------------------------------------
    -- Make sure none of the datasets has a rating of -5 (Not Released)
    ---------------------------------------------------
    --
    Declare @list varchar(4000)
    Declare @NotReleasedCount int = 0

    SELECT @NotReleasedCount = COUNT(*)
    FROM #TD
    WHERE DS_Rating = -5

    If @NotReleasedCount > 0 And @allowNonReleasedDatasets = 0
    Begin
        Set @list = ''

        SELECT @list = @list + Dataset_Name + ', '
        FROM #TD
        WHERE DS_Rating = -5
        ORDER BY Dataset_Name

        -- Remove the trailing comma If the length is less than 400 characters, otherwise truncate
        If Len(@list) < 400
            Set @list = Left(@list, Len(@list)-1)
        Else
            Set @list = Left(@list, 397) + '...'

        If @autoRemoveNotReleasedDatasets = 0
        Begin
            if @NotReleasedCount = 1
                set @message = 'Dataset is "Not Released": ' + @list
            else
                set @message = Convert(varchar(12), @NotReleasedCount) + ' datasets are "Not Released": ' + @list

            if @showDebugMessages <> 0
                print @message

            return 50101
        End
        Else
        Begin
            set @message = 'Skipped ' + Convert(varchar(12), @NotReleasedCount) + ' "Not Released" ' + dbo.check_plural(@NotReleasedCount, 'dataset', 'datasets') + ': ' + @list

            if @showDebugMessages <> 0
                print @message

            DELETE FROM #TD
            WHERE DS_Rating = -5

        End
    End

    ---------------------------------------------------
    -- Verify that datasets in list all exist
    ---------------------------------------------------
    --
    set @list = null
    --
    SELECT @list = Coalesce(@list + Dataset_Name + ', ', Dataset_Name)
    FROM #TD
    WHERE Dataset_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error checking dataset existence'
        if @showDebugMessages <> 0
            print @message

        return 51007
    end
    --
    if IsNull(@list, '') <> ''
    begin
        set @message = 'The following datasets were not in the database: ' + @list
        if @showDebugMessages <> 0
            print @message

        return 51007
    end

    ---------------------------------------------------
    -- Verify state of datasets
    -- If @allowNewDatasets is 0, they must all have state Complete
    -- If @allowNewDatasets is non-zero, we also allow New and Capture In Progress datasets
    ---------------------------------------------------
    --
    set @list = null
    --
    SELECT @list = Coalesce(@list + Dataset_Name + ', ', Dataset_Name)
    FROM #TD
    WHERE (@allowNewDatasets = 0 AND DS_state_ID <> 3) OR
          (@allowNewDatasets > 0 AND DS_state_ID NOT IN (1,2,3))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error checking dataset state'
        if @showDebugMessages <> 0
            print @message

        return 51007
    end
    --
    if IsNull(@list, '') <> ''
    begin
        set @message = 'The following datasets were not in correct state: ' + @list
        if @showDebugMessages <> 0
            print @message

        return 51007
    end

    ---------------------------------------------------
    -- Verify rating of datasets
    ---------------------------------------------------
    --
    set @list = null
    --
    SELECT @list = Coalesce(@list + Dataset_Name + ', ', Dataset_Name)
    FROM #TD
    WHERE (DS_rating IN (-1, -2))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error checking dataset rating'
        if @showDebugMessages <> 0
            print @message

        return 51007
    end
    --
    if IsNull(@list, '') <> ''
    begin
        set @message = 'The following datasets have a rating of -1 (No Data) or -2 (Data Files Missing): ' + @list
        if @showDebugMessages <> 0
            print @message

        return 51007
    end

    ---------------------------------------------------
    -- Do not allow high res datasets to be mixed with low res datasets
    -- (though this is OK if the tool is MSXML_Gen, MaxQuant, MSFragger, or DiaNN)
    ---------------------------------------------------
    --
    Declare @HMSCount int = 0
    Declare @MSCount int = 0

    SELECT @HMSCount = COUNT(*)
    FROM #TD
    WHERE Dataset_Type LIKE 'hms%' OR
          Dataset_Type LIKE 'ims-hms%'


    SELECT @MSCount = COUNT(*)
    FROM #TD
    WHERE Dataset_Type LIKE 'MS%' OR
          Dataset_Type LIKE 'IMS-MS%'

    If @HMSCount > 0 And @MSCount > 0 And Not @toolName in ('MSXML_Gen', 'MaxQuant', 'MSFragger', 'DiaNN')
    Begin
        Set @message = 'You cannot mix high-res MS datasets with low-res datasets; create separate analysis job requests. You currently have ' + Convert(varchar(12), @HMSCount) + ' high res (HMS) and ' + Convert(varchar(12), @MSCount) + ' low res (MS)'
        if @showDebugMessages <> 0
            print @message

        return 51009
    End

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[validate_analysis_job_request_datasets] TO [DDL_Viewer] AS [dbo]
GO
