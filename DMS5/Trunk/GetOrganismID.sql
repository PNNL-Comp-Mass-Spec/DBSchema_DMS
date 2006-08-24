/****** Object:  StoredProcedure [dbo].[GetOrganismID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








Create Procedure GetOrganismID
/****************************************************
**
**	Desc: Gets organismID for given organism name
**
**	Return values: 0: failure, otherwise, organismID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@organismName varchar(80) = " "
)
As
	declare @organismID int
	set @organismID = 0
	
	SELECT @organismID = Organism_ID 
	FROM T_Organisms 
	WHERE (OG_name = @organismName)
	
	return @organismID
GO
GRANT EXECUTE ON [dbo].[GetOrganismID] TO [DMS_SP_User]
GO
