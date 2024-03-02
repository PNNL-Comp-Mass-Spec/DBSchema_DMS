/****** Object:  StoredProcedure [dbo].[update_experiment_name_for_qc_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_experiment_name_for_qc_datasets]
/****************************************************
**
**  Desc:   Assures that the experiment name associated with QC datasets matches the dataset name
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   08/09/2018 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    Set nocount On

    Declare @myError int = 0;
    Declare @myRowCount int = 0;

    -- Format the date in the form 2018-08-09
    Declare @dateStamp varchar(32) = Substring(Convert(varchar(32), GetDate(), 120), 1, 10)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    set @infoOnly = IsNull(@infoOnly, 1);
    set @message = '';

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TABLE #Tmp_QCExperiments (
        ExperimentID int Not Null,
        Experiment varchar(128) Not Null
    );

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_QCExperiments ON #Tmp_QCExperiments(ExperimentID);

    CREATE TABLE #Tmp_DatasetsToUpdate (
        ID int Identity(1,1) Not Null,
        Dataset_ID int,
        OldExperiment varchar(128) Not Null,
        NewExperiment varchar(128) Not Null,
        NewExperimentID int Not Null,
        Ambiguous tinyint Not Null
    );

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_DatasetsToUpdate ON #Tmp_DatasetsToUpdate(Dataset_ID, ID);

    ---------------------------------------------------
    -- Find the QC experiments to process
    -- This list is modelled after the list in UDF get_dataset_priority
    ---------------------------------------------------

    INSERT INTO #Tmp_QCExperiments (ExperimentID, Experiment )
    SELECT Exp_ID, Experiment_Num
    FROM T_Experiments
    WHERE (Experiment_Num LIKE 'QC[_-]Shew[_-][0-9][0-9][_-][0-9][0-9]' OR
           Experiment_Num LIKE 'QC[_-]ShewIntact[_-][0-9][0-9]%' OR
           Experiment_Num LIKE 'QC[_]Shew[_]TEDDY%' OR
           Experiment_Num LIKE 'QC[_]Mam%' OR
           Experiment_Num LIKE 'QC[_]PP[_]MCF-7%'
          ) AND Ex_Created >= '1/1/2018'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount;

    Declare @continue tinyint = 1;
    Declare @currentExperimentID int = 0;
    Declare @experiment varchar(128);

    While @continue > 0
    Begin
        SELECT TOP 1 @currentExperimentID = ExperimentID,
                     @experiment = Experiment
        FROM #Tmp_QCExperiments
        WHERE ExperimentID > @currentExperimentID
        ORDER BY ExperimentID;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount;

        If @myRowCount = 0
        Begin
            Set @continue = 0;
        End
        Else
        Begin
            INSERT INTO #Tmp_DatasetsToUpdate( Dataset_ID,
                                               OldExperiment,
                                               NewExperiment,
                                               NewExperimentID,
                                               Ambiguous )
            SELECT DS.Dataset_ID,
                   E.Experiment_Num,
                   @experiment,
                   @currentExperimentID,
                   0 As Ambiguous
            FROM T_Dataset DS
                 INNER JOIN T_Experiments E
                   ON DS.Exp_ID = E.Exp_ID
            WHERE Dataset_Num LIKE @experiment + '%' AND
                  E.Experiment_Num <> @experiment AND
                  E.Experiment_Num Not In ('QC_Shew_16_01_AutoPhospho', 'EMSL_48364_Chacon_Testing', 'UVPD_MW_Dependence')
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount;

        End

    End

    ---------------------------------------------------
    -- Look for duplicate datasets in #Tmp_DatasetsToUpdate
    ---------------------------------------------------

    UPDATE #Tmp_DatasetsToUpdate
    SET Ambiguous = 1
    WHERE Dataset_ID IN ( SELECT Dataset_ID
                          FROM #Tmp_DatasetsToUpdate
                          GROUP BY Dataset_ID
                          HAVING Count(*) > 1 )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount;

    If Not Exists (Select * From #Tmp_DatasetsToUpdate)
    Begin
        Print 'No candidate datasets were found'
        Return 0
    End

    If @infoOnly = 0 And Not Exists (Select * From #Tmp_DatasetsToUpdate Where Ambiguous = 0)
    Begin
        Print 'Candidate datasets were found, but they are all ambiguous; see them with @infoOnly=1'
        Return 0
    End

    If @infoOnly <> 0
    Begin
        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------
        --
        SELECT DS.Dataset_ID,
               DS.Dataset_Num AS Dataset,
               DTU.OldExperiment,
               DTU.NewExperiment,
               DTU.NewExperimentID,
               dbo.append_to_text(DS.DS_Comment, 'Switched experiment from ' + DTU.OldExperiment +
                                               ' to ' + DTU.NewExperiment + ' on ' + @dateStamp, 0, ';', 512) As [Comment]
        FROM T_Dataset DS
             INNER JOIN #Tmp_DatasetsToUpdate DTU
               ON DS.Dataset_ID = DTU.Dataset_ID
        WHERE DTU.Ambiguous = 0
        ORDER BY DTU.NewExperiment, DTU.OldExperiment, Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Exists (Select * From #Tmp_DatasetsToUpdate Where Ambiguous > 0)
        Begin
            SELECT DS.Dataset_ID,
                   DS.Dataset_Num AS Dataset,
                   DTU.OldExperiment,
                   DTU.NewExperiment,
                   'Ambiguous match' AS [Comment]
            FROM T_Dataset DS
                 INNER JOIN #Tmp_DatasetsToUpdate DTU
                   ON DS.Dataset_ID = DTU.Dataset_ID
            WHERE DTU.Ambiguous = 1

        End
    End
    Else
    Begin

        ---------------------------------------------------
        -- Update the experiments associated with the datasets
        ---------------------------------------------------
        --
        UPDATE T_Dataset
        SET Exp_ID= DTU.NewExperimentID,
            DS_comment = dbo.append_to_text(DS.DS_Comment, 'Switched experiment from ' + DTU.OldExperiment +
                                                         ' to ' + DTU.NewExperiment + ' on ' + @dateStamp, 0, ';', 512)
        FROM T_Dataset DS
            INNER JOIN #Tmp_DatasetsToUpdate DTU On DS.Dataset_ID = DTU.Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Declare @msg varchar(128) = 'Updated the experiment name for ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowcount, ' QC dataset',  ' QC datasets')

        Exec post_log_entry 'Normal', @msg, 'update_experiment_name_for_qc_datasets'

    End
        

GO
