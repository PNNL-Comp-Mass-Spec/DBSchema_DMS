/****** Object:  StoredProcedure [dbo].[GetOrganismID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetOrganismID
/****************************************************
**
**	Desc: Gets organismID for given organism name
**
**	Return values: 0: failure, otherwise, organismID
**
**	Auth:	grk
**	Date:	01/26/2001
**			09/25/2012 mem - Expanded @organismName to varchar(128)
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@organismName varchar(128) = ''
)
As
	Set NoCount On
	
	Declare @organismID int = 0
	
	SELECT @organismID = Organism_ID 
	FROM T_Organisms 
	WHERE OG_name = @organismName
	
	return @organismID
GO
GRANT VIEW DEFINITION ON [dbo].[GetOrganismID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetOrganismID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetOrganismID] TO [Limited_Table_Write] AS [dbo]
GO
