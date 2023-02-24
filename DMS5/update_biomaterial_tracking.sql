/****** Object:  StoredProcedure [dbo].[UpdateCellCultureTracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCellCultureTracking]
/****************************************************
**
**  Desc: Updates summary stats in T_Cell_Culture_Tracking
**
**  Return values: 0: success, otherwise, error code
**    
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          08/30/2018 mem - Use merge instead of truncate
**    
*****************************************************/
AS
    Declare @message varchar(512)

    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    set @message = ''

    ----------------------------------------------------------
    -- Create a temporary table to hold the stats
    ----------------------------------------------------------
    --
    CREATE TABLE #Tmp_CellCultureStats (
        CC_ID int NOT NULL,
        Experiment_Count int NOT NULL,
        Dataset_Count int NOT NULL,
        Job_Count int NOT NULL,
        CONSTRAINT PK_Tmp_CellCultureStats PRIMARY KEY CLUSTERED ( CC_ID Asc)
    ) 
     
    ----------------------------------------------------------
    -- Make entry in results table for each cell culture
    ----------------------------------------------------------
    --
    INSERT INTO #Tmp_CellCultureStats( CC_ID,
                                       Experiment_Count,
                                       Dataset_Count,
                                       Job_Count )
    SELECT CC_ID,
           0, 0, 0
    FROM T_Cell_Culture
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     
     
    ----------------------------------------------------------
    -- Update experiment count statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CellCultureStats
    SET Experiment_Count = S.Cnt
    FROM #Tmp_CellCultureStats
         INNER JOIN ( SELECT CC_ID,
                             COUNT(Exp_ID) AS Cnt
                      FROM T_Experiment_Cell_Cultures
                      GROUP BY CC_ID 
                     ) AS S
           ON #Tmp_CellCultureStats.CC_ID = S.CC_ID


    ----------------------------------------------------------
    -- Update dataset count statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CellCultureStats
    SET Dataset_Count = S.Cnt
    FROM #Tmp_CellCultureStats
         INNER JOIN ( SELECT T_Experiment_Cell_Cultures.CC_ID,
                             COUNT(T_Dataset.Dataset_ID) AS Cnt
                      FROM T_Experiment_Cell_Cultures
                           INNER JOIN T_Experiments
                             ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
                           INNER JOIN T_Dataset
                             ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
                      GROUP BY T_Experiment_Cell_Cultures.CC_ID 
                     ) AS S
           ON #Tmp_CellCultureStats.CC_ID = S.CC_ID

    ----------------------------------------------------------
    -- Update analysis count statistics for results table
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CellCultureStats
    SET Job_Count = S.Cnt
    FROM #Tmp_CellCultureStats
         INNER JOIN ( SELECT T_Experiment_Cell_Cultures.CC_ID,
                             COUNT(T_Analysis_Job.AJ_jobID) AS Cnt
                      FROM T_Experiment_Cell_Cultures
                           INNER JOIN T_Experiments
                             ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
                           INNER JOIN T_Dataset
                             ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
                           INNER JOIN T_Analysis_Job
                             ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
                      GROUP BY T_Experiment_Cell_Cultures.CC_ID 
                     ) AS S
           ON #Tmp_CellCultureStats.CC_ID = S.CC_ID

    ----------------------------------------------------------
    -- Update T_Cell_Culture_Tracking using #Tmp_CellCultureStats
    ----------------------------------------------------------
    --        
    MERGE T_Cell_Culture_Tracking AS t
    USING (SELECT * FROM #Tmp_CellCultureStats) as s
    ON ( t.CC_ID = s.CC_ID)
    WHEN MATCHED AND (
        t.Experiment_Count <> s.Experiment_Count OR
        t.Dataset_Count <> s.Dataset_Count OR
        t.Job_Count <> s.Job_Count
        )
    THEN UPDATE SET 
        Experiment_Count = s.Experiment_Count,
        Dataset_Count = s.Dataset_Count,
        Job_Count = s.Job_Count
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(CC_ID, Experiment_Count, Dataset_Count, Job_Count)
        VALUES(s.CC_ID, s.Experiment_Count, s.Dataset_Count, s.Job_Count)
    WHEN NOT MATCHED BY SOURCE THEN DELETE
    ;
    
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCellCultureTracking] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCellCultureTracking] TO [Limited_Table_Write] AS [dbo]
GO
