/****** Object:  UserDefinedFunction [dbo].[get_data_analysis_request_data_package_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_data_analysis_request_data_package_list]
/****************************************************
**
**  Desc:
**      Build delimited list of data package IDs associated with the given data analysis request
**
**  Return value:
**      Comma-separated list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/11/2024 mem - Initial version
**
*****************************************************/
(
    @dataAnalysisRequestID int
)
RETURNS varchar(max)
AS
BEGIN
    Declare @list varchar(max) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN cast(Data_Pkg_ID as varchar(12))
                               ELSE ', ' + cast(Data_Pkg_ID as varchar(12))
                           END
    FROM T_Data_Analysis_Request_Data_Package_IDs
    WHERE Request_ID = @dataAnalysisRequestID
    ORDER BY Data_Pkg_ID

    RETURN @list
END


GO
