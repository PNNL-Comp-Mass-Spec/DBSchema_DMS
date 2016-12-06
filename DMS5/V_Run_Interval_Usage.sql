/****** Object:  View [dbo].[V_Run_Interval_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_Usage]
AS
SELECT ID, 
       ISNULL(xmlNode.value('@User', 'nvarchar(256)'), 0) [User],
       ISNULL(xmlNode.value('@Proposal', 'nvarchar(256)'), '') User_Proposal,
       ISNULL(xmlNode.value('@Broken', 'nvarchar(256)'), 0) Broken,
       ISNULL(xmlNode.value('@Maintenance', 'nvarchar(256)'), 0) Maintenance,
       ISNULL(xmlNode.value('@StaffNotAvailable', 'nvarchar(256)'), 0) StaffNotAvailable,
       ISNULL(xmlNode.value('@CapDev', 'nvarchar(256)'), 0) CapDev,
       ISNULL(xmlNode.value('@InstrumentAvailable', 'nvarchar(256)'), 0) InstrumentAvailable
FROM T_Run_Interval cross apply Usage.nodes('//u') AS R(xmlNode)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_Usage] TO [DDL_Viewer] AS [dbo]
GO
