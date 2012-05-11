/****** Object:  StoredProcedure [dbo].[UpdateJobStepMemoryUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateJobStepMemoryUsage
/****************************************************
**
**	Desc: 
**		Examines the job parameters to find entries related to memory usage
**		Updates 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	mem
**	Date:	10/17/2011 mem - Initial release
**    
*****************************************************/
(
	@job int,
	@pXML xml,
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Look for the memory size parmeters
	---------------------------------------------------

	Declare @MemorySettings AS Table ( 
		UniqueID int IDENTITY (1,1),
		Step_Tool varchar(64),
		MemoryRequiredMB varchar(64)
	)

	/*
	-- Could use this query to populate @MemorySettings
	-- However, this turns out to be more expensive than running 4 separate queries against @pXML with a specific XPath filter
	INSERT INTO @MemorySettings (Step_Tool, MemoryRequiredMB)
	SELECT REPLACE(Name, 'JavaMemorySize', '') AS Name, Value
	FROM (
		SELECT
			xmlNode.value('@Name', 'nvarchar(256)') Name,
			xmlNode.value('@Value', 'nvarchar(4000)') Value
		FROM @pXML.nodes('//Param') AS R(xmlNode)
		) ParameterQ
	WHERE Name like '%JavaMemorySize'
	*/

	INSERT INTO @MemorySettings (Step_Tool, MemoryRequiredMB)
	SELECT 'MSGF', xmlNode.value('@Value', 'varchar(64)') AS MemoryRequiredMB
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="MSGFJavaMemorySize"]') = 1


	INSERT INTO @MemorySettings (Step_Tool, MemoryRequiredMB)
	SELECT 'MSGFDB', xmlNode.value('@Value', 'varchar(64)') AS MemoryRequiredMB
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="MSGFDBJavaMemorySize"]') = 1
	

	INSERT INTO @MemorySettings (Step_Tool, MemoryRequiredMB)
	SELECT 'MSDeconv', xmlNode.value('@Value', 'varchar(64)') AS MemoryRequiredMB
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="MSDeconvJavaMemorySize"]') = 1
		

	INSERT INTO @MemorySettings (Step_Tool, MemoryRequiredMB)
	SELECT 'MSAlign', xmlNode.value('@Value', 'varchar(64)') AS MemoryRequiredMB
	FROM   @pXML.nodes('//Param') AS R(xmlNode)
	WHERE  xmlNode.exist('.[@Name="MSAlignJavaMemorySize"]') = 1

	If EXISTS (Select * From @MemorySettings)
	Begin -- <a>
		Declare @CurrentID Int = 0
		Declare @StepTool varchar(64)
		Declare @MemoryRequiredMB varchar(64)
		Declare @ValMemoryRequiredMB int

		Declare @Continue tinyint = 1
		
		While @Continue <> 0
		Begin -- <b>
			SELECT TOP 1 @CurrentID = UniqueID,
			             @StepTool = Step_Tool,
			             @MemoryRequiredMB = MemoryRequiredMB
			FROM @MemorySettings
			WHERE UniqueID > @CurrentID
			ORDER BY UniqueID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
				Set @Continue = 0
			Else
			Begin -- <c>
				If IsNumeric(@MemoryRequiredMB) <> 0
				Begin -- <d>
					Set @ValMemoryRequiredMB = Convert(int, @MemoryRequiredMB)
					
					UPDATE #Job_Steps
					SET Memory_Usage_MB = @ValMemoryRequiredMB
					WHERE Step_Tool = @StepTool AND
					      Job = @Job

				End -- </d>
			End -- </c>
			
		End -- </b>
	End -- </a>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
