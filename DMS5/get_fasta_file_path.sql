/****** Object:  UserDefinedFunction [dbo].[get_fasta_file_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_fasta_file_path]
/****************************************************
**
**  Desc:
**      Returns the appropriate path to the fasta file based
**      on FastaFileName and Organism Name.  If the fasta
**      file name is blank or 'na', then returns the legacy
**      path for the given organism.  Otherwise,
**      looks for the file in Protein_Sequences.dbo.T_Archived_Output_Files
**      or V_Legacy_FASTA_File_Paths
**
**  Return values: Path to the folder containing the Fasta file
**
**  Auth:   kja
**  Date:   01/23/2007
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs (Ticket #531)
**          09/11/2015 mem - Now using synonym S_ProteinSeqs_T_Archived_Output_Files
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @fastaFileName varchar(256),
    @organismName varchar(256)
)
RETURNS varchar(512)
AS
Begin
    declare @filePath varchar(512)
    declare @fileNamePosition int

    set @filePath = ''
    IF (LEN(@fastaFileName) = 0 or @fastaFileName = 'na')
    Begin
        SELECT TOP 1 @filePath = OG_organismDBPath
        FROM T_Organisms
        WHERE OG_name = @organismName
    End
    Else
    Begin
        If PATINDEX('%.fasta',@fastaFileName) = 0
            set @fastaFileName = @fastaFileName + '.fasta'


        SELECT TOP 1 @filePath = Archived_File_Path
        FROM S_ProteinSeqs_T_Archived_Output_Files
        WHERE Archived_File_Path LIKE '%' + @fastaFileName + '%'

        If LEN(@filePath) = 0
            SELECT TOP 1 @filePath = FilePath
            FROM V_Legacy_FASTA_File_Paths
            WHERE FileName = @fastaFileName

        set @fileNamePosition = PATINDEX('%' + @fastaFileName, @filePath)

        IF @fileNamePosition > 0
            SET @filePath = SUBSTRING(@filePath, 1, @fileNamePosition -1)
        Else
            SET @filePath = ''
    End

    RETURN @filePath
End

GO
GRANT VIEW DEFINITION ON [dbo].[get_fasta_file_path] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_fasta_file_path] TO [public] AS [dbo]
GO
