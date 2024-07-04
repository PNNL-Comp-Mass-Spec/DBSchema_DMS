/****** Object:  StoredProcedure [dbo].[load_metadata_for_multiple_experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[load_metadata_for_multiple_experiments]
/****************************************************
**
**  Desc:
**      Load metadata for experiments in given list
**
**  Returns:
**      Recordset containing keyword-value pairs for all metadata items
**
**  Parameters:
**      This stored procedure expects that its caller
**      will have loaded a temporary table (named #exp)
**      with all the experiment names that it should
**      load metadata for.
**
**      It also expects its caller to have created a
**      temporary table (named #metaD) into which it
**      will load the metadata.
**
**  Auth:   grk
**  Date:   11/01/2006
**          07/06/2022 mem - Use new aux info definition view name
**          02/08/2023 bcg - Update to use V_Biomaterial_Metadata
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/04/2024 mem - Make arguments optional
**                         - Use new column names
**
*****************************************************/
(
    @options varchar(256) = '', -- ignore for now
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Load experiment tracking info for the experiments
    ---------------------------------------------------

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Name', MD.Name
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'ID', CONVERT(varchar(32), MD.ID)
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Researcher', MD.Researcher
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Organism', MD.Organism
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Reason for Experiment', MD.Reason_for_Experiment
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Comment', MD.Comment
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Created', CONVERT(varchar(32), MD.Created)
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Sample Concentration', MD.Sample_Concentration
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Digestion Enzyme', MD.Digestion_Enzyme
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Lab Notebook', MD.Lab_Notebook
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Campaign', MD.Campaign
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Cell Cultures', MD.Cell_Cultures
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Labelling', MD.Labelling
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Predigest Int Std', MD.Predigest_Int_Std
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Postdigest Int Std', MD.Postdigest_Int_Std
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT Name , '', 'Experiment', 'Request', CONVERT(varchar(32), MD.Request)
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT mExp FROM #exp)

    ---------------------------------------------------
    -- Append aux info for the experiments
    ---------------------------------------------------

    INSERT INTO #metaD(mExp, mCC,  mAType, mTag, mVal)
    SELECT T.Experiment_Num, '', 'Experiment', AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, AI.Value
    FROM T_Experiments T INNER JOIN
         V_Aux_Info_Value AI ON T.Exp_ID = AI.Target_ID
    WHERE AI.Target = 'Experiment' AND
          T.Experiment_Num IN (SELECT mExp FROM #exp)

    ---------------------------------------------------
    -- Append cell culture tracking info for the experiments
    ---------------------------------------------------

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Name', MD.Name
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'ID', CONVERT(varchar(32), MD.ID)
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Source', MD.Source
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Source Contact', MD.Source_Contact
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'PI', MD.PI
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Type', MD.Type
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Reason', MD.Reason
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Comment', MD.Comment
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT EX.Experiment_Num, MD.Name, 'Cell Culture', 'Campaign', MD.Campaign
    FROM T_Experiment_Cell_Cultures INNER JOIN
         T_Experiments EX ON T_Experiment_Cell_Cultures.Exp_ID = EX.Exp_ID INNER JOIN
         V_Biomaterial_Metadata MD ON T_Experiment_Cell_Cultures.CC_ID = MD.ID
    WHERE EX.Experiment_Num IN (SELECT mExp FROM #exp)

    ---------------------------------------------------
    -- Append cell culture aux info for the experiments
    ---------------------------------------------------

    INSERT INTO #metaD (mExp, mCC, mAType, mTag, mVal)
    SELECT T_Experiments.Experiment_Num, T.CC_Name, 'Cell Culture', AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, AI.Value
    FROM T_Cell_Culture T INNER JOIN
         V_Aux_Info_Value AI ON T.CC_ID = AI.Target_ID INNER JOIN
         T_Experiment_Cell_Cultures ON T.CC_ID = T_Experiment_Cell_Cultures.CC_ID INNER JOIN
         T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
    WHERE AI.Target = 'Cell Culture' AND
          T_Experiments.Experiment_Num IN (SELECT mExp FROM #exp)
    ORDER BY T_Experiments.Experiment_Num, T.CC_Name

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[load_metadata_for_multiple_experiments] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[load_metadata_for_multiple_experiments] TO [Limited_Table_Write] AS [dbo]
GO
