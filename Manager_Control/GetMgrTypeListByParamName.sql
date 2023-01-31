/****** Object:  UserDefinedFunction [dbo].[GetMgrTypeListByParamName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetMgrTypeListByParamName]
/****************************************************
**
**  Desc: 
**      Returns a delimited list of manager types by parameter name
**
**  Auth:   jds
**  Date:   03/26/2009 jds - Initial commit
**          01/30/2023 mem - Use new view name
**      
*****************************************************/
(
@ParamName varchar(128)
)
RETURNS varchar(8000)
AS
BEGIN
        Declare @delimiter char(1) = ','
        Declare @mgr_type varchar(128) = ''        
        Declare @theMgrTypeList varchar(8000) = ''

        Declare @EOL int
        Declare @count int

        Declare @myError int = 0
        Declare @myRowCount int = 0
        
        Declare @id int

        Declare manager_type cursor for 
        Select mgr_type_name
        From V_Mgr_Types_By_Param
        Where param_name = @ParamName

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

        Close manager_type
        Deallocate manager_type

        return(@theMgrTypeList)
end


GO
