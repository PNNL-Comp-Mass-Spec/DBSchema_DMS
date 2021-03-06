/****** Object:  StoredProcedure [dbo].[GetDefaultRemoteInfoForManager] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDefaultRemoteInfoForManager]
/****************************************************
** 
**  Desc:   Gets the default remote info parameters for the given manager
**          Retrieves parameters using GetManagerParametersWork, so properly retrieves parent group parameters, if any
**          If the manager does not have parameters RunJobsRemotely and RemoteHostName defined, returns an empty string
**          Also returns an empty string if RunJobsRemotely is not True
**
**          Example value for @remoteInfoXML
**          <host>prismweb2</host><user>svc-dms</user><taskQueue>/file1/temp/DMSTasks</taskQueue><workDir>/file1/temp/DMSWorkDir</workDir><orgDB>/file1/temp/DMSOrgDBs</orgDB><privateKey>Svc-Dms.key</privateKey><passphrase>Svc-Dms.pass</passphrase>
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/18/2017 mem - Initial version
**          03/14/2018 mem - Use GetManagerParametersWork to lookup manager parameters, allowing for getting remote info parameters from parent groups
**          03/29/2018 mem - Return an empty string if the manager does not have parameters RunJobsRemotely and RemoteHostName defined, or if RunJobsRemotely is false
**    
*****************************************************/
(
    @managerName varchar(128),            -- Manager name
    @remoteInfoXML varchar(900) Output    -- Output XML if valid remote info parameters are defined, otherwise an empty string
)
As
    Set NoCount On
    
    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0
    
    Declare @managerID int = 0
    Set @remoteInfoXML = ''
    
    SELECT @managerID = M_ID
    FROM T_Mgrs
    WHERE M_Name = @managerName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        -- Manager not found
        Goto Done
    End
            
    -----------------------------------------------
    -- Create the Temp Table to hold the manager parameters
    -----------------------------------------------
       
    CREATE TABLE #Tmp_Mgr_Params (
        M_Name varchar(50) NOT NULL,
        ParamName varchar(50) NOT NULL,
        Entry_ID int NOT NULL,
        TypeID int NOT NULL,
        Value varchar(128) NOT NULL,
        MgrID int NOT NULL,
        Comment varchar(255) NULL,
        Last_Affected datetime NULL,
        Entered_By varchar(128) NULL,
        M_TypeID int NOT NULL,
        ParentParamPointerState tinyint,
        Source varchar(50) NOT NULL
    ) 

    -- Populate the temporary table with the manager parameters
    Exec @myError = GetManagerParametersWork @managerName, 0, 50
    
    If Not Exists ( SELECT [Value]
                    FROM #Tmp_Mgr_Params
                    WHERE M_Name = @managerName And
                          ParamName = 'RunJobsRemotely' AND
                          Value = 'True' ) 
       OR
       Not Exists ( SELECT [Value]
                    FROM #Tmp_Mgr_Params
                    WHERE M_Name = @managerName And
                          ParamName = 'RemoteHostName' AND
                          Len(Value) > 0 )
    Begin
        Set @remoteInfoXML = ''
    End
    Else
    Begin
        SELECT @remoteInfoXML = @remoteInfoXML + SourceQ.[Value]
        FROM (SELECT 1 AS Sort,
                     '<host>' + [Value] + '</host>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteHostName' And M_Name = @managerName)
              UNION
              SELECT 2 AS Sort,
                     '<user>' + [Value] + '</user>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteHostUser' And M_Name = @managerName)
              UNION
              SELECT 3 AS Sort,
                     '<dmsPrograms>' + [Value] + '</dmsPrograms>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteHostDMSProgramsPath' And M_Name = @managerName)
              UNION
              SELECT 4 AS Sort,
                     '<taskQueue>' + [Value] + '</taskQueue>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteTaskQueuePath' And M_Name = @managerName)
              UNION
              SELECT 5 AS Sort,
                     '<workDir>' + [Value] + '</workDir>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteWorkDirPath' And M_Name = @managerName)
              UNION
              SELECT 6 AS Sort,
                     '<orgDB>' + [Value] + '</orgDB>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteOrgDBPath' And M_Name = @managerName)
              UNION
              SELECT 7 AS Sort,
                     '<privateKey>' + dbo.udfGetFilename([Value]) + '</privateKey>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteHostPrivateKeyFile' And M_Name = @managerName)
              UNION
              SELECT 8 AS Sort,
                     '<passphrase>' + dbo.udfGetFilename([Value]) + '</passphrase>' AS [Value]
              FROM #Tmp_Mgr_Params
              WHERE (ParamName = 'RemoteHostPassphraseFile' And M_Name = @managerName)
              ) SourceQ
        ORDER BY SourceQ.Sort
    End
       
Done:
    Return @myError


GO
GRANT EXECUTE ON [dbo].[GetDefaultRemoteInfoForManager] TO [MTUser] AS [dbo]
GO
