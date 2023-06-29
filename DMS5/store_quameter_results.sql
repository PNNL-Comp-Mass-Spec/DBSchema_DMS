/****** Object:  StoredProcedure [dbo].[store_quameter_results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[store_quameter_results]
/****************************************************
**
**  Desc:
**      Updates the Quameter information for the dataset specified by @DatasetID
**      If @DatasetID is 0, then will use the dataset name defined in @ResultsXML
**      If @DatasetID is non-zero, then will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by @DatasetID
**
**      Typical XML file contents:
**
**      <Quameter_Results>
**        <Dataset>QC_BTLE_01_Lipid_Pos_28Jun23_Crater_WCSH315309</Dataset>
**        <Job>6041131</Job>
**        <Measurements>
**          <Measurement Name="XIC_WideFrac">0.150247</Measurement><Measurement Name="XIC_FWHM_Q1">154.879</Measurement><Measurement Name="XIC_FWHM_Q2">197.899</Measurement><Measurement Name="XIC_FWHM_Q3">236.983</Measurement><Measurement Name="XIC_Height_Q2">0.533508</Measurement><Measurement Name="XIC_Height_Q3">0.427546</Measurement><Measurement Name="XIC_Height_Q4">1.32528</Measurement>
**          <Measurement Name="RT_Duration">2461.28</Measurement><Measurement Name="RT_TIC_Q1">0.520133</Measurement><Measurement Name="RT_TIC_Q2">0.11564</Measurement><Measurement Name="RT_TIC_Q3">0.147399</Measurement><Measurement Name="RT_TIC_Q4">0.216828</Measurement><Measurement Name="RT_MS_Q1">0.253362</Measurement><Measurement Name="RT_MS_Q2">0.25316</Measurement><Measurement Name="RT_MS_Q3">0.241555</Measurement><Measurement Name="RT_MS_Q4">0.251923</Measurement>
**          <Measurement Name="RT_MSMS_Q1">0.252978</Measurement><Measurement Name="RT_MSMS_Q2">0.253037</Measurement><Measurement Name="RT_MSMS_Q3">0.242426</Measurement><Measurement Name="RT_MSMS_Q4">0.251559</Measurement><Measurement Name="MS1_TIC_Change_Q2">0.938397</Measurement><Measurement Name="MS1_TIC_Change_Q3">0.945567</Measurement><Measurement Name="MS1_TIC_Change_Q4">3.247</Measurement>
**          <Measurement Name="MS1_TIC_Q2">0.551227</Measurement><Measurement Name="MS1_TIC_Q3">0.332419</Measurement><Measurement Name="MS1_TIC_Q4">1.43225</Measurement><Measurement Name="MS1_Count">936</Measurement><Measurement Name="MS1_Freq_Max">0.416628</Measurement><Measurement Name="MS1_Density_Q1">1789</Measurement><Measurement Name="MS1_Density_Q2">2287.5</Measurement><Measurement Name="MS1_Density_Q3">3086.5</Measurement>
**          <Measurement Name="MS2_Count">7481</Measurement><Measurement Name="MS2_Freq_Max">3.31577</Measurement><Measurement Name="MS2_Density_Q1">18</Measurement><Measurement Name="MS2_Density_Q2">27</Measurement><Measurement Name="MS2_Density_Q3">47</Measurement>
**          <Measurement Name="MS2_PrecZ_1">0.947868</Measurement><Measurement Name="MS2_PrecZ_2">0.00641625</Measurement><Measurement Name="MS2_PrecZ_3">0</Measurement><Measurement Name="MS2_PrecZ_4">0</Measurement><Measurement Name="MS2_PrecZ_5">0</Measurement><Measurement Name="MS2_PrecZ_more">0</Measurement>
**          <Measurement Name="MS2_PrecZ_likely_1">0.0274028</Measurement><Measurement Name="MS2_PrecZ_likely_multi">0.0183131</Measurement>
**        </Measurements>
**      </Quameter_Results>
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version (modelled after store_smaqc_results)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetID int = 0,                -- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
    @resultsXML xml,                -- XML holding the Quameter results for a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @DatasetName varchar(128)
    Declare @DatasetIDCheck int

    -----------------------------------------------------------
    -- Create the table to hold the data
    -----------------------------------------------------------

    Declare @DatasetInfoTable table (
        Dataset_ID int NULL ,
        Dataset_Name varchar (128) NOT NULL ,
        Job int NULL                -- Analysis job used to generate the Quameter results
    )


    Declare @MeasurementsTable table (
        [Name] varchar(64) NOT NULL,
        ValueText varchar(64) NULL,
        Value float NULL
    )

    Declare @KnownMetricsTable table (
        Dataset_ID int NOT NULL,
        XIC_WideFrac float Null,
        XIC_FWHM_Q1 float Null,
        XIC_FWHM_Q2 float Null,
        XIC_FWHM_Q3 float Null,
        XIC_Height_Q2 float Null,
        XIC_Height_Q3 float Null,
        XIC_Height_Q4 float Null,
        RT_Duration float Null,
        RT_TIC_Q1 float Null,
        RT_TIC_Q2 float Null,
        RT_TIC_Q3 float Null,
        RT_TIC_Q4 float Null,
        RT_MS_Q1 float Null,
        RT_MS_Q2 float Null,
        RT_MS_Q3 float Null,
        RT_MS_Q4 float Null,
        RT_MSMS_Q1 float Null,
        RT_MSMS_Q2 float Null,
        RT_MSMS_Q3 float Null,
        RT_MSMS_Q4 float Null,
        MS1_TIC_Change_Q2 float Null,
        MS1_TIC_Change_Q3 float Null,
        MS1_TIC_Change_Q4 float Null,
        MS1_TIC_Q2 float Null,
        MS1_TIC_Q3 float Null,
        MS1_TIC_Q4 float Null,
        MS1_Count float Null,
        MS1_Freq_Max float Null,
        MS1_Density_Q1 float Null,
        MS1_Density_Q2 float Null,
        MS1_Density_Q3 float Null,
        MS2_Count float Null,
        MS2_Freq_Max float Null,
        MS2_Density_Q1 float Null,
        MS2_Density_Q2 float Null,
        MS2_Density_Q3 float Null,
        MS2_PrecZ_1 float Null,
        MS2_PrecZ_2 float Null,
        MS2_PrecZ_3 float Null,
        MS2_PrecZ_4 float Null,
        MS2_PrecZ_5 float Null,
        MS2_PrecZ_more float Null,
        MS2_PrecZ_likely_1 float Null,
        MS2_PrecZ_likely_multi float Null
    )

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @DatasetID = IsNull(@DatasetID, 0)
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)


    ---------------------------------------------------
    -- Parse out the dataset name from @ResultsXML
    -- If this parse fails, there is no point in continuing
    ---------------------------------------------------

    SELECT @DatasetName = DSName
    FROM (SELECT @ResultsXML.value('(/Quameter_Results/Dataset)[1]', 'varchar(128)') AS DSName
         ) LookupQ
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error extracting the dataset name from @ResultsXML'
        goto Done
    end

    If @myRowCount = 0 or IsNull(@DatasetName, '') = ''
    Begin
        set @message = 'XML in @ResultsXML is not in the expected form; Could not match /Quameter_Results/Dataset'
        Set @myError = 50000
        goto Done
    End

    ---------------------------------------------------
    -- Parse the contents of @ResultsXML to populate @DatasetInfoTable
    ---------------------------------------------------
    --
    INSERT INTO @DatasetInfoTable (
        Dataset_ID,
        Dataset_Name,
        Job
    )
    SELECT    @DatasetID AS DatasetID,
            @DatasetName AS Dataset,
            @ResultsXML.value('(/Quameter_Results/Job)[1]', 'int') AS Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error extracting data from @ResultsXML'
        goto Done
    end


    ---------------------------------------------------
    -- Now extract out the Quameter Measurement information
    ---------------------------------------------------
    --
    INSERT INTO @MeasurementsTable ([Name], ValueText)
    SELECT [Name], ValueText
    FROM (    SELECT  xmlNode.value('.', 'varchar(64)') AS ValueText,
                xmlNode.value('@Name', 'varchar(64)') AS [Name]
        FROM   @ResultsXML.nodes('/Quameter_Results/Measurements/Measurement') AS R(xmlNode)
    ) LookupQ
    WHERE NOT ValueText IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error parsing Measurement nodes in @ResultsXML'
        goto Done
    end

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in @DatasetInfoTable
    ---------------------------------------------------
    --
    If @DatasetID = 0
    Begin
        UPDATE @DatasetInfoTable
        SET Dataset_ID = DS.Dataset_ID
        FROM @DatasetInfoTable Target
             INNER JOIN T_Dataset DS
               ON Target.Dataset_Name = DS.Dataset_Num
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Warning: dataset not found in table T_Dataset: ' + @DatasetName
            Set @myError = 50001
            Goto Done
        End

        -- Update @DatasetID
        SELECT @DatasetID = Dataset_ID
        FROM @DatasetInfoTable

    End
    Else
    Begin

        -- @DatasetID was non-zero
        -- Validate the dataset name in @DatasetInfoTable against T_Dataset

        SELECT @DatasetIDCheck = DS.Dataset_ID
        FROM @DatasetInfoTable Target
             INNER JOIN T_Dataset DS
             ON Target.Dataset_Name = DS.Dataset_Num

        If @DatasetIDCheck <> @DatasetID
        Begin
            Set @message = 'Error: dataset ID values for ' + @DatasetName + ' do not match; expecting ' + Convert(varchar(12), @DatasetIDCheck) + ' but stored procedure param @DatasetID is ' + Convert(varchar(12), @DatasetID)
            Set @myError = 50002
            Goto Done
        End
    End

    -----------------------------------------------
    -- Populate the Value column in @MeasurementsTable
    -- If any of the metrics has a non-numeric value, then the Value column will remain Null
    -----------------------------------------------

    UPDATE @MeasurementsTable
    SET Value = Convert(float, FilterQ.ValueText)
    FROM @MeasurementsTable Target
         INNER JOIN ( SELECT Name,
                             ValueText
                      FROM @MeasurementsTable
                      WHERE Not Try_Parse(ValueText as float) Is Null
                    ) FilterQ
           ON Target.Name = FilterQ.Name


    -- Do not allow values to be larger than 1E+38 or smaller than -1E+38
    UPDATE @MeasurementsTable
    SET Value = 1E+38
    WHERE Value > 1E+38

    UPDATE @MeasurementsTable
    SET Value = -1E+38
    WHERE Value < -1E+38


    -----------------------------------------------
    -- Populate @KnownMetricsTable using data in @MeasurementsTable
    -- Use a Pivot to extract out the known columns
    -----------------------------------------------

    INSERT INTO @KnownMetricsTable (Dataset_ID,
                                    XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                                    RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                                    RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                                    RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                                    MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                                    MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                                    MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                                    MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                                    MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                                    MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi
                                  )
    SELECT @DatasetID,
            XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
            RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
            RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
            RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
            MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
            MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
            MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
            MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
            MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
            MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi
    FROM ( SELECT [Name],
                  [Value]
           FROM @MeasurementsTable ) AS SourceTable
         PIVOT ( MAX([Value])
                 FOR Name
                 IN ( [XIC_WideFrac], [XIC_FWHM_Q1], [XIC_FWHM_Q2], [XIC_FWHM_Q3], [XIC_Height_Q2], [XIC_Height_Q3], [XIC_Height_Q4],
                      [RT_Duration], [RT_TIC_Q1], [RT_TIC_Q2], [RT_TIC_Q3], [RT_TIC_Q4],
                      [RT_MS_Q1], [RT_MS_Q2], [RT_MS_Q3], [RT_MS_Q4],
                      [RT_MSMS_Q1], [RT_MSMS_Q2], [RT_MSMS_Q3], [RT_MSMS_Q4],
                      [MS1_TIC_Change_Q2], [MS1_TIC_Change_Q3], [MS1_TIC_Change_Q4],
                      [MS1_TIC_Q2], [MS1_TIC_Q3], [MS1_TIC_Q4],
                      [MS1_Count], [MS1_Freq_Max], [MS1_Density_Q1], [MS1_Density_Q2], [MS1_Density_Q3],
                      [MS2_Count], [MS2_Freq_Max], [MS2_Density_Q1], [MS2_Density_Q2], [MS2_Density_Q3],
                      [MS2_PrecZ_1], [MS2_PrecZ_2], [MS2_PrecZ_3], [MS2_PrecZ_4], [MS2_PrecZ_5], [MS2_PrecZ_more],
                      [MS2_PrecZ_likely_1], [MS2_PrecZ_likely_multi] )
                ) AS PivotData


    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT *
        FROM @DatasetInfoTable

        SELECT *
        FROM @MeasurementsTable

        SELECT *
        FROM @KnownMetricsTable

        Goto Done
    End


    -----------------------------------------------
    -- Add/Update T_Dataset_QC using a MERGE statement
    -----------------------------------------------
    --
    MERGE T_Dataset_QC AS target
    USING
        (SELECT    M.Dataset_ID,
                DI.Job,
                XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi
         FROM @KnownMetricsTable M INNER JOIN
              @DatasetInfoTable DI ON M.Dataset_ID = DI.Dataset_ID
        ) AS Source (Dataset_ID, Quameter_Job,
                     XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                     RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                     RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                     RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                     MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                     MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                     MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                     MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                     MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                     MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi)
        ON (target.Dataset_ID = Source.Dataset_ID)

    WHEN Matched
        THEN UPDATE
            Set Quameter_Job = Source.Quameter_Job,
                XIC_WideFrac = Source.XIC_WideFrac, XIC_FWHM_Q1 = Source.XIC_FWHM_Q1, XIC_FWHM_Q2 = Source.XIC_FWHM_Q2, XIC_FWHM_Q3 = Source.XIC_FWHM_Q3, XIC_Height_Q2 = Source.XIC_Height_Q2, XIC_Height_Q3 = Source.XIC_Height_Q3, XIC_Height_Q4 = Source.XIC_Height_Q4,
                RT_Duration = Source.RT_Duration, RT_TIC_Q1 = Source.RT_TIC_Q1, RT_TIC_Q2 = Source.RT_TIC_Q2, RT_TIC_Q3 = Source.RT_TIC_Q3, RT_TIC_Q4 = Source.RT_TIC_Q4,
                RT_MS_Q1 = Source.RT_MS_Q1, RT_MS_Q2 = Source.RT_MS_Q2, RT_MS_Q3 = Source.RT_MS_Q3, RT_MS_Q4 = Source.RT_MS_Q4,
                RT_MSMS_Q1 = Source.RT_MSMS_Q1, RT_MSMS_Q2 = Source.RT_MSMS_Q2, RT_MSMS_Q3 = Source.RT_MSMS_Q3, RT_MSMS_Q4 = Source.RT_MSMS_Q4,
                MS1_TIC_Change_Q2 = Source.MS1_TIC_Change_Q2, MS1_TIC_Change_Q3 = Source.MS1_TIC_Change_Q3, MS1_TIC_Change_Q4 = Source.MS1_TIC_Change_Q4,
                MS1_TIC_Q2 = Source.MS1_TIC_Q2, MS1_TIC_Q3 = Source.MS1_TIC_Q3, MS1_TIC_Q4 = Source.MS1_TIC_Q4,
                MS1_Count = Source.MS1_Count, MS1_Freq_Max = Source.MS1_Freq_Max, MS1_Density_Q1 = Source.MS1_Density_Q1, MS1_Density_Q2 = Source.MS1_Density_Q2, MS1_Density_Q3 = Source.MS1_Density_Q3,
                MS2_Count = Source.MS2_Count, MS2_Freq_Max = Source.MS2_Freq_Max, MS2_Density_Q1 = Source.MS2_Density_Q1, MS2_Density_Q2 = Source.MS2_Density_Q2, MS2_Density_Q3 = Source.MS2_Density_Q3,
                MS2_PrecZ_1 = Source.MS2_PrecZ_1, MS2_PrecZ_2 = Source.MS2_PrecZ_2, MS2_PrecZ_3 = Source.MS2_PrecZ_3, MS2_PrecZ_4 = Source.MS2_PrecZ_4, MS2_PrecZ_5 = Source.MS2_PrecZ_5, MS2_PrecZ_more = Source.MS2_PrecZ_more,
                MS2_PrecZ_likely_1 = Source.MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi = Source.MS2_PrecZ_likely_multi,
                Quameter_Last_Affected = GetDate()

    WHEN Not Matched THEN
        INSERT (Dataset_ID,
                Quameter_Job,
                XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi,
                Quameter_Last_Affected
               )
        VALUES ( Source.Dataset_ID,
                 Source.Quameter_Job,
                 XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                 RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                 RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                 RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                 MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                 MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                 MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                 MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                 MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                 MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi,
                 GetDate()
               )
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating T_Dataset_QC'
        goto Done
    end


    Set @message = 'Quameter measurement storage successful'

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in store_quameter_results'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @InfoOnly = 0
            Exec post_log_entry 'Error', @message, 'store_quameter_results'
    End

    If Len(@message) > 0 AND @InfoOnly <> 0
        Print @message

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    If IsNull(@DatasetName, '') = ''
        Set @UsageMessage = 'Dataset ID: ' + Convert(varchar(12), @DatasetID)
    Else
        Set @UsageMessage = 'Dataset: ' + @DatasetName

    If @InfoOnly = 0
        Exec post_usage_log_entry 'store_quameter_results', @UsageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[store_quameter_results] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_quameter_results] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_quameter_results] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_quameter_results] TO [svc-dms] AS [dbo]
GO
