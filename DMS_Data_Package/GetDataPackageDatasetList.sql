/****** Object:  UserDefinedFunction [dbo].[GetDataPackageDatasetList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetDataPackageDatasetList]
/****************************************************
**
**	Desc: 
**  Builds delimited list of datasets
**  for given data package
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	10/22/2014 mem - Initial version
**    
*****************************************************/
(
	@dataPackageID int
)
RETURNS varchar(max)
AS
	BEGIN
		declare @list varchar(max)
		set @list = NULL
	
		SELECT @list = Coalesce(@list + ', ' + Dataset, Dataset)
		FROM T_Data_Package_Datasets
		WHERE (Data_Package_ID = @dataPackageID)
		ORDER BY Dataset

		If @list Is Null
			Set @list = ''
		
		RETURN @list
	END


GO
