/****** Object:  UserDefinedFunction [dbo].[GetJobParamHistoryTableLocal] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetJobParamHistoryTableLocal
/****************************************************
**
**  Desc:	Returns a table of the job parameters stored locally in T_Job_Parameters_History
**
**  Auth:	mem
**  Date:	01/12/2012
**    
*****************************************************/
(
	@jobNumber INT
)
RETURNS @theTable TABLE (
		Job INT NULL,
		[Name] Varchar(128),
		[Value] Varchar(max)
	)
AS
BEGIN

	---------------------------------------------------
	-- The following demonstrates how we could Query the XML for a specific parameter:
	--
	-- The XML we are querying looks like:
	-- <Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
	---------------------------------------------------
/*
		
	SELECT @TransferFolderPath = Parameters.query('Param[@Name = "transferFolderPath"]').value('(/Param/@Value)[1]', 'varchar(256)')
	FROM [T_Job_Parameters_History]
	WHERE Job = @currJob
*/
	
	---------------------------------------------------
	-- Query T_Job_Parameters_History
	---------------------------------------------------
	--
	INSERT INTO @theTable (Job, [Name], [Value])
	SELECT
		@jobNumber as Job,
--		xmlNode.value('@Section', 'nvarchar(256)') Section,
		xmlNode.value('@Name', 'nvarchar(256)') Name,
		xmlNode.value('@Value', 'nvarchar(4000)') Value
	FROM
		T_Job_Parameters_History cross apply Parameters.nodes('//Param') AS R(xmlNode)
	WHERE
		T_Job_Parameters_History.Job = @jobNumber

	RETURN
END

GO
