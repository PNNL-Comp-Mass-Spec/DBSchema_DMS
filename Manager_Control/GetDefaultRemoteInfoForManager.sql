/****** Object:  StoredProcedure [dbo].[GetDefaultRemoteInfoForManager] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.GetDefaultRemoteInfoForManager
/****************************************************
** 
**	Desc:	Gets the parameters for the given analysis manager
**			Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	05/07/2015 mem - Initial version
**			08/10/2015 mem - Added @SortMode=3
**			09/02/2016 MEM - Increase the default for parameter @MaxRecursion from 5 to 50
**    
*****************************************************/
(
	@managerName varchar(128),
	@remoteInfoXML varchar(900) output
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
		Goto Done
	
	-- Manager found, construct the XML
	
	SELECT @remoteInfoXML = @remoteInfoXML + SourceQ.[Value]
	FROM (SELECT 1 AS Sort,
				 '<host>' + PV.[Value] + '</host>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteHostName' And PV.MgrID = @managerID)
		  UNION
		  SELECT 2 AS Sort,
				 '<user>' + PV.[Value] + '</user>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteHostUser' And PV.MgrID = @managerID)
		  UNION
		  SELECT 3 AS Sort,
				 '<taskQueue>' + PV.[Value] + '</taskQueue>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteTaskQueuePath' And PV.MgrID = @managerID)
		  UNION
		  SELECT 4 AS Sort,
				 '<workDir>' + PV.[Value] + '</workDir>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteWorkDirPath' And PV.MgrID = @managerID)
		  UNION
		  SELECT 5 AS Sort,
				 '<orgDB>' + PV.[Value] + '</orgDB>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteOrgDBPath' And PV.MgrID = @managerID)
		  UNION
		  SELECT 6 AS Sort,
				 '<privateKey>' + dbo.udfGetFilename(PV.[Value]) + '</privateKey>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteHostPrivateKeyFile' And PV.MgrID = @managerID)
		  UNION
		  SELECT 7 AS Sort,
				 '<passphrase>' + dbo.udfGetFilename(PV.[Value]) + '</passphrase>' AS [Value]
		  FROM T_ParamType PType
			   INNER JOIN T_ParamValue PV
				 ON PType.ParamID = PV.TypeID
		  WHERE (PType.ParamName = 'RemoteHostPassphraseFile' And PV.MgrID = @managerID)
		  ) SourceQ
	ORDER BY SourceQ.Sort
			
Done:
	Return @myError


GO
GRANT EXECUTE ON [dbo].[GetDefaultRemoteInfoForManager] TO [MTUser] AS [dbo]
GO
