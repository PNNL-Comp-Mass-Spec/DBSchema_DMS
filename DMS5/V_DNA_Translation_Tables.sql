/****** Object:  View [dbo].[V_DNA_Translation_Tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DNA_Translation_Tables]
AS
SELECT Translation_Table_Name_ID,
       Translation_Table_Name,
       DNA_Translation_Table_ID
FROM S_ProteinSeqs_T_DNA_Translation_Tables


GO
GRANT VIEW DEFINITION ON [dbo].[V_DNA_Translation_Tables] TO [PNL\D3M578] AS [dbo]
GO
