/****** Object:  UserDefinedFunction [dbo].[get_data_package_dataset_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_data_package_dataset_list]
/****************************************************
**
**  Desc:
**      Builds delimited list of datasets for given data package
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/22/2014 mem - Initial version
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in T_Data_Package_Datasets
**          09/26/2023 mem - Obtain dataset names from T_Dataset
**
*****************************************************/
(
    @dataPackageID int
)
RETURNS varchar(max)
AS
    BEGIN
        Declare @list varchar(max) = Null

        SELECT @list = Coalesce(@list + ', ' + DS.Dataset_Num, DS.Dataset_Num)
        FROM T_Data_Package_Datasets TD
             INNER JOIN S_Dataset DS
               ON TD.Dataset_ID = DS.Dataset_ID
        WHERE TD.Data_Pkg_ID = @dataPackageID
        ORDER BY DS.Dataset_Num

        RETURN Coalesce(@list, '')
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_data_package_dataset_list] TO [DDL_Viewer] AS [dbo]
GO
