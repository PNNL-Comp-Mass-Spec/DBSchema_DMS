/****** Object:  StoredProcedure [dbo].[UpdateTaxonomyItemIfDefined] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateTaxonomyItemIfDefined
/****************************************************
**
**	Desc: This procedure is called via GetTaxonomyValueByTaxonomyID
**        (Note that GetTaxonomyValueByTaxonomyID is called by AddUpdateOrganisms when auto-defining taxonomy)
**
**  The calling procedure must create table #Tmp_TaxonomyInfo
**
**		CREATE TABLE #Tmp_TaxonomyInfo (
**			Entry_ID int not null,
**			[Rank] varchar(32) not null,
**			[Name] varchar(255) not null
**		)		
**		
**
**	Auth:	mem
**	Date:	03/02/2016
**    
*****************************************************/
(
	@Rank varchar(32),
	@Value varchar(255) output		-- input/output variable
	
)
As
	set nocount on

	Declare @TaxonomyName varchar(255) = ''
	
	SELECT @TaxonomyName = [Name]
	FROM  #Tmp_TaxonomyInfo
	WHERE [Rank] = @Rank
	
	If IsNull(@TaxonomyName, '') <> ''
		Set @Value = @TaxonomyName

	return 0


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateTaxonomyItemIfDefined] TO [DDL_Viewer] AS [dbo]
GO
