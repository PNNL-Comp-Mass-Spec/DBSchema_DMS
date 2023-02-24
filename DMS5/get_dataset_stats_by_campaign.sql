/****** Object:  StoredProcedure [dbo].[get_dataset_stats_by_campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_dataset_stats_by_campaign]
/****************************************************
**
**  Desc:
**      Returns a table summarizing datasets stats,
**      grouped by campaign, work package, and instrument over the given time frame
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial release
**          06/10/2019 mem - Add parameters @excludeQCAndBlankWithoutWP, @campaignNameExclude, and @instrumentBuilding
**          03/24/2020 mem - Add parameter @excludeAllQCAndBlank
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mostRecentWeeks int = 20,
    @startDate datetime = null,     -- Ignored if @mostRecentWeeks is non-zero
    @endDate datetime = null,       -- Ignored if @mostRecentWeeks is non-zero
    @includeInstrument tinyint = 0,
    @excludeQCAndBlankWithoutWP tinyint = 1,
    @excludeAllQCAndBlank tinyint = 0,
    @campaignNameFilter varchar(128) = '',
    @campaignNameExclude varchar(128) = '',
    @instrumentBuilding varchar(64) = '',
    @previewSql tinyint = 0,
    @message varchar(512) ='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @msg varchar(256)

    Declare @sql nvarchar(2000)
    Declare @sqlParams nvarchar(1000)

    Declare @optionalCampaignNot varchar(16) = ''
    Declare @optionalBuildingNot varchar(16) = ''

    Declare @totalRuntimeHours float

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    Set @mostRecentWeeks = IsNull(@mostRecentWeeks, 0)
    Set @includeInstrument = IsNull(@includeInstrument, 0)
    Set @excludeQCAndBlankWithoutWP = IsNull(@excludeQCAndBlankWithoutWP, 1)
    SET @excludeAllQCAndBlank = IsNull(@excludeAllQCAndBlank, 0)
    Set @campaignNameFilter = IsNull(@campaignNameFilter, '')
    Set @campaignNameExclude = IsNull(@campaignNameExclude, '')
    Set @instrumentBuilding = IsNull(@instrumentBuilding, '')
    Set @previewSql = IsNull(@previewSql, 0)
    Set @message = ''

    If @mostRecentWeeks < 1
    Begin
        Set @startDate = IsNull(@startDate, DateAdd(Week, -20, GetDate()))
        Set @endDate = IsNull(@endDate, GetDate())
        If @previewSql > 0
        Begin
            Print 'Filtering on date range ' + Cast(@startDate As Varchar(24)) + ' to ' + Cast(@endDate As Varchar(24))
        End
    End
    Else
    Begin
        If @previewSql > 0
        Begin
            Print 'Filtering on datasets acquired within the last ' + Cast(@mostRecentWeeks As Varchar(12)) + ' weeks'
        End
    End

    If @campaignNameFilter Like ':%' And Len(@campaignNameFilter) > 1
    Begin
        Set @campaignNameFilter = Substring(@campaignNameFilter, 2, Len(@campaignNameFilter) - 1)
        Set @optionalCampaignNot = 'Not'
    End


    If @instrumentBuilding Like ':%' And Len(@instrumentBuilding) > 1
    Begin
        Set @instrumentBuilding = Substring(@instrumentBuilding, 2, Len(@instrumentBuilding) - 1)
        Set @optionalBuildingNot = 'Not'
    End

    Set @campaignNameFilter = dbo.validate_wildcard_filter(@campaignNameFilter)
    Set @campaignNameExclude = dbo.validate_wildcard_filter(@campaignNameExclude)
    Set @instrumentBuilding = dbo.validate_wildcard_filter(@instrumentBuilding)

    If @previewSql > 0 And @campaignNameFilter <> ''
    Begin
        Print 'Filtering on campaign name matching ''' + @campaignNameFilter + ''''
    End

    If @previewSql > 0 And @campaignNameExclude <> ''
    Begin
        Print 'Excluding campaigns matching ''' + @campaignNameExclude + ''''
    End

    If @previewSql > 0 And @instrumentBuilding <> ''
    Begin
        Print 'Filtering on building matching ''' + @instrumentBuilding + ''''
    End

    -----------------------------------------
    -- Create a temporary table to cache the results
    -----------------------------------------
    --

    Create Table #Tmp_CampaignDatasetStats (
        Campaign Varchar(128) Not Null,
        WorkPackage Varchar(16) Null,
        FractionEMSLFunded Decimal(3,2) Null,
        RuntimeHours decimal(9,1) Not Null,
        Datasets int Not Null,
        Building Varchar(64) Not Null,
        Instrument Varchar(64) Not Null,
        RequestMin int Not Null,
        RequestMax Int Not Null
    )

    -----------------------------------------
    -- Construct the query to retrieve the results
    -----------------------------------------
    --
    Set @sql = ''
    Set @sql = @sql + ' INSERT INTO #Tmp_CampaignDatasetStats (Campaign, WorkPackage, FractionEMSLFunded, RuntimeHours, Datasets, Building, Instrument, RequestMin, RequestMax)'
    Set @sql = @sql + ' SELECT C.Campaign_Num AS Campaign,'
    Set @sql = @sql +        ' RR.RDS_WorkPackage AS WorkPackage,'
    Set @sql = @sql +        ' C.CM_Fraction_EMSL_FUnded AS FractionEMSLFunded,'
    Set @sql = @sql +        ' Cast(Sum(DS.Acq_Length_Minutes) / 60.0 AS decimal(9,1)) AS RuntimeHours,'
    Set @sql = @sql +        ' Count(*) AS Datasets,'
    Set @sql = @sql +        ' InstName.Building,'
    If @includeInstrument > 0
    Begin
        Set @sql = @sql +    ' InstName.IN_name As Instrument,'
    End
    Else
    Begin
        Set @sql = @sql +    ' '''' As Instrument,'
    End
    Set @sql = @sql +        ' Min(RR.ID) AS RequestMin,'
    Set @sql = @sql +        ' Max(RR.ID) AS RequestMax'

    Set @sql = @sql + ' FROM T_Dataset DS'
    Set @sql = @sql +      ' INNER JOIN T_Experiments E ON DS.Exp_ID = E.Exp_ID'
    Set @sql = @sql +      ' INNER JOIN T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID'
    Set @sql = @sql +      ' INNER JOIN T_Requested_Run RR ON DS.Dataset_ID = RR.DatasetID'
    Set @sql = @sql +      ' INNER JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID'

    If @mostRecentWeeks > 0
    Begin
        Set @sql = @sql + ' WHERE DS.DateSortKey > DATEADD(Week, -@mostRecentWeeks, GETDATE())'
    End
    Else
    Begin
        Set @sql = @sql + ' WHERE DS.DateSortKey BETWEEN @startDate AND @endDate'
    End

    If @campaignNameFilter <> ''
    Begin
        Set @sql = @sql +   ' AND ' + @optionalCampaignNot + ' C.Campaign_Num LIKE @campaignNameFilter'
    End

    If @campaignNameExclude <> ''
    Begin
        Set @sql = @sql +   ' AND NOT C.Campaign_Num LIKE @campaignNameExclude'
    End

    If @instrumentBuilding <> ''
    Begin
        Set @sql = @sql +   ' AND ' + @optionalBuildingNot + ' InstName.Building LIKE @instrumentBuilding'
    End

    If @excludeQCAndBlankWithoutWP > 0
    Begin
        Set @sql = @sql +   ' AND NOT (C.Campaign_Num LIKE ''QC[-_]%'' AND RR.RDS_WorkPackage = ''None'') '
        Set @sql = @sql +   ' AND NOT (C.Campaign_Num IN (''Blank'', ''DataUpload'', ''DMS_Pipeline_Jobs'', ''Tracking'') AND RR.RDS_WorkPackage = ''None'') '
        Set @sql = @sql +   ' AND NOT (InstName.IN_Name LIKE ''External%'' AND RR.RDS_WorkPackage = ''None'') '
    End

    If @excludeAllQCAndBlank > 0
    Begin
        Set @sql = @sql +   ' AND NOT C.Campaign_Num LIKE ''QC[-_]%'' '
        Set @sql = @sql +   ' AND NOT C.Campaign_Num IN (''Blank'', ''DataUpload'', ''DMS_Pipeline_Jobs'', ''Tracking'') '
    End

    Set @sql = @sql + ' GROUP BY Campaign_Num, RR.RDS_WorkPackage, C.CM_Fraction_EMSL_FUnded, InstName.Building'
    If @includeInstrument > 0
    Begin
        Set @sql = @sql +    ', InstName.IN_name'
    End

    Set @sqlParams = '@mostRecentWeeks int, @campaignNameFilter varchar(128), @campaignNameExclude varchar(128), ' +
                     '@instrumentBuilding varchar(64), @startDate DateTime, @endDate DateTime'

    -----------------------------------------
    -- Preview or execute the query
    -----------------------------------------
    --
    If @previewSql <> 0
    Begin
        Print @sql
    End
    Else
    Begin
        Exec sys.sp_executesql @sql, @sqlParams,
            @mostRecentWeeks=@mostRecentWeeks,
            @campaignNameFilter=@campaignNameFilter,
            @campaignNameExclude=@campaignNameExclude,
            @instrumentBuilding=@instrumentBuilding,
            @startdate=@startdate,
            @endDate=@endDate
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -----------------------------------------
        -- Determine the total runtime
        -----------------------------------------
        --
        SELECT @totalRuntimeHours = Sum(RuntimeHours)
        FROM #Tmp_CampaignDatasetStats AS StatsQ

        -----------------------------------------
        -- Return the results
        -----------------------------------------
        --
        SELECT Campaign,
               WorkPackage AS [Work Package],
               FractionEMSLFunded * 100 As [Pct EMSL Funded],
               RuntimeHours AS [Runtime Hours],
               Datasets,
               Building,
               Instrument,
               RequestMin AS [Request Min],
               RequestMax AS [Request Max],
               Cast(RuntimeHours / @totalRuntimeHours * 100 AS decimal(9, 3)) AS [Pct Total Runtime]
        FROM #Tmp_CampaignDatasetStats
        ORDER BY RuntimeHours DESC

    End

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_stats_by_campaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_stats_by_campaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_stats_by_campaign] TO [Limited_Table_Write] AS [dbo]
GO
