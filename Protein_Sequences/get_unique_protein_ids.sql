/****** Object:  StoredProcedure [dbo].[GetUniqueProteinIDs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetUniqueProteinIDs]
-- =============================================
-- Author:      Ken Auberry
-- Create date: 2004-04-16
-- Description: Shows the Protein_IDs present in
--              collection_1 that are not in
--              collection_2
-- =============================================
(
    @Collection_1 int,
    @Collection_2 int
)
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
        RIGHT OUTER JOIN Collection_2
        ON Collection_1.Protein_ID = Collection_2.protein_ID
        WHERE (Collection_1.Protein_ID IS NULL)

END

GO
