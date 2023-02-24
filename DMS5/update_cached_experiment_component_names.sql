/****** Object:  StoredProcedure [dbo].[update_cached_experiment_component_names] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_experiment_component_names]
/****************************************************
**
**  Desc:   Updates T_Cached_Experiment_Components,
**          which tracks the semicolon separated list of
**          biomaterial names and reference compound names for each exeriment
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/29/2017 mem - Initial version
**          01/04/2018 mem - Now caching reference compounds using the ID_Name field (which is of the form Compound_ID:Compound_Name)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experimentID int,         -- Set to 0 to process all experiments, or a positive number to only process the given experiment
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @experimentID = IsNull(@experimentID, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    Declare @cellCultureList varchar(2048) = null
    Declare @refCompoundList varchar(2048) = null

    If @experimentID > 0
    Begin -- <SingleExperiment>

        ------------------------------------------------
        -- Processing a single experiment
        ------------------------------------------------
        --
        SELECT @cellCultureList = Coalesce(@cellCultureList + '; ' + CC.CC_Name, CC.CC_Name)
        FROM T_Experiment_Cell_Cultures ECC
             INNER JOIN T_Cell_Culture CC
               ON ECC.CC_ID = CC.CC_ID
        WHERE ECC.Exp_ID = @experimentID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        SELECT @refCompoundList = Coalesce(@refCompoundList + '; ' + RC.ID_Name, RC.ID_Name)
        FROM T_Experiment_Reference_Compounds ERC
             INNER JOIN T_Reference_Compound RC
               ON ERC.Compound_ID = RC.Compound_ID
        WHERE ERC.Exp_ID = @experimentID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            SELECT @experimentID AS Experiment_ID, @cellCultureList AS Cell_Culture_List, @refCompoundList AS Reference_Compound_List
        End
        Else
        Begin

            MERGE T_Cached_Experiment_Components AS t
            USING (SELECT @experimentID AS Exp_ID, @cellCultureList AS Cell_Culture_List, @refCompoundList AS Reference_Compound_List) as s
            ON ( t.[Exp_ID] = s.[Exp_ID])
            WHEN MATCHED AND (
                ISNULL( NULLIF(t.[Cell_Culture_List], s.[Cell_Culture_List]),
                        NULLIF(s.[Cell_Culture_List], t.[Cell_Culture_List])) IS NOT NULL OR
                ISNULL( NULLIF(t.[Reference_Compound_List], s.[Reference_Compound_List]),
                        NULLIF(s.[Reference_Compound_List], t.[Reference_Compound_List])) IS NOT NULL
                )
            THEN UPDATE SET
                [Cell_Culture_List] = s.[Cell_Culture_List],
                [Reference_Compound_List] = s.[Reference_Compound_List],
                [Last_affected] = GetDate()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT([Exp_ID], [Cell_Culture_List], [Reference_Compound_List])
                VALUES(s.[Exp_ID], s.[Cell_Culture_List], s.[Reference_Compound_List])
            ;

        End

    End  -- </SingleExperiment>
    Else
    Begin -- <AllExperiments>
        ------------------------------------------------
        -- Processing all experiments
        -- Populate temporary tables with the data to store
        ------------------------------------------------
        --

        CREATE TABLE #Tmp_ExperimentCellCultures (
            Exp_ID int not null,
            Cell_Culture_List varchar(2048) null,
            Items int null
        )

        CREATE TABLE #Tmp_ExperimentRefCompounds (
            Exp_ID int not null,
            Reference_Compound_List varchar(2048) null,
            Items int null
        )

        CREATE TABLE #Tmp_AdditionalExperiments (
            Exp_ID int not null
        )

        CREATE UNIQUE CLUSTERED INDEX #Tmp_ExperimentCellCultures_ExpID ON #Tmp_ExperimentCellCultures (Exp_ID)

        CREATE UNIQUE CLUSTERED INDEX #Tmp_ExperimentRefCompounds_ExpID ON #Tmp_ExperimentRefCompounds (Exp_ID)

        CREATE UNIQUE CLUSTERED INDEX #Tmp_AdditionalExperiments_ExpID ON #Tmp_AdditionalExperiments (Exp_ID)

        -- Add mapping info for experiments with only one cell culture
        --
        INSERT INTO #Tmp_ExperimentCellCultures (Exp_ID, Cell_Culture_List, Items)
        SELECT ECC.Exp_ID,
               CC.CC_Name,
               1 as Items
        FROM T_Experiment_Cell_Cultures ECC
             INNER JOIN T_Cell_Culture CC
               ON ECC.CC_ID = CC.CC_ID
             INNER JOIN ( SELECT Exp_ID
                          FROM T_Experiment_Cell_Cultures
                          GROUP BY Exp_ID
                          HAVING COUNT(*) = 1 ) FilterQ
               ON ECC.Exp_ID = FilterQ.Exp_ID

        -- Add mapping info for experiments with only one reference compound
        --
        INSERT INTO #Tmp_ExperimentRefCompounds (Exp_ID, Reference_Compound_List, Items)
        SELECT ERC.Exp_ID,
               RC.ID_Name,
               1 as Items
        FROM T_Experiment_Reference_Compounds ERC
             INNER JOIN T_Reference_Compound RC
               ON ERC.Compound_ID = RC.Compound_ID
             INNER JOIN ( SELECT Exp_ID
                          FROM T_Experiment_Reference_Compounds
                          GROUP BY Exp_ID
                          HAVING COUNT(*) = 1 ) FilterQ
               ON ERC.Exp_ID = FilterQ.Exp_ID

        Declare @currentExperimentID int
        Declare @continue tinyint

        -- Add experiments with multiple cell cultures
        --
        TRUNCATE TABLE #Tmp_AdditionalExperiments

        INSERT INTO #Tmp_AdditionalExperiments (Exp_ID)
        SELECT Exp_ID
        FROM T_Experiment_Cell_Cultures
        GROUP BY Exp_ID
        HAVING COUNT(*) > 1

        Set @currentExperimentID = 0
        Set @continue = 1

        While @continue > 0
        Begin
            SELECT TOP 1 @currentExperimentID = Exp_ID
            FROM #Tmp_AdditionalExperiments
            WHERE Exp_ID > @currentExperimentID
            ORDER BY Exp_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Set @cellCultureList = null

                SELECT @cellCultureList = Coalesce(@cellCultureList + '; ' + CC.CC_Name, CC.CC_Name)
                FROM T_Experiment_Cell_Cultures ECC
                    INNER JOIN T_Cell_Culture CC
                    ON ECC.CC_ID = CC.CC_ID
                WHERE ECC.Exp_ID = @currentExperimentID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                INSERT INTO #Tmp_ExperimentCellCultures (Exp_ID, Cell_Culture_List, Items)
                SELECT @currentExperimentID, @cellCultureList, @myRowCount

            End

        End

        -- Add experiments with multiple reference compounds
        --
        TRUNCATE TABLE #Tmp_AdditionalExperiments

        INSERT INTO #Tmp_AdditionalExperiments (Exp_ID)
        SELECT Exp_ID
        FROM T_Experiment_Reference_Compounds
        GROUP BY Exp_ID
        HAVING COUNT(*) > 1

        Set @currentExperimentID = 0
        Set @continue = 1

        While @continue > 0
        Begin
            SELECT TOP 1 @currentExperimentID = Exp_ID
            FROM #Tmp_AdditionalExperiments
            WHERE Exp_ID > @currentExperimentID
            ORDER BY Exp_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Set @refCompoundList = null

                SELECT @refCompoundList = Coalesce(@refCompoundList + '; ' + RC.ID_Name, RC.ID_Name)
                FROM T_Experiment_Reference_Compounds ERC
                     INNER JOIN T_Reference_Compound RC
                       ON ERC.Compound_ID = RC.Compound_ID
                WHERE ERC.Exp_ID = @currentExperimentID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                INSERT INTO #Tmp_ExperimentRefCompounds (Exp_ID, Reference_Compound_List, Items)
                SELECT @currentExperimentID, @refCompoundList, @myRowCount

            End
        End

        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the data that would be merged into T_Cached_Experiment_Components
            ------------------------------------------------
            --

            SELECT ECC.Exp_ID,
                   ECC.Cell_Culture_List,
                   ECC.Items AS CellCulture_Items,
                   ERC.Reference_Compound_List,
                   ERC.Items AS RefCompound_Items
            FROM #Tmp_ExperimentCellCultures ECC
              FULL OUTER JOIN #Tmp_ExperimentRefCompounds ERC
                   ON ECC.Exp_ID = ERC.Exp_ID
            ORDER BY IsNull(ECC.Items, ERC.Items), Exp_ID

        End
        Else
        Begin
            ------------------------------------------------
            -- Update cell culture lists
            ------------------------------------------------
            --
            MERGE T_Cached_Experiment_Components AS t
            USING (SELECT Exp_ID, Cell_Culture_List FROM #Tmp_ExperimentCellCultures) as s
            ON ( t.[Exp_ID] = s.[Exp_ID])
            WHEN MATCHED AND (
                ISNULL( NULLIF(t.[Cell_Culture_List], s.[Cell_Culture_List]),
                        NULLIF(s.[Cell_Culture_List], t.[Cell_Culture_List])) IS NOT NULL
                )
            THEN UPDATE SET
                [Cell_Culture_List] = s.[Cell_Culture_List],
                [Last_affected] = GetDate()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT([Exp_ID], [Cell_Culture_List])
                VALUES(s.[Exp_ID], s.[Cell_Culture_List])
            ;

            ------------------------------------------------
            -- Update reference compound lists
            ------------------------------------------------
            --
            MERGE T_Cached_Experiment_Components AS t
            USING (SELECT Exp_ID, Reference_Compound_List FROM #Tmp_ExperimentRefCompounds) as s
            ON ( t.[Exp_ID] = s.[Exp_ID])
            WHEN MATCHED AND (
                ISNULL( NULLIF(t.[Reference_Compound_List], s.[Reference_Compound_List]),
                        NULLIF(s.[Reference_Compound_List], t.[Reference_Compound_List])) IS NOT NULL
                )
            THEN UPDATE SET
                [Reference_Compound_List] = s.[Reference_Compound_List],
                [Last_affected] = GetDate()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT([Exp_ID], [Reference_Compound_List])
                VALUES(s.[Exp_ID], s.[Reference_Compound_List])
            ;

            ------------------------------------------------
            -- Assure Cell_Culture_List and Reference_Compound_List are Null for experiments not in the temp tables
            ------------------------------------------------
            --
            UPDATE T_Cached_Experiment_Components
            SET Cell_Culture_List = NULL
            FROM T_Cached_Experiment_Components Target
                 LEFT OUTER JOIN #Tmp_ExperimentCellCultures Src
                   ON Target.Exp_ID = Src.Exp_ID
            WHERE NOT Target.Cell_Culture_List IS NULL AND
                  Src.Exp_ID IS NULL

            UPDATE T_Cached_Experiment_Components
            SET Reference_Compound_List = NULL
            FROM T_Cached_Experiment_Components Target
                 LEFT OUTER JOIN #Tmp_ExperimentRefCompounds Src
                   ON Target.Exp_ID = Src.Exp_ID
            WHERE NOT Target.Reference_Compound_List IS NULL AND
                  Src.Exp_ID IS NULL

        End

    End -- </AllExperiments>

Done:
    return @myError

GO
