/****** Object:  UserDefinedFunction [dbo].[GetParamFileMassModsTableCode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetParamFileMassModsTableCode]
/****************************************************
**
**  Desc:
**      Returns the mass mods for the given parameter file, formatted as a string-based table
**      The format codes are thosed used by Jira
**
**  Return value: list of mass mods
**
**  Parameters:
**
**  Auth:   mem
**  Date:   12/05/2016 mem - Initial version
**
*****************************************************/
(
    @paramFileId int
)
RETURNS varchar(4000)
AS
BEGIN
    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @lineFeed varchar(4) = '<br>'
    Declare @header varchar(500) = Null
    Declare @rows varchar(3900) = Null
    Declare @paramFileMassMods varchar(4000) = ''

    SELECT @header = TableCode_Header,
           @rows = COALESCE(@rows + @lineFeed + TableCode_Row, TableCode_Row)
    FROM V_Param_File_Mass_Mods
    WHERE (Param_File_ID = @paramFileId)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @paramFileMassMods = @header + @lineFeed + @rows

    Return @paramFileMassMods
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileMassModsTableCode] TO [DDL_Viewer] AS [dbo]
GO
