/****** Object:  View [dbo].[V_Instrument_Tracked] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Tracked
AS
SELECT        dbo.T_Instrument_Name.Instrument_ID AS ID, dbo.T_Instrument_Name.IN_name AS Name, dbo.T_Instrument_Name.IN_Description AS Description, 
                         dbo.T_Instrument_Name.IN_operations_role AS Ops_Role, dbo.T_Instrument_Name.IN_Group AS [Group], dbo.T_Instrument_Name.IN_class AS Class, 
                         dbo.T_EMSL_Instruments.EUS_Instrument_Name, dbo.T_EMSL_Instruments.EUS_Instrument_ID, dbo.T_EMSL_Instruments.EUS_Available_Hours, 
                         dbo.T_EMSL_Instruments.EUS_Active_Sw, dbo.T_EMSL_Instruments.EUS_Primary_Instrument, dbo.T_Instrument_Name.Percent_EMSL_Owned
FROM            dbo.T_EMSL_Instruments INNER JOIN
                         dbo.T_EMSL_DMS_Instrument_Mapping ON 
                         dbo.T_EMSL_Instruments.EUS_Instrument_ID = dbo.T_EMSL_DMS_Instrument_Mapping.EUS_Instrument_ID RIGHT OUTER JOIN
                         dbo.T_Instrument_Name ON dbo.T_EMSL_DMS_Instrument_Mapping.DMS_Instrument_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE        (dbo.T_Instrument_Name.IN_status = 'active') AND (dbo.T_Instrument_Name.IN_operations_role = 'Production') OR
                         (dbo.T_Instrument_Name.IN_status = 'active') AND (dbo.T_EMSL_Instruments.EUS_Active_Sw = 'Y')

GO
