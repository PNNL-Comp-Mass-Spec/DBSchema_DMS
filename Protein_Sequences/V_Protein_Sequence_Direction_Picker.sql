/****** Object:  View [dbo].[V_Protein_Sequence_Direction_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Sequence_Direction_Picker
AS
SELECT     Output_Sequence_Type_ID AS ID, Output_Sequence_Type AS Direction, Display, Description
FROM         dbo.T_Output_Sequence_Types

GO
