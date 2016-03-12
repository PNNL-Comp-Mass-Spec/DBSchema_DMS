/****** Object:  View [dbo].[V_Archive_Path_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Path_Entry
AS
SELECT     TAP.AP_path_ID, TAP.AP_archive_path, TAP.AP_Server_Name, TIN.IN_name AS AP_instrument_name, TAP.Note, TAP.AP_Function, 
                      TAP.AP_network_share_path
FROM         dbo.T_Archive_Path AS TAP INNER JOIN
                      dbo.T_Instrument_Name AS TIN ON TAP.AP_instrument_name_ID = TIN.Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_Entry] TO [PNL\D3M578] AS [dbo]
GO
