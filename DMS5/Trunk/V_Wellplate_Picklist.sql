/****** Object:  View [dbo].[V_Wellplate_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Wellplate_Picklist
AS
SELECT     [Well Plate] + ' ' + CAST(ISNULL(Description, '') AS Char(24)) AS val, [Well Plate] AS ex
FROM         dbo.V_Run_Assignment_Wellplate_List_Report

GO
