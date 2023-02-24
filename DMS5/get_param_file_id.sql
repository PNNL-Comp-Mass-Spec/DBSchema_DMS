/****** Object:  UserDefinedFunction [dbo].[get_param_file_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_param_file_id]
/****************************************************
**
**  Desc: Gets ParamFileID for given ParamFileName
**
**  Return values: 0: failure, otherwise, ParamFileID
**
**  Auth:   grk
**  Date:   01/26/2001
**          02/12/2010 mem - Increased size of @ParamFileName to varchar(255)
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileName varchar(255) = " "
)
RETURNS int
AS
BEGIN
    Declare @ParamFileID int = 0

    SELECT @ParamFileID = Param_File_ID
    FROM T_Param_Files
    WHERE Param_File_Name = @ParamFileName

    Return @ParamFileID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_param_file_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_param_file_id] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_param_file_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_param_file_id] TO [Limited_Table_Write] AS [dbo]
GO
