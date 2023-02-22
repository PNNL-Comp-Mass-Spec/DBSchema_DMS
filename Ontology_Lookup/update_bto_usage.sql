/****** Object:  StoredProcedure [dbo].[UpdateBTOUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateBTOUsage]
/****************************************************
**
**  Desc:   Updates the usage columns in T_CV_BTO
**
**  Auth:   mem
**  Date:   11/08/2018 mem - Initial version
**    
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
As
    
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message2 varchar(255)
    Declare @rowsUpdated int = 0

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @message = ''

    ---------------------------------------------------
    -- Populate a temporary table with tissue usage stats for DMS experiments
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_UsageStats (
        Tissue_ID            varchar(24) NOT NULL,
        Usage_All_Time       int NULL,
        Usage_Last_12_Months int NULL Default 0
    )

    INSERT INTO #Tmp_UsageStats( Tissue_ID,
                                 Usage_All_Time )
    SELECT E.EX_Tissue_ID,
           Count(*) AS Usage_All_Time
    FROM S_T_Experiments E
    WHERE NOT E.EX_Tissue_ID IS NULL
    GROUP BY E.EX_Tissue_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    UPDATE #Tmp_UsageStats
    SET Usage_Last_12_Months = SourceQ.Usage_Last_12_Months
    FROM #Tmp_UsageStats Target
         INNER JOIN ( SELECT E.EX_Tissue_ID AS Tissue_ID,
                             Count(*) AS Usage_Last_12_Months
                      FROM S_T_Experiments E
                      WHERE NOT E.EX_Tissue_ID IS NULL AND
                            E.EX_Created >= DateAdd(DAY, - 365, GetDate())
                      GROUP BY E.EX_Tissue_ID ) SourceQ
           ON Target.Tissue_ID = SourceQ.Tissue_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
           
    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- Update T_CV_BTO_Cached_Names
        ---------------------------------------------------
        
        UPDATE T_CV_BTO
        SET Usage_Last_12_Months = Source.Usage_Last_12_Months,
            Usage_All_Time = Source.Usage_All_Time
        FROM T_CV_BTO Target
             INNER JOIN #Tmp_UsageStats Source
               ON Target.Identifier = Source.Tissue_ID
        Where Target.Usage_Last_12_Months <>  Source.Usage_Last_12_Months Or
              Target.Usage_All_Time <>  Source.Usage_All_Time
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @rowsUpdated = @rowsUpdated + @myRowCount
            Set @message = 'Updated ' + Cast(@myRowCount As varchar(12)) + ' ' + 
                           dbo.CheckPlural(@myRowCount, 'row', 'rows') + ' in T_CV_BTO'
        End

        UPDATE T_CV_BTO
        SET Usage_Last_12_Months = 0,
            Usage_All_Time = 0
        FROM T_CV_BTO Target
             LEFT OUTER JOIN #Tmp_UsageStats Source
               ON Target.Identifier = Source.Tissue_ID
        WHERE (Target.Usage_Last_12_Months > 0 Or Target.Usage_All_Time > 0) And
              Source.Tissue_ID IS Null
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @rowsUpdated = @rowsUpdated + @myRowCount
            Set @message2 = 'Set usage stats to 0 for ' + Cast(@myRowCount As varchar(12)) + ' ' + 
                            dbo.CheckPlural(@myRowCount, 'row', 'rows') + ' in T_CV_BTO'

            If @message = ''
                Set @message = @message2
            Else
                Set @message = @message + '; ' + @message2
        End

        If @rowsUpdated = 0
        Begin
            Set @message = 'Usage stats were already up-to-date'
        End
    End
    Else
    Begin
        ---------------------------------------------------
        -- Preview the usage stats
        ---------------------------------------------------
        
        SELECT *
        FROM #Tmp_UsageStats
        ORDER BY Usage_All_Time DESC
    End
        
Done:
    return 0


GO
