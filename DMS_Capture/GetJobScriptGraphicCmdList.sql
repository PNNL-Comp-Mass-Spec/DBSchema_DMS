/****** Object:  UserDefinedFunction [dbo].[GetJobScriptGraphicCmdList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetJobScriptGraphicCmdList
/****************************************************	
**	Returns Dot graphic commnd list for given script
**
**	Auth:	grk
**	Date:	09/08/2009
**  
****************************************************/ 
( 
	@script VARCHAR(256) 
)
RETURNS VARCHAR(4096)
AS 
	BEGIN
		DECLARE @s VARCHAR(4096)
		SET @s = ''
		--
		SELECT @s = @s + line
		FROM dbo.V_Script_Dot_Format 
		WHERE Script = @script
		ORDER BY seq
		--
		RETURN @s
	END

GO
