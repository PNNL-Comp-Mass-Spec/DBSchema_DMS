/****** Object:  UserDefinedFunction [dbo].[GetLCConfigDocsPath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetLCConfigDocsPath
/****************************************************
**
**	Desc: 
**       Get path to LC config file
**
**	Return values: {path}: success, otherwise, {''}
**                 @storagePath contains path
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/17/2006
**    
*****************************************************/
(
	@cartName varchar(128),
	@suffix varchar(32)
)
RETURNS varchar(1024)
AS
	BEGIN
	declare @result varchar(256)
	set @result = ''

	declare @path varchar(256)
	set @path = ''
	--
	SELECT @path = Client
	FROM T_MiscPaths
	WHERE [Function] = 'LCCartConfigDocs'
	
	if @path <> ''
	begin
		set @result = '<a href="' + @path + @cartName + @suffix + '" >' + @cartName + @suffix + '</a>'
	end

	return @result
	END

GO
