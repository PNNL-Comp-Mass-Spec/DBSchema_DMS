/****** Object:  UserDefinedFunction [dbo].[MakePRISMWikiPageLink] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.MakePRISMWikiPageLink
/****************************************************
**
**  Desc: Generates URL to PRISM Wiki page for data package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**			06/05/2009 grk - initial release
**			06/10/2009 grk - using package name for link
**			06/11/2009 mem - Removed space from before https://
**			06/26/2009 mem - Updated link format to be @baseURL plus the data package name
**			09/21/2012 mem - Changed from https:// to http://
**    
*****************************************************/
(
	@ID int,
	@packageName varchar(256)
)
RETURNS varchar(256)
AS
BEGIN
	DECLARE @result varchar(256)
	
	DECLARE @baseURL varchar(64)
	set @baseURL = 'http://prismwiki.pnl.gov/wiki/DataPackages:'

	DECLARE @temp varchar(512)
	Set @temp = IsNull(@packageName, '')
		
	-- Replace invalid DOS characters with an underscore
	SET @temp = REPLACE(@temp, ' ', '_')
	SET @temp = REPLACE(@temp, '/', '_')
	SET @temp = REPLACE(@temp, '\', '_')
	SET @temp = REPLACE(@temp, ':', '_')
	SET @temp = REPLACE(@temp, '*', '_')
	SET @temp = REPLACE(@temp, '?', '_')
	SET @temp = REPLACE(@temp, '"', '_')
	SET @temp = REPLACE(@temp, '>', '_')
	SET @temp = REPLACE(@temp, '<', '_')
	SET @temp = REPLACE(@temp, '|', '_')

	-- Replace other characters that we'd rather not see in the wiki link
	SET @temp = REPLACE(@temp, '''', '_')
	SET @temp = REPLACE(@temp, '+', '_')
	SET @temp = REPLACE(@temp, '-', '_')

	SET @result = @baseURL + @temp -- + '_' + CONVERT(VARCHAR(8), @ID)
		
	RETURN @result
END
GO
