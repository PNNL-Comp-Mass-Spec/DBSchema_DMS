/****** Object:  StoredProcedure [dbo].[GetOrganismID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure GetOrganismID
/****************************************************
**
**	Desc: Gets organismID for given organism name
**
**	Return values: 0: failure, otherwise, organismID
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	01/26/2001
**			09/25/2012 mem - Expanded @organismName to varchar(128)
**    
*****************************************************/
(
	@organismName varchar(128) = ''
)
As
	declare @organismID int
	set @organismID = 0
	
	SELECT @organismID = Organism_ID 
	FROM T_Organisms 
	WHERE (OG_name = @organismName)
	
	return @organismID
GO
GRANT EXECUTE ON [dbo].[GetOrganismID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetOrganismID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetOrganismID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetOrganismID] TO [PNL\D3M580] AS [dbo]
GO
