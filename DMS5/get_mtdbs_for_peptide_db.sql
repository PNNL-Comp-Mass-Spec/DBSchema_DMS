/****** Object:  UserDefinedFunction [dbo].[get_mtdbs_for_peptide_db] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_mtdbs_for_peptide_db]
/****************************************************
**
**  Desc:
**     Builds a delimited list of MTS AMT tag databases
**     whose source is the specific peptide database
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/18/2012
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @peptideDBName varchar(128)
)
RETURNS varchar(3500)
AS
    BEGIN
        declare @list varchar(3000) = Null

        SELECT @list = COALESCE(@list + ', ' + MT_DB_Name, MT_DB_Name)
        FROM T_MTS_MT_DBs_Cached
        WHERE (Peptide_DB = @PeptideDBName)

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_mtdbs_for_peptide_db] TO [DDL_Viewer] AS [dbo]
GO
