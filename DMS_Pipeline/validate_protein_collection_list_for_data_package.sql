/****** Object:  StoredProcedure [dbo].[validate_protein_collection_list_for_data_package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_protein_collection_list_for_data_package]
/****************************************************
**
**  Desc: Check input parameters against the definition for the script
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/06/2010 grk - Initial release
**          11/25/2010 mem - Now validating that the script exists in T_Scripts
**          12/10/2013 grk - problem inserting null values into #TPD
**          04/08/2016 mem - Clear @message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add argument @debugMode
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/22/2023 mem - Rename column in temp table
**          10/03/2023 mem - Obtain dataset name from S_Dataset since the name in S_Data_Package_Datasets is a cached name and could be an old dataset name
**
*****************************************************/
(
    @dataPackageID int,
    @protCollNameList varchar(4000)='' output,
    @collectionCountAdded int = 0 output,
    @showMessages tinyint = 1,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = IsNull(@message, '')

    Declare @dataPackageName varchar(1024)

    ---------------------------------------------------
    -- Create a temporary table to hold dataset names
    ---------------------------------------------------
    --
    CREATE TABLE #TmpDatasets (
        Dataset_Name varchar(128),
    )

    ---------------------------------------------------
    -- Validate the data package ID
    ---------------------------------------------------
    --
    SELECT @dataPackageName = Name
    FROM dbo.S_Data_Package_Details
    WHERE ID = @dataPackageID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Data package ID is invalid: ' + Cast(@dataPackageID as varchar(9))
        Return 20000
    End

    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------
    --
    INSERT INTO #TmpDatasets (Dataset_Name)
    SELECT DS.Dataset_Num
    FROM S_Data_Package_Datasets AS TPKG
         INNER JOIN S_Dataset DS
           ON TPKG.Dataset_ID = DS.Dataset_ID
    WHERE TPKG.Data_Package_ID = @dataPackageID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Data package does not have any datasets, ID: ' + Cast(@dataPackageID as varchar(9))
        Return 20001
    End

    exec @myError = dbo.s_validate_protein_collection_list_for_dataset_table
                        @protCollNameList=@protCollNameList output,
                        @collectionCountAdded = @collectionCountAdded output,
                        @showMessages = @showMessages,
                        @message = @message output,
                        @showDebug = 0

    Return @myError

GO
