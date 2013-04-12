/****** Object:  UserDefinedFunction [dbo].[MakePackageFolderName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.MakePackageFolderName 
/****************************************************
**
**  Desc: Generates a package folder name given an ID and package name
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	05/21/2009 grk
**			05/29/2009 mem - Now replacing invalid characters with underscores
**			11/08/2010 mem - Now using first 96 characters of @packageName instead of first 40 characters
**			04/10/2013 mem - Now replacing commas
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@packageName varchar(256)
)
RETURNS varchar(256)
AS
BEGIN
	DECLARE @result varchar(256)

	Set @packageName = IsNull(@packageName, '')
	
	-- Replace spaces with an underscore
	SET @result = CONVERT(VARCHAR(8), @ID) + '_' + REPLACE(SUBSTRING (@packageName , 1 , 96 ), ' ', '_')
	
	-- Replace invalid DOS characters with an underscore
	SET @result = REPLACE(@result, '/', '_')
	SET @result = REPLACE(@result, '\', '_')
	SET @result = REPLACE(@result, ':', '_')
	SET @result = REPLACE(@result, '*', '_')
	SET @result = REPLACE(@result, '?', '_')
	SET @result = REPLACE(@result, '"', '_')
	SET @result = REPLACE(@result, '>', '_')
	SET @result = REPLACE(@result, '<', '_')
	SET @result = REPLACE(@result, '|', '_')

	-- Replace other characters that we'd rather not see in the folder name
	SET @result = REPLACE(@result, '''', '_')
	SET @result = REPLACE(@result, '+', '_')
	SET @result = REPLACE(@result, '-', '_')
	SET @result = REPLACE(@result, ',', '_')
	
	RETURN @result
END
GO
