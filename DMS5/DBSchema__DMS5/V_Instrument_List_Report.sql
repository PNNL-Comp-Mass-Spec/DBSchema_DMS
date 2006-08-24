/****** Object:  View [dbo].[V_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_List_Report
AS
SELECT     dbo.T_Instrument_Name.Instrument_ID AS ID, dbo.T_Instrument_Name.IN_name AS Name, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS [Assigned Storage], S.Source AS [Assigned Source], 
                      dbo.T_Instrument_Name.IN_Description AS Description, dbo.T_Instrument_Name.IN_class AS Class, 
                      dbo.T_Instrument_Name.IN_Room_Number AS Room, dbo.T_Instrument_Name.IN_capture_method AS Capture, 
                      dbo.T_Instrument_Name.IN_status AS Status, dbo.T_Instrument_Name.IN_usage AS Usage, 
                      dbo.T_Instrument_Name.IN_operations_role AS [Ops Role]
FROM         dbo.T_Instrument_Name INNER JOIN
                      dbo.t_storage_path ON dbo.T_Instrument_Name.IN_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                          (SELECT     SP_path_ID, SP_vol_name_server + SP_path AS Source
                            FROM          t_storage_path) S ON S.SP_path_ID = dbo.T_Instrument_Name.IN_source_path_ID

GO
