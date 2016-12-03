/****** Object:  UserDefinedFunction [dbo].[GetBiomaterialOrganismList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetBiomaterialOrganismList
/****************************************************
**
**	Desc: 
**  Builds a delimited list of organism names for the given biomaterial
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	12/02/2016 mem - Initial version
**    
*****************************************************/
(
	@biomaterialID int		-- aka cell culture ID
)
RETURNS varchar(max)
AS
	Begin
		Declare @list varchar(max) = ''
		Declare @sep varchar(2) = ', '

		SELECT @list = @list + CASE
		                           WHEN @list = '' THEN ''
		                           ELSE @sep
		                       END + Org.OG_name
		FROM T_Biomaterial_Organisms BiomaterialOrganisms
		     INNER JOIN T_Organisms Org
		       ON BiomaterialOrganisms.Organism_ID = Org.Organism_ID
		WHERE BiomaterialOrganisms.Biomaterial_ID = @biomaterialID

		Return @list
	End


GO
