/****** Object:  StoredProcedure [dbo].[GetDatasetStatsByCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDatasetStatsByCampaign]
/****************************************************
**
**  Desc: 
**      Returns a table summarizing datasets stats, 
**      grouped by campaign, work package, and instrument over the given time frame
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial release
**    
*****************************************************/
(
    @mostRecentWeeks Int = 20,
    @startDate Datetime = null,     -- Ignored if @mostRecentWeeks is non-zero
    @endDate Datetime = null,       -- Ignored if @mostRecentWeeks is non-zero
    @includeInstrument Tinyint = 0,
    @campaignNameFilter Varchar(512) = 'emsl',
    @previewSql Tinyint = 0,
    @message varchar(512) ='' OUTPUT
)
AS

    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError Int = 0
    
    Declare @msg varchar(256)
    
    Declare @sql nvarchar(2000)
    Declare @sqlParams Nvarchar(1000)

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    Set @mostRecentWeeks = IsNull(@mostRecentWeeks, 0)
    Set @includeInstrument = IsNull(@includeInstrument, 0)
    Set @campaignNameFilter = IsNull(@campaignNameFilter, '')
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

    If @campaignNameFilter <> '' 
    Begin
        -- Optionally add wildcards to the campaign filter
        If Not @campaignNameFilter Like '%[%]%'
        Begin
            Set @campaignNameFilter = '%' + @campaignNameFilter + '%'
        End

        If @previewSql > 0
        Begin
            Print 'Filtering on campaign name matching ''' + @campaignNameFilter + ''''
        End
    End


    -----------------------------------------
    -- Construct the query to retrieve the results
    -----------------------------------------
    --
    Set @sql = ''
    Set @sql = @sql + ' SELECT C.Campaign_Num AS Campaign,'
    If @includeInstrument > 0
    Begin
        Set @sql = @sql +    ' InstName.IN_name As Instrument,'
    End
    Set @sql = @sql +        ' RR.RDS_WorkPackage AS [Work Package],'
    Set @sql = @sql +        ' Cast(Sum(DS.Acq_Length_Minutes) / 60.0 AS decimal(9, 1)) AS [Runtime Hours],'
    Set @sql = @sql +        ' Count(*) AS Datasets,'
    Set @sql = @sql +        ' Min(RR.ID) AS [Request Min],'
    Set @sql = @sql +        ' Max(RR.ID) AS [Request Max]'

    Set @sql = @sql + ' FROM T_Dataset DS'
    Set @sql = @sql +      ' INNER JOIN T_Experiments E ON DS.Exp_ID = E.Exp_ID'
    Set @sql = @sql +      ' INNER JOIN T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID'
    Set @sql = @sql +      ' INNER JOIN T_Requested_Run RR ON DS.Dataset_ID = RR.DatasetID'
    If @includeInstrument > 0
    Begin
        Set @sql = @sql +  ' INNER JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID'
    End

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
        Set @sql = @sql +   ' AND C.Campaign_Num LIKE @campaignNameFilter'
    End

    Set @sql = @sql + ' GROUP BY Campaign_Num, RR.RDS_WorkPackage'
    If @includeInstrument > 0
    Begin
        Set @sql = @sql +    ', InstName.IN_name'
    End
    Set @sql = @sql + ' ORDER BY Sum(DS.Acq_Length_Minutes) DESC'

    Set @sqlParams = '@mostRecentWeeks int, @campaignNameFilter varchar(512), @startDate DateTime, @endDate DateTime'

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
        Exec sys.sp_executesql @sql, @sqlParams, @mostRecentWeeks=@mostRecentWeeks, @campaignNameFilter=@campaignNameFilter, @startdate=@startdate, @endDate=@endDate
    	--
    	SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetStatsByCampaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDatasetStatsByCampaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetStatsByCampaign] TO [Limited_Table_Write] AS [dbo]
GO
