/****** Object:  StoredProcedure [dbo].[check_permissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[check_permissions]
    /*
    (
    @parameter1 int = 5,
    @parameter2 datatype OUTPUT
    )
    */
AS
    SET NOCOUNT ON

    DECLARE @state  int
    declare @name varchar(30)

    set @name = SYSTEM_USER

    SET @state = IS_MEMBER('PNL\EMSL-Prism.Users.Web_Analysis')

    RETURN

GO
