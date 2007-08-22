/****** Object:  View [dbo].[V_Instrument_Admin_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Instrument_Admin_Picklist
AS
SELECT     IN_name + ' ' + IN_usage AS val, IN_name AS ex
FROM         dbo.T_Instrument_Name
WHERE  (IN_status = 'active')



GO
