/****** Object:  UserDefinedFunction [dbo].[get_param_file_mass_mod_code_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_param_file_mass_mod_code_list]
/****************************************************
**
**  Desc:
**      Returns the mass mods for the given parameter file,
**      formatted as a comma-separated list of mod codes
**
**  Return value: list of mass mod codes
**
**  Auth:   mem
**  Date:   11/04/2021 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileId int,
    @includeSymbol Tinyint = 0
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @massModCodes Varchar(1024) = Null

    -- A subquery is used in the following queries because, without it,
    -- when ORDER BY is used with the string concatenation technique shown,
    -- only one row is stored in @massModCodes

    If @includeSymbol > 0
    Begin
        SELECT @massModCodes = COALESCE(@massModCodes + ', ' + Mod_Code_With_Symbol, Mod_Code_With_Symbol)
        FROM ( SELECT TOP 500 Mod_Code_With_Symbol
               FROM V_Param_File_Mass_Mod_Info
               WHERE Param_File_ID = @paramFileId
               ORDER BY Mod_Code_With_Symbol ) SortQ
    End
    Else
    Begin
        SELECT @massModCodes = COALESCE(@massModCodes + ', ' + Mod_Code, Mod_Code)
        FROM ( SELECT TOP 500 Mod_Code
               FROM V_Param_File_Mass_Mod_Info
               WHERE Param_File_ID = @paramFileId
               ORDER BY Mod_Code ) SortQ
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Return IsNull(@massModCodes, '')
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_param_file_mass_mod_code_list] TO [DDL_Viewer] AS [dbo]
GO
