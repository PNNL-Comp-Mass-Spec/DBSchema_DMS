/****** Object:  StoredProcedure [dbo].[x_UpdateProteinCollectionsByOrganism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[x_UpdateProteinCollectionsByOrganism]
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
**		Modified 06/01/2006 kja
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
		
		SELECT DISTINCT VPC.Protein_Collection_ID,
                VPC.Display,
                VPC.Description,
                PC.Collection_State_ID,
                PC.Collection_Type_ID,
                PC.NumProteins,
                PC.Authentication_Hash,
                VPC.FileName,
                OrgXRef.Organism_ID,
                VPC.Primary_Annotation_Type_ID AS Authority_ID,
                OrgPicker.Short_Name AS Organism_Name,
                VPC.Contents_Encrypted AS Contents_Encrypted
        INTO T_Protein_Collections_By_Organism
		FROM T_Protein_Collections PC
			INNER JOIN T_Collection_Organism_Xref OrgXRef
			ON PC.Protein_Collection_ID = OrgXRef.Protein_Collection_ID
			INNER JOIN V_Protein_Collections VPC
			ON PC.Protein_Collection_ID = VPC.Protein_Collection_ID
			INNER JOIN V_Organism_Picker OrgPicker
			ON OrgXRef.Organism_ID = OrgPicker.ID
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
GRANT EXECUTE ON [dbo].[x_UpdateProteinCollectionsByOrganism] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
