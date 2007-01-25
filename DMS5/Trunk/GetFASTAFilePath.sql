/****** Object:  UserDefinedFunction [dbo].[GetFASTAFilePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetFASTAFilePath
/****************************************************
**
**	Desc: 
**		Returns the appropriate path to the fasta file based 
**		on FastaFileName and Organism Name.  If the fasta
**		file name is blank or 'na', then returns the legacy
**		path for the given organism.  Otherwise,
**		looks for the file in Protein_Sequences.dbo.T_Archived_Output_Files 
**		or V_Legacy_FASTA_File_Paths
**
**	Return values: Path to the folder containing the Fasta file
**
**		Auth: kja
**		Date: 1/23/2007
**    
*****************************************************/
(
	@fastaFileName varchar(256),
	@organismName varchar(256)
)
RETURNS varchar(512)
AS
	
	BEGIN
		declare @filePath varchar(512)
		declare @fileNamePosition int
		
		set @filePath = ''
		IF (LEN(@fastaFileName) = 0 or @fastaFileName = 'na')
			BEGIN
				SELECT TOP 1 @filePath = OG_organismDBPath
				FROM T_Organisms
				WHERE OG_name = @organismName
			END
		ELSE
			BEGIN
				IF PATINDEX('%.fasta',@fastaFileName) = 0
					set @fastaFileName = @fastaFileName + '.fasta'
			
				
				SELECT TOP 1 @filePath = Archived_File_Path
				FROM gigasax.Protein_Sequences.dbo.T_Archived_Output_Files 
				WHERE Archived_File_Path LIKE '%' + @fastaFileName + '%'
				
				IF LEN(@filePath) = 0
				SELECT TOP 1 @filePath = FilePath
				FROM V_Legacy_FASTA_File_Paths
				WHERE FileName = @fastaFileName
				
				set @fileNamePosition = PATINDEX('%' + @fastaFileName, @filePath)
				
				IF @fileNamePosition > 0
					SET @filePath = SUBSTRING(@filePath, 1, @fileNamePosition -1)
				ELSE
					SET @filePath = ''
			END
	
	RETURN @filePath
END
GO
