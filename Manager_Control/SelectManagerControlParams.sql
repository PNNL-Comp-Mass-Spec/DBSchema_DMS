/****** Object:  StoredProcedure [dbo].[SelectManagerControlParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SelectManagerControlParams]
/****************************************************
**
**	Desc: 
**	Returns a set of manager params for a set of given managers
**  
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: jds
**		Date: 9/28/2007
**    
**    
**    
*****************************************************/
	@paramNameList varchar(2048),
	@managerIDList varchar(2048)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @message varchar(512)
	set @message = ''
	
	---------------------------------------------------
	-- Get results of multiple parameters and multiple managers 
	---------------------------------------------------

	--Insert IDs into temp table (selected managers that are enabled for change)
	--
	SELECT Manager, [Manager Type], Param, [Value]
	FROM V_MgrParamsAll
	WHERE [Manager ID] in (SELECT Item FROM MakeTableFromList(@managerIDList))
	and Param in (SELECT Item FROM MakeTableFromList(@paramNameList))
	ORDER BY Param
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to retrieve manager param results', 10, 1)
		return 51091
	end

	return @myError

GO
GRANT EXECUTE ON [dbo].[SelectManagerControlParams] TO [DMSWebUser] AS [dbo]
GO
