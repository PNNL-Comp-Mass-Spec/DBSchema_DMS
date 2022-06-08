/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItemsUtility] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDataPackageItemsUtility]
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      Expects list of items to be in temp table #TPI
**
**      CREATE TABLE #TPI(
**          DataPackageID int not null,         -- Data package ID
**          [Type] varchar(50) null,            -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
**          Identifier varchar(256) null        -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/23/2010
**          06/10/2009 grk - changed size of item list to max
**          06/10/2009 mem - Now calling UpdateDataPackageItemCounts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, S_V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
**          12/31/2013 mem - Added support for EUS Proposals
**          09/02/2014 mem - Updated to remove non-numeric items when working with analysis jobs
**          10/28/2014 mem - Added support for adding datasets using dataset IDs; to delete datasets, you must use the dataset name (safety feature)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/18/2016 mem - Fix bug removing duplicate analysis jobs
**                         - Add parameter @infoOnly
**          10/19/2016 mem - Update #TPI to use an integer field for data package ID
**                         - Call UpdateDataPackageEUSInfo
**                         - Prevent addition of Biomaterial '(none)'
**          11/14/2016 mem - Add parameter @removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          04/25/2018 mem - Populate column Dataset_ID in T_Data_Package_Analysis_Jobs
**          06/12/2018 mem - Send @maxLength to AppendToText
**          07/17/2019 mem - Remove .raw and .d from the end of dataset names
**          07/02/2021 mem - Update the package comment for any existing items when @mode is 'add' and @comment is not an empty string
**          07/02/2021 mem - Change the default value for @mode from undefined mode 'update' to 'add'
**          07/06/2021 mem - Add support for dataset IDs when @mode is 'comment' or 'delete'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Rename package comment field to Package_Comment
**
*****************************************************/
(
    @comment varchar(512),
    @mode varchar(12) = 'add',               -- 'add', 'comment', 'delete'
    @removeParents tinyint = 0,              -- When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
    @message varchar(512) = '' output,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @itemCountChanged int = 0
    Declare @actionMsg varchar(128)

    CREATE TABLE #Tmp_DatasetIDsToAdd (
        DataPackageID int NOT NULL,
        DatasetID int NOT NULL
    )

    CREATE TABLE #Tmp_JobsToAddOrDelete (
        DataPackageID int not null,            -- Data package ID
        Job int not null
    )

    CREATE INDEX #IX_Tmp_JobsToAddOrDelete ON #Tmp_JobsToAddOrDelete (Job, DataPackageID)

    BEGIN TRY

        ---------------------------------------------------
        -- Verify that the user can execute this procedure from the given client host
        ---------------------------------------------------

        Declare @authorized tinyint = 0
        Exec @authorized = VerifySPAuthorized 'UpdateDataPackageItemsUtility', @raiseError = 1
        If @authorized = 0
        Begin
            RAISERROR ('Access denied', 11, 3)
        End

        -- If working with analysis jobs, populate #Tmp_JobsToAddOrDelete with all numeric job entries
        --
        If Exists ( SELECT * FROM #TPI WHERE [Type] = 'Job' )
        Begin
            DELETE #TPI
            WHERE IsNull(Identifier, '') = '' OR Try_Parse(Identifier as int) Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @infoOnly > 0 And @myRowCount > 0
            Begin
                Print 'Warning: deleted ' + Cast(@myRowCount as varchar(12)) + ' job(s) that were not numeric'
            End

            INSERT INTO #Tmp_JobsToAddOrDelete( DataPackageID, Job )
            SELECT DataPackageID,
                   Job
            FROM ( SELECT DataPackageID,
                          Try_Parse(Identifier as int) as Job
                   FROM #TPI
                   WHERE [Type] = 'Job' AND
                         Not DataPackageID Is Null) SourceQ
            WHERE Not Job Is Null
        End

        If Exists ( SELECT * FROM #TPI WHERE [Type] = 'Dataset' )
        Begin
            -- Auto-remove .raw and .d from the end of dataset names
            Update #TPI
            Set Identifier = Substring(Identifier, 1, Len(Identifier) - 4)
            Where [Type] = 'Dataset' And #TPI.Identifier Like '%.raw'

            Update #TPI
            Set Identifier = Substring(Identifier, 1, Len(Identifier) - 2)
            Where [Type] = 'Dataset' And #TPI.Identifier Like '%.d'

            -- Auto-convert dataset IDs to dataset names
            -- First look for dataset IDs
            INSERT INTO #Tmp_DatasetIDsToAdd( DataPackageID, DatasetID )
            SELECT DataPackageID,
                   DatasetID
            FROM ( SELECT DataPackageID,
                          Try_Parse(Identifier as int) AS DatasetID
                   FROM #TPI
                   WHERE [Type] = 'Dataset' AND
                         NOT DataPackageID IS NULL ) SourceQ
            WHERE NOT DatasetID IS NULL

            If Exists (SELECT * FROM #Tmp_DatasetIDsToAdd)
            Begin
                -- Add the dataset names
                INSERT INTO #TPI( DataPackageID,
                                  [Type],
                                  Identifier )
                SELECT Source.DataPackageID,
                       'Dataset' AS [Type],
                       DL.Dataset
                FROM #Tmp_DatasetIDsToAdd Source
                     INNER JOIN S_V_Dataset_List_Report_2 DL
                       ON Source.DatasetID = DL.ID

                -- Update the Type of the Dataset IDs so that they will be ignored
                UPDATE #TPI
                SET [Type] = 'DatasetID'
                FROM #TPI
                     INNER JOIN #Tmp_DatasetIDsToAdd Source
                       ON #TPI.Identifier = Cast(Source.DatasetID AS varchar(12))

            End

        End

        -- Add parent items and associated items to list for items in the list
        -- This process cascades up the DMS hierarchy of tracking entities, but not down
        --
        IF @mode = 'add'
        BEGIN -- <add_associated_items>

            -- Add datasets to list that are parents of jobs in the list
            -- (and are not already in the list)
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT DISTINCT
                J.DataPackageID,
                'Dataset',
                TX.Dataset
            FROM
                #Tmp_JobsToAddOrDelete J
                INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                  ON J.Job = TX.Job
            WHERE
                NOT EXISTS (
                    SELECT *
                    FROM #TPI
                    WHERE #TPI.[Type] = 'Dataset' AND #TPI.Identifier = TX.Dataset AND #TPI.DataPackageID = J.DataPackageID
                )

            -- Add experiments to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'Experiment',
                TX.Experiment
            FROM
                #TPI TP
                INNER JOIN S_V_Dataset_List_Report_2 TX
                ON TP.Identifier = TX.Dataset
            WHERE
                TP.[Type] = 'Dataset'
                AND NOT EXISTS (
                    SELECT *
                    FROM #TPI
                    WHERE #TPI.[Type] = 'Experiment' AND #TPI.Identifier = TX.Experiment AND #TPI.DataPackageID = TP.DataPackageID
                )

            -- Add EUS Proposals to list that are parents of datasets in the list
            -- (and are not already in the list)
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'EUSProposal',
                TX.Proposal
            FROM
                #TPI TP
                INNER JOIN S_V_Dataset_List_Report_2 TX
                ON TP.Identifier = TX.Dataset
            WHERE
                TP.[Type] = 'Dataset'
                AND NOT EXISTS (
                    SELECT *
                    FROM #TPI
                    WHERE #TPI.[Type] = 'EUSProposal' AND #TPI.Identifier = TX.Proposal AND #TPI.DataPackageID = TP.DataPackageID
                )

            -- Add biomaterial items to list that are associated with experiments in the list
            -- (and are not already in the list)
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT DISTINCT
                TP.DataPackageID,
                'Biomaterial',
                TX.Cell_Culture_Name
            FROM
                #TPI TP
                INNER JOIN S_V_Experiment_Cell_Culture TX
                ON TP.Identifier = TX.Experiment_Num
            WHERE
                TP.[Type] = 'Experiment' AND
                TX.Cell_Culture_Name NOT IN ('(none)')
                AND NOT EXISTS (
                    SELECT *
                    FROM #TPI
                    WHERE #TPI.[Type] = 'Biomaterial' AND #TPI.Identifier = TX.Cell_Culture_Name AND #TPI.DataPackageID = TP.DataPackageID
                )

        END -- </add_associated_items>


        If @mode = 'delete' And @removeParents > 0
        Begin
            -- Find Datasets, Experiments, Biomaterial, and Cell Culture items that we can safely delete
            -- after deleting the jobs and/or datasets in #TPI

            -- Find parent datasets that will have no jobs remaining once we remove the jobs in #TPI
            --
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Dataset
            FROM (
                   -- Datasets associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Dataset' AS ItemType,
                                   TX.Dataset AS Dataset
                   FROM #Tmp_JobsToAddOrDelete J
                       INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Datasets associated with the data package; skipping the jobs that we're deleting
                        SELECT Datasets.Dataset,
                               Datasets.Data_Package_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Package_ID = Datasets.Data_Package_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Package_ID = ItemsQ.DataPackageID AND
                                  Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Package_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.Data_Package_ID AND
                      ToDelete.Dataset = ToKeep.Dataset
            WHERE ToKeep.Data_Package_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            -- Find parent experiments that will have no jobs or datasets remaining once we remove the jobs in #TPI
            --
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Experiment
            FROM (
                   -- Experiments associated with jobs or datasets that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Experiment' AS ItemType,
                                   TX.Experiment AS Experiment
                   FROM #Tmp_JobsToAddOrDelete J
                        INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                   UNION
                   SELECT DISTINCT TP.DataPackageID,
                                   'Experiment',
                                   TX.Experiment
                   FROM #TPI TP
                        INNER JOIN S_V_Dataset_List_Report_2 TX
                          ON TP.Identifier = TX.Dataset
                   WHERE TP.[Type] = 'Dataset'
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Experiments associated with the data package; skipping any jobs that we're deleting
                        SELECT Experiments.Experiment,
                               Datasets.Data_Package_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Package_ID = Datasets.Data_Package_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Package_ID = Experiments.Data_Package_ID
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Package_ID = ItemsQ.DataPackageID AND
                                   Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Package_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep1
                   ON ToDelete.DataPackageID = ToKeep1.Data_Package_ID AND
                      ToDelete.Experiment = ToKeep1.Experiment
                 LEFT OUTER JOIN (
                        -- Experiments associated with the data package; skipping any datasets that we're deleting
                        SELECT Experiments.Experiment,
                               Datasets.Data_Package_ID
                        FROM T_Data_Package_Datasets Datasets
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Package_ID = Experiments.Data_Package_ID
                             LEFT OUTER JOIN #TPI ItemsQ
                               ON Datasets.Data_Package_ID = ItemsQ.DataPackageID AND
                                   ItemsQ.[Type] = 'Dataset' AND
                                   ItemsQ.Identifier = Datasets.Dataset
                        WHERE Datasets.Data_Package_ID IN (SELECT DISTINCT DataPackageID FROM #TPI) AND
                              ItemsQ.Identifier IS NULL
                 ) AS ToKeep2
                   ON ToDelete.DataPackageID = ToKeep2.Data_Package_ID AND
                      ToDelete.Experiment = ToKeep2.Experiment
            WHERE ToKeep1.Data_Package_ID IS NULL AND
                  ToKeep2.Data_Package_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            -- Find parent biomaterial that will have no jobs or datasets remaining once we remove the jobs in #TPI
            --
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Cell_Culture_Name
            FROM (
                   -- Biomaterial associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Biomaterial' AS ItemType,
                                   Biomaterial.Cell_Culture_Name
                   FROM #Tmp_JobsToAddOrDelete J
                        INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                        INNER JOIN S_V_Experiment_Cell_Culture Biomaterial
                          ON Biomaterial.Experiment_Num = TX.Experiment
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Biomaterial associated with the data package; skipping the jobs that we're deleting
                        SELECT DISTINCT Biomaterial.Name AS Cell_Culture_Name,
                                        Datasets.Data_Package_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Package_ID = Datasets.Data_Package_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Package_ID = Experiments.Data_Package_ID
                             INNER JOIN T_Data_Package_Biomaterial Biomaterial
                               ON Experiments.Data_Package_ID = Biomaterial.Data_Package_ID
                             INNER JOIN S_V_Experiment_Cell_Culture Exp_CC_Map
                               ON Experiments.Experiment = Exp_CC_Map.Experiment_Num AND
                                  Exp_CC_Map.Cell_Culture_Name = Biomaterial.Name
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Package_ID = ItemsQ.DataPackageID AND
                                  Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Package_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.Data_Package_ID AND
                      ToDelete.Cell_Culture_Name = ToKeep.Cell_Culture_Name
            WHERE ToKeep.Data_Package_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

        ---------------------------------------------------
        -- Possibly preview the items
        ---------------------------------------------------

        If @infoOnly <> 0
        Begin
            If Not @mode In ('add', 'comment', 'delete')
            Begin
                SELECT '@mode should be add, comment, or delete; ' + @mode + ' is invalid' As Warning
            End

            SELECT *
            FROM #TPI
            ORDER BY DataPackageID, [Type], Identifier
        End

        ---------------------------------------------------
        -- Biomaterial operations
        ---------------------------------------------------

        IF @mode = 'delete' And Exists (Select * From #TPI Where [Type] = 'Biomaterial')
        BEGIN -- <delete biomaterial>
            If @infoOnly > 0
            Begin
                SELECT 'Biomaterial to delete' AS Biomaterial_Msg, Target.*
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.CheckPlural(@myRowCount, ' item', ' items')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </delete biomaterial>

        IF @mode = 'comment' And Exists (Select * From #TPI Where [Type] = 'Biomaterial')
        BEGIN -- <comment biomaterial>
            If @infoOnly > 0
            Begin
                SELECT 'Update Biomaterial comment' AS Item_Type,
                       @comment AS New_Comment, *
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin
                UPDATE T_Data_Package_Biomaterial
                SET Package_Comment = @comment
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.CheckPlural(@myRowCount, ' item', ' items')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </comment biomaterial>

        IF @mode = 'add' And Exists (Select * From #TPI Where [Type] = 'Biomaterial')
        BEGIN -- <add biomaterial>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Biomaterial TX
                   ON #TPI.DataPackageID = TX.Data_Package_ID AND
                      #TPI.Identifier = TX.Name AND
                      #TPI.[Type] = 'Biomaterial'

            If @infoOnly > 0
            Begin
                SELECT DISTINCT #TPI.DataPackageID,
                                'New Biomaterial' AS Item_Type,
                                TX.ID,
                                @comment AS [Comment],
                                TX.Name,
                                TX.Campaign,
                                TX.Created,
                                TX.[Type]
                FROM #TPI
                     INNER JOIN S_V_Cell_Culture_List_Report_2 TX
                       ON #TPI.Identifier = Name

                WHERE #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin

                -- Add new items
                INSERT INTO T_Data_Package_Biomaterial(
                    Data_Package_ID,
                    Biomaterial_ID,
                    Package_Comment,
                    Name,
                    Campaign,
                    Created,
                    [Type]
                )
                SELECT DISTINCT
                    #TPI.DataPackageID,
                    TX.ID,
                    @comment,
                    TX.Name,
                    TX.Campaign,
                    TX.Created,
                    TX.[Type]
                FROM
                    #TPI
                    INNER JOIN S_V_Cell_Culture_List_Report_2 TX
                    ON #TPI.Identifier = Name
                WHERE #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.CheckPlural(@myRowCount, ' item', ' items')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </add biomaterial>

        ---------------------------------------------------
        -- EUS Proposal operations
        ---------------------------------------------------

        IF @mode = 'delete' And Exists (Select * From #TPI Where [Type] = 'EUSProposal')
        BEGIN -- <delete EUS Proposals>
            If @infoOnly > 0
            Begin
                SELECT 'EUS Proposal to delete' AS EUS_Proposal_Msg, Target.*
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.CheckPlural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </delete EUS Proposal>

        IF @mode = 'comment' And Exists (Select * From #TPI Where [Type] = 'EUSProposal')
        BEGIN -- <comment EUS Proposals>
            If @infoOnly > 0
            Begin
                SELECT 'Update EUS Proposal comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_EUS_Proposal Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
            End
            Else
            Begin
                UPDATE T_Data_Package_EUS_Proposals
                SET Package_Comment = @comment
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.CheckPlural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </comment EUS Proposals>

        IF @mode = 'add' And Exists (Select * From #TPI Where [Type] = 'EUSProposal')
        BEGIN -- <add EUS Proposals>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_EUS_Proposals TX
                   ON #TPI.DataPackageID = TX.Data_Package_ID AND
                      #TPI.Identifier = TX.Proposal_ID AND
                      #TPI.[Type] = 'EUSProposal'

            If @infoOnly > 0
            Begin
                SELECT DISTINCT #TPI.DataPackageID,
                                'New EUS Proposal' AS Item_Type,
                                TX.ID,
                                @comment AS [Comment]
                FROM #TPI
                     INNER JOIN S_V_EUS_Proposals_List_Report TX
                       ON #TPI.Identifier = TX.ID
                WHERE #TPI.[Type] = 'EUSProposal'

            End
            Else
            Begin
                -- Add new items
                INSERT INTO T_Data_Package_EUS_Proposals( Data_Package_ID,
                                                          Proposal_ID,
                                                          Package_Comment )
                SELECT DISTINCT #TPI.DataPackageID,
                                TX.ID,
                                @comment
                FROM #TPI
                     INNER JOIN S_V_EUS_Proposals_List_Report TX
                       ON #TPI.Identifier = TX.ID
                WHERE #TPI.[Type] = 'EUSProposal'

                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.CheckPlural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </add EUS Proposals>

        ---------------------------------------------------
        -- Experiment operations
        ---------------------------------------------------

        IF @mode = 'delete' And Exists (Select * From #TPI Where [Type] = 'Experiment')
        BEGIN -- <delete experiments>
            If @infoOnly > 0
            Begin
                SELECT 'Experiment to delete' AS Experiment_Msg, Target.*
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'

            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                  #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </delete experiments>

        IF @mode = 'comment' And Exists (Select * From #TPI Where [Type] = 'Experiment')
        BEGIN -- <comment experiments>
            If @infoOnly > 0
            Begin
                SELECT 'Update Experiment comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'

            End
            Else
            Begin
                UPDATE T_Data_Package_Experiments
                SET Package_Comment = @comment
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </comment experiments>

        IF @mode = 'add' And Exists (Select * From #TPI Where [Type] = 'Experiment')
        BEGIN -- <add experiments>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Experiments TX
                   ON #TPI.DataPackageID = TX.Data_Package_ID AND
                      #TPI.Identifier = TX.Experiment AND
                      #TPI.[Type] = 'Experiment'


            If @infoOnly > 0
            Begin
                SELECT DISTINCT
                    #TPI.DataPackageID,
                    'New Experiment ID' as Item_Type,
                    TX.ID,
                    @comment AS [Comment],
                    TX.Experiment,
                    TX.Created
                FROM
                    #TPI
                    INNER JOIN S_V_Experiment_Detail_Report_Ex TX
                    ON #TPI.Identifier = TX.Experiment
                WHERE #TPI.[Type] = 'Experiment'
            End
            Else
            Begin
                -- Add new items
                INSERT INTO T_Data_Package_Experiments(
                    Data_Package_ID,
                    Experiment_ID,
                    Package_Comment,
                    Experiment,
                    Created
                )
                SELECT DISTINCT
                    #TPI.DataPackageID,
                    TX.ID,
                    @comment,
                    TX.Experiment,
                    TX.Created
                FROM
                    #TPI
                    INNER JOIN S_V_Experiment_Detail_Report_Ex TX
                    ON #TPI.Identifier = TX.Experiment
                WHERE #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </add experiments>

        ---------------------------------------------------
        -- Dataset operations
        ---------------------------------------------------

        IF @mode = 'delete' And Exists (Select * From #TPI Where [Type] = 'Dataset')
        BEGIN -- <delete datasets>
            If @infoOnly > 0
            Begin
                SELECT 'Dataset to delete' AS Dataset_Msg, Target.*
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'

            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </delete datasets>

        IF @mode = 'comment' And Exists (Select * From #TPI Where [Type] = 'Dataset')
        BEGIN -- <comment datasets>
            If @infoOnly > 0
            Begin
                SELECT 'Update Dataset comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'

            End
            Else
            Begin
                UPDATE T_Data_Package_Datasets
                SET Package_Comment = @comment
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Package_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </comment datasets>

        IF @mode = 'add' And Exists (Select * From #TPI Where [Type] = 'Dataset')
        BEGIN -- <add datasets>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Datasets TX
                   ON #TPI.DataPackageID = TX.Data_Package_ID AND
                      #TPI.Identifier = TX.Dataset AND
                      #TPI.[Type] = 'Dataset'

            If @infoOnly > 0
            Begin
                SELECT DISTINCT #TPI.DataPackageID,
                                'New Dataset ID' AS Item_Type,
                                TX.ID,
                                @comment AS [Comment],
                                TX.Dataset,
                                TX.Created,
                                TX.Experiment,
                                TX.Instrument
                FROM #TPI
                     INNER JOIN S_V_Dataset_List_Report_2 TX
                       ON #TPI.Identifier = TX.Dataset
                WHERE #TPI.[Type] = 'Dataset'

            End
            Else
            Begin
                -- Add new items
                INSERT INTO T_Data_Package_Datasets( Data_Package_ID,
                                                     Dataset_ID,
                                                     Package_Comment,
                                                     Dataset,
                                                     Created,
                                                     Experiment,
                                                     Instrument )
                SELECT DISTINCT #TPI.DataPackageID,
                                TX.ID,
                                @comment,
                                TX.Dataset,
                                TX.Created,
                                TX.Experiment,
                                TX.Instrument
                FROM #TPI
                     INNER JOIN S_V_Dataset_List_Report_2 TX
                       ON #TPI.Identifier = TX.Dataset
                WHERE #TPI.[Type] = 'Dataset'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </add datasets>

        ---------------------------------------------------
        -- Analysis_job operations
        ---------------------------------------------------

        IF @mode = 'delete' And Exists (Select * From #Tmp_JobsToAddOrDelete)
        BEGIN -- <delete analysis_jobs>
            If @infoOnly > 0
            Begin
                SELECT 'Job to delete' AS Job_Msg, *
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Package_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Package_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.CheckPlural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </delete analysis_jobs>

        IF @mode = 'comment' And Exists (Select * From #Tmp_JobsToAddOrDelete)
        BEGIN -- <comment analysis_jobs>
            If @infoOnly > 0
            Begin
                SELECT 'Update Job comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Package_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
            End
            Else
            Begin
                UPDATE Target
                SET Package_Comment = @comment
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Package_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.CheckPlural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </comment analysis_jobs>

        IF @mode = 'add' And Exists (Select * From #Tmp_JobsToAddOrDelete)
        BEGIN -- <add analysis_jobs>

            -- Delete extras
            DELETE #Tmp_JobsToAddOrDelete
            FROM #Tmp_JobsToAddOrDelete Target
                 INNER JOIN T_Data_Package_Analysis_Jobs TX
                   ON Target.DataPackageID = TX.Data_Package_ID AND
                      Target.Job = TX.Job

            If @infoOnly > 0
            Begin
                SELECT DISTINCT ItemsQ.DataPackageID,
                                'New Job' AS Item_Type,
                                TX.Job,
                                @comment AS [Comment],
                                TX.Created,
                                TX.Dataset,
                                TX.Tool
                FROM S_V_Analysis_Job_List_Report_2 TX
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON TX.Job = ItemsQ.Job

            End
            Else
            Begin
                -- Add new items
                INSERT INTO T_Data_Package_Analysis_Jobs( Data_Package_ID,
                                                          Job,
                                                          Package_Comment,
                                                          Created,
                                                          Dataset_ID,
                                                          Dataset,
                                                          Tool )
                SELECT DISTINCT ItemsQ.DataPackageID,
                                TX.Job,
                                @comment,
                                TX.Created,
                                TX.Dataset_ID,
                                TX.Dataset,
                                TX.Tool
                FROM S_V_Analysis_Job_List_Report_2 TX
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON TX.Job = ItemsQ.Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.CheckPlural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.AppendToText(@message, @actionMsg, 0, ', ', 512)
                End
            End
        END -- </add analysis_jobs>

        ---------------------------------------------------
        -- Update item counts for all data packages in the list
        ---------------------------------------------------

        If @itemCountChanged > 0
        Begin -- <UpdateDataPackageItemCounts>
            CREATE TABLE #TK (ID int)

            INSERT INTO #TK (ID)
            SELECT DISTINCT DataPackageID
            FROM #TPI

            Declare @packageID int = -10000
            Declare @continue tinyint = 1

            While @continue = 1
            Begin
                SELECT TOP 1 @packageID = ID
                FROM #TK
                WHERE ID > @packageID
                ORDER BY ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @continue = 0
                End
                Else
                Begin
                    exec UpdateDataPackageItemCounts @packageID, '', @callingUser
                End
            End

        End -- </UpdateDataPackageItemCounts>

        ---------------------------------------------------
        -- Update EUS Info for all data packages in the list
        ---------------------------------------------------
        --
        If @itemCountChanged > 0
        Begin -- <UpdateEUSInfo>

            Declare @DataPackageList varchar(max) = ''

            SELECT @DataPackageList = @DataPackageList + Cast(DataPackageID AS varchar(12)) + ','
            FROM ( SELECT DISTINCT DataPackageID
                   FROM #TPI ) AS ListQ

            Exec UpdateDataPackageEUSInfo @DataPackageList
        End -- </UpdateEUSInfo>

        ---------------------------------------------------
        -- Update the last modified date for affected data packages
        ---------------------------------------------------
        --
        if @itemCountChanged > 0
        begin
            UPDATE T_Data_Package
            SET Last_Modified = GETDATE()
            WHERE ID IN (
                SELECT DISTINCT DataPackageID FROM #TPI
            )
        end

        If @message = ''
        Begin
            Set @message = 'No items were updated'

            If @mode = 'add'
                Set @message = 'No items were added'

            If @mode = 'delete'
                Set @message = 'No items were removed'
        End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @msgForLog, 'UpdateDataPackageItemsUtility'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemsUtility] TO [DDL_Viewer] AS [dbo]
GO
