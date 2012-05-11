/****** Object:  View [dbo].[V_Protein_Collection_Members_Insert] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collection_Members_Insert
AS
SELECT     Original_Reference_ID, Protein_ID, Protein_Collection_ID, Sorting_Index, Original_Description_ID
FROM         dbo.T_Protein_Collection_Members

GO
