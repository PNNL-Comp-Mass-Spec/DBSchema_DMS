/****** Object:  StoredProcedure [dbo].[AddUpdateTransferPathsInParamsUsingDataPkg] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateTransferPathsInParamsUsingDataPkg]
/****************************************************
**
**  Desc: 
**      If a job has a data package ID defined, determines the
**      appropriate paths for 'CacheFolderPath' and 'transferFolderPath'
**
**      Updates #PARAMS to have these paths defined if not yet defined or if different
**      If #PARAMS is upodated, @paramsUpdated will be set to 1
**
**      The calling procedure must create and populate table #PARAMS
**
**      CREATE TABLE #PARAMS (
**          [Section] varchar(128),
**          [Name] varchar(128),
**          [Value] varchar(max)
**      )
**
**  Return values: 0:  success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/16/2016 mem - Initial version
**          06/09/2021 mem - Tabs to spaces
**
*****************************************************/
(
    @dataPackageID int,                     -- If 0 or null, will auto-define using parameter 'DataPackageID' in the #PARAMS table (in section 'JobParameters')
    @paramsUpdated int = 0 output,          -- Output: will be 1 if #PARAMS is updated
    @message varchar(512) = '' output
)
As
    Set nocount on
    
    Declare @myError int = 0
    Declare @myRowcount int = 0

    Declare @value varchar(2000)
    Declare @dataPkgSharePath varchar(260) = ''
    Declare @dataPkgName varchar(128) = ''        
    Declare @xferPath varchar(260) = ''
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --    
    Set @DataPackageID = IsNull(@DataPackageID, 0)
    Set @paramsUpdated = 0
    Set @message = ''

    ---------------------------------------------------
    -- Update @DataPackageID if 0 yet defined in #PARAMS
    ---------------------------------------------------
    --
    If @DataPackageID <= 0
    Begin

        Set @value = ''
        SELECT @value = Value
        FROM #PARAMS
        WHERE Section = 'JobParameters' and Name = 'DataPackageID'
        --
        If IsNull(@value, '') <> ''
        Begin
            Set @dataPackageID = Try_Cast(@value as int)            
        End
    End

    ---------------------------------------------------
    -- Get data package info (if one is specified)
    ---------------------------------------------------
    --
    If @DataPackageID <> 0 
    Begin 
        SELECT 
            @dataPkgSharePath = [Share Path],
            @dataPkgName = Name
        FROM S_Data_Package_Details 
        WHERE ID = @DataPackageID
    End 


    ---------------------------------------------------
    -- Is there a repo cache root folder path defined for job?
    --
    -- Step Tool PRIDE_Converter uses this parameter to store
    -- data in folder \\protoapps\MassIVE_Staging
    ---------------------------------------------------
    
    Declare @cacheFolderPath varchar(260) = ''
    Declare @cacheRootFolderPath varchar(260) = ''
    
    SELECT @cacheRootFolderPath = Value
    FROM #PARAMS
    WHERE Name = 'CacheFolderRootPath'


    ---------------------------------------------------
    -- Define the path parameters
    ---------------------------------------------------
    --
    If @DataPackageID > 0
    Begin
        -- Lookup paths already defined in #PARAMS
        --
        Declare @cacheFolderPathOld varchar(260) = ''
        Declare @xferPathOld varchar(260) = ''
        
        SELECT @cacheFolderPathOld = Value
        FROM #PARAMS
        WHERE Section = 'JobParameters' and Name = 'CacheFolderPath'

        SELECT @xferPathOld = Value
        FROM #PARAMS
        WHERE Section = 'JobParameters' and Name = 'transferFolderPath'

                
        If IsNull(@cacheRootFolderPath, '') = '' 
        Begin
            Set @xferPath = @dataPkgSharePath
        End
        Else
        Begin
            Set @cacheFolderPath = @cacheRootFolderPath + '\' + Convert(varchar(12), @DataPackageID) + '_' + REPLACE(@dataPkgName, ' ', '_')
            Set @xferPath = @cacheRootFolderPath

            If @cacheFolderPathOld <> @cacheFolderPath
            Begin
                DELETE FROM #PARAMS
                WHERE Name = 'CacheFolderPath'
                --
                INSERT INTO #PARAMS ( Section, Name, Value )
                VALUES ( 'JobParameters', 'CacheFolderPath', @cacheFolderPath )
                --
                Set @paramsUpdated = 1
            End
        End
        
        If @xferPathOld <> @xferPath
        Begin
            DELETE FROM #PARAMS
            WHERE Name = 'transferFolderPath'
            --
            INSERT INTO #PARAMS ( Section, Name, Value )
            VALUES ( 'JobParameters', 'transferFolderPath', @xferPath )
            --
            Set @paramsUpdated = 1
        End
    End 
    
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateTransferPathsInParamsUsingDataPkg] TO [DDL_Viewer] AS [dbo]
GO
