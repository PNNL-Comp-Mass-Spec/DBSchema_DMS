/****** Object:  StoredProcedure [dbo].[check_access_permission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[check_access_permission]
/****************************************************
**
**  Desc:
**  Does current user have permission to execute
**  given stored procedure
**
**  Return values: 0: no, >0: yes
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/08/2005
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
@sprocName varchar(128)
AS
    SET NOCOUNT ON
    declare @result int
    set @result = 0

    select @result = (PERMISSIONS(OBJECT_ID(@sprocName)) & 0x20)

    RETURN @result

GO
GRANT EXECUTE ON [dbo].[check_access_permission] TO [Mgr_Config_Admin] AS [dbo]
GO
