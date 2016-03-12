/****** Object:  View [dbo].[V_Instrument_Source_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Instrument_Source_Paths] AS 
SELECT TP.SP_vol_name_server AS vol,
       TP.SP_path AS [Path],
       TIN.IN_capture_method AS method,
       TIN.IN_name AS Instrument
FROM T_Instrument_Name AS TIN
     INNER JOIN t_storage_path AS TP
       ON TIN.IN_source_path_ID = TP.SP_path_ID
WHERE (TIN.IN_status = 'active')
/*
** Removed reference to Prep Instruments on 9/21/2012
UNION
SELECT TP.SP_vol_name_server AS vol,
       TP.SP_path AS [Path],
       TIN.Capture_Method AS method,
       TIN.Name AS Instrument
FROM T_Prep_Instruments AS TIN
     INNER JOIN T_Prep_Instrument_Storage AS TP
       ON TP.SP_instrument_name = TIN.Name AND
          TP.SP_function = 'inbox'
WHERE TIN.Status = 'active'
*/


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Source_Paths] TO [PNL\D3M578] AS [dbo]
GO
