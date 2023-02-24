/****** Object:  StoredProcedure [dbo].[GetParamFileID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetParamFileID]
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
**
*****************************************************/
(
    @ParamFileName varchar(255) = " "
)
AS
    Set NoCount On

    Declare @ParamFileID int = 0

    SELECT @ParamFileID = Param_File_ID
    FROM T_Param_Files
    WHERE Param_File_Name = @ParamFileName

    Return @ParamFileID

GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamFileID] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamFileID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileID] TO [Limited_Table_Write] AS [dbo]
GO
