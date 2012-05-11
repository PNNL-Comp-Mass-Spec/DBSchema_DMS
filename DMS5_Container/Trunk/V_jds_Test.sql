/****** Object:  View [dbo].[V_jds_Test] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_jds_Test]
AS
SELECT 1 as ID, 'True' as Selected, 'first record' as Entities

GO
GRANT VIEW DEFINITION ON [dbo].[V_jds_Test] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_jds_Test] TO [PNL\D3M580] AS [dbo]
GO
