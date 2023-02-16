/****** Object:  UserDefinedFunction [dbo].[get_data_package_dataset_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_data_package_dataset_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of datasets
**  for given data package
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/22/2014 mem - Initial version
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
GRANT VIEW DEFINITION ON [dbo].[get_data_package_dataset_list] TO [DDL_Viewer] AS [dbo]
GO
