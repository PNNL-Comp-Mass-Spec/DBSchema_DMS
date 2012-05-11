/****** Object:  View [dbo].[V_Capture_Step_Tools_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Step_Tools_Entry
AS
SELECT     ID, Name, Description, Bionet_Required AS BionetRequired, Only_On_Storage_Server AS OnlyOnStorageServer, 
                      Instrument_Capacity_Limited AS InstrumentCapacityLimited
FROM         dbo.T_Step_Tools

GO
