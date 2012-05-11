/****** Object:  View [dbo].[V_Capture_Machines_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Machines_Detail_Report]
AS
SELECT     Machine, Bionet_Available
FROM         T_Machines

GO
