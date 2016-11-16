/****** Object:  StoredProcedure [dbo].[x_UpdateProteinCollectionsByOrganism_Old] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[x_UpdateProteinCollectionsByOrganism_Old]

/****************************************************
**
**	Desc: Refreshes the cached table of Collections
**        and their associated organisms
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 09/29/2004
**    
*****************************************************/
(
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(64)
	set @transName = 'UpdateProteinCollectionsByOrganism'
	begin transaction @transName

	begin
		DROP TABLE T_Protein_Collections_By_Organism
		
SELECT     V_Protein_Collections_By_Organism.Protein_Collection_ID, V_Protein_Collections_By_Organism.Display, 
                      V_Protein_Collections_By_Organism.Description, T_Protein_Collections.Collection_State_ID, T_Protein_Collections.Collection_Type_ID, 
                      T_Protein_Collections.NumProteins, T_Protein_Collections.Authentication_Hash, V_Protein_Collections_By_Organism.FileName, 
                      V_Protein_Collections_By_Organism.Organism_ID, V_Protein_Collections_By_Organism.Primary_Annotation_Type_ID AS Authority_ID, 
                      V_Protein_Collections_By_Organism.Short_Name AS Organism_Name, 
                      V_Protein_Collections_By_Organism.Contents_Encrypted AS Contents_Encrypted
INTO            T_Protein_Collections_By_Organism
FROM         T_Protein_Collections INNER JOIN
                      V_Protein_Collections_By_Organism ON T_Protein_Collections.Protein_Collection_ID = V_Protein_Collections_By_Organism.Protein_Collection_ID

--		SELECT  
--			T_Protein_Collections.Protein_Collection_ID, 
--			T_Protein_Collections.FileName + ' (' + CAST(dbo.T_Protein_Collections.NumProteins AS varchar)
--                       + ' Entries)' AS Display, 
--            T_Protein_Collections.Description, 
--            T_Protein_Collections.Collection_State_ID, 
--            T_Protein_Collections.NumProteins,
--           T_Protein_Collections.SHA1Authentication, 
--            T_Protein_Collections.FileName, 
--            V_Protein_Collection_Organism.Organism_ID,
--            T_Protein_Collections.Primary_Authority_ID
--        INTO T_Protein_Collections_By_Organism
--        FROM T_Protein_Collections INNER JOIN
--                      V_Protein_Collection_Organism 
--                      ON T_Protein_Collections.Protein_Collection_ID = V_Protein_Collection_Organism.Protein_Collection_ID
     
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert operation failed'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end
	
	commit transaction @transName

	
	return 0

GO
GRANT EXECUTE ON [dbo].[x_UpdateProteinCollectionsByOrganism_Old] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
