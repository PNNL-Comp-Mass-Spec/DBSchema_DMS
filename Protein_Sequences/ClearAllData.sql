/****** Object:  StoredProcedure [dbo].[ClearAllData] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ClearAllData
/****************************************************
** 
**	Desc: 
**		This is a DANGEROUS procedure that will clear all
**		data from all of the tables in this database
**
**		This is useful for creating test databases
**		or for migrating the DMS databases to a new laboratory
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	08/20/2015 mem - Initial release
**    
*****************************************************/
(
	@ServerNameFailsafe varchar(64) = 'Pass in the name of the current server to confirm that you truly want to delete data',
	@CurrentDateFailsafe varchar(64) = 'Enter the current date, in the format yyyy-mm-dd',
	@infoOnly tinyint = 1,
	@message varchar(255) = '' output
)
As
	Set NoCount On
	
	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''

	-------------------------------------------------
	-- Verify that we truly should do this
	-------------------------------------------------
	
	If @ServerNameFailsafe <> @@ServerName
	Begin
		set @message = 'You must enter the name of the server hosting this database'		
		Goto Done
	End
	
	Declare @userDate date 
	set @userDate = Convert(date, @CurrentDateFailsafe)
	
	If IsNull(@userDate, '') = '' OR @userDate <> Cast(GetDate() as Date)
	Begin
		set @message = 'You must set @CurrentDateFailsafe to the current date, in the form yyyy-mm-dd'		
		Goto Done
	End

	-------------------------------------------------
	-- Remove foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
	
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Archived_Output_File_Collections_XRef_T_Archived_Output_Files')
		  ALTER TABLE dbo.T_Archived_Output_File_Collections_XRef
			DROP CONSTRAINT FK_T_Archived_Output_File_Collections_XRef_T_Archived_Output_Files
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_DNA_Structures_T_Genome_Assembly')	
		  ALTER TABLE dbo.T_DNA_Structures
			DROP CONSTRAINT FK_T_DNA_Structures_T_Genome_Assembly

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Position_Info_T_DNA_Structures')	
		  ALTER TABLE dbo.T_Position_Info
			DROP CONSTRAINT FK_T_Position_Info_T_DNA_Structures
	
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Protein_Collection_Members_T_Protein_Collections')	
		  ALTER TABLE dbo.T_Protein_Collection_Members
			DROP CONSTRAINT FK_T_Protein_Collection_Members_T_Protein_Collections
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Archived_Output_File_Collections_XRef_T_Protein_Collections')	
		  ALTER TABLE dbo.T_Archived_Output_File_Collections_XRef
			DROP CONSTRAINT FK_T_Archived_Output_File_Collections_XRef_T_Protein_Collections
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Annotation_Groups_T_Protein_Collections')	
		  ALTER TABLE dbo.T_Annotation_Groups
			DROP CONSTRAINT FK_T_Annotation_Groups_T_Protein_Collections
			
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Protein_Descriptions_T_Protein_Names')	
		  ALTER TABLE dbo.T_Protein_Descriptions
			DROP CONSTRAINT FK_T_Protein_Descriptions_T_Protein_Names

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Protein_Names_T_Proteins')	
		  ALTER TABLE dbo.T_Protein_Names
			DROP CONSTRAINT FK_T_Protein_Names_T_Proteins
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Protein_Collection_Members_T_Protein_Names')	
		  ALTER TABLE dbo.T_Protein_Collection_Members
			DROP CONSTRAINT FK_T_Protein_Collection_Members_T_Protein_Names
	
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Protein_Collection_Members_T_Proteins')	
		  ALTER TABLE dbo.T_Protein_Collection_Members
			DROP CONSTRAINT FK_T_Protein_Collection_Members_T_Proteins

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Position_Info_T_Proteins')	
		  ALTER TABLE dbo.T_Position_Info
			DROP CONSTRAINT FK_T_Position_Info_T_Proteins
			
	End
	
	-------------------------------------------------
	-- Truncate tables
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		Select 'Deleting data' AS Task
		
		TRUNCATE TABLE T_Annotation_Groups
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		TRUNCATE TABLE T_Archived_File_Creation_Options
		TRUNCATE TABLE T_Archived_Output_File_Collections_XRef
		TRUNCATE TABLE T_Archived_Output_Files
		TRUNCATE TABLE T_Collection_Organism_Xref		
		TRUNCATE TABLE T_DNA_Structures
		TRUNCATE TABLE T_Encrypted_Collection_Authorizations
		TRUNCATE TABLE T_Encrypted_Collection_Passphrases
		TRUNCATE TABLE T_Event_Log
		TRUNCATE TABLE T_Genome_Assembly
		TRUNCATE TABLE T_Legacy_File_Upload_Requests
		TRUNCATE TABLE T_Log_Entries
		TRUNCATE TABLE T_Passphrase_Hashes
		TRUNCATE TABLE T_Position_Info
		TRUNCATE TABLE T_Protein_Collection_Members
		TRUNCATE TABLE T_Protein_Collections
		TRUNCATE TABLE T_Protein_Descriptions
		TRUNCATE TABLE T_Protein_Headers
		TRUNCATE TABLE T_Protein_Names
		TRUNCATE TABLE T_Proteins
				
		Select 'Deletion Complete' AS Task
	End
	Else
	Begin
		SELECT 'T_Annotation_Groups' AS Table_to_Truncate
		UNION
		SELECT 'T_Archived_File_Creation_Options'
		UNION
		SELECT 'T_Archived_Output_File_Collections_XRef'
		UNION
		SELECT 'T_Archived_Output_Files'
		UNION
		SELECT 'T_Collection_Organism_Xref'
		UNION
		SELECT 'T_DNA_Structures'
		UNION
		SELECT 'T_Encrypted_Collection_Authorizations'
		UNION
		SELECT 'T_Encrypted_Collection_Passphrases'
		UNION
		SELECT 'T_Event_Log'
		UNION
		SELECT 'T_Genome_Assembly'
		UNION
		SELECT 'T_Legacy_File_Upload_Requests'
		UNION
		SELECT 'T_Log_Entries'
		UNION
		SELECT 'T_Passphrase_Hashes'
		UNION
		SELECT 'T_Position_Info'
		UNION
		SELECT 'T_Protein_Collection_Members'
		UNION
		SELECT 'T_Protein_Collections'
		UNION
		SELECT 'T_Protein_Descriptions'
		UNION
		SELECT 'T_Protein_Headers'
		UNION
		SELECT 'T_Protein_Names'
		UNION
		SELECT 'T_Proteins'
		ORDER BY 1
		
	End

	-------------------------------------------------
	-- Add back foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
			
		alter table T_Annotation_Groups add
			constraint FK_T_Annotation_Groups_T_Protein_Collections foreign key(Protein_Collection_ID) references T_Protein_Collections(Protein_Collection_ID);

		alter table T_Archived_Output_File_Collections_XRef add
			constraint FK_T_Archived_Output_File_Collections_XRef_T_Protein_Collections foreign key(Protein_Collection_ID) references T_Protein_Collections(Protein_Collection_ID),
			constraint FK_T_Archived_Output_File_Collections_XRef_T_Archived_Output_Files foreign key(Archived_File_ID) references T_Archived_Output_Files(Archived_File_ID);

		alter table T_DNA_Structures add
			constraint FK_T_DNA_Structures_T_Genome_Assembly foreign key(Assembly_ID) references T_Genome_Assembly(Assembly_ID);

		alter table T_Position_Info add
			constraint FK_T_Position_Info_T_Proteins foreign key(Protein_ID) references T_Proteins(Protein_ID);

		alter table T_Position_Info add
			constraint FK_T_Position_Info_T_DNA_Structures foreign key(DNA_Structure_ID) references T_DNA_Structures(DNA_Structure_ID);
  
		alter table T_Protein_Collection_Members add
			constraint FK_T_Protein_Collection_Members_T_Protein_Collections foreign key(Protein_Collection_ID) references T_Protein_Collections(Protein_Collection_ID),
			constraint FK_T_Protein_Collection_Members_T_Proteins foreign key(Protein_ID) references T_Proteins(Protein_ID),
			constraint FK_T_Protein_Collection_Members_T_Protein_Names foreign key(Original_Reference_ID) references T_Protein_Names(Reference_ID);

		alter table T_Protein_Descriptions add
			constraint FK_T_Protein_Descriptions_T_Protein_Names foreign key(Reference_ID) references T_Protein_Names(Reference_ID);

		alter table T_Protein_Names add
			constraint FK_T_Protein_Names_T_Proteins foreign key(Protein_ID) references T_Proteins(Protein_ID);


	End
			
Done:
	If @message <> ''
		Print @message
		
	return @myError

GO
