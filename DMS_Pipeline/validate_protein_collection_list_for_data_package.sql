/****** Object:  StoredProcedure [dbo].[ValidateProteinCollectionListForDataPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateProteinCollectionListForDataPackage]
/****************************************************
**
**  Desc: Check input parameters against the definition for the script
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:	grk
**  Date:	10/06/2010 grk - Initial release
**			11/25/2010 mem - Now validating that the script exists in T_Scripts
**			12/10/2013 grk - problem inserting null values into #TPD
**			04/08/2016 mem - Clear @message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add argument @debugMode
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
        Dataset_Num varchar(128),
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
    INSERT INTO #TmpDatasets (Dataset_Num)
    SELECT Dataset
    FROM dbo.S_Data_Package_Datasets
    WHERE Data_Package_ID = @dataPackageID
    --
	SELECT @myError = @@error, @myRowCount = @@rowcount
    
    If @myRowCount = 0
    Begin
        Set @message = 'Data package does not have any datasets, ID: ' + Cast(@dataPackageID as varchar(9))
        Return 20001
    End

    exec @myError = dbo.S_ValidateProteinCollectionListForDatasetTable
                        @protCollNameList=@protCollNameList output,
                        @collectionCountAdded = @collectionCountAdded output,
                        @showMessages = @showMessages,
                        @message = @message output,
                        @showDebug = 0

	return @myError

GO
