/****** Object:  UserDefinedFunction [dbo].[get_hplc_run_dataset_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_hplc_run_dataset_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of datasets for
**  given HPLC run id
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   09/29/2012
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @hplcRunId INT,
    @returnType VARCHAR(12) = 'name'
)
RETURNS varchar(MAX)
AS
    BEGIN
        declare @list varchar(MAX)
        set @list = ''

        IF @returnType = 'name'
        BEGIN
            SELECT  @list = @list + CASE WHEN @list = '' THEN Dataset_Num
                                         ELSE ', ' + Dataset_Num
                                    END
            FROM    T_Prep_LC_Run_Dataset AS TPLRD
                    INNER JOIN T_Dataset AS TDS ON TPLRD.Dataset_ID = TDS.Dataset_ID
            WHERE   TPLRD.Prep_LC_Run_ID = @hplcRunId
        END
        ELSE
        BEGIN

            SELECT  @list = @list
                    + CASE WHEN @list = '' THEN CAST(TDS.Dataset_ID AS VARCHAR(12))
                           ELSE ', ' + CAST(TDS.Dataset_ID AS VARCHAR(12))
                      END
            FROM    T_Prep_LC_Run_Dataset AS TPLRD
                    INNER JOIN T_Dataset AS TDS ON TPLRD.Dataset_ID = TDS.Dataset_ID
            WHERE   TPLRD.Prep_LC_Run_ID = @hplcRunId
        END

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_hplc_run_dataset_list] TO [DDL_Viewer] AS [dbo]
GO
