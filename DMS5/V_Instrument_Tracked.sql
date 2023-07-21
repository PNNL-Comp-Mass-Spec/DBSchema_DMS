/****** Object:  View [dbo].[V_Instrument_Tracked] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Tracked]
AS
SELECT Name,
       Reporting,
       Description,
       Ops_Role,
       EMSL_Primary,
       [Group],
       Class,
       EUS_Instrument_Name,
       EUS_Instrument_ID,
       EUS_Available_Hours,
       EUS_Active_Sw,
       EUS_Primary_Instrument,
       Percent_EMSL_Owned,
       Tracked,
       Name + ' (' + Reporting + ')' As Name_with_Reporting
FROM (SELECT TD.IN_name AS Name,
             CASE WHEN TI.EUS_Primary_Instrument IN ('Y', '1') THEN 'E' ELSE '' END +
             CASE WHEN TD.IN_operations_role = 'Production'    THEN 'P' ELSE '' END +
             CASE WHEN TD.IN_Tracking = 1                      THEN 'T' ELSE '' END AS Reporting,
             TD.IN_Description AS Description,
             TD.IN_operations_role AS Ops_Role,
             TI.EUS_Primary_Instrument AS EMSL_Primary,
             TD.IN_Group AS [Group],
             TD.IN_class AS Class,
             TI.EUS_Instrument_Name,
             TI.EUS_Instrument_ID,
             TI.EUS_Available_Hours,
             TI.EUS_Active_Sw,
             TI.EUS_Primary_Instrument,
             TD.Percent_EMSL_Owned,
             TD.IN_Tracking AS [Tracked]
      FROM T_EMSL_Instruments AS TI
           INNER JOIN T_EMSL_DMS_Instrument_Mapping AS TM
             ON TI.EUS_Instrument_ID = TM.EUS_Instrument_ID
           RIGHT OUTER JOIN T_Instrument_Name AS TD
             ON TM.DMS_Instrument_ID = TD.Instrument_ID
      WHERE TD.IN_status = 'active' AND
            TD.IN_operations_role = 'Production' OR
            TD.IN_Tracking = 1 OR
            TI.EUS_Primary_Instrument IN ('Y', '1') AND
            TI.EUS_Active_Sw = 'Y'
      ) FilterQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Tracked] TO [DDL_Viewer] AS [dbo]
GO
