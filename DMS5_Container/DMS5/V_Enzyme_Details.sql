/****** Object:  View [dbo].[V_Enzyme_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Enzyme_Details
AS
SELECT     Enzyme_Name AS enzyme_name, NULLIF (P1, 'na') AS left_cleave_point, NULLIF (P1_Exception, 'na') AS left_no_cleave_point, NULLIF (P2, 'na') 
                      AS right_cleave_point, NULLIF (P2_Exception, 'na') AS right_no_cleave_point, NULLIF (Cleavage_Method, 'na') AS cleavage_method, Cleavage_Offset AS offset, 
                      Sequest_Enzyme_Index AS selected_enzyme_index
FROM         dbo.T_Enzymes

GO
