/****** Object:  StoredProcedure [dbo].[CheckPermissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CheckPermissions 
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
