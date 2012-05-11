/****** Object:  UserDefinedFunction [dbo].[GetMgrTypeListByParamName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetMgrTypeListByParamName]
/****************************************************
**
**	Desc: 
**  Returns a delimited list of manager types by parameter name
**
**	Return values: 
**
**	Parameters:
**
**		Auth: jds
**		Date: 3/26/2009
**      
*****************************************************/
(
@ParamName varchar(128)
)
RETURNS varchar(8000)
AS
BEGIN
		declare @delimiter char(1)
		set @delimiter = ','

		declare @mgr_type varchar(128)
		set @mgr_type = ''

		declare @theMgrTypeList varchar(8000)
		set @theMgrTypeList = ''

		declare @EOL int
		declare @count int

		declare @myError int
		set @myError = 0

		declare @myRowCount int
		set @myRowCount = 0
		--
		declare @id int
		--

		declare manager_type cursor for 
		select MT_TypeName
		from V_MgrTypesByParam
		where ParamName = @ParamName

		open manager_type

		fetch NEXT from manager_type 
		into @mgr_type

		while @@FETCH_STATUS = 0
		begin
			set @theMgrTypeList = @mgr_type + @delimiter + @theMgrTypeList
		-- Get the next manager type
		fetch NEXT from manager_type 
		into @mgr_type
		end 

		close manager_type
		deallocate manager_type

		return(@theMgrTypeList)
end

GO
