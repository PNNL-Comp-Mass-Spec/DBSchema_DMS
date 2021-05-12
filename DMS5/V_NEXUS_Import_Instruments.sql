/****** Object:  View [dbo].[V_NEXUS_Import_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NEXUS_Import_Instruments]
As
(
SELECT instrument_id, 
       instrument_name, 
       eus_display_name, 
       available_hours,
       active_sw, 
       primary_instrument
FROM openquery ( NEXUS, 'SELECT * FROM proteomics_views.vw_instruments' )
)

GO
