/****** Object:  StoredProcedure [dbo].[GetSharedProteinIDs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ken Auberry
-- Create date: 2004-04-16
-- Description:	Shows the shared Protein_IDs for two collections
-- =============================================
create PROCEDURE GetSharedProteinIDs 
	-- Add the parameters for the stored procedure here
	@Collection_1 int = 0, 
	@Collection_2 int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	WITH Collection_1 AS 
		(SELECT     Protein_ID, Protein_Collection_ID
         FROM         dbo.T_Protein_Collection_Members
         WHERE     (Protein_Collection_ID = @Collection_1)),
		 Collection_2(protein_ID, protein_collection_ID) AS
		(SELECT     Protein_ID, Protein_Collection_ID
		 FROM          dbo.T_Protein_Collection_Members
		 WHERE      (Protein_Collection_ID = @Collection_2))
	SELECT     collection_2.protein_ID
		FROM Collection_1 
		INNER JOIN Collection_2 
		ON Collection_1.Protein_ID = Collection_2.protein_ID
END

GO
