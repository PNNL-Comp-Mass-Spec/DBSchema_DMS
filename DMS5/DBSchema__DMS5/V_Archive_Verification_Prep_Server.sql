/****** Object:  View [dbo].[V_Archive_Verification_Prep_Server] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Verification_Prep_Server
AS
SELECT     REPLACE(message, 'Verifying Archived dataset ', '') AS Dataset, REPLACE(posted_by, 'ArchiveVerify: ', '') AS PrepServer
FROM         dbo.T_Log_Entries
WHERE     (message LIKE 'Verifying Archived dataset%')

GO
