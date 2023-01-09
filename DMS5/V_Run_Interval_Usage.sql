/****** Object:  View [dbo].[V_Run_Interval_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_Usage]
AS
SELECT id,
       ISNULL(xmlNode.value('@UserRemote', 'nvarchar(256)'), 0) user_remote,
       ISNULL(xmlNode.value('@UserOnsite', 'nvarchar(256)'), 0) user_onsite,
       ISNULL(xmlNode.value('@User', 'nvarchar(256)'), 0) [user],
       ISNULL(xmlNode.value('@Proposal', 'nvarchar(256)'), '') user_proposal,
       ISNULL(xmlNode.value('@Broken', 'nvarchar(256)'), 0) broken,
       ISNULL(xmlNode.value('@Maintenance', 'nvarchar(256)'), 0) maintenance,
       ISNULL(xmlNode.value('@StaffNotAvailable', 'nvarchar(256)'), 0) staff_not_available,
       ISNULL(xmlNode.value('@CapDev', 'nvarchar(256)'), 0) cap_dev,
       ISNULL(xmlNode.value('@InstrumentAvailable', 'nvarchar(256)'), 0) instrument_available
FROM T_Run_Interval cross apply Usage.nodes('//u') AS R(xmlNode)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_Usage] TO [DDL_Viewer] AS [dbo]
GO
