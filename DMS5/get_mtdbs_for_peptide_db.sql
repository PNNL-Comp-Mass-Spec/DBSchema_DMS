/****** Object:  UserDefinedFunction [dbo].[GetMTDBsForPeptideDB] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetMTDBsForPeptideDB]
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
**
*****************************************************/
(
    @PeptideDBName varchar(128)
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
GRANT VIEW DEFINITION ON [dbo].[GetMTDBsForPeptideDB] TO [DDL_Viewer] AS [dbo]
GO
