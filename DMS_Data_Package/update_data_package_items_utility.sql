/****** Object:  StoredProcedure [dbo].[update_data_package_items_utility] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_data_package_items_utility]
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      Expects list of items to be in temp table #TPI
**
**      CREATE TABLE #TPI(
**          DataPackageID int not null,         -- Data package ID
**          [Type] varchar(50) null,            -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
**          Identifier varchar(256) null        -- Job ID, Dataset Name or ID, Experiment Name, Biomaterial Name, or EUSProposal ID
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/23/2010
**          06/10/2009 grk - changed size of item list to max
**          06/10/2009 mem - Now calling update_data_package_item_counts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, S_V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of update_data_package_items and update_data_package_items_xml
**          12/31/2013 mem - Added support for EUS Proposals
**          09/02/2014 mem - Updated to remove non-numeric items when working with analysis jobs
**          10/28/2014 mem - Added support for adding datasets using dataset IDs; to delete datasets, you must use the dataset name (safety feature)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/18/2016 mem - Fix bug removing duplicate analysis jobs
**                         - Add parameter @infoOnly
**          10/19/2016 mem - Update #TPI to use an integer field for data package ID
**                         - Call update_data_package_eus_info
**                         - Prevent addition of Biomaterial '(none)'
**          11/14/2016 mem - Add parameter @removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          04/25/2018 mem - Populate column Dataset_ID in T_Data_Package_Analysis_Jobs
**          06/12/2018 mem - Send @maxLength to append_to_text
**          07/17/2019 mem - Remove .raw and .d from the end of dataset names
**          07/02/2021 mem - Update the package comment for any existing items when @mode is 'add' and @comment is not an empty string
**          07/02/2021 mem - Change the default value for @mode from undefined mode 'update' to 'add'
**          07/06/2021 mem - Add support for dataset IDs when @mode is 'comment' or 'delete'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Rename package comment field to Package_Comment
**          07/08/2022 mem - Use new synonym name for experiment biomaterial view
**          01/04/2023 mem - Update to use S_V_Biomaterial_List_Report_2
**          02/08/2023 bcg - Update to use S_V_Experiment_Biomaterial
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/04/2023 mem - When adding datasets, do not add data package placeholder datasets (e.g. dataset DataPackage_3442_TestData)
**          05/19/2023 mem - When adding analysis jobs, do not add data package placeholder datasets
**          07/07/2023 mem - Replace synonym S_V_Experiment_Detail_Report_Ex with S_V_Experiment_List_Report
**          08/17/2023 mem - Use renamed column data_pkg_id in data package tables
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
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @itemCountChanged int = 0
    Declare @actionMsg varchar(512)
    Declare @datasetsRemoved varchar(512)

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
        Exec @authorized = verify_sp_authorized 'update_data_package_items_utility', @raiseError = 1
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
            UPDATE #TPI
            SET Identifier = Substring(Identifier, 1, Len(Identifier) - 4)
            WHERE [Type] = 'Dataset' And #TPI.Identifier Like '%.raw'

            UPDATE #TPI
            SET Identifier = Substring(Identifier, 1, Len(Identifier) - 2)
            WHERE [Type] = 'Dataset' And #TPI.Identifier Like '%.d'

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

            If Exists (SELECT * FROM #TPI WHERE [Type] = 'Dataset' And Identifier LIKE 'DataPackage[_][0-9][0-9]%')
            Begin
                Set @datasetsRemoved = ''

                SELECT @datasetsRemoved = @datasetsRemoved + Identifier + ', '
                FROM #TPI
                WHERE [Type] = 'Dataset' And Identifier LIKE 'DataPackage[_][0-9][0-9]%'
                ORDER BY Identifier

                Set @datasetsRemoved = Rtrim(@datasetsRemoved)

                If Len(@datasetsRemoved) > 0
                Begin
                    -- Remove the trailing comma
                    Set @datasetsRemoved = Left(@datasetsRemoved, Len(@datasetsRemoved) - 1)
                End

                DELETE FROM #TPI
                WHERE [Type] = 'Dataset' And Identifier LIKE 'DataPackage[_][0-9][0-9]%'

                Set @actionMsg = 'Data packages cannot include placeholder data package datasets; removed "' + @datasetsRemoved + '"';
                Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
            End

        End

        -- Add parent items and associated items to list for items in the list
        -- This process cascades up the DMS hierarchy of tracking entities, but not down
        --
        If @mode = 'add'
        Begin -- <add_associated_items>

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
                ) AND
                NOT TX.Dataset LIKE 'DataPackage[_][0-9][0-9]%'

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
                TX.Biomaterial_Name
            FROM
                #TPI TP
                INNER JOIN S_V_Experiment_Biomaterial TX
                ON TP.Identifier = TX.Experiment
            WHERE
                TP.[Type] = 'Experiment' AND
                TX.Biomaterial_Name NOT IN ('(none)')
                AND NOT EXISTS (
                    SELECT *
                    FROM #TPI
                    WHERE #TPI.[Type] = 'Biomaterial' AND #TPI.Identifier = TX.Biomaterial_Name AND #TPI.DataPackageID = TP.DataPackageID
                )

        End -- </add_associated_items>


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
                               Datasets.Data_Pkg_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Pkg_ID = Datasets.Data_Pkg_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Pkg_ID = ItemsQ.DataPackageID AND
                                  Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Pkg_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.Data_Pkg_ID AND
                      ToDelete.Dataset = ToKeep.Dataset
            WHERE ToKeep.Data_Pkg_ID IS NULL
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
                               Datasets.Data_Pkg_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Pkg_ID = Datasets.Data_Pkg_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Pkg_ID = Experiments.Data_Pkg_ID
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Pkg_ID = ItemsQ.DataPackageID AND
                                   Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Pkg_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep1
                   ON ToDelete.DataPackageID = ToKeep1.Data_Pkg_ID AND
                      ToDelete.Experiment = ToKeep1.Experiment
                 LEFT OUTER JOIN (
                        -- Experiments associated with the data package; skipping any datasets that we're deleting
                        SELECT Experiments.Experiment,
                               Datasets.Data_Pkg_ID
                        FROM T_Data_Package_Datasets Datasets
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Pkg_ID = Experiments.Data_Pkg_ID
                             LEFT OUTER JOIN #TPI ItemsQ
                               ON Datasets.Data_Pkg_ID = ItemsQ.DataPackageID AND
                                   ItemsQ.[Type] = 'Dataset' AND
                                   ItemsQ.Identifier = Datasets.Dataset
                        WHERE Datasets.Data_Pkg_ID IN (SELECT DISTINCT DataPackageID FROM #TPI) AND
                              ItemsQ.Identifier IS NULL
                 ) AS ToKeep2
                   ON ToDelete.DataPackageID = ToKeep2.Data_Pkg_ID AND
                      ToDelete.Experiment = ToKeep2.Experiment
            WHERE ToKeep1.Data_Pkg_ID IS NULL AND
                  ToKeep2.Data_Pkg_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            -- Find parent biomaterial that will have no jobs or datasets remaining once we remove the jobs in #TPI
            --
            INSERT INTO #TPI (DataPackageID, [Type], Identifier)
            SELECT ToDelete.DataPackageID, ToDelete.ItemType, ToDelete.Biomaterial_Name
            FROM (
                   -- Biomaterial associated with jobs that we are removing
                   SELECT DISTINCT J.DataPackageID,
                                   'Biomaterial' AS ItemType,
                                   Biomaterial.Biomaterial_Name
                   FROM #Tmp_JobsToAddOrDelete J
                        INNER JOIN S_V_Analysis_Job_List_Report_2 TX
                          ON J.Job = TX.Job
                        INNER JOIN S_V_Experiment_Biomaterial Biomaterial
                          ON Biomaterial.Experiment = TX.Experiment
                 ) ToDelete
                 LEFT OUTER JOIN (
                        -- Biomaterial associated with the data package; skipping the jobs that we're deleting
                        SELECT DISTINCT Biomaterial.Name AS Biomaterial_Name,
                                        Datasets.Data_Pkg_ID
                        FROM T_Data_Package_Analysis_Jobs Jobs
                             INNER JOIN T_Data_Package_Datasets Datasets
                               ON Jobs.Data_Pkg_ID = Datasets.Data_Pkg_ID AND
                                  Jobs.Dataset_ID = Datasets.Dataset_ID
                             INNER JOIN T_Data_Package_Experiments Experiments
                               ON Datasets.Experiment = Experiments.Experiment AND
                                  Datasets.Data_Pkg_ID = Experiments.Data_Pkg_ID
                             INNER JOIN T_Data_Package_Biomaterial Biomaterial
                               ON Experiments.Data_Pkg_ID = Biomaterial.Data_Pkg_ID
                             INNER JOIN S_V_Experiment_Biomaterial Exp_Biomaterial_Map
                               ON Experiments.Experiment = Exp_Biomaterial_Map.Experiment AND
                                  Exp_Biomaterial_Map.Biomaterial_Name = Biomaterial.Name
                             LEFT OUTER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                               ON Jobs.Data_Pkg_ID = ItemsQ.DataPackageID AND
                                  Jobs.Job = ItemsQ.Job
                        WHERE Jobs.Data_Pkg_ID IN (SELECT DISTINCT DataPackageID FROM #Tmp_JobsToAddOrDelete) AND
                              ItemsQ.Job IS NULL
                 ) AS ToKeep
                   ON ToDelete.DataPackageID = ToKeep.Data_Pkg_ID AND
                      ToDelete.Biomaterial_Name = ToKeep.Biomaterial_Name
            WHERE ToKeep.Data_Pkg_ID IS NULL
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

        If @mode = 'delete' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Biomaterial')
        Begin -- <delete biomaterial>
            If @infoOnly > 0
            Begin
                SELECT 'Biomaterial to delete' AS Biomaterial_Msg, Target.*
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.check_plural(@myRowCount, ' item', ' items')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </delete biomaterial>

        If @mode = 'comment' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Biomaterial')
        Begin -- <comment biomaterial>
            If @infoOnly > 0
            Begin
                SELECT 'Update biomaterial comment' AS Item_Type,
                       @comment AS New_Comment, *
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin
                UPDATE T_Data_Package_Biomaterial
                SET Package_Comment = @comment
                FROM T_Data_Package_Biomaterial Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Name AND
                          #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.check_plural(@myRowCount, ' item', ' items')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </comment biomaterial>

        If @mode = 'add' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Biomaterial')
        Begin -- <add biomaterial>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Biomaterial TX
                   ON #TPI.DataPackageID = TX.Data_Pkg_ID AND
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
                     INNER JOIN S_V_Biomaterial_List_Report_2 TX
                       ON #TPI.Identifier = Name

                WHERE #TPI.[Type] = 'Biomaterial'
            End
            Else
            Begin

                -- Add new items
                INSERT INTO T_Data_Package_Biomaterial(
                    Data_Pkg_ID,
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
                    INNER JOIN S_V_Biomaterial_List_Report_2 TX
                    ON #TPI.Identifier = Name
                WHERE #TPI.[Type] = 'Biomaterial'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' biomaterial' + dbo.check_plural(@myRowCount, ' item', ' items')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </add biomaterial>

        ---------------------------------------------------
        -- EUS Proposal operations
        ---------------------------------------------------

        If @mode = 'delete' And Exists (SELECT * FROM #TPI WHERE [Type] = 'EUSProposal')
        Begin -- <delete EUS Proposals>
            If @infoOnly > 0
            Begin
                SELECT 'EUS Proposal to delete' AS EUS_Proposal_Msg, Target.*
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.check_plural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </delete EUS Proposal>

        If @mode = 'comment' And Exists (SELECT * FROM #TPI WHERE [Type] = 'EUSProposal')
        Begin -- <comment EUS Proposals>
            If @infoOnly > 0
            Begin
                SELECT 'Update EUS Proposal comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_EUS_Proposal Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
            End
            Else
            Begin
                UPDATE T_Data_Package_EUS_Proposals
                SET Package_Comment = @comment
                FROM T_Data_Package_EUS_Proposals Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Proposal_ID AND
                          #TPI.[Type] = 'EUSProposal'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.check_plural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </comment EUS Proposals>

        If @mode = 'add' And Exists (SELECT * FROM #TPI WHERE [Type] = 'EUSProposal')
        Begin -- <add EUS Proposals>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_EUS_Proposals TX
                   ON #TPI.DataPackageID = TX.Data_Pkg_ID AND
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
                INSERT INTO T_Data_Package_EUS_Proposals( Data_Pkg_ID,
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
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' EUS' + dbo.check_plural(@myRowCount, ' proposal', ' proposals')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </add EUS Proposals>

        ---------------------------------------------------
        -- Experiment operations
        ---------------------------------------------------

        If @mode = 'delete' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Experiment')
        Begin -- <delete experiments>
            If @infoOnly > 0
            Begin
                SELECT 'Experiment to delete' AS Experiment_Msg, Target.*
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'

            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                  #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </delete experiments>

        If @mode = 'comment' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Experiment')
        Begin -- <comment experiments>
            If @infoOnly > 0
            Begin
                SELECT 'Update Experiment comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'

            End
            Else
            Begin
                UPDATE T_Data_Package_Experiments
                SET Package_Comment = @comment
                FROM T_Data_Package_Experiments Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Experiment AND
                          #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </comment experiments>

        If @mode = 'add' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Experiment')
        Begin -- <add experiments>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Experiments TX
                   ON #TPI.DataPackageID = TX.Data_Pkg_ID AND
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
                    INNER JOIN S_V_Experiment_List_Report TX
                    ON #TPI.Identifier = TX.Experiment
                WHERE #TPI.[Type] = 'Experiment'
            End
            Else
            Begin
                -- Add new items
                INSERT INTO T_Data_Package_Experiments(
                    Data_Pkg_ID,
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
                    INNER JOIN S_V_Experiment_List_Report TX
                    ON #TPI.Identifier = TX.Experiment
                WHERE #TPI.[Type] = 'Experiment'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' experiment', ' experiments')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </add experiments>

        ---------------------------------------------------
        -- Dataset operations
        ---------------------------------------------------

        If @mode = 'delete' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Dataset')
        Begin -- <delete datasets>
            If @infoOnly > 0
            Begin
                SELECT 'Dataset to delete' AS Dataset_Msg, Target.*
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'

            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </delete datasets>

        If @mode = 'comment' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Dataset')
        Begin -- <comment datasets>
            If @infoOnly > 0
            Begin
                SELECT 'Update Dataset comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'

            End
            Else
            Begin
                UPDATE T_Data_Package_Datasets
                SET Package_Comment = @comment
                FROM T_Data_Package_Datasets Target
                     INNER JOIN #TPI
                       ON #TPI.DataPackageID = Target.Data_Pkg_ID AND
                          #TPI.Identifier = Target.Dataset AND
                          #TPI.[Type] = 'Dataset'
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </comment datasets>

        If @mode = 'add' And Exists (SELECT * FROM #TPI WHERE [Type] = 'Dataset')
        Begin -- <add datasets>

            -- Delete extras
            DELETE #TPI
            FROM #TPI
                 INNER JOIN T_Data_Package_Datasets TX
                   ON #TPI.DataPackageID = TX.Data_Pkg_ID AND
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
                INSERT INTO T_Data_Package_Datasets( Data_Pkg_ID,
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
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' dataset', ' datasets')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </add datasets>

        ---------------------------------------------------
        -- Analysis_job operations
        ---------------------------------------------------

        If @mode = 'delete' And Exists (SELECT * FROM #Tmp_JobsToAddOrDelete)
        Begin -- <delete analysis_jobs>
            If @infoOnly > 0
            Begin
                SELECT 'Job to delete' AS Job_Msg, *
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Pkg_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
            End
            Else
            Begin
                DELETE Target
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Pkg_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Deleted ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.check_plural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </delete analysis_jobs>

        If @mode = 'comment' And Exists (SELECT * FROM #Tmp_JobsToAddOrDelete)
        Begin -- <comment analysis_jobs>
            If @infoOnly > 0
            Begin
                SELECT 'Update Job comment' AS Item_Type,
                       @comment AS New_Comment,
                       Target.*
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Pkg_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
            End
            Else
            Begin
                UPDATE Target
                SET Package_Comment = @comment
                FROM T_Data_Package_Analysis_Jobs Target
                     INNER JOIN #Tmp_JobsToAddOrDelete ItemsQ
                       ON Target.Data_Pkg_ID = ItemsQ.DataPackageID AND
                          Target.Job = ItemsQ.Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myRowCount > 0
                Begin
                    Set @itemCountChanged = @itemCountChanged + @myRowCount
                    Set @actionMsg = 'Updated the comment for ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.check_plural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </comment analysis_jobs>

        If @mode = 'add' And Exists (SELECT * FROM #Tmp_JobsToAddOrDelete)
        Begin -- <add analysis_jobs>

            -- Delete extras
            DELETE #Tmp_JobsToAddOrDelete
            FROM #Tmp_JobsToAddOrDelete Target
                 INNER JOIN T_Data_Package_Analysis_Jobs TX
                   ON Target.DataPackageID = TX.Data_Pkg_ID AND
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
                INSERT INTO T_Data_Package_Analysis_Jobs( Data_Pkg_ID,
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
                    Set @actionMsg = 'Added ' + Cast(@myRowCount as varchar(12)) + ' analysis' + dbo.check_plural(@myRowCount, ' job', ' jobs')
                    Set @message = dbo.append_to_text(@message, @actionMsg, 0, ', ', 512)
                End
            End
        End -- </add analysis_jobs>

        ---------------------------------------------------
        -- Update item counts for all data packages in the list
        ---------------------------------------------------

        If @itemCountChanged > 0
        Begin -- <update_data_package_item_counts>
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
                    exec update_data_package_item_counts @packageID, '', @callingUser
                End
            End

        End -- </update_data_package_item_counts>

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

            Exec update_data_package_eus_info @DataPackageList
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
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msgForLog, 'update_data_package_items_utility'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_data_package_items_utility] TO [DDL_Viewer] AS [dbo]
GO
