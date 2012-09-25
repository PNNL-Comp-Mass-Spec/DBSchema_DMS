/****** Object:  StoredProcedure [dbo].[StoreQuameterResults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StoreQuameterResults]
/****************************************************
**
**	Desc: 
**		Store Quameter results by calling S_StoreQuameterResults
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	09/17/2012 mem - Initial version
**    
*****************************************************/
(
	@DatasetID int = 0,				-- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
	@ResultsXML xml,				-- XML holding the Quameter results for a single dataset
	@message varchar(255) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	exec @myError = S_StoreQuameterResults @DatasetID=@DatasetID, @ResultsXML=@ResultsXML, @message=@message output, @infoOnly=@infoOnly

	Return @myError


GO
GRANT EXECUTE ON [dbo].[StoreQuameterResults] TO [svc-dms] AS [dbo]
GO
