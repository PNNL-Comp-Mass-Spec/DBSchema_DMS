/****** Object:  UserDefinedFunction [dbo].[GetModificationSiteList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetModificationSiteList]
/****************************************************
**
**	Desc: 
**  Builds delimited list of modification sites for given Unimod ID
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	05/15/2013 - Initial version
**    
*****************************************************/
(
	@UnimodID int,
	@Hidden tinyint
)
RETURNS 
@TableOfResults TABLE
(
	-- Add the column definitions for the TABLE variable here
	Unimod_ID int, 
	Sites varchar(255)
)
AS
BEGIN
	Declare @list varchar(4000) = ''
	
	SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + Sites
	FROM (SELECT CASE WHEN Position IN ('Anywhere', 'Any N-Term', 'Any C-term') 
			  THEN Site WHEN Site LIKE '_-term' THEN Position ELSE Site + ' @ ' + Position END AS Sites
		  FROM T_Unimod_Specificity
		  WHERE Unimod_ID = @UnimodID And (Hidden = @Hidden)
		 ) SourceQ
	ORDER BY Sites
	
	INSERT INTO @TableOfResults(Unimod_ID, Sites)
		Values (@UnimodID, @list)
			
	RETURN
END


GO
