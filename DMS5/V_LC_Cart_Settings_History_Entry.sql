/****** Object:  View [dbo].[V_LC_Cart_Settings_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_LC_Cart_Settings_History_Entry
AS
SELECT CONVERT(varchar, MONTH(CSH.Date_Of_Change)) + '/' + CONVERT(varchar, DAY(CSH.Date_Of_Change))  + '/' + CONVERT(varchar, YEAR(CSH.Date_Of_Change)) AS date_of_change,
       CSH.id,
       CSH.valve_to_column_extension,
       CSH.valve_to_column_extension_dimensions,
       CSH.operating_pressure,
       CSH.interface_configuration,
       CSH.mixer_volume,
       CSH.sample_loop_volume,
       CSH.sample_loading_time,
       CSH.split_flow_rate,
       CSH.split_column_dimensions,
       CSH.purge_flow_rate,
       CSH.purge_column_dimensions,
       CSH.purge_volume,
       CSH.acquisition_time,
       CSH.comment,
       C.Cart_Name AS cart_name,
       CSH.entered,
       CSH.EnteredBy AS entered_by,
       CSH.solvent_a,
       CSH.solvent_b
FROM T_LC_Cart_Settings_History CSH
     INNER JOIN T_LC_Cart C
       ON CSH.Cart_ID = C.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_Entry] TO [DDL_Viewer] AS [dbo]
GO
